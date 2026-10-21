<script lang="ts">
	import type { Cycle, KpiDirection, NodeStatus, NodeWithExtras, Profile, StrategyNode, Team } from '$lib/types';
	import { enhanceFormValidation, formatNumber, formatPct, getInitials, getTeamIcon } from '$lib/utils';
	import { getDossierTheme } from '$lib/dossier-theme';
	import PaperColorPicker from '$lib/components/ui/PaperColorPicker.svelte';
	import { onMount } from 'svelte';

	interface Props {
		node: NodeWithExtras | null;
		allNodes: StrategyNode[];
		cycles: Cycle[];
		profiles: Profile[];
		teams: Team[];
		canEdit: boolean;
		onClose: () => void;
		onOpenParent?: (id: string) => void;
	}

	let {
		node,
		allNodes,
		cycles,
		profiles,
		teams,
		canEdit,
		onClose,
		onOpenParent
	}: Props = $props();

	// Active tab
	let activeTab = $state<'tab1' | 'tab2' | 'tab3'>('tab1');

	// Local mutable states
	let title = $state('');
	let description = $state('');
	let status = $state<NodeStatus>('on_track');
	let weight = $state(1);
	let cycleId = $state('');
	let parentId = $state('');
	let unit = $state('');
	let baseline = $state(0);
	let targetValue = $state(100);
	let currentValue = $state(0);
	let direction = $state<KpiDirection>('up');

	// Relationships state
	let selectedTeamIds = $state<string[]>([]);
	let selectedMemberIds = $state<string[]>([]);

	// Visual theme state
	let accentColor = $state('#00665a');

	// Check-in input states for Tab 2
	let newCheckinValue = $state<number | null>(null);
	let newCheckinNote = $state('');
	let isLoggingCheckin = $state(false);

	// Dropdowns and confirmation
	let showAddTeamDropdown = $state(false);
	let showAddMemberDropdown = $state(false);
	let showDeleteConfirm = $state(false);
	let isSaving = $state(false);

	// Sync local states whenever node prop changes
	$effect(() => {
		if (node) {
			title = node.title;
			description = node.description ?? '';
			status = node.status;
			weight = node.weight;
			cycleId = node.cycle_id ?? '';
			parentId = node.parent_id ?? '';
			unit = node.unit ?? '';
			baseline = node.baseline ?? 0;
			targetValue = node.target_value ?? 100;
			currentValue = node.current_value ?? 0;
			direction = node.direction ?? 'up';

			selectedTeamIds = node.teams.map((t) => t.id);
			selectedMemberIds = node.assignees.map((a) => a.id);

			// Initial accent color: if node has color, prioritize it
			if (node.color) {
				accentColor = node.color;
			} else if (node.teams.length > 0 && node.teams[0].color) {
				accentColor = node.teams[0].color;
			} else {
				accentColor = '#00665a';
			}
		}
	});

	// Color swatches for KPI customization
	const colorSwatches = [
		{ name: 'Teal Esmeralda', hex: '#00665a' },
		{ name: 'Azul Céu', hex: '#0284c7' },
		{ name: 'Azul Horizonte', hex: '#0058bd' },
		{ name: 'Verde Floresta', hex: '#059669' },
		{ name: 'Roxo Métrico', hex: '#7c3aed' },
		{ name: 'Framboesa', hex: '#b30069' },
		{ name: 'Laranja Terracota', hex: '#ea580c' }
	];

	// Derived theme
	const theme = $derived(getDossierTheme(accentColor));

	// Parent Key Result
	const parentKr = $derived.by(() => {
		if (!node || !parentId) return null;
		return allNodes.find((n) => n.id === parentId) ?? null;
	});

	// Root Objective (Grandparent)
	const rootObjective = $derived.by(() => {
		if (!parentKr || !parentKr.parent_id) return null;
		return allNodes.find((n) => n.id === parentKr.parent_id) ?? null;
	});

	// Valid potential parents for reparenting (Key Results or Objectives)
	const validParents = $derived(
		allNodes.filter((n) => n.id !== node?.id && (n.type === 'key_result' || n.type === 'objective'))
	);

	// Resolved cycle
	const currentCycle = $derived.by(() => {
		if (!node) return null;
		if (cycleId) return cycles.find((c) => c.id === cycleId) ?? null;
		return node.cycle;
	});

	// Progress calculation based on direction
	const calculatedProgressPct = $derived.by(() => {
		if (targetValue === baseline) return 100;
		let raw = 0;
		if (direction === 'down') {
			raw = (baseline - currentValue) / (baseline - targetValue);
		} else {
			raw = (currentValue - baseline) / (targetValue - baseline);
		}
		return Math.round(Math.max(0, Math.min(1.5, raw)) * 100);
	});

	const deltaValue = $derived(currentValue - baseline);

	// Sparkline generator for Tab 2
	const sparklineData = $derived.by(() => {
		if (!node) return null;
		const chron = [...node.metricUpdates].reverse();
		const vals = chron.map((m) => m.value);
		if (node.baseline != null) vals.unshift(node.baseline);
		if (vals.length < 2) return null;

		const min = Math.min(...vals, targetValue, baseline);
		const max = Math.max(...vals, targetValue, baseline);
		const range = max - min || 1;
		const W = 520;
		const H = 140;
		const padX = 20;
		const padY = 16;

		const coords = vals.map((v, idx) => {
			const x = padX + (idx / (vals.length - 1)) * (W - padX * 2);
			const y = H - padY - ((v - min) / range) * (H - padY * 2);
			return { x, y, v };
		});

		const d = coords.reduce((acc, pt, i) => `${acc} ${i === 0 ? 'M' : 'L'} ${pt.x} ${pt.y}`, '');
		const targetY = H - padY - ((targetValue - min) / range) * (H - padY * 2);

		return {
			d,
			coords,
			targetY,
			W,
			H,
			min,
			max
		};
	});

	// Keyboard dismiss listener
	function handleKeyDown(e: KeyboardEvent) {
		if (e.key === 'Escape' && !showDeleteConfirm) {
			onClose();
		}
	}

	onMount(() => {
		document.addEventListener('keydown', handleKeyDown);
		return () => {
			document.removeEventListener('keydown', handleKeyDown);
		};
	});

	// Status options config
	const statusOptions: Array<{
		key: NodeStatus;
		label: string;
		dotClass: string;
		activeClass: string;
	}> = [
		{
			key: 'not_started',
			label: 'Pendente',
			dotClass: 'bg-stone-400',
			activeClass: 'border-stone-400 bg-stone-100 text-stone-700'
		},
		{
			key: 'on_track',
			label: 'No Alvo',
			dotClass: 'bg-emerald-500',
			activeClass: 'border-emerald-500 bg-emerald-50 text-emerald-800'
		},
		{
			key: 'at_risk',
			label: 'Em Risco',
			dotClass: 'bg-amber-500',
			activeClass: 'border-amber-500 bg-amber-50 text-amber-800'
		},
		{
			key: 'off_track',
			label: 'Fora da Rota',
			dotClass: 'bg-red-500',
			activeClass: 'border-red-500 bg-red-50 text-red-800'
		},
		{
			key: 'done',
			label: 'Concluído',
			dotClass: 'bg-blue-600',
			activeClass: 'border-blue-600 bg-blue-50 text-blue-800'
		}
	];

	function addTeam(teamId: string) {
		if (!selectedTeamIds.includes(teamId)) {
			selectedTeamIds = [...selectedTeamIds, teamId];
		}
		showAddTeamDropdown = false;
	}

	function removeTeam(teamId: string) {
		selectedTeamIds = selectedTeamIds.filter((id) => id !== teamId);
	}

	function addMember(userId: string) {
		if (!selectedMemberIds.includes(userId)) {
			selectedMemberIds = [...selectedMemberIds, userId];
		}
		showAddMemberDropdown = false;
	}

	function removeMember(userId: string) {
		selectedMemberIds = selectedMemberIds.filter((id) => id !== userId);
	}

	// Full save handler synchronizing node and assignees
	async function handleSaveSubmit(e: SubmitEvent) {
		if (!node) return;
		isSaving = true;

		try {
			// Sincroniza responsáveis e equipes
			const fdAssign = new FormData();
			fdAssign.append('nodeId', node.id);
			for (const u of selectedMemberIds) fdAssign.append('userIds', u);
			for (const t of selectedTeamIds) fdAssign.append('teamIds', t);
			await fetch('/strategy?/setAssignees', { method: 'POST', body: fdAssign });
		} catch (err) {
			console.error('Falha ao sincronizar responsáveis do KPI:', err);
		} finally {
			isSaving = false;
		}
	}
</script>

{#if node}
	<!-- Modal Backdrop Overlay -->
	<div
		role="presentation"
		onclick={onClose}
		class="fixed inset-0 z-50 flex items-center justify-center p-3 sm:p-6 bg-[#181613]/60 backdrop-blur-[5px] overflow-y-auto"
	>
		<!-- WRAPPER: PASTA DE ARQUIVO COM ABAS (SEM TRILHO METÁLICO SUPERIOR) -->
		<!-- svelte-ignore a11y_click_events_have_key_events -->
		<div
			role="dialog"
			tabindex="-1"
			aria-modal="true"
			aria-labelledby="kpi-modal-title"
			onclick={(e) => e.stopPropagation()}
			class="relative w-full max-w-5xl my-auto flex flex-col items-stretch animate-in fade-in zoom-in-95 duration-200"
			style="font-family: 'Poppins', sans-serif;"
		>
			<!-- 1. TOPO DA PASTA: ABAS SALIENTES DE ARQUIVO (SEM TRILHO METÁLICO SUPERIOR) -->
			<div class="flex items-end justify-between px-3 sm:px-6 -mb-[1px] relative z-30">
				<!-- Grupo de Abas Recortadas -->
				<div class="flex items-end gap-1.5 overflow-x-auto overflow-y-hidden no-scrollbar">
					<!-- Aba 1: Parâmetros & Metas -->
					<button
						type="button"
						onclick={() => (activeTab = 'tab1')}
						class="folder-tab group flex items-center gap-2 px-4 sm:px-5 py-2.5 text-xs font-bold transition-all cursor-pointer rounded-t-xl {activeTab ===
						'tab1'
							? 'border-t-2 border-l-2 border-r-2 text-on-surface shadow-[0_-3px_8px_rgba(29,27,23,0.06)] relative after:absolute after:bottom-[-2px] after:left-0 after:right-0 after:h-[3px]'
							: 'bg-white/70 hover:bg-white/90 border-t-2 border-l border-r border-transparent text-[#727784] hover:text-[#1d1b17]'}"
						style={activeTab === 'tab1'
							? `background-color: ${theme.folderBg}; border-color: ${theme.folderBorder}; after:bg-color: ${theme.folderBg};`
							: ''}
					>
						<span
							class="w-2.5 h-2.5 rounded-full shrink-0 shadow-xs"
							style="background-color: {theme.accent};"
						></span>
						<span class="tracking-tight whitespace-nowrap">1. Parâmetros &amp; Meta</span>
						{#if activeTab === 'tab1'}
							<span
								class="text-[10px] px-1.5 py-0.2 rounded font-bold ml-0.5"
								style="background-color: {theme.badgeBg}; color: {theme.badgeText};"
							>
								{calculatedProgressPct}%
							</span>
						{/if}
					</button>

					<!-- Aba 2: Histórico & Check-ins -->
					<button
						type="button"
						onclick={() => (activeTab = 'tab2')}
						class="folder-tab group flex items-center gap-2 px-4 sm:px-5 py-2.5 text-xs font-bold transition-all cursor-pointer rounded-t-xl {activeTab ===
						'tab2'
							? 'border-t-2 border-l-2 border-r-2 text-on-surface shadow-[0_-3px_8px_rgba(29,27,23,0.06)] relative after:absolute after:bottom-[-2px] after:left-0 after:right-0 after:h-[3px]'
							: 'bg-white/70 hover:bg-white/90 border-t-2 border-l border-r border-transparent text-[#727784] hover:text-[#1d1b17]'}"
						style={activeTab === 'tab2'
							? `background-color: ${theme.folderBg}; border-color: ${theme.folderBorder};`
							: ''}
					>
						<span class="material-symbols-outlined text-[15px]" style="color: {theme.accent};">
							timeline
						</span>
						<span class="tracking-tight whitespace-nowrap">2. Histórico &amp; Check-ins</span>
						<span
							class="text-[10px] px-1.5 py-0.2 rounded-full font-bold ml-0.5"
							style="background-color: {theme.badgeBg}; color: {theme.badgeText};"
						>
							{node.metricUpdates.length}
						</span>
					</button>

					<!-- Aba 3: Vínculos & Equipes -->
					<button
						type="button"
						onclick={() => (activeTab = 'tab3')}
						class="folder-tab group flex items-center gap-2 px-4 sm:px-5 py-2.5 text-xs font-bold transition-all cursor-pointer rounded-t-xl {activeTab ===
						'tab3'
							? 'border-t-2 border-l-2 border-r-2 text-on-surface shadow-[0_-3px_8px_rgba(29,27,23,0.06)] relative after:absolute after:bottom-[-2px] after:left-0 after:right-0 after:h-[3px]'
							: 'bg-white/70 hover:bg-white/90 border-t-2 border-l border-r border-transparent text-[#727784] hover:text-[#1d1b17]'}"
						style={activeTab === 'tab3'
							? `background-color: ${theme.folderBg}; border-color: ${theme.folderBorder};`
							: ''}
					>
						<span class="material-symbols-outlined text-[15px]" style="color: {theme.accent};">
							groups
						</span>
						<span class="tracking-tight whitespace-nowrap">3. Vínculos &amp; Equipe</span>
						<span
							class="text-[10px] px-1.5 py-0.2 rounded-full font-bold ml-0.5"
							style="background-color: {theme.badgeBg}; color: {theme.badgeText};"
						>
							{selectedTeamIds.length + selectedMemberIds.length}
						</span>
					</button>
				</div>

				<!-- Canto Superior Direito: Seletor de Cor & Botão Fechar -->
				<div class="flex items-center gap-2 pb-1.5 pr-1 shrink-0 relative z-40">
					<PaperColorPicker bind:value={accentColor} disabled={!canEdit} align="right" />

					<button
						type="button"
						onclick={onClose}
						class="w-8 h-8 rounded-full bg-white/95 hover:bg-white text-[#524d45] hover:text-[#1d1b17] border border-[#cfc5b4] shadow-sm flex items-center justify-center transition-all hover:scale-105 active:scale-95 cursor-pointer"
						title="Fechar Pasta"
					>
						<span class="material-symbols-outlined text-[18px]">close</span>
					</button>
				</div>
			</div>

			<!-- 2. CORPO DA PASTA FÍSICA: Manilha Elegante com tom suave da cor do indicador -->
			<div
				class="w-full border-2 rounded-2xl hanging-folder-shadow flex flex-col relative overflow-hidden transition-colors duration-200"
				style="background-color: {theme.folderBg}; border-color: {theme.folderBorder};"
			>
				<!-- Linha de reforço estrutural com gradiente sutil -->
				<div
					class="h-1.5 w-full relative z-10 border-b transition-colors duration-200"
					style="background: linear-gradient(to right, color-mix(in srgb, {accentColor} 25%, transparent), color-mix(in srgb, {accentColor} 45%, transparent), color-mix(in srgb, {accentColor} 20%, transparent)); border-color: {theme.folderBorder};"
				></div>

				<!-- Barra de Cabeçalho do Dossiê -->
				<div
					class="px-5 py-3 sm:px-6 sm:py-3.5 border-b flex items-center justify-between shrink-0 bg-white/60"
					style="border-color: {theme.cardBorder};"
				>
					<div class="flex flex-wrap items-center gap-2.5">
						<div
							class="flex items-center gap-1.5 px-2.5 py-0.5 rounded border text-[11px] font-extrabold uppercase tracking-wider"
							style="background-color: {theme.badgeBg}; border-color: {theme.badgeBorder}; color: {theme.badgeText};"
						>
							<span class="material-symbols-outlined text-[14px]">analytics</span>
							<span>DOSSIÊ KPI OPERACIONAL</span>
						</div>

						{#if parentKr}
							<div class="flex items-center gap-1.5 px-2 py-0.5 rounded-md bg-white border border-[#d5cebe] text-[11px] font-semibold text-[#424753]">
								<span class="material-symbols-outlined text-[14px] text-primary">arrow_upward</span>
								<span>KR Pai: <strong class="text-[#1d1b17]">{parentKr.title.slice(0, 32)}...</strong></span>
							</div>
						{/if}
					</div>

					<div class="flex items-center gap-2">
						<span
							class="text-[11px] font-semibold px-2 py-0.5 rounded border hidden sm:inline-flex items-center gap-1"
							style="background-color: {theme.badgeBg}; border-color: {theme.badgeBorder}; color: {theme.badgeText};"
						>
							<span class="material-symbols-outlined text-[13px]">published_with_changes</span>
							{currentCycle?.code ?? '2026-S1'}
						</span>
					</div>
				</div>

				<!-- ÁREA SCROLLÁVEL DA ABA ATIVA -->
				<div class="p-4 sm:p-6 lg:p-7 max-h-[calc(88vh-175px)] overflow-y-auto custom-scroll relative z-10">
					<!-- ============================================================== -->
					<!-- ABA 1: PARÂMETROS, METAS E UNIDADES                            -->
					<!-- ============================================================== -->
					{#if activeTab === 'tab1'}
						<form
							id="updateKpiForm"
							method="POST"
							action="/strategy?/updateNode"
							use:enhanceFormValidation
							onsubmit={handleSaveSubmit}
							class="space-y-5"
						>
							<input type="hidden" name="nodeId" value={node.id} />
							<input type="hidden" name="color" value={accentColor} />

							<!-- Bloco de Identificação -->
							<div
								class="p-5 rounded-2xl border shadow-xs space-y-4 transition-colors"
								style="background-color: {theme.cardBg}; border-color: {theme.cardBorder};"
							>
								<!-- Título do KPI -->
								<div class="space-y-1.5">
									<div class="flex items-center justify-between">
										<label
											for="kpi-title-input"
											class="flex items-center gap-1.5 font-mono text-[11px] uppercase tracking-wider font-bold"
											style="color: {theme.accentDark};"
										>
											<span class="material-symbols-outlined text-[16px]" style="color: {theme.accent};">
												tune
											</span>
											Nome do Indicador-Chave (KPI)
										</label>
										<span
											class="text-[11px] font-mono font-semibold px-2 py-0.5 rounded border"
											style="background-color: {theme.badgeBg}; border-color: {theme.badgeBorder}; color: {theme.badgeText};"
										>
											Nível 03 • Métrica Operacional
										</span>
									</div>
									<div
										class="relative flex items-center rounded-xl px-3.5 py-2.5 shadow-inner transition-all border"
										style="background-color: {theme.inputBg}; border-color: {theme.inputBorder};"
									>
										<input
											id="kpi-title-input"
											name="title"
											type="text"
											required
											disabled={!canEdit}
											bind:value={title}
											placeholder="Ex.: Taxa de Conversão de Leads Inbound (%)"
											class="w-full bg-transparent border-0 p-0 text-[#1d1b17] font-display text-[18px] sm:text-[20px] font-bold tracking-tight focus:ring-0 focus:outline-none"
										/>
										<span class="material-symbols-outlined text-[20px] ml-2 shrink-0" style="color: {theme.accent};">
											edit
										</span>
									</div>
								</div>

								<!-- Vínculo ao Nó Pai (Reparenting) -->
								<div class="space-y-1 pt-1 border-t border-[#edf4ee]">
									<label
										for="kpi-parent-select"
										class="block font-mono text-[10.5px] uppercase font-bold text-[#424753]"
									>
										Resultado-Chave ou Objetivo Vinculado (Nó Pai)
									</label>
									<select
										id="kpi-parent-select"
										name="parent_id"
										disabled={!canEdit}
										bind:value={parentId}
										class="w-full rounded-xl px-3 py-2 text-xs font-semibold text-[#1d1b17] border shadow-inner transition-all"
										style="background-color: {theme.inputBg}; border-color: {theme.inputBorder};"
									>
										{#each validParents as p (p.id)}
											<option value={p.id}>
												[{p.type === 'key_result' ? 'RESULTADO-CHAVE' : 'OBJETIVO'}] {p.title}
											</option>
										{/each}
									</select>
								</div>
							</div>

							<!-- Grid de Métricas Numéricas e Linha de Base -->
							<div
								class="p-5 rounded-2xl border shadow-xs space-y-4 transition-colors"
								style="background-color: {theme.cardBg}; border-color: {theme.cardBorder};"
							>
								<h4
									class="font-mono text-[11px] uppercase tracking-wider font-bold flex items-center gap-1.5"
									style="color: {theme.accentDark};"
								>
									<span class="material-symbols-outlined text-[16px]" style="color: {theme.accent};">
										calculate
									</span>
									Métricas de Apuração &amp; Metas Numéricas
								</h4>

								<div class="grid grid-cols-2 sm:grid-cols-4 gap-3">
									<!-- Unidade -->
									<div class="space-y-1">
										<label for="kpi-unit-input" class="block font-mono text-[10px] uppercase font-bold text-[#727784]">
											Unidade de Medida
										</label>
										<input
											id="kpi-unit-input"
											name="unit"
											type="text"
											disabled={!canEdit}
											bind:value={unit}
											placeholder="R$, %, leads, pts"
											class="w-full rounded-xl px-3 py-2 text-xs font-bold text-[#1d1b17] border shadow-inner"
											style="background-color: {theme.inputBg}; border-color: {theme.inputBorder};"
										/>
									</div>

									<!-- Linha de Base (Início) -->
									<div class="space-y-1">
										<label for="kpi-baseline-input" class="block font-mono text-[10px] uppercase font-bold text-[#727784]">
											Linha de Base
										</label>
										<input
											id="kpi-baseline-input"
											name="baseline"
											type="number"
											step="any"
											disabled={!canEdit}
											bind:value={baseline}
											class="w-full rounded-xl px-3 py-2 text-xs font-bold text-[#1d1b17] border shadow-inner"
											style="background-color: {theme.inputBg}; border-color: {theme.inputBorder};"
										/>
									</div>

									<!-- Valor Atual -->
									<div class="space-y-1">
										<label for="kpi-current-input" class="block font-mono text-[10px] uppercase font-bold text-[#727784]">
											Valor Atual Apurado
										</label>
										<div
											class="rounded-xl px-3 py-2 text-xs font-bold border flex items-center justify-between"
											style="background-color: {theme.badgeBg}; border-color: {theme.badgeBorder}; color: {theme.accentDark};"
										>
											<span>{formatNumber(currentValue, unit)}</span>
											<span class="text-[10px] font-normal text-[#727784]">auto</span>
										</div>
									</div>

									<!-- Meta Alvo -->
									<div class="space-y-1">
										<label for="kpi-target-input" class="block font-mono text-[10px] uppercase font-bold text-[#727784]">
											Meta Desejada
										</label>
										<input
											id="kpi-target-input"
											name="target_value"
											type="number"
											step="any"
											required
											disabled={!canEdit}
											bind:value={targetValue}
											class="w-full rounded-xl px-3 py-2 text-xs font-bold text-[#1d1b17] border shadow-inner"
											style="background-color: {theme.inputBg}; border-color: {theme.inputBorder};"
										/>
									</div>
								</div>

								<!-- Direção & Peso -->
								<div class="grid grid-cols-1 sm:grid-cols-3 gap-3 pt-2 border-t border-[#edf4ee] items-center">
									<!-- Direção da Meta -->
									<div class="space-y-1">
										<label for="kpi-dir-select" class="block font-mono text-[10px] uppercase font-bold text-[#727784]">
											Direção da Meta
										</label>
										<select
											id="kpi-dir-select"
											name="direction"
											disabled={!canEdit}
											bind:value={direction}
											class="w-full rounded-xl px-3 py-1.5 text-xs font-semibold text-[#1d1b17] border"
											style="background-color: {theme.inputBg}; border-color: {theme.inputBorder};"
										>
											<option value="up">Aumentar Valor (↑ Mais é Melhor)</option>
											<option value="down">Reduzir Valor (↓ Menos é Melhor)</option>
										</select>
									</div>

									<!-- Peso -->
									<div class="space-y-1">
										<label for="kpi-weight-input" class="block font-mono text-[10px] uppercase font-bold text-[#727784]">
											Peso no Cálculo
										</label>
										<input
											id="kpi-weight-input"
											name="weight"
											type="number"
											step="0.1"
											min="0.1"
											disabled={!canEdit}
											bind:value={weight}
											class="w-full rounded-xl px-3 py-1.5 text-xs font-semibold text-[#1d1b17] border"
											style="background-color: {theme.inputBg}; border-color: {theme.inputBorder};"
										/>
									</div>

									<!-- Ciclo Semestral -->
									<div class="space-y-1">
										<label for="kpi-cycle-select" class="block font-mono text-[10px] uppercase font-bold text-[#727784]">
											Ciclo Semestral
										</label>
										<select
											id="kpi-cycle-select"
											name="cycle_id"
											disabled={!canEdit}
											bind:value={cycleId}
											class="w-full rounded-xl px-3 py-1.5 text-xs font-semibold text-[#1d1b17] border"
											style="background-color: {theme.inputBg}; border-color: {theme.inputBorder};"
										>
											<option value="">Herdar do Nó Pai</option>
											{#each cycles as cyc (cyc.id)}
												<option value={cyc.id}>{cyc.code} ({cyc.year})</option>
											{/each}
										</select>
									</div>
								</div>

								<!-- Card de Progresso Visual e Delta -->
								<div
									class="p-4 rounded-xl border flex flex-col sm:flex-row items-center justify-between gap-4 mt-2"
									style="background-color: {theme.folderBg}; border-color: {theme.folderBorder};"
								>
									<div class="space-y-1 w-full sm:w-auto">
										<div class="flex items-center gap-2">
											<span class="material-symbols-outlined text-[18px]" style="color: {theme.accent};">
												speed
											</span>
											<span class="text-xs font-bold text-[#1d1b17]">
												Atingimento da Meta: {calculatedProgressPct}%
											</span>
										</div>
										<p class="text-[11px] text-[#727784]">
											Variação desde a base: <strong>{deltaValue >= 0 ? `+${formatNumber(deltaValue, unit)}` : formatNumber(deltaValue, unit)}</strong>
										</p>
									</div>

									<div class="w-full sm:w-56 space-y-1">
										<div class="w-full h-3 rounded-full bg-[#e8e2d8] overflow-hidden p-0.5">
											<div
												class="h-full rounded-full transition-all duration-500"
												style="width: {Math.min(100, calculatedProgressPct)}%; background-color: {theme.accent};"
											></div>
										</div>
										<div class="flex justify-between text-[9px] font-mono text-[#727784]">
											<span>Base: {formatNumber(baseline, unit)}</span>
											<span>Meta: {formatNumber(targetValue, unit)}</span>
										</div>
									</div>
								</div>
							</div>

							<!-- Status e Descrição -->
							<div
								class="p-5 rounded-2xl border shadow-xs space-y-4 transition-colors"
								style="background-color: {theme.cardBg}; border-color: {theme.cardBorder};"
							>
								<!-- Status -->
								<div class="space-y-2">
									<label for="kpi-status" class="block font-mono text-[10.5px] uppercase font-bold text-[#424753]">
										Status do Indicador
									</label>
									<input type="hidden" name="status" value={status} />
									<div class="grid grid-cols-2 sm:grid-cols-5 gap-1.5">
										{#each statusOptions as opt}
											{@const isSelected = status === opt.key}
											<button
												type="button"
												onclick={() => canEdit && (status = opt.key)}
												class="flex flex-col items-center justify-center py-2 px-1 rounded-xl border text-center transition-all cursor-pointer {isSelected
													? `${opt.activeClass} font-bold shadow-xs scale-102`
													: 'bg-[#faf8f5] hover:bg-[#f3ede4] text-[#727784] border-[#e5dfd5]'}"
											>
												<span class="w-2 h-2 rounded-full mb-1 {opt.dotClass}"></span>
												<span class="text-[11px] tracking-tight">{opt.label}</span>
											</button>
										{/each}
									</div>
								</div>

								<!-- Descrição & Metodologia de Cálculo -->
								<div class="space-y-1.5 pt-1 border-t border-[#edf4ee]">
									<label
										for="kpi-desc-input"
										class="flex items-center gap-1.5 font-mono text-[11px] uppercase tracking-wider font-bold"
										style="color: {theme.accentDark};"
									>
										<span class="material-symbols-outlined text-[16px]" style="color: {theme.accent};">
											description
										</span>
										Descrição &amp; Metodologia de Cálculo
									</label>
									<div
										class="rounded-xl p-3 shadow-inner transition-all border"
										style="background-color: {theme.inputBg}; border-color: {theme.inputBorder};"
									>
										<textarea
											id="kpi-desc-input"
											name="description"
											rows="2"
											disabled={!canEdit}
											bind:value={description}
											placeholder="Explique a fórmula, fontes de dados e periodicidade de medição deste indicador..."
											class="w-full bg-transparent border-0 p-0 text-[#1d1b17] font-sans text-[13px] leading-relaxed focus:ring-0 focus:outline-none resize-none font-medium"
										></textarea>
									</div>
								</div>
							</div>
						</form>
					{/if}

					<!-- ============================================================== -->
					<!-- ABA 2: HISTÓRICO DE MEDIÇÕES & NOVO CHECK-IN                   -->
					<!-- ============================================================== -->
					{#if activeTab === 'tab2'}
						<div class="space-y-5">
							<!-- Card de Gráfico Sparkline Contínuo SVG -->
							<div
								class="p-5 rounded-2xl bg-white border shadow-xs space-y-4"
								style="border-color: {theme.cardBorder};"
							>
								<div class="flex items-center justify-between">
									<h4
										class="font-mono text-[11px] uppercase tracking-wider font-bold flex items-center gap-1.5"
										style="color: {theme.accentDark};"
									>
										<span class="material-symbols-outlined text-[18px]" style="color: {theme.accent};">
											show_chart
										</span>
										Trajetória Temporal do Indicador
									</h4>
									<span class="text-xs font-bold" style="color: {theme.accentDark};">
										Atual: {formatNumber(currentValue, unit)} / Meta: {formatNumber(targetValue, unit)}
									</span>
								</div>

								{#if sparklineData}
									<div class="p-3 rounded-xl bg-[#faf8f5] border border-[#e8e2d8] relative overflow-hidden">
										<svg
											viewBox="0 0 {sparklineData.W} {sparklineData.H}"
											class="w-full h-36 overflow-visible"
										>
											<!-- Linha de Meta tracejada horizontal -->
											{#if sparklineData.targetY != null}
												<line
													x1="0"
													y1={sparklineData.targetY}
													x2={sparklineData.W}
													y2={sparklineData.targetY}
													stroke={theme.accent}
													stroke-dasharray="4 3"
													stroke-width="1.5"
													opacity="0.75"
												/>
												<text
													x={sparklineData.W - 60}
													y={sparklineData.targetY - 5}
													font-size="10"
													font-family="monospace"
													fill={theme.accentDark}
													font-weight="bold"
												>
													Meta: {formatNumber(targetValue, unit)}
												</text>
											{/if}

											<!-- Curva contínua das medições -->
											<path
												d={sparklineData.d}
												fill="none"
												stroke={theme.accent}
												stroke-width="3"
												stroke-linecap="round"
												stroke-linejoin="round"
											/>

											<!-- Pontos interativos das medições -->
											{#each sparklineData.coords as pt, idx}
												<circle
													cx={pt.x}
													cy={pt.y}
													r={idx === sparklineData.coords.length - 1 ? '5' : '3.5'}
													fill={idx === sparklineData.coords.length - 1 ? theme.accent : '#ffffff'}
													stroke={theme.accent}
													stroke-width="2"
												>
													<title>Medição: {formatNumber(pt.v, unit)}</title>
												</circle>
											{/each}
										</svg>
									</div>
								{:else}
									<div class="p-6 rounded-xl bg-[#faf8f5] border border-dashed border-[#dcd6cc] text-center">
										<p class="text-xs text-[#727784] font-medium">
											Ainda não há medições suficientes para traçar a curva de evolução temporal.
										</p>
										<p class="text-[11px] text-[#727784]/80 mt-1">
											Registre seu primeiro check-in no formulário abaixo para iniciar o histórico.
										</p>
									</div>
								{/if}
							</div>

							<!-- Formulário de Registro Rápido de Check-in -->
							{#if canEdit}
								<form
									method="POST"
									action="/strategy?/logMetric"
									use:enhanceFormValidation
									class="p-5 rounded-2xl bg-white border shadow-xs space-y-3"
									style="border-color: {theme.cardBorder};"
								>
									<input type="hidden" name="nodeId" value={node.id} />

									<h4
										class="font-mono text-[11px] uppercase tracking-wider font-bold flex items-center gap-1.5"
										style="color: {theme.accentDark};"
									>
										<span class="material-symbols-outlined text-[16px]" style="color: {theme.accent};">
											add_task
										</span>
										Registrar Nova Medição (Check-in)
									</h4>

									<div class="grid grid-cols-1 sm:grid-cols-12 gap-3">
										<div class="sm:col-span-4 space-y-1">
											<label for="new-checkin-val" class="block font-mono text-[10px] uppercase font-bold text-[#727784]">
												Novo Valor Apurado ({unit || 'un'}) <span class="text-[#ba1a1a]">*</span>
											</label>
											<input
												id="new-checkin-val"
												name="value"
												type="number"
												step="any"
												required
												bind:value={newCheckinValue}
												placeholder="Ex.: 45000"
												class="w-full rounded-xl px-3 py-2 text-xs font-bold text-[#1d1b17] border shadow-inner"
												style="background-color: {theme.inputBg}; border-color: {theme.inputBorder};"
											/>
										</div>

										<div class="sm:col-span-5 space-y-1">
											<label for="new-checkin-note" class="block font-mono text-[10px] uppercase font-bold text-[#727784]">
												Nota / Justificativa de Contexto (Opcional)
											</label>
											<input
												id="new-checkin-note"
												name="note"
												type="text"
												bind:value={newCheckinNote}
												placeholder="Ex.: Fechamento após campanha de marketing..."
												class="w-full rounded-xl px-3 py-2 text-xs text-[#1d1b17] border shadow-inner"
												style="background-color: {theme.inputBg}; border-color: {theme.inputBorder};"
											/>
										</div>

										<div class="sm:col-span-3 flex items-end">
											<button
												type="submit"
												class="w-full py-2 px-3 rounded-xl text-white font-sans text-xs font-bold shadow-xs active:translate-y-0.5 transition-all cursor-pointer hover:brightness-105"
												style="background-color: {theme.accent}; box-shadow: 0 2px 0 {theme.accentShadow};"
											>
												Registrar Medição
											</button>
										</div>
									</div>
								</form>
							{/if}

							<!-- Linha do Tempo de Check-ins Registrados -->
							<div
								class="p-5 rounded-2xl bg-white border shadow-xs space-y-3"
								style="border-color: {theme.cardBorder};"
							>
								<div class="flex items-center justify-between pb-2 border-b border-[#edf4ee]">
									<h4
										class="font-mono text-[11px] uppercase tracking-wider font-bold flex items-center gap-1.5"
										style="color: {theme.accentDark};"
									>
										<span class="material-symbols-outlined text-[16px]" style="color: {theme.accent};">
											history
										</span>
										Livro de Registro &amp; Auditoria de Medições ({node.metricUpdates.length})
									</h4>
								</div>

								{#if node.metricUpdates.length === 0}
									<p class="text-xs text-[#727784] italic py-2">
										Nenhum check-in registrado para este indicador até o momento.
									</p>
								{:else}
									<div class="space-y-2 max-h-60 overflow-y-auto custom-scroll p-0.5">
										{#each node.metricUpdates as mu (mu.id)}
											<div
												class="flex items-center justify-between p-2.5 rounded-xl bg-[#faf8f5] border text-xs shadow-xs"
												style="border-color: {theme.cardBorder};"
											>
												<div class="flex items-center gap-3 min-w-0">
													<span
														class="font-mono text-xs font-bold px-2 py-0.5 rounded border"
														style="background-color: {theme.badgeBg}; border-color: {theme.badgeBorder}; color: {theme.accentDark};"
													>
														{formatNumber(mu.value, unit)}
													</span>
													{#if mu.note}
														<span class="text-[#424753] truncate">{mu.note}</span>
													{:else}
														<span class="text-[#727784] italic">Sem anotação</span>
													{/if}
												</div>

												<div class="flex items-center gap-2 shrink-0">
													<span class="font-mono text-[10px] text-[#727784]">
														{new Date(mu.created_at).toLocaleDateString('pt-BR')}
													</span>
												</div>
											</div>
										{/each}
									</div>
								{/if}
							</div>
						</div>
					{/if}

					<!-- ============================================================== -->
					<!-- ABA 3: VÍNCULOS HIERÁRQUICOS & EQUIPES                        -->
					<!-- ============================================================== -->
					{#if activeTab === 'tab3'}
						<div class="grid grid-cols-1 md:grid-cols-2 gap-5">
							<!-- Card de Hierarquia Estratégica -->
							<div
								class="p-5 rounded-2xl bg-white border shadow-xs space-y-4"
								style="border-color: {theme.cardBorder};"
							>
								<h4
									class="font-mono text-[11px] uppercase tracking-wider font-bold flex items-center gap-1.5 pb-2 border-b border-[#edf4ee]"
									style="color: {theme.accentDark};"
								>
									<span class="material-symbols-outlined text-[16px]" style="color: {theme.accent};">
										account_tree
									</span>
									Alinhamento na Árvore Estratégica
								</h4>

								<!-- Resultado-Chave Pai -->
								{#if parentKr}
									<div class="p-3.5 rounded-xl bg-[#faf8f5] border border-[#e2dcd2] space-y-2">
										<span class="font-mono text-[10px] uppercase font-bold text-[#727784]">
											Resultado-Chave Pai:
										</span>
										<p class="text-sm font-bold text-[#1d1b17]">{parentKr.title}</p>
										<div class="flex items-center justify-between pt-1">
											<span class="text-xs text-[#727784]">
												Progresso do KR: <strong>{Math.round(((parentKr as any).progress ?? parentKr.manual_progress ?? 0) * 100)}%</strong>
											</span>
											{#if onOpenParent}
												<button
													type="button"
													onclick={() => onOpenParent(parentKr.id)}
													class="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg bg-white border border-[#d5cebe] text-xs font-semibold text-[#0058bd] hover:bg-[#eef5fc] cursor-pointer shadow-xs"
												>
													<span>Abrir Dossiê do KR</span>
													<span class="material-symbols-outlined text-[14px]">arrow_forward</span>
												</button>
											{/if}
										</div>
									</div>
								{/if}

								<!-- Objetivo Raiz -->
								{#if rootObjective}
									<div class="p-3.5 rounded-xl bg-[#faf8f5] border border-[#e2dcd2] space-y-1">
										<span class="font-mono text-[10px] uppercase font-bold text-[#727784]">
											Objetivo Macroestratégico Raiz:
										</span>
										<p class="text-xs font-bold text-[#1d1b17]">{rootObjective.title}</p>
										<span class="text-[10px] font-mono text-[#727784] block">
											Ano: {rootObjective.year ?? 2026}
										</span>
									</div>
								{/if}
							</div>

							<!-- Card de Equipes e Responsáveis -->
							<div class="space-y-4">
								<!-- Equipes -->
								<div
									class="p-4 rounded-2xl bg-white border shadow-xs space-y-3"
									style="border-color: {theme.cardBorder};"
								>
									<div class="flex items-center justify-between pb-1 border-b border-[#edf4ee]">
										<h4
											class="font-mono text-[11px] uppercase tracking-wider font-bold"
											style="color: {theme.accentDark};"
										>
											Diretorias Responsáveis ({selectedTeamIds.length})
										</h4>

										{#if canEdit}
											<div class="relative">
												<button
													type="button"
													onclick={() => (showAddTeamDropdown = !showAddTeamDropdown)}
													class="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg font-mono text-[10.5px] font-bold border transition-colors cursor-pointer hover:brightness-95"
													style="background-color: {theme.badgeBg}; border-color: {theme.badgeBorder}; color: {theme.accentDark};"
												>
													<span class="material-symbols-outlined text-[14px]">add</span>
													<span>+ Diretoria</span>
												</button>

												{#if showAddTeamDropdown}
													{@const availableTeams = teams.filter((t) => !selectedTeamIds.includes(t.id))}
													<div
														role="presentation"
														class="fixed inset-0 z-30"
														onclick={() => (showAddTeamDropdown = false)}
													></div>
													<div
														class="absolute right-0 top-full mt-1.5 w-60 rounded-xl bg-white border border-[#d5cebe] shadow-xl p-2 z-40 space-y-1 max-h-56 overflow-y-auto custom-scroll"
													>
														{#if availableTeams.length === 0}
															<span class="block px-2 py-2 text-[11.5px] text-[#727784] italic">
																Todas as diretorias já estão vinculadas.
															</span>
														{:else}
															{#each availableTeams as t (t.id)}
																<button
																	type="button"
																	onclick={() => addTeam(t.id)}
																	class="w-full flex items-center justify-between gap-2 p-1.5 rounded-lg hover:bg-[#f3ede6] text-left transition-colors cursor-pointer"
																>
																	<div class="flex items-center gap-2 min-w-0">
																		<span
																			class="material-symbols-outlined text-[15px] shrink-0"
																			style="color: {t.color || '#0058bd'};"
																		>
																			{getTeamIcon(t)}
																		</span>
																		<span class="text-[12px] font-semibold text-[#1d1b17] truncate">{t.name}</span>
																	</div>
																	<span class="material-symbols-outlined text-[15px] text-[#059669]">add</span>
																</button>
															{/each}
														{/if}
													</div>
												{/if}
											</div>
										{/if}
									</div>

									<div class="flex flex-wrap gap-1.5">
										{#if selectedTeamIds.length === 0}
											<p class="text-[11.5px] text-[#727784] italic py-1">Nenhuma diretoria vinculada.</p>
										{:else}
											{#each selectedTeamIds as tid (tid)}
												{@const tm = teams.find((t) => t.id === tid)}
												{#if tm}
													{@const tmTheme = getDossierTheme(tm.color || '#0058bd')}
													<div
														class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-xl border text-xs font-semibold shadow-xs transition-colors"
														style="background-color: {tmTheme.badgeBg}; border-color: {tmTheme.badgeBorder}; color: {tmTheme.badgeText};"
													>
														<span
															class="material-symbols-outlined text-[15px] shrink-0"
															style="color: {tmTheme.accent};"
														>
															{getTeamIcon(tm)}
														</span>
														<span>{tm.name}</span>
														{#if canEdit}
															<button
																type="button"
																onclick={() => removeTeam(tm.id)}
																class="opacity-70 hover:opacity-100 hover:text-[#ba1a1a] transition-colors p-0.5 rounded cursor-pointer"
															>
																<span class="material-symbols-outlined text-[14px]">close</span>
															</button>
														{/if}
													</div>
												{/if}
											{/each}
										{/if}
									</div>
								</div>

								<!-- Membros Responsáveis -->
								<div
									class="p-4 rounded-2xl bg-white border shadow-xs space-y-3"
									style="border-color: {theme.cardBorder};"
								>
									<div class="flex items-center justify-between pb-1 border-b border-[#edf4ee]">
										<h4
											class="font-mono text-[11px] uppercase tracking-wider font-bold"
											style="color: {theme.accentDark};"
										>
											Responsáveis pela Apuração ({selectedMemberIds.length})
										</h4>

										{#if canEdit}
											<div class="relative">
												<button
													type="button"
													onclick={() => (showAddMemberDropdown = !showAddMemberDropdown)}
													class="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg font-mono text-[10.5px] font-bold border transition-colors cursor-pointer hover:brightness-95"
													style="background-color: {theme.badgeBg}; border-color: {theme.badgeBorder}; color: {theme.accentDark};"
												>
													<span class="material-symbols-outlined text-[14px]">person_add</span>
													<span>+ Membro</span>
												</button>

												{#if showAddMemberDropdown}
													{@const availableProfiles = profiles.filter((p) => !selectedMemberIds.includes(p.id))}
													<div
														role="presentation"
														class="fixed inset-0 z-30"
														onclick={() => (showAddMemberDropdown = false)}
													></div>
													<div
														class="absolute right-0 top-full mt-1.5 w-60 rounded-xl bg-white border border-[#d5cebe] shadow-xl p-2 z-40 space-y-1 max-h-56 overflow-y-auto custom-scroll"
													>
														{#if availableProfiles.length === 0}
															<span class="block px-2 py-2 text-[11.5px] text-[#727784] italic">
																Todos os membros já estão vinculados.
															</span>
														{:else}
															{#each availableProfiles as p (p.id)}
																<button
																	type="button"
																	onclick={() => addMember(p.id)}
																	class="w-full flex items-center justify-between gap-2 p-1.5 rounded-lg hover:bg-[#f3ede6] text-left transition-colors cursor-pointer"
																>
																	<div class="flex items-center gap-2 min-w-0">
																		<div
																			class="w-6 h-6 rounded-full text-white text-[9px] font-bold flex items-center justify-center shrink-0"
																			style="background-color: {p.color || '#004190'};"
																		>
																			{getInitials(p.name)}
																		</div>
																		<span class="text-[12px] font-semibold text-[#1d1b17] truncate">{p.name}</span>
																	</div>
																	<span class="material-symbols-outlined text-[15px] text-[#059669]">add</span>
																</button>
															{/each}
														{/if}
													</div>
												{/if}
											</div>
										{/if}
									</div>

									<div class="space-y-1.5 max-h-40 overflow-y-auto custom-scroll p-0.5">
										{#if selectedMemberIds.length === 0}
											<p class="text-[11.5px] text-[#727784] italic py-1">Nenhum responsável individual associado.</p>
										{:else}
											{#each selectedMemberIds as mid (mid)}
												{@const mem = profiles.find((p) => p.id === mid)}
												{#if mem}
													<div
														class="flex items-center justify-between p-2 rounded-xl bg-[#faf8f5] border text-xs"
														style="border-color: {theme.cardBorder};"
													>
														<div class="flex items-center gap-2 min-w-0">
															<div
																class="w-6 h-6 rounded-full text-white text-[9px] font-bold flex items-center justify-center shrink-0"
																style="background-color: {mem.color || '#004190'};"
															>
																{getInitials(mem.name)}
															</div>
															<span class="font-bold text-[#1d1b17] truncate">{mem.name}</span>
														</div>

														{#if canEdit}
															<button
																type="button"
																onclick={() => removeMember(mem.id)}
																class="text-[#727784] hover:text-[#ba1a1a] transition-colors p-0.5 rounded cursor-pointer"
															>
																<span class="material-symbols-outlined text-[14px]">close</span>
															</button>
														{/if}
													</div>
												{/if}
											{/each}
										{/if}
									</div>
								</div>
							</div>
						</div>
					{/if}
				</div>

				<!-- 3. RODAPÉ DA PASTA: LINHA DE COSTURA SUTIL E BOTÕES DE AÇÃO -->
				<div
					class="relative z-10 border-t px-5 sm:px-7 py-3.5 transition-colors duration-200"
					style="background-color: {theme.footerBg}; border-color: {theme.folderBorder};"
				>
					<!-- Linha de Costura / Picote Sutil de Papel Manilha -->
					<div
						class="h-[1.5px] w-full mb-3 opacity-75"
						style="background-image: repeating-linear-gradient(to right, {theme.stitchedColor} 0px, {theme.stitchedColor} 6px, transparent 6px, transparent 11px);"
					></div>

					<div class="flex flex-col sm:flex-row items-center justify-between gap-3">
						<!-- Botão 'Excluir KPI' -->
						{#if canEdit}
							<button
								type="button"
								onclick={() => (showDeleteConfirm = true)}
								class="inline-flex items-center gap-1.5 px-3 py-2 rounded-xl text-[#ba1a1a] hover:bg-[#ffdad6]/60 font-sans text-[12.5px] font-semibold transition-colors self-start sm:self-auto cursor-pointer"
							>
								<span class="material-symbols-outlined text-[16px]">delete</span>
								<span>Excluir Indicador</span>
							</button>
						{:else}
							<div></div>
						{/if}

						<!-- Ações Principais -->
						<div class="flex items-center gap-2.5 w-full sm:w-auto justify-end">
							<button
								type="button"
								onclick={onClose}
								class="px-4 py-2 rounded-xl bg-white hover:bg-slate-50 text-[#1d1b17] border font-sans text-[12.5px] font-semibold shadow-xs active:translate-y-0.5 transition-all cursor-pointer"
								style="border-color: {theme.inputBorder};"
							>
								Cancelar
							</button>

							{#if canEdit}
								<button
									type="submit"
									form="updateKpiForm"
									disabled={isSaving}
									class="inline-flex items-center gap-2 px-5 py-2 rounded-xl text-white font-sans text-[12.5px] font-bold active:translate-y-0.5 transition-all cursor-pointer hover:brightness-105 disabled:opacity-50"
									style="background-color: {theme.accent}; box-shadow: 0 2.5px 0 {theme.accentShadow};"
								>
									<span class="material-symbols-outlined text-[17px]">
										{isSaving ? 'sync' : 'check'}
									</span>
									<span>{isSaving ? 'Salvando...' : 'Salvar Alterações'}</span>
								</button>
							{/if}
						</div>
					</div>
				</div>
			</div>
		</div>
	</div>

	<!-- Modal de Confirmação de Exclusão -->
	{#if showDeleteConfirm}
		<div
			role="presentation"
			onclick={() => (showDeleteConfirm = false)}
			class="fixed inset-0 z-[110] flex items-center justify-center p-4 bg-black/50 backdrop-blur-xs"
		>
			<!-- svelte-ignore a11y_click_events_have_key_events -->
			<!-- svelte-ignore a11y_no_noninteractive_element_interactions -->
			<div
				role="dialog"
				tabindex="-1"
				aria-modal="true"
				onclick={(e) => e.stopPropagation()}
				class="w-full max-w-md rounded-2xl bg-white p-6 shadow-2xl border border-[#d5cebe] space-y-4"
			>
				<div class="flex items-center gap-3 text-[#ba1a1a]">
					<span class="material-symbols-outlined text-[28px]">warning</span>
					<h3 class="font-bold text-lg text-[#1d1b17]">Excluir Indicador (KPI)?</h3>
				</div>

				<p class="text-sm text-[#424753] leading-relaxed">
					Você tem certeza de que deseja excluir o indicador <strong>"{node.title}"</strong>?
					Esta ação removerá todos os registros históricos de check-in vinculados.
				</p>

				<form method="POST" action="/strategy?/deleteNode" use:enhanceFormValidation class="space-y-4 pt-2">
					<input type="hidden" name="nodeId" value={node.id} />

					<div class="flex items-center justify-end gap-2 pt-2">
						<button
							type="button"
							onclick={() => (showDeleteConfirm = false)}
							class="px-4 py-2 rounded-xl border border-[#d5cebe] text-xs font-bold text-[#424753] hover:bg-slate-50 cursor-pointer"
						>
							Cancelar
						</button>
						<button
							type="submit"
							class="px-4 py-2 rounded-xl bg-[#ba1a1a] text-white text-xs font-bold hover:bg-[#991b1b] shadow-xs cursor-pointer"
						>
							Confirmar Exclusão
						</button>
					</div>
				</form>
			</div>
		</div>
	{/if}
{/if}

<style>
	/* Completely hide scrollbars on the tabs container across WebKit, Firefox, and IE/Edge */
	.no-scrollbar::-webkit-scrollbar {
		display: none;
		width: 0;
		height: 0;
	}
	.no-scrollbar {
		-ms-overflow-style: none; /* IE and Edge */
		scrollbar-width: none; /* Firefox */
	}
</style>

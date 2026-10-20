<script lang="ts">
	import type { Cycle, NodeStatus, NodeWithExtras, Profile, StrategyNode, Team } from '$lib/types';
	import { enhanceFormValidation, formatNumber, formatPct, getInitials } from '$lib/utils';
	import { valueColor } from '$lib/value-colors';
	import { getDossierTheme } from '$lib/dossier-theme';
	import PaperColorPicker from '$lib/components/ui/PaperColorPicker.svelte';
	import { onMount } from 'svelte';

	interface Props {
		node: NodeWithExtras | null;
		allNodes: StrategyNode[];
		cycles: Cycle[];
		profiles: Profile[];
		teams: Team[];
		valuesList: StrategyNode[];
		canEdit: boolean;
		onClose: () => void;
		onAddChild: (parent: NodeWithExtras) => void;
		onOpenNode?: (id: string) => void;
	}

	let {
		node,
		allNodes,
		cycles,
		profiles,
		teams,
		valuesList,
		canEdit,
		onClose,
		onAddChild,
		onOpenNode
	}: Props = $props();

	// Active tab inside the Dossier
	let activeTab = $state<'tab1' | 'tab2' | 'tab3' | 'tab4'>('tab1');

	// Local mutable states for reactive calculations
	let title = $state('');
	let description = $state('');
	let status = $state<NodeStatus>('on_track');
	let weight = $state(1);
	let cycleId = $state('');
	let parentId = $state('');
	let unit = $state('R$');
	let baseline = $state(0);
	let targetValue = $state(100);
	let currentValue = $state(0);
	let direction = $state<'up' | 'down'>('up');
	let manualProgressPct = $state(0);

	// Mode: 'aggregate' (calculated from child KPIs) vs 'manual' (direct %)
	let progressMode = $state<'aggregate' | 'manual'>('aggregate');

	// Check-in input states for Tab 4
	let showNewCheckinForm = $state(false);
	let newCheckinValue = $state<number | null>(null);
	let newCheckinNote = $state('');

	// Delete confirmation modal state
	let showDeleteConfirm = $state(false);

	// Theme color state
	let accentColor = $state('#b30069');

	// Sync states when node prop changes
	$effect(() => {
		if (node) {
			title = node.title;
			description = node.description ?? '';
			status = node.status;
			weight = node.weight;
			cycleId = node.cycle_id ?? '';
			parentId = node.parent_id ?? '';
			unit = node.unit ?? 'R$';
			baseline = node.baseline ?? 0;
			targetValue = node.target_value ?? 100;
			currentValue = node.current_value ?? 0;
			direction = node.direction ?? 'up';
			manualProgressPct = Math.round((node.manual_progress ?? 0) * 100);

			if (node.color) {
				accentColor = node.color;
			} else if (node.teams.length > 0 && node.teams[0].color) {
				accentColor = node.teams[0].color;
			} else if (node.alignedValues.length > 0) {
				accentColor = valueColor(node.alignedValues[0].id);
			} else {
				accentColor = '#b30069';
			}

			const kpiChildren = node.children.filter((c) => c.type === 'kpi');
			progressMode =
				kpiChildren.length > 0 && (node.manual_progress === null || node.manual_progress === 0)
					? 'aggregate'
					: 'manual';
		}
	});

	const theme = $derived(getDossierTheme(accentColor));

	// Child KPIs
	const childKpis = $derived(node ? node.children.filter((c) => c.type === 'kpi') : []);

	// Parent Objective
	const parentObjective = $derived.by(() => {
		if (!node || !parentId) return null;
		return allNodes.find((n) => n.id === parentId) ?? null;
	});

	// Valid parent objectives for reparenting
	const validParentObjectives = $derived(allNodes.filter((n) => n.type === 'objective'));

	// Resolved cycle
	const currentCycle = $derived.by(() => {
		if (!node) return null;
		if (cycleId) return cycles.find((c) => c.id === cycleId) ?? null;
		return node.cycle;
	});

	// Dynamic Progress Percentage Calculation
	const calculatedProgressPct = $derived.by(() => {
		if (progressMode === 'manual' || childKpis.length === 0) {
			return Math.max(0, Math.min(100, manualProgressPct));
		}
		// In aggregate mode, use node's aggregated progress from engine
		return Math.round(Math.max(0, Math.min(1, node?.progress ?? 0)) * 100);
	});

	// Calculated nominal progress from baseline and target
	const deltaValue = $derived(currentValue - baseline);

	// Primary Leader (first assignee) and Co-assignees
	const primaryAssignee = $derived(node && node.assignees.length > 0 ? node.assignees[0] : null);
	const coAssignees = $derived(node && node.assignees.length > 1 ? node.assignees.slice(1) : []);

	// Last audit date / check-in
	const latestMetricUpdate = $derived.by(() => {
		if (!node || node.metricUpdates.length === 0) return null;
		return node.metricUpdates[0];
	});

	// Color swatches for KR customization
	const colorSwatches = [
		{ name: 'Framboesa Magenta', hex: '#b30069' },
		{ name: 'Azul Horizonte', hex: '#0058bd' },
		{ name: 'Verde Floresta', hex: '#059669' },
		{ name: 'Roxo Estratégico', hex: '#7c3aed' },
		{ name: 'Âmbar Solar', hex: '#c2ac00' },
		{ name: 'Laranja Terracota', hex: '#ea580c' },
		{ name: 'Teal Esmeralda', hex: '#00665a' }
	];

	// Keyboard dismiss listener
	function handleKeyDown(e: KeyboardEvent) {
		if (e.key === 'Escape') {
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
		sub: string;
		borderClass: string;
		dotClass: string;
	}> = [
		{
			key: 'not_started',
			label: 'Pendente',
			sub: 'Não Iniciado (0%)',
			borderClass: 'border-2 border-stone-400 bg-stone-100/90 text-stone-700 shadow-[0_2px_5px_rgba(36,34,30,0.06)]',
			dotClass: 'bg-stone-400 ring-4 ring-stone-200'
		},
		{
			key: 'on_track',
			label: 'No Alvo',
			sub: 'On Track (70%+)',
			borderClass: 'border-2 border-emerald-500 bg-[#DCFCE7]/75 text-[#14532D] shadow-[0_2px_5px_rgba(36,34,30,0.06)]',
			dotClass: 'bg-emerald-500 ring-4 ring-emerald-200'
		},
		{
			key: 'at_risk',
			label: 'Em Risco',
			sub: 'Atenção (40-69%)',
			borderClass: 'border-2 border-amber-500 bg-[#FEF3C7]/90 text-[#92400E] shadow-[0_2px_5px_rgba(36,34,30,0.06)]',
			dotClass: 'bg-amber-500 ring-4 ring-amber-200'
		},
		{
			key: 'off_track',
			label: 'Fora da Rota',
			sub: 'Crítico (< 40%)',
			borderClass: 'border-2 border-red-500 bg-[#FEE2E2]/90 text-[#991B1B] shadow-[0_2px_5px_rgba(36,34,30,0.06)]',
			dotClass: 'bg-red-500 ring-4 ring-red-200'
		},
		{
			key: 'done',
			label: 'Concluído',
			sub: '100% atingido',
			borderClass: 'border-2 border-primary bg-[#DBEAFE]/90 text-primary shadow-[0_2px_5px_rgba(36,34,30,0.06)]',
			dotClass: 'bg-primary ring-4 ring-blue-200'
		}
	];

	// Sparkline generator for child KPIs in Tab 2
	function getKpiSparkline(kpi: NodeWithExtras) {
		const chron = [...kpi.metricUpdates].reverse();
		const vals = chron.map((m) => m.value);
		if (kpi.baseline != null) vals.unshift(kpi.baseline);
		if (vals.length < 2) return null;

		const min = Math.min(...vals, kpi.target_value ?? vals[0]);
		const max = Math.max(...vals, kpi.target_value ?? vals[0]);
		const range = max - min || 1;
		const W = 80;
		const H = 20;

		const coords = vals.map((v, idx) => {
			const x = (idx / (vals.length - 1)) * W;
			const y = H - ((v - min) / range) * H;
			return { x, y };
		});

		const d = coords.reduce((acc, pt, i) => `${acc} ${i === 0 ? 'M' : 'L'} ${pt.x} ${pt.y}`, '');
		const lastPt = coords[coords.length - 1];

		return { d, lastPt };
	}

	function timeAgo(dateStr?: string | null): string {
		if (!dateStr) return 'Sem check-in registrado';
		const d = new Date(dateStr);
		const now = new Date();
		const diffDays = Math.floor((now.getTime() - d.getTime()) / (1000 * 60 * 60 * 24));
		if (diffDays <= 0) return 'hoje';
		if (diffDays === 1) return 'há 1 dia';
		return `há ${diffDays} dias`;
	}
</script>

{#if node}
	<!-- Modal Container with Ambient Dimming Backdrop -->
	<div
		id="editKrModal"
		class="fixed inset-0 z-[100] flex justify-center p-3 sm:p-5 overflow-y-auto"
		style="font-family: 'Poppins', sans-serif !important;"
	>
		<!-- Backdrop Overlay -->
		<div
			role="presentation"
			onclick={onClose}
			class="fixed inset-0 bg-[#1d1b17]/65 backdrop-blur-xs transition-opacity"
		></div>

		<!-- Outer Folder Jacket & Tabbed Dossier Shell -->
		<div
			class="relative w-full max-w-5xl my-auto z-10 flex flex-col h-[88vh] max-h-[850px] min-h-[460px] pt-1 sm:pt-2"
		>
			<!-- FOLDER SUSPENDED TABS (Recortes de abas salientes superiores estilo pasta Hal Lee / ShareWillow) -->
			<div
				class="flex items-end gap-1.5 px-4 sm:px-8 -mb-[2px] z-20 shrink-0 select-none overflow-x-auto no-scrollbar"
			>
				<!-- Tab 1: Parâmetros & Meta -->
				<button
					type="button"
					onclick={() => (activeTab = 'tab1')}
					class="folder-tab group flex items-center gap-2 px-4 sm:px-5 py-2.5 text-xs font-bold transition-all cursor-pointer {activeTab ===
					'tab1'
						? 'folder-tab-active border-t-2 border-l border-r text-on-surface shadow-[0_-3px_8px_rgba(29,27,23,0.06)] relative'
						: 'bg-[#F6F0E9] hover:bg-[#FAF6F0] border-t-2 border-l border-r border-transparent text-on-surface-variant hover:text-on-surface shadow-[0_-1px_3px_rgba(29,27,23,0.04)]'}"
					style={activeTab === 'tab1'
						? `background-color: ${theme.folderBg}; border-color: ${theme.folderBorder};`
						: ''}
				>
					<span
						class="w-2.5 h-2.5 rounded-full shrink-0 shadow-xs"
						style="background-color: {theme.accent};"
					></span>
					<span class="tracking-tight whitespace-nowrap">1. Parâmetros &amp; Meta</span>
					{#if activeTab === 'tab1'}
						<span
							class="text-[10px] px-1.5 py-0.2 rounded font-bold ml-1 border"
							style="background-color: {theme.badgeBg}; border-color: {theme.badgeBorder}; color: {theme.badgeText};"
							>Ativo</span
						>
					{/if}
				</button>

				<!-- Tab 2: KPIs & Indicadores Filhos -->
				<button
					type="button"
					onclick={() => (activeTab = 'tab2')}
					class="folder-tab group flex items-center gap-2 px-4 sm:px-5 py-2 text-xs font-bold transition-all cursor-pointer {activeTab ===
					'tab2'
						? 'folder-tab-active border-t-2 border-l border-r text-on-surface shadow-[0_-3px_8px_rgba(29,27,23,0.06)] relative'
						: 'bg-[#F6F0E9] hover:bg-[#FAF6F0] border-t-2 border-l border-r border-transparent text-on-surface-variant hover:text-on-surface shadow-[0_-1px_3px_rgba(29,27,23,0.04)]'}"
					style={activeTab === 'tab2'
						? `background-color: ${theme.folderBg}; border-color: ${theme.folderBorder};`
						: ''}
				>
					<span class="w-2 h-2 rounded-full shrink-0" style="background-color: {theme.accent};"></span>
					<span class="tracking-tight whitespace-nowrap">2. KPIs &amp; Indicadores Filhos</span>
					<span
						class="text-[10px] px-1.5 py-0.2 rounded-full font-bold ml-0.5"
						style="background-color: {theme.badgeBg}; color: {theme.badgeText};"
					>
						{childKpis.length}
					</span>
				</button>

				<!-- Tab 3: Alinhamento de Equipe & Valores -->
				<button
					type="button"
					onclick={() => (activeTab = 'tab3')}
					class="folder-tab group flex items-center gap-2 px-4 sm:px-5 py-2 text-xs font-bold transition-all cursor-pointer {activeTab ===
					'tab3'
						? 'folder-tab-active border-t-2 border-l border-r text-on-surface shadow-[0_-3px_8px_rgba(29,27,23,0.06)] relative'
						: 'bg-[#F6F0E9] hover:bg-[#FAF6F0] border-t-2 border-l border-r border-transparent text-on-surface-variant hover:text-on-surface shadow-[0_-1px_3px_rgba(29,27,23,0.04)]'}"
					style={activeTab === 'tab3'
						? `background-color: ${theme.folderBg}; border-color: ${theme.folderBorder};`
						: ''}
				>
					<span class="w-2 h-2 rounded-full shrink-0" style="background-color: {theme.accent};"></span>
					<span class="tracking-tight whitespace-nowrap">3. Equipe &amp; Valores</span>
					<span
						class="text-[10px] px-1.5 py-0.2 rounded-full font-bold ml-0.5"
						style="background-color: {theme.badgeBg}; color: {theme.badgeText};"
					>
						{node.assignees.length + node.alignedValues.length}
					</span>
				</button>

				<!-- Tab 4: Histórico & Log de Check-in -->
				<button
					type="button"
					onclick={() => (activeTab = 'tab4')}
					class="folder-tab group flex items-center gap-2 px-4 sm:px-5 py-2 text-xs font-bold transition-all cursor-pointer {activeTab ===
					'tab4'
						? 'folder-tab-active border-t-2 border-l border-r text-on-surface shadow-[0_-3px_8px_rgba(29,27,23,0.06)] relative'
						: 'bg-[#F6F0E9] hover:bg-[#FAF6F0] border-t-2 border-l border-r border-transparent text-on-surface-variant hover:text-on-surface shadow-[0_-1px_3px_rgba(29,27,23,0.04)]'}"
					style={activeTab === 'tab4'
						? `background-color: ${theme.folderBg}; border-color: ${theme.folderBorder};`
						: ''}
				>
					<span class="material-symbols-outlined text-[15px]" style="color: {theme.accent};"
						>history_edu</span
					>
					<span class="tracking-tight whitespace-nowrap">4. Histórico &amp; Check-ins</span>
					{#if node.metricUpdates.length > 0}
						<span
							class="text-[10px] px-1.5 py-0.2 rounded-full font-bold ml-0.5"
							style="background-color: {theme.badgeBg}; color: {theme.badgeText};"
						>
							{node.metricUpdates.length}
						</span>
					{/if}
				</button>
			</div>

			<!-- MAIN DOSSIER CARRIER (Pasta aberta com textura encorpada de arquivo executivo) -->
			<div
				class="relative text-on-surface w-full rounded-2xl shadow-[0_22px_60px_rgba(29,27,23,0.28),0_4px_16px_rgba(29,27,23,0.08),inset_0_1px_0_#ffffff] border-2 flex-1 flex flex-col min-h-0 transition-colors duration-200 overflow-hidden"
				style="background-color: {theme.folderBg}; border-color: {theme.folderBorder};"
			>
				<!-- Linha de reforço estrutural -->
				<div
					class="h-1.5 w-full relative z-10 border-b rounded-t-2xl transition-colors duration-200"
					style="background: linear-gradient(to right, color-mix(in srgb, {accentColor} 25%, transparent), color-mix(in srgb, {accentColor} 45%, transparent), color-mix(in srgb, {accentColor} 20%, transparent)); border-color: {theme.folderBorder};"
				></div>

				<!-- Archival Folder Header Strip -->
				<div
					class="px-5 py-3 sm:px-6 sm:py-3.5 border-b flex items-center justify-between shrink-0 relative z-30 transition-colors"
					style="background-color: {theme.cardBg}; border-color: {theme.folderBorder};"
				>
					<div class="flex flex-wrap items-center gap-3">
						<!-- Physical Tag Badge -->
						<div
							class="flex items-center gap-1.5 px-2.5 py-1 rounded border shadow-[inset_0_1px_1px_rgba(255,255,255,0.7)] transition-colors"
							style="background-color: {theme.badgeBg}; border-color: {theme.badgeBorder}; color: {theme.badgeText};"
						>
							<span class="material-symbols-outlined text-[14px]" style="color: {theme.accent};">folder_special</span>
							<span class="text-[11px] font-extrabold uppercase tracking-widest">
								DOSSIÊ RESULTADO-CHAVE
							</span>
						</div>
						<div
							class="flex items-center gap-1.5 bg-surface-container-lowest px-2.5 py-1 rounded-md text-on-surface-variant border border-outline-variant/40 text-[11px] font-semibold"
						>
							<span class="w-2 h-2 rounded-full" style="background-color: {theme.accent};"></span>
							<span>Ciclo: {currentCycle?.code ?? '2026-S1'}</span>
						</div>
						<span class="text-[#c1c6d6] hidden sm:inline">|</span>
						<span class="text-xs font-semibold text-on-surface-variant hidden md:inline">
							Pasta de Governança &amp; Medição Executiva
						</span>
					</div>

					<div class="flex items-center gap-2">
						<!-- Seletor de Cor Paper Strategist -->
						<PaperColorPicker bind:value={accentColor} disabled={!canEdit} align="right" />

						<span
							class="text-[11px] font-semibold text-on-surface-variant bg-surface-container-low px-2 py-1 rounded border border-outline-variant/30 hidden sm:inline-flex items-center gap-1"
						>
							<span class="material-symbols-outlined text-[14px] text-tertiary">lock_open</span>
							Revisão Estratégica Aberta
						</span>
						<button
							type="button"
							onclick={onClose}
							class="w-8 h-8 rounded-lg bg-surface-container-lowest hover:bg-surface-container text-on-surface-variant hover:text-on-surface border border-outline-variant/40 transition-colors shadow-xs flex items-center justify-center cursor-pointer"
						>
							<span class="material-symbols-outlined text-[18px]">close</span>
						</button>
					</div>
				</div>

				<!-- Scrollable Dossier Body -->
				<div class="p-5 sm:p-6 md:p-7 flex-1 min-h-0 overflow-y-auto text-on-surface">
					<!-- ============================================================== -->
					<!-- ABA 1: PARÂMETROS & META (Título, Objetivo Pai, Baseline, Meta) -->
					<!-- ============================================================== -->
					{#if activeTab === 'tab1'}
						<form
							id="updateKrForm"
							method="POST"
							action="/strategy?/updateNode"
							use:enhanceFormValidation
							class="flex flex-col gap-5"
						>
							<input type="hidden" name="nodeId" value={node.id} />
							<input type="hidden" name="color" value={accentColor} />
							<input type="hidden" name="status" value={status} />
							<input
								type="hidden"
								name="manual_progress_pct"
								value={progressMode === 'manual' ? manualProgressPct : ''}
							/>

							<!-- Objective Parent Association Anchor -->
							<div
								class="p-4 bg-[#F7F2EA] rounded-xl border-l-4 border-l-primary border border-outline-variant/40 flex items-center justify-between shadow-[inset_0_1px_2px_rgba(36,34,30,0.04)]"
							>
								<div class="flex items-center gap-3 min-w-0">
									<div
										class="w-8 h-8 rounded-lg bg-primary-fixed text-on-primary-fixed flex items-center justify-center shrink-0 font-bold text-xs shadow-xs"
									>
										OBJ
									</div>
									<div class="min-w-0 flex flex-col">
										<span
											class="text-[10px] uppercase font-bold tracking-wider text-on-surface-variant"
										>
											Objetivo Pai Vinculado (Nível 1 · Corporativo)
										</span>
										{#if canEdit && validParentObjectives.length > 0}
											<select
												name="parent_id"
												bind:value={parentId}
												class="text-[13px] font-bold text-primary bg-transparent border-0 p-0 focus:ring-0 focus:outline-none cursor-pointer max-w-full truncate"
											>
												{#each validParentObjectives as pObj (pObj.id)}
													<option value={pObj.id} class="text-on-surface font-normal">
														{pObj.title}
													</option>
												{/each}
											</select>
										{:else}
											<input type="hidden" name="parent_id" value={parentId} />
											<span class="text-[13px] font-bold text-primary truncate">
												{parentObjective?.title ?? 'Objetivo não especificado'}
											</span>
										{/if}
									</div>
								</div>
								{#if onOpenNode && parentId}
									<button
										type="button"
										onclick={() => onOpenNode(parentId)}
										class="px-2.5 py-1 rounded bg-surface-container-lowest border border-outline-variant/40 text-[11px] font-bold text-primary hover:bg-surface-container flex items-center gap-1 transition-colors cursor-pointer"
										title="Abrir Dossiê do Objetivo Pai"
									>
										<span>Abrir Dossiê Pai</span>
										<span class="material-symbols-outlined text-[14px]">open_in_new</span>
									</button>
								{:else}
									<button
										type="button"
										onclick={onClose}
										class="px-2.5 py-1 rounded bg-surface-container-lowest border border-outline-variant/40 text-[11px] font-bold text-primary hover:bg-surface-container flex items-center gap-1 transition-colors cursor-pointer"
									>
										<span>Visualizar Árvore</span>
										<span class="material-symbols-outlined text-[14px]">open_in_new</span>
									</button>
								{/if}
							</div>

							<!-- KR Title Input with Dynamic Counter -->
							<div class="flex flex-col gap-1.5">
								<label
									for="kr-title-input"
									class="text-[11px] font-bold uppercase tracking-wider text-on-surface-variant flex items-center justify-between"
								>
									<span>Título do Resultado-Chave (Key Result) *</span>
									<span class="text-[11px] font-normal text-on-surface-variant">
										{title.length} / 120 caracteres
									</span>
								</label>
								<div class="relative">
									<input
										id="kr-title-input"
										name="title"
										type="text"
										required
										maxlength="120"
										disabled={!canEdit}
										bind:value={title}
										class="w-full pl-4 pr-11 py-3 bg-[#FFFDF8] rounded-xl border border-outline-variant/70 text-on-surface text-[14px] font-bold focus:outline-none focus:ring-2 focus:ring-primary shadow-[inset_0_1px_3px_rgba(36,34,30,0.05)] transition-all"
										placeholder="Ex: Atingir R$ 4.2M em ARR até o fim do semestre"
									/>
									<span
										class="material-symbols-outlined absolute right-3.5 top-3.5 text-on-surface-variant text-[20px] pointer-events-none"
									>
										edit_note
									</span>
								</div>
							</div>

							<!-- KR Context & Description -->
							<div class="flex flex-col gap-1.5">
								<label
									for="kr-desc-input"
									class="text-[11px] font-bold uppercase tracking-wider text-on-surface-variant"
								>
									Contexto Estratégico &amp; Racional do KR
								</label>
								<textarea
									id="kr-desc-input"
									name="description"
									rows="2"
									disabled={!canEdit}
									bind:value={description}
									placeholder="Descreva a tese por trás deste resultado-chave e como ele move o ponteiro do objetivo corporativo..."
									class="w-full px-4 py-2.5 bg-[#FFFDF8] rounded-xl border border-outline-variant/70 text-on-surface text-xs focus:outline-none focus:ring-2 focus:ring-primary shadow-[inset_0_1px_3px_rgba(36,34,30,0.05)] resize-none"
								></textarea>
							</div>

							<!-- Status & Health Selector Ribbon -->
							<div class="flex flex-col gap-2">
								<div class="flex items-center justify-between">
									<span class="text-[11px] font-bold uppercase tracking-wider text-on-surface-variant">
										Status de Desempenho &amp; Termômetro
									</span>
									<span class="text-[10px] text-on-surface-variant font-medium">
										Selecione o estado atual de saúde
									</span>
								</div>
								<div class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-5 gap-2">
									{#each statusOptions as opt (opt.key)}
										{@const isSelected = status === opt.key}
										<button
											type="button"
											onclick={() => {
												if (canEdit) status = opt.key;
											}}
											class="p-3 rounded-xl cursor-pointer flex items-center gap-2.5 transition-all text-left select-none {isSelected
												? opt.borderClass
												: 'border border-outline-variant/50 bg-[#FFFDF8] hover:bg-surface-container text-on-surface'}"
										>
											<span
												class="w-3 h-3 rounded-full shrink-0 {isSelected
													? opt.dotClass
													: 'bg-outline-variant'}"
											></span>
											<div class="flex flex-col">
												<span class="text-[12px] {isSelected ? 'font-bold' : 'font-semibold'}">
													{opt.label}
												</span>
												<span
													class="text-[10px] {isSelected
														? 'opacity-90'
														: 'text-on-surface-variant'}"
												>
													{opt.sub}
												</span>
											</div>
										</button>
									{/each}
								</div>
							</div>

							<!-- Metric Engine & Quantitative Ledger -->
							<div
								class="p-4 sm:p-5 rounded-xl bg-[#F6F1E9] border border-outline-variant/50 flex flex-col gap-4 shadow-[inset_0_1px_3px_rgba(36,34,30,0.05)]"
							>
								<div class="flex flex-wrap items-center justify-between gap-2">
									<span
										class="text-[12px] font-bold uppercase tracking-wider text-on-surface flex items-center gap-1.5"
									>
										<span class="material-symbols-outlined text-primary text-[18px]">calculate</span>
										Fórmulas de Agregação &amp; Balanço Numérico
									</span>
									<div
										class="inline-flex items-center gap-1 bg-[#FFFDF8] p-1 rounded-lg border border-outline-variant/40 shadow-xs"
									>
										<button
											type="button"
											onclick={() => (progressMode = 'aggregate')}
											class="px-2.5 py-1 rounded text-[11px] flex items-center gap-1 transition-all cursor-pointer {progressMode ===
											'aggregate'
												? 'font-bold bg-primary text-on-primary shadow-xs'
												: 'font-semibold text-on-surface-variant hover:text-on-surface'}"
										>
											<span class="material-symbols-outlined text-[13px]">lan</span>
											Agregado de KPIs filhos ({childKpis.length})
										</button>
										<button
											type="button"
											onclick={() => (progressMode = 'manual')}
											class="px-2.5 py-1 rounded text-[11px] flex items-center gap-1 transition-all cursor-pointer {progressMode ===
											'manual'
												? 'font-bold bg-primary text-on-primary shadow-xs'
												: 'font-semibold text-on-surface-variant hover:text-on-surface'}"
										>
											<span class="material-symbols-outlined text-[13px]">tune</span>
											Progresso Manual
										</button>
									</div>
								</div>

								<!-- Aggregate Mode Banner -->
								{#if progressMode === 'aggregate'}
									<div
										class="flex flex-wrap items-center justify-between gap-2 p-2.5 bg-[#EFF6FF] rounded-lg border border-[#BFDBFE] text-xs"
									>
										<div class="flex items-center gap-2 text-[#1E40AF]">
											<span class="material-symbols-outlined text-[18px]">account_tree</span>
											{#if childKpis.length > 0}
												<span class="font-medium">
													Cálculo Ponderado:
													<strong
														>{childKpis
															.map((k) => `${k.title} (peso ${k.weight})`)
															.join(' + ')}</strong
													>
													= <span class="font-bold underline">{calculatedProgressPct}% Global</span
													>
												</span>
											{:else}
												<span class="font-medium">
													Nenhum KPI vinculado ainda. Adicione KPIs na Aba 2 para alimentar este KR
													automaticamente.
												</span>
											{/if}
										</div>
										<button
											type="button"
											onclick={() => (activeTab = 'tab2')}
											class="text-primary hover:underline font-bold text-[11px] flex items-center gap-0.5 cursor-pointer"
										>
											Ver / Editar Indicadores Filhos
											<span class="material-symbols-outlined text-[13px]">arrow_forward</span>
										</button>
									</div>
								{:else}
									<!-- Manual Mode Slider Card -->
									<div
										class="flex flex-col gap-2.5 p-3.5 bg-[#FFFBEB] rounded-lg border border-[#FDE68A] text-xs"
									>
										<div class="flex items-center justify-between">
											<span class="font-bold text-[#92400E] flex items-center gap-1.5">
												<span class="material-symbols-outlined text-[16px]">tune</span>
												Ajuste Direto de Progresso Manual
											</span>
											<span class="text-[11px] text-[#B45309] font-medium">
												Controle direto sem cálculo de KPIs
											</span>
										</div>
										<div class="flex items-center gap-3">
											<input
												type="range"
												min="0"
												max="100"
												step="1"
												disabled={!canEdit}
												bind:value={manualProgressPct}
												class="w-full accent-primary h-2 bg-[#FDE047] rounded-lg cursor-pointer"
											/>
											<div
												class="flex items-center gap-1 shrink-0 bg-white px-2.5 py-1 rounded-md border border-[#FDE68A] shadow-xs"
											>
												<input
													type="number"
													min="0"
													max="100"
													disabled={!canEdit}
													bind:value={manualProgressPct}
													class="w-12 text-right font-extrabold text-sm text-[#78350F] border-0 p-0 focus:ring-0 focus:outline-none"
												/>
												<span class="font-bold text-xs text-[#78350F]">%</span>
											</div>
										</div>
										<div class="flex flex-wrap items-center gap-1.5">
											<span class="text-[10px] uppercase font-bold text-[#92400E]"
												>Atalhos rápidos:</span
											>
											{#each [0, 25, 50, 70, 82, 100] as preset}
												<button
													type="button"
													onclick={() => (manualProgressPct = preset)}
													class="px-2 py-0.5 rounded bg-white text-[10px] font-bold border border-[#FDE68A] text-[#78350F] hover:bg-[#FEF3C7] transition-colors cursor-pointer"
												>
													{preset}%
												</button>
											{/each}
										</div>
									</div>
								{/if}

								<!-- Base vs Atual vs Meta Ledger Columns -->
								<div class="grid grid-cols-1 sm:grid-cols-3 gap-3">
									<!-- Baseline -->
									<div
										class="bg-[#FFFDF8] p-3.5 rounded-xl border border-outline-variant/40 shadow-xs focus-within:border-primary focus-within:ring-1 focus-within:ring-primary transition-all"
									>
										<span
											class="block text-[10px] uppercase font-bold text-on-surface-variant mb-1"
										>
											Baseline (Inicial)
										</span>
										<div class="flex items-baseline">
											<span class="text-xs font-bold text-on-surface-variant mr-1">{unit}</span>
											<input
												name="baseline"
												type="number"
												step="any"
												disabled={!canEdit}
												bind:value={baseline}
												class="w-full text-[15px] font-bold text-on-surface bg-transparent border-0 p-0 focus:ring-0 focus:outline-none"
											/>
										</div>
										<span class="text-[10px] text-on-surface-variant font-medium">
											Posição em {currentCycle?.start_date?.slice(0, 10) ?? 'Início do Ciclo'}
										</span>
									</div>

									<!-- Realizado Atual (Highlighted Card) -->
									<div
										class="p-3.5 rounded-xl border-2 shadow-xs transition-all"
										style="background-color: {theme.badgeBg}; border-color: {theme.badgeBorder};"
									>
										<div class="flex items-center justify-between mb-1">
											<span class="block text-[10px] uppercase font-bold" style="color: {theme.badgeText};">
												Realizado Atual
											</span>
											<span
												class="text-[10px] font-extrabold px-1.5 py-0.2 rounded bg-white/80 border"
												style="border-color: {theme.badgeBorder}; color: {theme.accentDark};"
											>
												{calculatedProgressPct}%
											</span>
										</div>
										<div class="flex items-baseline">
											<span class="text-xs font-extrabold mr-1" style="color: {theme.accentDark};">{unit}</span>
											<input
												name="current_value"
												type="number"
												step="any"
												disabled={!canEdit}
												bind:value={currentValue}
												class="w-full text-[15px] font-extrabold bg-transparent border-0 p-0 focus:ring-0 focus:outline-none"
												style="color: {theme.accentDark};"
											/>
										</div>
										<span class="text-[10px] font-medium" style="color: {theme.badgeText};">
											{deltaValue >= 0 ? '+' : ''}{formatNumber(deltaValue, unit)} no período
										</span>
									</div>

									<!-- Meta Final -->
									<div
										class="bg-[#FFFDF8] p-3.5 rounded-xl border border-outline-variant/40 shadow-xs focus-within:border-primary focus-within:ring-1 focus-within:ring-primary transition-all"
									>
										<span
											class="block text-[10px] uppercase font-bold text-on-surface-variant mb-1"
										>
											Meta Final (100%)
										</span>
										<div class="flex items-baseline">
											<span class="text-xs font-bold text-primary mr-1">{unit}</span>
											<input
												name="target_value"
												type="number"
												step="any"
												disabled={!canEdit}
												bind:value={targetValue}
												class="w-full text-[15px] font-bold text-primary bg-transparent border-0 p-0 focus:ring-0 focus:outline-none"
											/>
										</div>
										<span class="text-[10px] text-primary/80 font-medium">
											Alvo {currentCycle?.code ?? 'Semestral'}
										</span>
									</div>
								</div>

								<!-- Tactile Dual-Color Progress Ribbon -->
								<div class="flex flex-col gap-1.5 pt-1">
									<div class="flex justify-between items-center text-[12px]">
										<span class="font-bold text-on-surface-variant"
											>Progresso Consolidado Ponderado</span
										>
										<span
											class="font-bold px-2.5 py-0.5 rounded text-[11px] border transition-all"
											style="background-color: {theme.badgeBg}; border-color: {theme.badgeBorder}; color: {theme.badgeText};"
										>
											{calculatedProgressPct}% Concluído
										</span>
									</div>
									<div
										class="w-full h-3.5 rounded-full bg-surface-container-high p-0.5 shadow-[inset_0_1px_3px_rgba(36,34,30,0.12)]"
									>
										<div
											class="h-full rounded-full transition-all duration-500 shadow-xs"
											style="width: {calculatedProgressPct}%; background-color: {theme.accent};"
										></div>
									</div>
								</div>

								<!-- Bottom Metric Ledger Specs with Interactive Selectors -->
								<div
									class="grid grid-cols-1 sm:grid-cols-3 gap-3 pt-2 border-t border-dashed border-outline-variant/50 text-[12px]"
								>
									<div
										class="flex items-center justify-between bg-[#FFFDF8] px-3.5 py-2 rounded-lg border border-outline-variant/40 shadow-xs"
									>
										<span
											class="text-on-surface-variant font-semibold flex items-center gap-1.5"
										>
											<span class="material-symbols-outlined text-[16px] text-primary"
												>payments</span
											>
											Unidade:
										</span>
										<input
											name="unit"
											type="text"
											bind:value={unit}
											placeholder="R$, %, pts"
											class="w-24 text-right text-xs font-bold text-on-surface bg-[#F6F1E9] border border-outline-variant/40 rounded px-2 py-1 focus:ring-1 focus:ring-primary focus:outline-none"
										/>
									</div>

									<div
										class="flex items-center justify-between bg-[#FFFDF8] px-3.5 py-2 rounded-lg border border-outline-variant/40 shadow-xs"
									>
										<span
											class="text-on-surface-variant font-semibold flex items-center gap-1.5"
										>
											<span class="material-symbols-outlined text-[16px] text-emerald-700"
												>{direction === 'up' ? 'trending_up' : 'trending_down'}</span
											>
											Direção:
										</span>
										<select
											name="direction"
											bind:value={direction}
											class="text-xs font-bold text-emerald-800 bg-[#DCFCE7]/60 border border-emerald-300 rounded px-2 py-1 focus:ring-1 focus:ring-primary focus:outline-none cursor-pointer"
										>
											<option value="up">↗ Crescente</option>
											<option value="down">↘ Decrescente</option>
										</select>
									</div>

									<div
										class="flex items-center justify-between bg-[#FFFDF8] px-3.5 py-2 rounded-lg border border-outline-variant/40 shadow-xs"
									>
										<span
											class="text-on-surface-variant font-semibold flex items-center gap-1.5"
										>
											<span class="material-symbols-outlined text-[16px] text-tertiary"
												>scale</span
											>
											Peso:
										</span>
										<input
											name="weight"
											type="number"
											step="0.1"
											min="0.1"
											bind:value={weight}
											class="w-16 text-right text-xs font-bold text-on-surface bg-[#F6F1E9] border border-outline-variant/40 rounded px-2 py-1 focus:ring-1 focus:ring-primary focus:outline-none"
										/>
									</div>
								</div>
							</div>
						</form>
					{/if}

					<!-- ============================================================== -->
					<!-- ABA 2: KPIS & INDICADORES FILHOS (MRR, NRR, Sparklines)       -->
					<!-- ============================================================== -->
					{#if activeTab === 'tab2'}
						<div class="flex flex-col gap-5">
							<div
								class="flex flex-wrap items-center justify-between gap-2 p-3.5 bg-[#EBF5FF] rounded-xl border border-[#BAE6FD]"
							>
								<div class="flex items-center gap-2.5">
									<span
										class="w-8 h-8 rounded-lg bg-[#3080F9] text-white flex items-center justify-center font-bold text-xs shadow-xs"
									>
										<span class="material-symbols-outlined text-[18px]">monitoring</span>
									</span>
									<div>
										<h4 class="text-xs font-bold text-[#0C4A6E]">
											Desdobramento em Indicadores Operacionais
										</h4>
										<p class="text-[11px] text-[#0369A1]">
											Estes KPIs alimentam automaticamente o cálculo percentual deste Key Result.
										</p>
									</div>
								</div>
								{#if canEdit}
									<button
										type="button"
										onclick={() => onAddChild(node)}
										class="px-3.5 py-1.5 bg-[#3080F9] hover:bg-primary-container text-white rounded-lg text-xs font-bold shadow-xs flex items-center gap-1.5 transition-all cursor-pointer"
									>
										<span class="material-symbols-outlined text-[16px]">add_circle</span>
										Vincular Novo KPI
									</button>
								{/if}
							</div>

							{#if childKpis.length > 0}
								<div class="grid grid-cols-1 md:grid-cols-2 gap-4">
									{#each childKpis as kpi, idx (kpi.id)}
										{@const spark = getKpiSparkline(kpi)}
										{@const isHealthy = kpi.progress >= 0.7}
										{@const kpiColor = kpi.color || (kpi.teams.length > 0 && kpi.teams[0].color ? kpi.teams[0].color : '#00665a')}
										{@const kpiTheme = getDossierTheme(kpiColor)}
										<div
											class="border-2 rounded-xl p-4 shadow-[0_2px_6px_rgba(36,34,30,0.04)] flex flex-col justify-between gap-3 transition-all"
											style="background-color: {kpiTheme.folderBg}; border-color: {kpiTheme.folderBorder};"
										>
											<div>
												<div class="flex items-center justify-between mb-2">
													<div class="flex items-center gap-1.5 flex-wrap">
														<span
															class="px-2 py-0.5 text-[10px] font-bold rounded border"
															style="background-color: {kpiTheme.badgeBg}; border-color: {kpiTheme.badgeBorder}; color: {kpiTheme.badgeText};"
														>
															KPI {idx + 1}
														</span>
														<span
															class="text-[10px] font-bold uppercase tracking-wider"
															style="color: {kpiTheme.accentDark};"
														>
															Peso: {kpi.weight}
														</span>
														{#each kpi.teams as kt (kt.id)}
															{@const ktTheme = getDossierTheme(kt.color || '#0058bd')}
															<span
																class="inline-flex items-center gap-1 px-1.5 py-0.2 rounded text-[9.5px] font-bold border"
																style="background-color: {ktTheme.badgeBg}; border-color: {ktTheme.badgeBorder}; color: {ktTheme.badgeText};"
															>
																<span class="w-1.5 h-1.5 rounded-full" style="background-color: {ktTheme.accent};"></span>
																{kt.name}
															</span>
														{/each}
													</div>
													<div class="flex items-center gap-1">
														{#if onOpenNode}
															<button
																type="button"
																onclick={() => onOpenNode(kpi.id)}
																class="p-1 rounded bg-white/80 hover:bg-white text-[#727784] hover:text-[#0058bd] transition-colors cursor-pointer shadow-xs"
																title="Abrir Dossiê deste KPI"
															>
																<span class="material-symbols-outlined text-[15px]">open_in_new</span>
															</button>
														{/if}
														<span
															class="px-2 py-0.5 rounded-full bg-white/90 text-[11px] font-bold shadow-xs flex items-center gap-1"
															style="color: {kpiTheme.accentDark};"
														>
															<span class="material-symbols-outlined text-[13px]"
																>{isHealthy ? 'trending_up' : 'trending_flat'}</span
															>
															{formatPct(kpi.progress)}
														</span>
													</div>
												</div>
												<h4
													class="text-sm font-bold text-[#1d1b17]"
												>
													{kpi.title}
												</h4>
												{#if kpi.description}
													<p
														class="text-xs mt-0.5"
														style="color: {kpiTheme.badgeText};"
													>
														{kpi.description}
													</p>
												{/if}
											</div>

											<!-- Ledger Metrics Strip -->
											<div
												class="grid grid-cols-3 gap-2 bg-white/85 p-2.5 rounded-lg border text-center"
												style="border-color: {kpiTheme.cardBorder};"
											>
												<div>
													<span
														class="block text-[10px] font-bold uppercase"
														style="color: {kpiTheme.badgeText};"
													>
														Base
													</span>
													<span
														class="text-xs font-bold text-[#1d1b17]"
													>
														{formatNumber(kpi.baseline, kpi.unit)}
													</span>
												</div>
												<div>
													<span
														class="block text-[10px] font-bold uppercase"
														style="color: {kpiTheme.badgeText};"
													>
														Meta
													</span>
													<span
														class="text-xs font-bold text-[#1d1b17]"
													>
														{formatNumber(kpi.target_value, kpi.unit)}
													</span>
												</div>
												<div>
													<span
														class="block text-[10px] font-bold uppercase"
														style="color: {kpiTheme.badgeText};"
													>
														Atual
													</span>
													<span
														class="text-xs font-extrabold"
														style="color: {kpiTheme.accentDark};"
													>
														{formatNumber(kpi.current_value, kpi.unit)}
													</span>
												</div>
											</div>

											<!-- Tactile Sparkline Visualizer -->
											<div
												class="pt-2 border-t border-dashed flex items-center justify-between"
												style="border-color: {kpiTheme.folderBorder};"
											>
												<span
													class="text-[11px] font-medium flex items-center gap-1"
													style="color: {kpiTheme.badgeText};"
												>
													<span class="material-symbols-outlined text-[14px]">history</span>
													Último check-in: {timeAgo(kpi.metricUpdates[0]?.created_at)}
												</span>
												{#if spark}
													<svg class="w-20 h-5" fill="none" viewBox="0 0 80 20">
														<path
															d={spark.d}
															stroke={kpiTheme.accent}
															stroke-linecap="round"
															stroke-width="2"
														></path>
														<circle
															cx={spark.lastPt.x}
															cy={spark.lastPt.y}
															fill={kpiTheme.accentDark}
															r="2.5"
														></circle>
													</svg>
												{/if}
											</div>
										</div>
									{/each}
								</div>

								<!-- KPI Aggregation Formula Explainer -->
								<div
									class="p-3.5 bg-[#FFFDF8] rounded-xl border border-outline-variant/40 flex items-center justify-between text-xs"
								>
									<div class="flex items-center gap-2">
										<span class="material-symbols-outlined text-primary text-[18px]"
											>functions</span
										>
										<span class="text-on-surface font-semibold">
											Ponderação consolidada de {childKpis.length} indicadores =
											<strong>{calculatedProgressPct}% Atingimento Global</strong>
										</span>
									</div>
								</div>
							{:else}
								<div
									class="p-8 bg-[#FBF7F0] rounded-xl border border-dashed border-outline-variant text-center flex flex-col items-center justify-center gap-2"
								>
									<span class="material-symbols-outlined text-outline text-[36px]"
										>account_tree</span
									>
									<h4 class="text-sm font-bold text-on-surface">Nenhum KPI vinculado ainda</h4>
									<p class="text-xs text-on-surface-variant max-w-md">
										Vincule indicadores operacionais para que o progresso deste Resultado-Chave
										seja calculado automaticamente a partir de métricas auditadas.
									</p>
									{#if canEdit}
										<button
											type="button"
											onclick={() => onAddChild(node)}
											class="mt-2 px-4 py-2 bg-primary text-white rounded-lg text-xs font-bold shadow-xs flex items-center gap-1.5 cursor-pointer"
										>
											<span class="material-symbols-outlined text-[16px]">add</span>
											Criar Primeiro KPI Filho
										</button>
									{/if}
								</div>
							{/if}
						</div>
					{/if}

					<!-- ============================================================== -->
					<!-- ABA 3: EQUIPE & VALORES (Líder, Co-donos, Alinhamento de Eras) -->
					<!-- ============================================================== -->
					{#if activeTab === 'tab3'}
						<div class="grid grid-cols-1 md:grid-cols-2 gap-5">
							<!-- Primary Assignee and Team Co-owners -->
							<form
								method="POST"
								action="/strategy?/setAssignees"
								class="p-4 bg-[#FFFDF8] rounded-xl border border-outline-variant/50 shadow-xs flex flex-col gap-4"
							>
								<input type="hidden" name="nodeId" value={node.id} />
								<div class="flex items-center justify-between">
									<span
										class="text-[11px] font-bold uppercase tracking-wider text-on-surface-variant flex items-center justify-between"
									>
										<span>Líder Responsável pelo KR</span>
									</span>
									{#if canEdit}
										<button
											type="submit"
											class="px-2.5 py-1 rounded bg-primary text-white text-[11px] font-bold shadow-xs hover:opacity-90 cursor-pointer"
										>
											Salvar Equipe
										</button>
									{/if}
								</div>

								{#if primaryAssignee}
									<div
										class="flex items-center gap-3 p-3 bg-[#FBF7F0] rounded-xl border border-outline-variant/40"
									>
										<span
											class="w-12 h-12 rounded-full text-white flex items-center justify-center font-bold text-sm shadow-xs ring-2 ring-white shrink-0"
											style="background-color: {primaryAssignee.color || '#005AC2'}"
										>
											{getInitials(primaryAssignee.name)}
										</span>
										<div class="flex flex-col min-w-0">
											<span class="text-[14px] font-bold text-on-surface truncate">
												{primaryAssignee.name}
											</span>
											<span class="text-[11px] text-on-surface-variant font-medium">
												{primaryAssignee.role.toUpperCase()}
											</span>
											<span class="text-[10px] text-primary font-semibold mt-0.5 truncate">
												{primaryAssignee.email ?? 'Sem e-mail cadastrado'}
											</span>
										</div>
									</div>
								{:else}
									<div
										class="p-3 bg-[#FBF7F0] rounded-xl border border-dashed border-outline-variant text-center text-xs text-on-surface-variant"
									>
										Nenhum titular atribuído
									</div>
								{/if}

								<!-- Members assignment checklist -->
								<div class="flex flex-col gap-1.5 pt-1">
									<span class="font-bold text-on-surface-variant text-[11px] uppercase tracking-wider">
										Atribuir Membros Responsáveis:
									</span>
									<div class="max-h-48 overflow-y-auto space-y-1 pr-1">
										{#each profiles as prof (prof.id)}
											{@const assigned = node.assignees.some((a) => a.id === prof.id)}
											<label
												class="flex cursor-pointer items-center justify-between rounded-lg border p-2 text-xs transition {assigned
													? 'border-on-surface bg-surface-container font-bold text-on-surface'
													: 'border-outline-variant/50 bg-[#FFFDF8] text-on-surface-variant hover:bg-surface-container'}"
											>
												<div class="flex items-center gap-2 min-w-0">
													<input
														type="checkbox"
														name="userIds"
														value={prof.id}
														checked={assigned}
														disabled={!canEdit}
														class="rounded-xs border-outline-variant text-primary"
													/>
													<span
														class="w-5 h-5 rounded-full text-[9px] font-bold text-white flex items-center justify-center shrink-0"
														style="background-color: {prof.color || '#005AC2'}"
													>
														{getInitials(prof.name)}
													</span>
													<span class="truncate">{prof.name}</span>
												</div>
												<span class="text-[10px] text-on-surface-variant font-normal">
													{prof.role}
												</span>
											</label>
										{/each}
									</div>
								</div>

								<!-- Teams co-responsible -->
								<div class="flex flex-col gap-1.5 pt-1 border-t border-outline-variant/40">
									<span class="font-bold text-on-surface-variant text-[11px] uppercase tracking-wider">
										Departamentos / Equipes:
									</span>
									<div class="flex flex-wrap gap-1.5">
										{#each teams as tm (tm.id)}
											{@const hasTeam = node.teams.some((t) => t.id === tm.id)}
											{@const tmTheme = getDossierTheme(tm.color || '#0058bd')}
											<label
												class="flex items-center gap-1.5 px-2.5 py-1 rounded-lg border text-xs cursor-pointer transition-colors {hasTeam
													? 'font-bold shadow-xs'
													: 'border-outline-variant/50 bg-[#FFFDF8] text-on-surface-variant hover:bg-surface-container'}"
												style={hasTeam
													? `background-color: ${tmTheme.badgeBg}; border-color: ${tmTheme.badgeBorder}; color: ${tmTheme.badgeText};`
													: ''}
											>
												<input
													type="checkbox"
													name="teamIds"
													value={tm.id}
													checked={hasTeam}
													disabled={!canEdit}
													class="hidden"
												/>
												<span
													class="w-2 h-2 rounded-full"
													style="background-color: {tmTheme.accent};"
												></span>
												<span>{tm.name}</span>
											</label>
										{/each}
									</div>
								</div>
							</form>

							<!-- Alignment with Era Values & Strategic Pillars -->
							<form
								method="POST"
								action="/strategy?/setValues"
								class="p-4 bg-[#FFFDF8] rounded-xl border border-outline-variant/50 shadow-xs flex flex-col justify-between gap-3"
							>
								<input type="hidden" name="nodeId" value={node.id} />
								<div class="flex items-center justify-between">
									<span class="text-[11px] font-bold uppercase tracking-wider text-on-surface-variant">
										Conexão com Valores da Era
									</span>
									{#if canEdit}
										<button
											type="submit"
											class="px-2.5 py-1 rounded bg-secondary text-white text-[11px] font-bold shadow-xs hover:opacity-90 cursor-pointer"
										>
											Salvar Valores
										</button>
									{/if}
								</div>

								<div class="flex flex-col gap-2">
									{#each valuesList as val (val.id)}
										{@const checked = node.alignedValues.some((v) => v.id === val.id)}
										<label
											class="p-2.5 rounded-lg border flex items-center justify-between cursor-pointer transition-all {checked
												? 'bg-[#FEF9C3] border-[#FDE047]'
												: 'bg-surface-container-lowest border-outline-variant/40 hover:bg-surface-container'}"
										>
											<div class="flex items-center gap-2.5 min-w-0">
												<input
													type="checkbox"
													name="valueIds"
													value={val.id}
													checked={checked}
													disabled={!canEdit}
													class="rounded-xs border-outline-variant text-primary"
												/>
												<span
													class="w-2.5 h-2.5 rounded-full shrink-0"
													style="background-color: {valueColor(val.id)}"
												></span>
												<div class="flex flex-col min-w-0">
													<span class="text-xs font-bold text-on-surface truncate">
														{val.title}
													</span>
													{#if val.description}
														<span class="text-[10px] text-on-surface-variant truncate">
															{val.description}
														</span>
													{/if}
												</div>
											</div>
											<span
												class="text-[10px] font-bold px-2 py-0.5 rounded shadow-xs ml-2 shrink-0 {checked
													? 'bg-white text-[#854D0E]'
													: 'bg-surface-container text-on-surface-variant'}"
											>
												{checked ? 'Alinhado' : 'Não Alinhado'}
											</span>
										</label>
									{/each}
								</div>

								<div class="mt-1 p-2.5 bg-[#F6F1E9] rounded-lg text-[11px] text-on-surface-variant">
									<strong>Regra de Governança:</strong> Toda alteração no escopo deste KR deve ser validada
									no Rito de Check-in Quinzenal com o Sponsor Executivo.
								</div>
							</form>
						</div>
					{/if}

					<!-- ============================================================== -->
					<!-- ABA 4: HISTÓRICO & LOG DE CHECK-IN (Timeline)                  -->
					<!-- ============================================================== -->
					{#if activeTab === 'tab4'}
						<div class="flex flex-col gap-4">
							<div
								class="flex items-center justify-between p-3.5 bg-[#FBF7F0] rounded-xl border border-outline-variant/40"
							>
								<div class="flex items-center gap-2">
									<span class="material-symbols-outlined text-primary text-[20px]"
										>history_toggle_off</span
									>
									<span class="text-xs font-bold text-on-surface">
										Linha do Tempo de Check-ins &amp; Atualizações Quantitativas
									</span>
								</div>
								{#if canEdit}
									<button
										type="button"
										onclick={() => (showNewCheckinForm = !showNewCheckinForm)}
										class="px-3 py-1 bg-surface-container-lowest hover:bg-surface-container border border-outline-variant/40 rounded-lg text-xs font-bold text-primary transition-all cursor-pointer"
									>
										{showNewCheckinForm ? 'Fechar Formulário' : '+ Novo Check-in Manual'}
									</button>
								{/if}
							</div>

							<!-- Inline Form for New Check-in -->
							{#if showNewCheckinForm && canEdit}
								<form
									method="POST"
									action="/strategy?/logMetric"
									use:enhanceFormValidation
									class="p-4 bg-[#FFFDF8] rounded-xl border-2 border-primary/40 shadow-xs flex flex-col gap-3"
								>
									<input type="hidden" name="nodeId" value={node.id} />
									<div class="flex items-center justify-between">
										<span class="text-xs font-bold text-on-surface uppercase tracking-wider">
											Registrar Nova Medição para este KR
										</span>
									</div>
									<div class="grid grid-cols-1 sm:grid-cols-12 gap-3">
										<div class="sm:col-span-4">
											<label
												for="modal-checkin-val"
												class="block text-[10px] uppercase font-bold text-on-surface-variant mb-1"
											>
												Novo Valor Aferido ({unit}) *
											</label>
											<input
												id="modal-checkin-val"
												name="value"
												type="number"
												step="any"
												required
												bind:value={newCheckinValue}
												placeholder="Ex: 3440000"
												class="w-full px-3 py-2 bg-surface-container-lowest rounded-lg border border-outline-variant text-xs font-bold text-on-surface focus:outline-none focus:ring-1 focus:ring-primary"
											/>
										</div>
										<div class="sm:col-span-8">
											<label
												for="modal-checkin-note"
												class="block text-[10px] uppercase font-bold text-on-surface-variant mb-1"
											>
												Nota Contextual / Evidência (Opcional)
											</label>
											<input
												id="modal-checkin-note"
												name="note"
												type="text"
												bind:value={newCheckinNote}
												placeholder="Ex: Novos contratos fechados com banco enterprise..."
												class="w-full px-3 py-2 bg-surface-container-lowest rounded-lg border border-outline-variant text-xs text-on-surface focus:outline-none focus:ring-1 focus:ring-primary"
											/>
										</div>
									</div>
									<div class="flex justify-end gap-2 pt-1">
										<button
											type="button"
											onclick={() => (showNewCheckinForm = false)}
											class="px-3 py-1.5 text-xs text-on-surface-variant hover:text-on-surface font-semibold cursor-pointer"
										>
											Cancelar
										</button>
										<button
											type="submit"
											class="px-4 py-1.5 bg-primary text-white rounded-lg text-xs font-bold shadow-xs hover:bg-primary-container cursor-pointer"
										>
											Salvar Medição
										</button>
									</div>
								</form>
							{/if}

							<!-- Timeline stream -->
							{#if node.metricUpdates.length > 0}
								<div
									class="relative pl-6 space-y-4 before:absolute before:left-2.5 before:top-2 before:bottom-2 before:w-0.5 before:bg-[#E7E2DB]"
								>
									{#each node.metricUpdates as mu, idx (mu.id)}
										<div class="relative">
											<span
												class="absolute -left-6 top-1 w-3 h-3 rounded-full ring-4 ring-[#FFFDF8] {idx ===
												0
													? 'bg-primary'
													: 'bg-[#3080F9]'}"
											></span>
											<div
												class="p-3.5 bg-[#FFFDF8] rounded-xl border border-outline-variant/40 shadow-xs flex flex-col gap-1"
											>
												<div class="flex items-center justify-between">
													<span class="text-xs font-bold text-on-surface">
														Medição: {formatNumber(mu.value, unit)}
													</span>
													<span class="text-[10px] text-on-surface-variant font-semibold">
														{mu.created_at.slice(0, 10)} ({timeAgo(mu.created_at)})
													</span>
												</div>
												{#if mu.note}
													<p class="text-xs text-on-surface-variant mt-0.5">
														{mu.note}
													</p>
												{/if}
											</div>
										</div>
									{/each}
								</div>
							{:else}
								<div
									class="p-8 bg-[#FBF7F0] rounded-xl border border-dashed border-outline-variant text-center flex flex-col items-center justify-center gap-2"
								>
									<span class="material-symbols-outlined text-outline text-[32px]">schedule</span>
									<h4 class="text-sm font-bold text-on-surface">Nenhum check-in registrado</h4>
									<p class="text-xs text-on-surface-variant max-w-sm">
										Clique em "+ Novo Check-in Manual" acima para auditar o primeiro registro de
										evolução quantitativa deste KR.
									</p>
								</div>
							{/if}
						</div>
					{/if}
				</div>

				<!-- Dossier Footer Ribbon -->
				<div
					class="px-5 py-3 sm:px-6 sm:py-3.5 border-t flex flex-col gap-2 shrink-0 transition-colors duration-200"
					style="background-color: {theme.footerBg}; border-color: {theme.folderBorder};"
				>
					<!-- Linha de Costura / Picote Sutil de Papel Manilha -->
					<div
						class="h-[1.5px] w-full opacity-75"
						style="background-image: repeating-linear-gradient(to right, {theme.stitchedColor} 0px, {theme.stitchedColor} 6px, transparent 6px, transparent 11px);"
					></div>

					<div class="flex flex-wrap items-center justify-between gap-3">
						<div class="flex items-center gap-2 text-xs text-on-surface-variant font-medium">
							<span class="material-symbols-outlined text-[16px]" style="color: {theme.accent};">schedule</span>
							<span>
								{#if latestMetricUpdate}
									Último check-in auditado {timeAgo(latestMetricUpdate.created_at)}
								{:else}
									Sem check-in auditado no período
								{/if}
							</span>
						</div>

					<div class="flex items-center gap-2.5">
						{#if canEdit}
							<button
								type="button"
								onclick={() => (showDeleteConfirm = true)}
								class="px-3.5 py-2 text-error hover:bg-error-container/40 rounded-lg text-xs font-bold transition-colors flex items-center gap-1 cursor-pointer"
							>
								<span class="material-symbols-outlined text-[16px]">delete</span>
								Excluir KR
							</button>
						{/if}
						<button
							type="button"
							onclick={onClose}
							class="px-4 py-2 bg-surface-container rounded-lg border border-outline-variant/50 text-on-surface hover:bg-surface-container-high text-xs font-bold transition-all shadow-xs cursor-pointer"
						>
							Cancelar
						</button>
						{#if canEdit}
							<button
								type="submit"
								form="updateKrForm"
								class="px-5 py-2 text-white rounded-lg text-xs font-bold hover:brightness-105 hover:-translate-y-0.5 active:translate-y-0.5 transition-all flex items-center gap-1.5 cursor-pointer"
								style="background-color: {theme.accent}; box-shadow: 0 2px 0 {theme.accentShadow};"
							>
								<span class="material-symbols-outlined text-[18px]">check</span>
								Salvar Alterações no Dossiê
							</button>
						{/if}
					</div>
				</div>
			</div>
		</div>
	</div>
	</div>

	<!-- Delete KR Confirmation Modal -->
	{#if showDeleteConfirm}
		<div
			role="presentation"
			onclick={() => (showDeleteConfirm = false)}
			class="fixed inset-0 z-60 flex items-center justify-center p-4 bg-on-surface/40 backdrop-blur-xs"
		>
			<!-- svelte-ignore a11y_click_events_have_key_events -->
			<!-- svelte-ignore a11y_no_noninteractive_element_interactions -->
			<div
				role="dialog"
				tabindex="-1"
				aria-modal="true"
				onclick={(e) => e.stopPropagation()}
				class="w-full max-w-md bg-surface-container-lowest p-6 rounded-2xl shadow-2xl border border-outline-variant flex flex-col gap-4"
			>
				<div class="flex items-center gap-3">
					<span
						class="w-10 h-10 rounded-full bg-error-container text-error flex items-center justify-center shrink-0"
					>
						<span class="material-symbols-outlined text-[24px]">warning</span>
					</span>
					<div>
						<h3 class="text-sm font-bold text-on-surface">Confirmar Exclusão de KR</h3>
						<p class="text-xs text-on-surface-variant">Esta ação não pode ser desfeita.</p>
					</div>
				</div>
				<p class="text-xs text-on-surface">
					Tem certeza que deseja excluir o Resultado-Chave <strong>"{node.title}"</strong>?
					{#if childKpis.length > 0}
						<br /><br />
						<span class="text-error font-semibold">
							Atenção: Este KR possui {childKpis.length} KPI(s) filho(s). Você pode excluí-los em cascata
							ou promovê-los para o Objetivo pai.
						</span>
					{/if}
				</p>
				<div class="flex flex-wrap items-center justify-end gap-2 pt-2">
					<button
						type="button"
						onclick={() => (showDeleteConfirm = false)}
						class="px-3 py-1.5 rounded-lg border border-outline-variant text-xs font-semibold text-on-surface hover:bg-surface-container"
					>
						Cancelar
					</button>
					<form method="POST" action="/strategy?/deleteNode">
						<input type="hidden" name="nodeId" value={node.id} />
						<input type="hidden" name="promote" value="0" />
						<button
							type="submit"
							class="px-3.5 py-1.5 rounded-lg bg-error text-white text-xs font-bold shadow-xs hover:opacity-90"
						>
							Excluir KR
						</button>
					</form>
					{#if childKpis.length > 0 && node.parent_id}
						<form method="POST" action="/strategy?/deleteNode">
							<input type="hidden" name="nodeId" value={node.id} />
							<input type="hidden" name="promote" value="1" />
							<button
								type="submit"
								class="px-3.5 py-1.5 rounded-lg bg-primary text-white text-xs font-bold shadow-xs hover:opacity-90"
							>
								Excluir e Promover KPIs
							</button>
						</form>
					{/if}
				</div>
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

	/* Folder Dossier Tab Trapeze / File-folder tab shapes */
	.folder-tab {
		position: relative;
		border-top-left-radius: 12px;
		border-top-right-radius: 12px;
		transition: all 0.2s cubic-bezier(0.16, 1, 0.3, 1);
	}
	.folder-tab-active {
		z-index: 20;
		box-shadow:
			0 -4px 12px rgba(29, 27, 23, 0.06),
			0 1px 0 #fffdfa;
	}
	.folder-tab:not(.folder-tab-active):hover {
		transform: translateY(-2px);
	}
</style>

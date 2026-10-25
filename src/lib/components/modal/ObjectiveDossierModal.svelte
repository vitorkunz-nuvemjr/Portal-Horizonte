<script lang="ts">
	import { enhance } from '$app/forms';
	import type { Cycle, NodeStatus, NodeWithExtras, Profile, StrategyNode, Team } from '$lib/types';
	import { enhanceFormValidation, formatNumber, formatPct, getInitials, getTeamIcon } from '$lib/utils';
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

	// Local mutable states for reactive calculations
	let title = $state('');
	let description = $state('');
	let status = $state<NodeStatus>('on_track');
	let weight = $state(1);
	let year = $state(2026);
	let quarter = $state<number | null>(null);
	let cycleId = $state('');
	let manualProgressPct = $state(0);

	// Relationships state
	let selectedTeamIds = $state<string[]>([]);
	let selectedMemberIds = $state<string[]>([]);
	let selectedValueIds = $state<string[]>([]);

	// Visual theme state
	let accentColor = $state('#0058bd');

	// UI interactive dropdowns
	let showAddTeamDropdown = $state(false);
	let showAddMemberDropdown = $state(false);
	let showDeleteConfirm = $state(false);
	let isSaving = $state(false);

	// Sync local states whenever node changes
	$effect(() => {
		if (node) {
			title = node.title;
			description = node.description ?? '';
			status = node.status;
			weight = node.weight;
			year = node.year ?? 2026;
			quarter = node.quarter ?? null;
			cycleId = node.cycle_id ?? '';
			manualProgressPct = Math.round((node.manual_progress ?? 0) * 100);

			selectedTeamIds = node.teams.map((t) => t.id);
			selectedMemberIds = node.assignees.map((a) => a.id);
			selectedValueIds = node.alignedValues.map((v) => v.id);

			// Determine initial accent color
			if (node.color) {
				accentColor = node.color;
			} else if (node.alignedValues.length > 0) {
				accentColor = valueColor(node.alignedValues[0].id);
			} else if (node.teams.length > 0 && node.teams[0].color) {
				accentColor = node.teams[0].color;
			} else {
				accentColor = '#0058bd';
			}
		}
	});

	// Derived theme based on active accent color
	const theme = $derived(getDossierTheme(accentColor));

	// Child Key Results
	const childKrs = $derived(node ? node.children.filter((c) => c.type === 'key_result') : []);

	// Calculated progress: if child KRs exist, use aggregate progress from engine; otherwise use manual %
	const consolidatedProgressPct = $derived.by(() => {
		if (!node) return 0;
		if (childKrs.length === 0) return Math.max(0, Math.min(100, manualProgressPct));
		return Math.round(Math.max(0, Math.min(1, node.progress)) * 100);
	});

	// Resolved cycle
	const currentCycle = $derived.by(() => {
		if (!node) return null;
		if (cycleId) return cycles.find((c) => c.id === cycleId) ?? null;
		return node.cycle;
	});

	// Color swatches for customization
	const colorSwatches = [
		{ name: 'Azul Horizonte', hex: '#0058bd' },
		{ name: 'Verde Esmeralda', hex: '#059669' },
		{ name: 'Roxo Estratégico', hex: '#7c3aed' },
		{ name: 'Framboesa Magenta', hex: '#b30069' },
		{ name: 'Âmbar Solar', hex: '#c2ac00' },
		{ name: 'Laranja Terracota', hex: '#ea580c' }
	];

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

	// Status options
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

	function toggleValue(valId: string) {
		if (selectedValueIds.includes(valId)) {
			selectedValueIds = selectedValueIds.filter((id) => id !== valId);
		} else {
			selectedValueIds = [...selectedValueIds, valId];
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
		<!-- WRAPPER: CLÁSSICA PASTA DE ARQUIVO SEM TRILHO METÁLICO -->
		<!-- svelte-ignore a11y_click_events_have_key_events -->
		<div
			role="dialog"
			tabindex="-1"
			aria-modal="true"
			aria-labelledby="obj-modal-title"
			onclick={(e) => e.stopPropagation()}
			class="relative w-full max-w-5xl my-auto flex flex-col items-stretch animate-in fade-in zoom-in-95 duration-200"
			style="font-family: 'Poppins', sans-serif;"
		>
			<!-- 1. TOPO DA PASTA: ABA SALIENTE COM VISOR DE ACETATO E ETIQUETA ENCAIXADA (SEM TRILHO METÁLICO) -->
			<div class="flex items-end justify-between px-3 sm:px-6 -mb-[1px] relative z-20">
				<!-- Aba Saliente de Arquivo Manilha -->
				<div
					class="relative flex items-center gap-3 px-5 sm:px-7 py-2.5 border-t-2 border-l-2 border-r-2 rounded-t-xl transition-colors duration-200"
					style="background-color: {theme.folderBg}; border-color: {theme.folderBorder}; box-shadow: 0 -3px 10px rgba(0,0,0,0.06), inset 0 1px 0 rgba(255,255,255,0.9);"
				>
					<!-- Visor de Acetato Transparente com Cartão Interno -->
					<div
						class="flex items-center gap-2 px-2.5 py-1 rounded bg-white/95 border shadow-[inset_0_1px_2px_rgba(0,0,0,0.06)]"
						style="border-color: {theme.badgeBorder};"
					>
						<span
							class="w-2.5 h-2.5 rounded-full shadow-sm animate-pulse"
							style="background-color: {accentColor};"
						></span>
						<span
							class="font-mono text-[11.5px] font-bold tracking-wider uppercase"
							style="color: {theme.accentDark};"
						>
							DOSSIÊ OBJETIVO • NÍVEL 01
						</span>
					</div>

					<!-- Indicador de KRs Vinculados e Progresso Consolidado -->
					<div
						class="flex items-center gap-1.5 px-2.5 py-1 rounded-md font-mono text-[11px] font-bold border transition-colors hidden sm:flex"
						style="background-color: {theme.badgeBg}; border-color: {theme.badgeBorder}; color: {theme.badgeText};"
					>
						<span class="material-symbols-outlined text-[14px]" style="color: {theme.accent};">
							target
						</span>
						<span>{childKrs.length} KRs VINCULADOS</span>
						<span class="text-xs font-black ml-1">({consolidatedProgressPct}%)</span>
					</div>

					<!-- Conector contínuo sem costura para o corpo da pasta -->
					<span
						class="absolute -bottom-1 left-0 right-0 h-2 transition-colors duration-200"
						style="background-color: {theme.folderBg};"
					></span>
				</div>

				<!-- Canto Superior Direito: Seletor de Tom Suave & Botão Fechar -->
				<div class="flex items-center gap-2 pb-1.5 pr-1 relative z-40">
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

			<!-- 2. CORPO DA PASTA FÍSICA: Manilha Elegante com tom suave da cor do nó -->
			<form
				method="POST"
				action="?/updateNode"
				use:enhance={() => {
					isSaving = true;
					return async ({ result, update }) => {
						isSaving = false;
						if (result.type === 'success') {
							onClose();
						}
						await update({ reset: false });
					};
				}}
				use:enhanceFormValidation
				class="w-full border-2 rounded-2xl hanging-folder-shadow flex flex-col relative overflow-hidden transition-colors duration-200"
				style="background-color: {theme.folderBg}; border-color: {theme.folderBorder};"
			>
				<input type="hidden" name="nodeId" value={node.id} />
				<input type="hidden" name="color" value={accentColor} />
				<input type="hidden" name="hasAssignees" value="1" />
				{#each selectedMemberIds as u}
					<input type="hidden" name="userIds" value={u} />
				{/each}
				{#each selectedTeamIds as t}
					<input type="hidden" name="teamIds" value={t} />
				{/each}
				<input type="hidden" name="hasValues" value="1" />
				{#each selectedValueIds as v}
					<input type="hidden" name="valueIds" value={v} />
				{/each}

				<!-- Linha de reforço estrutural com gradiente sutil na cor da identidade -->
				<div
					class="h-1.5 w-full relative z-10 border-b transition-colors duration-200"
					style="background: linear-gradient(to right, color-mix(in srgb, {accentColor} 25%, transparent), color-mix(in srgb, {accentColor} 45%, transparent), color-mix(in srgb, {accentColor} 20%, transparent)); border-color: {theme.folderBorder};"
				></div>

				<!-- ÁREA INTERNA DA PASTA (Aba Única em Split de 2 Colunas) -->
				<div class="p-4 sm:p-6 lg:p-7 max-h-[calc(88vh-120px)] overflow-y-auto custom-scroll relative z-10 space-y-6">
					<div class="grid grid-cols-1 lg:grid-cols-12 gap-5 lg:gap-6 items-start">
						<!-- ============================================================== -->
						<!-- COLUNA DA ESQUERDA: PARÂMETROS E ESCOPO ESTRATÉGICO (7/12 ~ 58%) -->
						<!-- ============================================================== -->
						<div class="lg:col-span-7 space-y-4">
							<div
								class="p-5 rounded-2xl border shadow-xs space-y-4 transition-colors"
								style="background-color: {theme.cardBg}; border-color: {theme.cardBorder};"
							>
								<!-- Título do Objetivo Estratégico -->
								<div class="space-y-1.5">
									<div class="flex items-center justify-between">
										<label
											for="obj-title-input"
											class="flex items-center gap-1.5 font-mono text-[11px] uppercase tracking-wider font-bold transition-colors"
											style="color: {theme.accentDark};"
										>
											<span class="material-symbols-outlined text-[16px]" style="color: {theme.accent};">
												flag
											</span>
											Objetivo Macroestratégico
										</label>
										<span
											class="text-[11px] font-mono font-semibold px-2 py-0.5 rounded border transition-colors"
											style="background-color: {theme.badgeBg}; border-color: {theme.badgeBorder}; color: {theme.badgeText};"
										>
											{currentCycle?.code ?? `${year}-S1`}
										</span>
									</div>
									<div
										class="relative flex items-center rounded-xl px-3.5 py-2.5 shadow-inner transition-all border"
										style="background-color: {theme.inputBg}; border-color: {theme.inputBorder};"
									>
										<input
											id="obj-title-input"
											name="title"
											type="text"
											required
											disabled={!canEdit}
											bind:value={title}
											placeholder="Ex.: Consolidar Liderança de Mercado e Eficiência Operacional"
											class="w-full bg-transparent border-0 p-0 text-[#1d1b17] font-display text-[18px] sm:text-[20px] font-bold tracking-tight focus:ring-0 focus:outline-none"
										/>
										<span class="material-symbols-outlined text-[20px] ml-2 shrink-0" style="color: {theme.accent};">
											edit
										</span>
									</div>
								</div>

								<!-- Ano, Trimestre e Ciclo Semestral -->
								<div class="grid grid-cols-1 sm:grid-cols-3 gap-3 pt-1 border-t border-[#edf4ee]">
									<!-- Ano -->
									<div class="space-y-1">
										<label
											for="obj-year-input"
											class="block font-mono text-[10.5px] uppercase font-bold text-[#424753]"
										>
											Ano de Vigência
										</label>
										<input
											id="obj-year-input"
											name="year"
											type="number"
											min="2020"
											max="2035"
											required
											disabled={!canEdit}
											bind:value={year}
											class="w-full rounded-xl px-3 py-1.5 text-xs font-semibold text-[#1d1b17] border shadow-inner transition-all"
											style="background-color: {theme.inputBg}; border-color: {theme.inputBorder};"
										/>
									</div>

									<!-- Trimestre Alvo -->
									<div class="space-y-1">
										<label
											for="obj-quarter-select"
											class="block font-mono text-[10.5px] uppercase font-bold text-[#424753]"
										>
											Trimestre Alvo
										</label>
										<select
											id="obj-quarter-select"
											name="quarter"
											disabled={!canEdit}
											bind:value={quarter}
											class="w-full rounded-xl px-3 py-1.5 text-xs font-semibold text-[#1d1b17] border shadow-inner transition-all"
											style="background-color: {theme.inputBg}; border-color: {theme.inputBorder};"
										>
											<option value={null}>Ano Inteiro</option>
											<option value={1}>1º Trimestre (Q1)</option>
											<option value={2}>2º Trimestre (Q2)</option>
											<option value={3}>3º Trimestre (Q3)</option>
											<option value={4}>4º Trimestre (Q4)</option>
										</select>
									</div>

									<!-- Ciclo Semestral -->
									<div class="space-y-1">
										<label
											for="obj-cycle-select"
											class="block font-mono text-[10.5px] uppercase font-bold text-[#424753]"
										>
											Ciclo Semestral
										</label>
										<select
											id="obj-cycle-select"
											name="cycle_id"
											disabled={!canEdit}
											bind:value={cycleId}
											class="w-full rounded-xl px-3 py-1.5 text-xs font-semibold text-[#1d1b17] border shadow-inner transition-all"
											style="background-color: {theme.inputBg}; border-color: {theme.inputBorder};"
										>
											<option value="">Herdar / Nenhum</option>
											{#each cycles as cyc (cyc.id)}
												<option value={cyc.id}>{cyc.code} ({cyc.year})</option>
											{/each}
										</select>
									</div>
								</div>

								<!-- Status Estratégico & Peso -->
								<div class="space-y-2 pt-1 border-t border-[#edf4ee]">
									<div class="flex items-center justify-between">
										<span class="font-mono text-[10.5px] uppercase font-bold text-[#424753]">
											Status de Execução &amp; Peso
										</span>
										<div class="flex items-center gap-2">
											<span class="text-[11px] font-mono text-[#727784]">Peso:</span>
											<input
												id="obj-weight-input"
												name="weight"
												type="number"
												step="0.1"
												min="0.1"
												disabled={!canEdit}
												bind:value={weight}
												class="w-16 rounded-lg px-2 py-0.5 text-xs font-bold text-center border"
												style="background-color: {theme.inputBg}; border-color: {theme.inputBorder};"
											/>
										</div>
									</div>

									<!-- Grade de Botões de Status -->
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

								<!-- Barra de Progresso Consolidado -->
								<div class="space-y-1.5 pt-1 border-t border-[#edf4ee]">
									<div class="flex items-center justify-between text-xs">
										<span class="font-mono text-[10.5px] uppercase font-bold text-[#424753] flex items-center gap-1.5">
											<span class="material-symbols-outlined text-[15px]" style="color: {theme.accent};">
												insights
											</span>
											Progresso do Objetivo
										</span>
										<span class="font-bold text-sm" style="color: {theme.accentDark};">
											{consolidatedProgressPct}%
										</span>
									</div>

									<div class="w-full h-2.5 rounded-full bg-[#e8e2d8] overflow-hidden p-0.5">
										<div
											class="h-full rounded-full transition-all duration-500"
											style="width: {consolidatedProgressPct}%; background-color: {theme.accent};"
										></div>
									</div>

									{#if childKrs.length === 0}
										<div class="flex items-center justify-between pt-1">
											<label
												for="obj-manual-prog"
												class="text-[11px] text-[#727784] font-medium"
											>
												Sem KRs filhos: definir progresso manual (%)
											</label>
											<input
												id="obj-manual-prog"
												name="manual_progress_pct"
												type="number"
												min="0"
												max="100"
												disabled={!canEdit}
												bind:value={manualProgressPct}
												class="w-16 rounded-lg px-2 py-0.5 text-xs font-bold text-center border"
												style="background-color: {theme.inputBg}; border-color: {theme.inputBorder};"
											/>
										</div>
									{:else}
										<p class="text-[10.5px] text-[#727784] italic">
											Progresso calculado automaticamente a partir dos {childKrs.length} Resultados-Chave filhos.
										</p>
									{/if}
								</div>

								<!-- Descrição & Contexto Estratégico -->
								<div class="space-y-1.5 pt-1 border-t border-[#edf4ee]">
									<label
										for="obj-desc-input"
										class="flex items-center gap-1.5 font-mono text-[11px] uppercase tracking-wider font-bold"
										style="color: {theme.accentDark};"
									>
										<span class="material-symbols-outlined text-[16px]" style="color: {theme.accent};">
											description
										</span>
										Descrição &amp; Racional Estratégico
									</label>
									<div
										class="rounded-xl p-3 shadow-inner transition-all border"
										style="background-color: {theme.inputBg}; border-color: {theme.inputBorder};"
									>
										<textarea
											id="obj-desc-input"
											name="description"
											rows="3"
											disabled={!canEdit}
											bind:value={description}
											placeholder="Descreva o propósito deste objetivo, por que ele é prioritário e quais impactos de negócio trará..."
											class="w-full bg-transparent border-0 p-0 text-[#1d1b17] font-sans text-[13px] leading-relaxed focus:ring-0 focus:outline-none resize-none font-medium"
										></textarea>
									</div>
								</div>

								<!-- Pilares Estratégicos & Valores Alinhados -->
								{#if valuesList.length > 0}
									<div class="space-y-2 pt-1 border-t border-[#edf4ee]">
										<div class="flex items-center justify-between">
											<span class="font-mono text-[10.5px] uppercase font-bold text-[#424753] flex items-center gap-1.5">
												<span class="material-symbols-outlined text-[15px]" style="color: {theme.accent};">
													verified
												</span>
												Pilares &amp; Valores da Missão
											</span>
											<span class="text-[11px] font-mono text-[#727784]">
												{selectedValueIds.length} selecionado(s)
											</span>
										</div>

										<div class="flex flex-wrap gap-1.5">
											{#each valuesList as val (val.id)}
												{@const isSelected = selectedValueIds.includes(val.id)}
												{@const col = valueColor(val.id)}
												<button
													type="button"
													onclick={() => canEdit && toggleValue(val.id)}
													class="inline-flex items-center gap-1.5 px-3 py-1 rounded-xl text-xs font-semibold border transition-all cursor-pointer {isSelected
														? 'shadow-xs scale-102 text-white'
														: 'bg-[#faf8f5] hover:bg-[#f3ede4] text-[#424753] border-[#e2dcd2]'}"
													style={isSelected ? `background-color: ${col}; border-color: ${col};` : ''}
												>
													<span class="w-1.5 h-1.5 rounded-full {isSelected ? 'bg-white' : ''}" style={!isSelected ? `background-color: ${col};` : ''}></span>
													<span>{val.title}</span>
													{#if isSelected}
														<span class="material-symbols-outlined text-[13px]">check</span>
													{/if}
												</button>
											{/each}
										</div>
									</div>
								{/if}
							</div>
						</div>

						<!-- ============================================================== -->
						<!-- COLUNA DA DIREITA: EQUIPES, LÍDERES E RESULTADOS-CHAVE (5/12)   -->
						<!-- ============================================================== -->
						<div class="lg:col-span-5 space-y-4">
							<!-- CARD 1: EQUIPES & DIRETORIAS RESPONSÁVEIS -->
							<div
								class="p-4 rounded-2xl border shadow-xs space-y-3 transition-colors"
								style="background-color: {theme.cardBg}; border-color: {theme.cardBorder};"
							>
								<div class="flex items-center justify-between pb-1 border-b border-[#edf4ee]">
									<div class="flex items-center gap-2">
										<span class="material-symbols-outlined text-[17px]" style="color: {theme.accent};">
											corporate_fare
										</span>
										<h4
											class="font-mono text-[11px] uppercase tracking-wider font-bold"
											style="color: {theme.accentDark};"
										>
											Diretorias ({selectedTeamIds.length})
										</h4>
									</div>

									{#if canEdit}
										<div class="relative">
											<button
												type="button"
												onclick={() => (showAddTeamDropdown = !showAddTeamDropdown)}
												class="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg font-mono text-[10.5px] font-bold border transition-colors cursor-pointer hover:brightness-95"
												style="background-color: {theme.badgeBg}; border-color: {theme.badgeBorder}; color: {theme.accentDark};"
											>
												<span class="material-symbols-outlined text-[14px]">add</span>
												<span>+ Vincular Diretoria</span>
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
													<span class="block px-2 py-1 font-mono text-[10px] uppercase font-bold text-[#727784]">
														Selecione a Diretoria:
													</span>
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

								<!-- Lista de Equipes Vinculadas -->
								<div class="flex flex-wrap gap-1.5">
									{#if selectedTeamIds.length === 0}
										<div class="w-full p-2.5 rounded-xl bg-[#faf8f5] border border-dashed border-[#dcd6cc] text-center">
											<p class="text-[11.5px] text-[#727784]">Nenhuma diretoria vinculada diretamente.</p>
										</div>
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
															title="Desvincular equipe"
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

							<!-- CARD 2: LÍDERES E MEMBROS RESPONSÁVEIS -->
							<div
								class="p-4 rounded-2xl border shadow-xs space-y-3 transition-colors"
								style="background-color: {theme.cardBg}; border-color: {theme.cardBorder};"
							>
								<div class="flex items-center justify-between pb-1 border-b border-[#edf4ee]">
									<div class="flex items-center gap-2">
										<span class="material-symbols-outlined text-[17px]" style="color: {theme.accent};">
											group
										</span>
										<h4
											class="font-mono text-[11px] uppercase tracking-wider font-bold"
											style="color: {theme.accentDark};"
										>
											Responsáveis ({selectedMemberIds.length})
										</h4>
									</div>

									{#if canEdit}
										<div class="relative">
											<button
												type="button"
												onclick={() => (showAddMemberDropdown = !showAddMemberDropdown)}
												class="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg font-mono text-[10.5px] font-bold border transition-colors cursor-pointer hover:brightness-95"
												style="background-color: {theme.badgeBg}; border-color: {theme.badgeBorder}; color: {theme.accentDark};"
											>
												<span class="material-symbols-outlined text-[14px]">person_add</span>
												<span>+ Adicionar</span>
											</button>

											{#if showAddMemberDropdown}
												{@const availableProfiles = profiles.filter((p) => !selectedMemberIds.includes(p.id))}
												<div
													role="presentation"
													class="fixed inset-0 z-30"
													onclick={() => (showAddMemberDropdown = false)}
												></div>
												<div
													class="absolute right-0 top-full mt-1.5 w-64 rounded-xl bg-white border border-[#d5cebe] shadow-xl p-2 z-40 space-y-1 max-h-56 overflow-y-auto custom-scroll"
												>
													<span class="block px-2 py-1 font-mono text-[10px] uppercase font-bold text-[#727784]">
														Selecione o Membro:
													</span>
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

								<!-- Lista de Membros -->
								<div class="space-y-1.5 max-h-44 overflow-y-auto custom-scroll p-0.5">
									{#if selectedMemberIds.length === 0}
										<div class="p-2.5 rounded-xl bg-[#faf8f5] border border-dashed border-[#dcd6cc] text-center">
											<p class="text-[11.5px] text-[#727784]">Nenhum líder associado individualmente.</p>
										</div>
									{:else}
										{#each selectedMemberIds as mid (mid)}
											{@const mem = profiles.find((p) => p.id === mid)}
											{#if mem}
												<div
													class="flex items-center justify-between p-2 rounded-xl bg-[#faf8f5] border transition-colors"
													style="border-color: {theme.cardBorder};"
												>
													<div class="flex items-center gap-2.5 min-w-0">
														<div
															class="w-7 h-7 rounded-full text-white text-[10px] font-bold flex items-center justify-center shadow-xs shrink-0"
															style="background-color: {mem.color || '#004190'};"
														>
															{getInitials(mem.name)}
														</div>
														<div class="min-w-0">
															<p class="text-[12.5px] font-bold text-[#1d1b17] truncate leading-tight">
																{mem.name}
															</p>
															<p class="text-[10px] font-mono text-[#727784] uppercase">
																{mem.role}
															</p>
														</div>
													</div>

													{#if canEdit}
														<button
															type="button"
															onclick={() => removeMember(mem.id)}
															class="p-1 text-[#727784] hover:text-[#ba1a1a] transition-colors rounded cursor-pointer"
															title="Remover responsável"
														>
															<span class="material-symbols-outlined text-[16px]">close</span>
														</button>
													{/if}
												</div>
											{/if}
										{/each}
									{/if}
								</div>
							</div>

							<!-- CARD 3: RESULTADOS-CHAVE (KRS FILHOS) VINCULADOS -->
							<div
								class="p-4 rounded-2xl border shadow-xs space-y-3 transition-colors"
								style="background-color: {theme.cardBg}; border-color: {theme.cardBorder};"
							>
								<div class="flex items-center justify-between pb-1 border-b border-[#edf4ee]">
									<div class="flex items-center gap-2">
										<span class="material-symbols-outlined text-[17px]" style="color: {theme.accent};">
											checklist
										</span>
										<h4
											class="font-mono text-[11px] uppercase tracking-wider font-bold"
											style="color: {theme.accentDark};"
										>
											Resultados-Chave ({childKrs.length})
										</h4>
									</div>

									{#if canEdit}
										<button
											type="button"
											onclick={() => onAddChild(node)}
											class="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg font-mono text-[10.5px] font-bold border transition-colors cursor-pointer hover:brightness-95"
											style="background-color: {theme.badgeBg}; border-color: {theme.badgeBorder}; color: {theme.accentDark};"
										>
											<span class="material-symbols-outlined text-[14px]">add</span>
											<span>+ Novo KR</span>
										</button>
									{/if}
								</div>

								<!-- Lista de KRs Filhos com Navegação Direta -->
								<div class="space-y-2 max-h-56 overflow-y-auto custom-scroll p-0.5">
									{#if childKrs.length === 0}
										<div class="p-3.5 rounded-xl bg-[#faf8f5] border border-dashed border-[#dcd6cc] text-center">
											<p class="text-[12px] text-[#727784] font-medium">Nenhum Resultado-Chave cadastrado.</p>
											<p class="text-[11px] text-[#727784]/80 mt-0.5">
												Clique em "+ Novo KR" para desdobrar este objetivo em metas mensuráveis.
											</p>
										</div>
									{:else}
										{#each childKrs as kr, kIdx (kr.id)}
											{@const krPct = Math.round(kr.progress * 100)}
											{@const krColor = kr.color || (kr.teams.length > 0 && kr.teams[0].color ? kr.teams[0].color : accentColor)}
											{@const krTheme = getDossierTheme(krColor)}
											<div
												class="p-2.5 rounded-xl border transition-all flex flex-col gap-1.5 shadow-xs hover:brightness-98"
												style="background-color: {krTheme.cardBg}; border-color: {krTheme.cardBorder};"
											>
												<div class="flex items-start justify-between gap-2">
													<div class="min-w-0">
														<div class="flex items-center gap-1.5 flex-wrap">
															<span
																class="font-mono text-[10px] font-bold px-1.5 py-0.2 rounded border"
																style="background-color: {krTheme.badgeBg}; border-color: {krTheme.badgeBorder}; color: {krTheme.badgeText};"
															>
																KR {kIdx + 1}
															</span>
															{#each kr.teams as kt (kt.id)}
																{@const ktTheme = getDossierTheme(kt.color || '#0058bd')}
																<span
																	class="inline-flex items-center gap-1 px-1.5 py-0.2 rounded text-[9.5px] font-bold border"
																	style="background-color: {ktTheme.badgeBg}; border-color: {ktTheme.badgeBorder}; color: {ktTheme.badgeText};"
																>
																	<span
																		class="material-symbols-outlined text-[12px] shrink-0"
																		style="color: {ktTheme.accent};"
																	>
																		{getTeamIcon(kt)}
																	</span>
																	{kt.name}
																</span>
															{/each}
														</div>
														<p class="text-[12px] font-bold text-[#1d1b17] mt-1 line-clamp-1">
															{kr.title}
														</p>
													</div>

													{#if onOpenNode}
														<button
															type="button"
															onclick={() => onOpenNode(kr.id)}
															class="p-1 rounded text-[#727784] hover:text-primary hover:bg-white transition-colors shrink-0 cursor-pointer"
															title="Abrir Dossiê deste Resultado-Chave"
														>
															<span class="material-symbols-outlined text-[16px]">open_in_new</span>
														</button>
													{/if}
												</div>

												<!-- Mini Barra de Progresso do KR -->
												<div class="flex items-center gap-2">
													<div class="flex-1 h-1.5 rounded-full bg-[#e8e2d8] overflow-hidden">
														<div
															class="h-full rounded-full"
															style="width: {krPct}%; background-color: {krTheme.accent};"
														></div>
													</div>
													<span class="font-mono text-[10.5px] font-bold" style="color: {krTheme.accentDark};">
														{krPct}%
													</span>
												</div>
											</div>
										{/each}
									{/if}
								</div>
							</div>
						</div>
					</div>
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
						<!-- Botão 'Excluir Objetivo' -->
						{#if canEdit}
							<button
								type="button"
								onclick={() => (showDeleteConfirm = true)}
								class="inline-flex items-center gap-1.5 px-3 py-2 rounded-xl text-[#ba1a1a] hover:bg-[#ffdad6]/60 font-sans text-[12.5px] font-semibold transition-colors self-start sm:self-auto cursor-pointer"
							>
								<span class="material-symbols-outlined text-[16px]">delete</span>
								<span>Excluir Objetivo</span>
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
			</form>
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
					<h3 class="font-bold text-lg text-[#1d1b17]">Excluir Objetivo Estratégico?</h3>
				</div>

				<p class="text-sm text-[#424753] leading-relaxed">
					Você tem certeza de que deseja excluir o objetivo <strong>"{node.title}"</strong>?
					{#if childKrs.length > 0}
						<br />
						<span class="text-xs text-[#ba1a1a] font-semibold mt-1 block">
							Atenção: Existem {childKrs.length} Resultados-Chave vinculados a este objetivo.
						</span>
					{/if}
				</p>

				<form
					method="POST"
					action="?/deleteNode"
					use:enhance={() => {
						return async ({ result, update }) => {
							if (result.type === 'success') {
								showDeleteConfirm = false;
								onClose();
							}
							await update({ reset: false });
						};
					}}
					use:enhanceFormValidation
					class="space-y-4 pt-2"
				>
					<input type="hidden" name="nodeId" value={node.id} />
					{#if childKrs.length > 0}
						<div class="p-3 bg-[#fff5f5] rounded-xl border border-[#fecdd3] text-xs text-[#991b1b]">
							<label class="flex items-center gap-2 cursor-pointer font-medium">
								<input type="checkbox" name="promote" value="1" class="rounded text-[#ba1a1a]" />
								<span>Manter KRs filhos (promover para o nível raiz)</span>
							</label>
						</div>
					{/if}

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

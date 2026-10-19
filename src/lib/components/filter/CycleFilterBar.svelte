<script lang="ts">
	import { page } from '$app/stores';
	import { goto } from '$app/navigation';
	import type { Cycle, NodeWithExtras, StrategyNode, Team } from '$lib/types';
	import { valueColor } from '$lib/value-colors';

	interface Props {
		cycles: Cycle[];
		valuesList: StrategyNode[];
		teams?: Team[];
		activeMission?: NodeWithExtras | null;
		availableYears: number[];
		selectedYears: number[];
		selectedSemesters: number[];
		selectedTeamId?: string;
		strictMode: boolean;
		activeLensId: string | null;
		viewMode: 'tree' | 'outline' | 'canvas';
		searchQuery: string;
		canEdit: boolean;
		onSearchChange: (q: string) => void;
		onTeamChange?: (teamId: string) => void;
		onSelectNode?: (id: string) => void;
		onCreateObjective: () => void;
		onCreateKR?: () => void;
		onCreateKPI?: () => void;
	}

	let {
		availableYears,
		selectedYears,
		selectedSemesters,
		selectedTeamId = 'all',
		strictMode,
		activeLensId,
		viewMode,
		valuesList,
		teams = [],
		activeMission = null,
		canEdit,
		onTeamChange,
		onSelectNode,
		onCreateObjective,
		onCreateKR,
		onCreateKPI
	}: Props = $props();

	let showTeamDropdown = $state(false);
	let showYearDropdown = $state(false);

	const activeYear = $derived(selectedYears[0] ?? 2026);

	function formatYearLabel(yr: number): string {
		if (yr === 2026) return '2026 Obrigatório';
		if (yr === 2027) return '2027 Projeção';
		return String(yr);
	}

	const selectedYearLabel = $derived.by(() => {
		if (selectedYears.length === 0) return 'Todos os Anos';
		if (selectedYears.length === 1) return formatYearLabel(selectedYears[0]);
		return `${selectedYears.length} anos selecionados`;
	});

	const selectedTeamLabel = $derived.by(() => {
		if (!selectedTeamId || selectedTeamId === 'all') return 'Todas Equipes';
		return teams.find((t) => t.id === selectedTeamId)?.name ?? 'Todas Equipes';
	});

	function updateParam(updater: (params: URLSearchParams) => void) {
		const url = new URL($page.url);
		updater(url.searchParams);
		goto(url.toString(), { replaceState: true, keepFocus: true, noScroll: true });
	}

	function selectYear(year: number, multi = false) {
		updateParam((params) => {
			if (!multi) {
				params.set('years', String(year));
				return;
			}
			const next = selectedYears.includes(year)
				? selectedYears.filter((y) => y !== year)
				: [...selectedYears, year].sort();
			if (next.length === 0) {
				params.delete('years');
			} else {
				params.set('years', next.join(','));
			}
		});
	}

	function toggleSemester(sem: number) {
		updateParam((params) => {
			const next = selectedSemesters.includes(sem)
				? selectedSemesters.filter((s) => s !== sem)
				: [...selectedSemesters, sem].sort();
			if (next.length === 0) {
				params.delete('semesters');
			} else {
				params.set('semesters', next.join(','));
			}
		});
	}

	function toggleStrict() {
		updateParam((params) => {
			if (strictMode) {
				params.set('strict', '0');
			} else {
				params.set('strict', '1');
			}
		});
	}

	function setLens(valId: string | null) {
		updateParam((params) => {
			if (!valId || activeLensId === valId) {
				params.delete('lens');
			} else {
				params.set('lens', valId);
			}
		});
	}

	function setViewMode(mode: 'tree' | 'outline' | 'canvas') {
		updateParam((params) => {
			params.set('view', mode);
		});
	}
</script>

<!-- Drafting Mat Ambient Header & Control Ribbon -->
<section class="relative w-full mb-space-lg">
	<!-- Top Identity Anchor (Archival Parchment Banner) -->
	<div
		class="relative bg-surface-container-low rounded-xl shadow-[0_1px_1px_rgba(36,34,30,0.05),0_3px_6px_-1px_rgba(36,34,30,0.04),0_-1px_0_rgba(255,255,255,0.8)_inset] p-space-md mb-space-md overflow-hidden"
	>
		<div
			class="absolute -right-10 -bottom-10 w-48 h-48 bg-primary/5 rounded-full pointer-events-none blur-2xl"
		></div>
		<div class="flex flex-col gap-space-md relative z-10 w-full">
			<!-- Top / Main: Corporate Vector & Active Mission -->
			<button
				type="button"
				onclick={() => activeMission && onSelectNode?.(activeMission.id)}
				class="flex items-start sm:items-center gap-space-md w-full text-left group"
			>
				<div
					class="w-12 h-12 rounded-lg bg-surface-container-lowest shadow-[0_2px_4px_rgba(36,34,30,0.08),inset_0_1px_0_rgba(255,255,255,1)] flex items-center justify-center shrink-0 group-hover:scale-105 transition-transform"
				>
					<span
						class="material-symbols-outlined text-primary text-[28px]"
						style="font-variation-settings: 'FILL' 1;"
					>
						assured_workload
					</span>
				</div>
				<div class="flex-1 min-w-0">
					<div class="flex items-center gap-2 mb-1">
						<span
							class="font-label-sm text-label-sm uppercase tracking-widest text-on-surface-variant font-semibold"
						>
							Vetor Estratégico Corporativo
						</span>
						<span class="w-1.5 h-1.5 rounded-full bg-primary"></span>
						<span class="font-label-sm text-label-sm font-bold text-primary tracking-wide">
							ERA {activeYear}
						</span>
					</div>
					<h1
						class="text-lg sm:text-xl md:text-2xl text-on-surface italic font-medium leading-relaxed group-hover:text-primary transition-colors"
					>
						<span class="not-italic font-bold text-on-surface">Missão:</span> “{activeMission?.title ?? 'Consolidação & Hiperescala Confiável'}”
					</h1>
				</div>
			</button>

			<!-- Right: Pillar Badges (Value Lens) -->
			{#if valuesList.length > 0}
				<div class="pt-2 border-t border-outline-variant/30 flex flex-wrap items-center gap-2">
					<span
						class="font-label-sm text-label-sm uppercase tracking-wider text-on-surface-variant mr-1 font-semibold"
					>
						Pilares Fundamentais:
					</span>
					{#each valuesList as val, idx (val.id)}
						{@const isSelected = activeLensId === val.id}
						{@const dotColor =
							idx === 0
								? 'bg-primary'
								: idx === 1
									? 'bg-secondary'
									: idx === 2
										? 'bg-tertiary-fixed-dim'
										: ''}
						<button
							type="button"
							onclick={() => setLens(val.id)}
							class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full transition-all {isSelected
								? 'bg-primary text-on-primary shadow-[0_2px_6px_rgba(0,88,189,0.25)] ring-2 ring-primary/30'
								: 'bg-surface-container-lowest text-on-surface shadow-[inset_0_1px_2px_rgba(36,34,30,0.06),0_1px_0_#ffffff] hover:bg-surface-container'}"
						>
							<span
								class="w-2 h-2 rounded-full {isSelected ? 'bg-white' : dotColor}"
								style={!isSelected && !dotColor ? `background-color: ${valueColor(val.id)}` : ''}
							></span>
							<span class="font-label-sm text-label-sm font-bold">
								{val.title}
							</span>
						</button>
					{/each}
					{#if activeLensId}
						<button
							type="button"
							onclick={() => setLens(null)}
							class="inline-flex items-center gap-1 px-2.5 py-1 rounded-full bg-surface-container text-on-surface-variant hover:text-on-surface font-label-sm text-label-sm font-bold"
						>
							<span class="material-symbols-outlined text-[14px]">close</span>
							Limpar
						</button>
					{/if}
				</div>
			{/if}
		</div>
	</div>

	<!-- Craft Cutting Mat Controls & Index Tabs Ribbon -->
	<div
		class="w-full bg-surface-container-high rounded-xl p-space-sm shadow-[inset_0_1px_3px_rgba(36,34,30,0.08)] flex flex-col xl:flex-row xl:items-center justify-between gap-space-md"
	>
		<!-- Left: Tabs & Filters -->
		<div class="flex flex-wrap items-center gap-space-xs">
			<!-- Year Dropdown Filter -->
			<div class="relative">
				<button
					type="button"
					onclick={() => (showYearDropdown = !showYearDropdown)}
					class="flex items-center gap-2 px-3 py-1.5 bg-surface-container-lowest text-on-surface rounded-lg font-label-md text-label-md shadow-[0_1px_2px_rgba(36,34,30,0.05)] hover:bg-surface-container transition-colors"
				>
					<span class="material-symbols-outlined text-[16px] text-primary">calendar_today</span>
					<span class="font-bold">{selectedYearLabel}</span>
					<span class="material-symbols-outlined text-[16px] text-on-surface-variant">
						expand_more
					</span>
				</button>

				{#if showYearDropdown}
					<!-- svelte-ignore a11y_click_events_have_key_events -->
					<!-- svelte-ignore a11y_no_static_element_interactions -->
					<div class="fixed inset-0 z-20" onclick={() => (showYearDropdown = false)}></div>
					<div
						class="absolute top-full left-0 mt-1 w-56 bg-surface-container-lowest rounded-xl shadow-[0_12px_24px_rgba(36,34,30,0.12)] p-1.5 z-30 border border-outline-variant/30 flex flex-col gap-0.5"
					>
						{#each availableYears as yr (yr)}
							{@const active = selectedYears.includes(yr)}
							<button
								type="button"
								onclick={(e) => {
									selectYear(yr, e.shiftKey || e.ctrlKey || e.metaKey);
									if (!e.shiftKey && !e.ctrlKey && !e.metaKey) {
										showYearDropdown = false;
									}
								}}
								class="w-full text-left px-2.5 py-1.5 rounded font-body-sm text-body-sm hover:bg-surface-container flex items-center justify-between transition-colors {active
									? 'text-primary font-bold bg-surface-container-low'
									: 'text-on-surface'}"
							>
								<span>{formatYearLabel(yr)}</span>
								{#if active}
									<span class="material-symbols-outlined text-primary text-[18px]">check</span>
								{/if}
							</button>
						{/each}
					</div>
				{/if}
			</div>

			<div class="h-6 w-px bg-outline-variant/60 mx-1 hidden sm:block"></div>

			<!-- Cycle Tab Switch -->
			<div
				class="flex items-center bg-surface-container-lowest rounded-lg p-1 shadow-[0_1px_2px_rgba(36,34,30,0.05)] gap-0.5"
			>
				{#each [1, 2] as sem}
					{@const active = selectedSemesters.includes(sem)}
					<button
						type="button"
						onclick={() => toggleSemester(sem)}
						class="px-3 py-1 rounded font-label-md text-label-md transition-all {active
							? 'font-bold bg-surface-container-highest text-on-surface shadow-[inset_0_1px_1px_rgba(36,34,30,0.08)]'
							: 'text-on-surface-variant hover:text-on-surface hover:bg-surface-container'}"
					>
						{activeYear}-S{sem}
					</button>
				{/each}
				<button
					type="button"
					onclick={toggleStrict}
					title="Quando Estrito está ativo, filtra KRs e KPIs estritamente pelo semestre selecionado"
					class="px-2 py-1 rounded font-label-sm text-label-sm uppercase transition-all {strictMode
						? 'bg-primary-fixed text-on-primary-fixed font-bold'
						: 'text-outline hover:text-on-surface'}"
				>
					Estrito: {strictMode ? 'ON' : 'OFF'}
				</button>
			</div>

			<!-- Teams Dropdown Filter -->
			<div class="relative">
				<button
					type="button"
					onclick={() => (showTeamDropdown = !showTeamDropdown)}
					class="flex items-center gap-2 px-3 py-1.5 bg-surface-container-lowest text-on-surface rounded-lg font-label-md text-label-md shadow-[0_1px_2px_rgba(36,34,30,0.05)] hover:bg-surface-container transition-colors"
				>
					<span class="material-symbols-outlined text-[16px] text-primary">groups</span>
					<span>{selectedTeamLabel}</span>
					<span class="material-symbols-outlined text-[16px] text-on-surface-variant">
						expand_more
					</span>
				</button>

				{#if showTeamDropdown}
					<!-- svelte-ignore a11y_click_events_have_key_events -->
					<!-- svelte-ignore a11y_no_static_element_interactions -->
					<div class="fixed inset-0 z-20" onclick={() => (showTeamDropdown = false)}></div>
					<div
						class="absolute top-full left-0 mt-1 w-56 bg-surface-container-lowest rounded-xl shadow-[0_12px_24px_rgba(36,34,30,0.12)] p-1.5 z-30 border border-outline-variant/30"
					>
						<button
							type="button"
							onclick={() => {
								onTeamChange?.('all');
								showTeamDropdown = false;
							}}
							class="w-full text-left px-2.5 py-1.5 rounded font-body-sm text-body-sm hover:bg-surface-container flex items-center justify-between {selectedTeamId ===
							'all'
								? 'text-primary font-semibold bg-surface-container-low'
								: 'text-on-surface'}"
						>
							<span>Todas Equipes</span>
							{#if selectedTeamId === 'all'}
								<span class="material-symbols-outlined text-primary text-[16px]">check</span>
							{/if}
						</button>
						{#each teams as t (t.id)}
							<button
								type="button"
								onclick={() => {
									onTeamChange?.(t.id);
									showTeamDropdown = false;
								}}
								class="w-full text-left px-2.5 py-1.5 rounded font-body-sm text-body-sm hover:bg-surface-container flex items-center justify-between {selectedTeamId ===
								t.id
									? 'text-primary font-semibold bg-surface-container-low'
									: 'text-on-surface-variant hover:text-on-surface'}"
							>
								<span class="flex items-center gap-2 truncate">
									<span
										class="w-2 h-2 rounded-full shrink-0"
										style="background-color: {t.color || '#0058bd'}"
									></span>
									<span class="truncate">{t.name}</span>
								</span>
								{#if selectedTeamId === t.id}
									<span class="material-symbols-outlined text-primary text-[16px]">check</span>
								{/if}
							</button>
						{/each}
					</div>
				{/if}
			</div>

			<!-- View Switcher (Folder Tabs) -->
			<div
				class="flex items-center gap-1 bg-surface-container p-1 rounded-lg shadow-[inset_0_1px_2px_rgba(36,34,30,0.06)]"
			>
				<button
					type="button"
					onclick={() => setViewMode('tree')}
					class="relative px-3 py-1 font-label-md text-label-md rounded flex items-center gap-1.5 transition-all {viewMode ===
					'tree'
						? 'font-bold bg-surface-container-lowest text-primary shadow-[0_2px_4px_rgba(36,34,30,0.08)]'
						: 'text-on-surface-variant hover:text-on-surface'}"
				>
					<span class="material-symbols-outlined text-[16px]">account_tree</span>
					<span>Visão Horizontal</span>
					{#if viewMode === 'tree'}
						<span class="w-1.5 h-1.5 rounded-full bg-primary"></span>
					{/if}
				</button>

				<button
					type="button"
					onclick={() => setViewMode('outline')}
					class="relative px-2.5 py-1 font-label-md text-label-md rounded flex items-center gap-1.5 transition-all {viewMode ===
					'outline'
						? 'font-bold bg-surface-container-lowest text-primary shadow-[0_2px_4px_rgba(36,34,30,0.08)]'
						: 'text-on-surface-variant hover:text-on-surface'}"
				>
					<span class="material-symbols-outlined text-[16px]">format_list_bulleted</span>
					<span>Lista</span>
					{#if viewMode === 'outline'}
						<span class="w-1.5 h-1.5 rounded-full bg-primary"></span>
					{/if}
				</button>

				<button
					type="button"
					onclick={() => setViewMode('canvas')}
					class="relative px-2.5 py-1 font-label-md text-label-md rounded flex items-center gap-1.5 transition-all {viewMode ===
					'canvas'
						? 'font-bold bg-surface-container-lowest text-primary shadow-[0_2px_4px_rgba(36,34,30,0.08)]'
						: 'text-on-surface-variant hover:text-on-surface'}"
				>
					<span class="material-symbols-outlined text-[16px]">view_kanban</span>
					<span>Visão Vertical</span>
					{#if viewMode === 'canvas'}
						<span class="w-1.5 h-1.5 rounded-full bg-primary"></span>
					{/if}
				</button>
			</div>
		</div>

		<!-- Right: Quick Action Physical Action Tabs -->
		{#if canEdit}
			<div class="flex flex-wrap items-center gap-2">
				<button
					type="button"
					onclick={onCreateObjective}
					class="px-3.5 py-2 bg-primary text-on-primary rounded-lg font-label-md text-label-md flex items-center gap-1.5 shadow-[0_2px_0_#004494] hover:-translate-y-0.5 active:translate-y-0.5 transition-all"
				>
					<span class="material-symbols-outlined text-[18px]">add</span>
					<span>Novo Objetivo</span>
				</button>
				<button
					type="button"
					onclick={() => onCreateKR?.()}
					class="px-3.5 py-2 bg-secondary text-on-secondary rounded-lg font-label-md text-label-md flex items-center gap-1.5 shadow-[0_2px_0_#8d0051] hover:-translate-y-0.5 active:translate-y-0.5 transition-all"
				>
					<span class="material-symbols-outlined text-[18px]">adjust</span>
					<span>Novo KR</span>
				</button>
				<button
					type="button"
					onclick={() => onCreateKPI?.()}
					class="px-3.5 py-2 bg-tertiary-fixed text-on-tertiary-fixed rounded-lg font-label-md text-label-md flex items-center gap-1.5 shadow-[0_2px_0_#6c5e00] hover:-translate-y-0.5 active:translate-y-0.5 transition-all font-bold"
				>
					<span class="material-symbols-outlined text-[18px]">analytics</span>
					<span>Indicador KPI</span>
				</button>
			</div>
		{/if}
	</div>
</section>

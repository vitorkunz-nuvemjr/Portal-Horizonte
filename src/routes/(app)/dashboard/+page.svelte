<script lang="ts">
	import { enhance } from '$app/forms';
	import { enrichNodes } from '$lib/progress';
	import { formatNumber, formatPct, getInitials, getTeamIcon } from '$lib/utils';
	import { valueColor } from '$lib/value-colors';
	import { getDossierTheme } from '$lib/dossier-theme';
	import type { NodeWithExtras, Team } from '$lib/types';

	let { data } = $props();

	// Primary filter states
	let selectedCycleId = $state<string>('cyc-2026-s1');
	let selectedTeamFilter = $state<string>('all');
	let searchQuery = $state<string>('');
	let showFilters = $state<boolean>(false);
	let kpiSortOrder = $state<'oldest' | 'newest' | 'lowest_progress' | 'title'>('oldest');
	let currentPage = $state<number>(1);
	const pageSize = 5;

	// Modal & interaction states
	let selectedNodeId = $state<string | null>(null);
	let submittingKpiId = $state<string | null>(null);
	let registeredKpiIds = $state<Set<string>>(new Set());

	// Quick check-in modal state
	let quickModalOpen = $state<boolean>(false);
	let quickKpiId = $state<string>('');
	let quickValue = $state<string>('');
	let quickNote = $state<string>('');

	const canEdit = $derived(data.user?.role === 'admin' || data.user?.role === 'member');

	const enriched = $derived(
		enrichNodes(
			data.nodes,
			data.assigns,
			data.values,
			data.profiles,
			data.cycles,
			data.metricUpdates,
			data.teams,
			data.teamMembers,
			data.nodeTeams
		)
	);

	const allStrategyNodes = $derived(
		Array.from(enriched.byId.values()).filter((n) => n.tree === 'strategy')
	);

	const selectedCycle = $derived(
		data.cycles.find((c) => c.id === selectedCycleId) ??
			(selectedCycleId === 'all' ? null : data.cycles[0] ?? null)
	);

	// Fallback to 'all' if selected cycle doesn't exist
	$effect(() => {
		if (selectedCycleId !== 'all' && !data.cycles.some((c) => c.id === selectedCycleId)) {
			if (data.cycles.length > 0) {
				selectedCycleId = data.cycles[0].id;
			} else {
				selectedCycleId = 'all';
			}
		}
	});

	// Helper to resolve teams for any node (with inheritance from parent/grandparent)
	function getNodeTeams(node: NodeWithExtras): Team[] {
		if (node.teams && node.teams.length > 0) return node.teams;
		if (node.parent_id) {
			const parent = enriched.byId.get(node.parent_id);
			if (parent && parent.teams && parent.teams.length > 0) return parent.teams;
			if (parent?.parent_id) {
				const grandparent = enriched.byId.get(parent.parent_id);
				if (grandparent && grandparent.teams && grandparent.teams.length > 0)
					return grandparent.teams;
			}
		}
		return [];
	}

	function getNodeYear(node: NodeWithExtras): number | null {
		if (node.year) return node.year;
		if (node.cycle?.year) return node.cycle.year;
		if (node.cycle_id) {
			const c = data.cycles.find((cyc) => cyc.id === node.cycle_id);
			if (c) return c.year;
		}
		if (node.parent_id) {
			const parent = enriched.byId.get(node.parent_id);
			if (parent) return getNodeYear(parent);
		}
		return null;
	}

	function nodeMatchesCycle(
		node: NodeWithExtras,
		cycleId: string,
		cycle: (typeof data.cycles)[number] | null
	): boolean {
		if (cycleId === 'all') return true;
		if (node.cycle_id === cycleId || node.cycle?.id === cycleId) return true;
		if (node.parent_id) {
			const parent = enriched.byId.get(node.parent_id);
			if (parent && (parent.cycle_id === cycleId || parent.cycle?.id === cycleId)) return true;
		}
		const nodeYear = getNodeYear(node);
		if (nodeYear && cycle && nodeYear === cycle.year) return true;
		return false;
	}

	// Filtered KRs based on cycle, team, and search
	const filteredKRs = $derived.by(() => {
		return allStrategyNodes.filter((n) => {
			if (n.type !== 'key_result') return false;
			if (!nodeMatchesCycle(n, selectedCycleId, selectedCycle)) return false;
			if (selectedTeamFilter !== 'all') {
				const teams = getNodeTeams(n);
				if (!teams.some((t) => t.id === selectedTeamFilter)) return false;
			}
			if (searchQuery.trim()) {
				const q = searchQuery.toLowerCase();
				const teams = getNodeTeams(n);
				const matchTitle = n.title.toLowerCase().includes(q);
				const matchTeam = teams.some((t) => t.name.toLowerCase().includes(q));
				if (!matchTitle && !matchTeam) return false;
			}
			return true;
		});
	});

	// Filtered KPIs based on cycle, team, and search
	const filteredKPIs = $derived.by(() => {
		return allStrategyNodes.filter((n) => {
			if (n.type !== 'kpi') return false;
			if (!nodeMatchesCycle(n, selectedCycleId, selectedCycle)) return false;
			if (selectedTeamFilter !== 'all') {
				const teams = getNodeTeams(n);
				if (!teams.some((t) => t.id === selectedTeamFilter)) return false;
			}
			if (searchQuery.trim()) {
				const q = searchQuery.toLowerCase();
				const teams = getNodeTeams(n);
				const matchTitle = n.title.toLowerCase().includes(q);
				const matchTeam = teams.some((t) => t.name.toLowerCase().includes(q));
				if (!matchTitle && !matchTeam) return false;
			}
			return true;
		});
	});

	// Strategy roots (annual objectives)
	const relevantObjectives = $derived.by(() => {
		return enriched.strategyRoots.filter((obj) => {
			if (!nodeMatchesCycle(obj, selectedCycleId, selectedCycle)) return false;
			if (selectedTeamFilter !== 'all') {
				const teams = getNodeTeams(obj);
				if (!teams.some((t) => t.id === selectedTeamFilter)) return false;
			}
			return true;
		});
	});

	// Overall Progress Calculation
	const overallProgress = $derived.by(() => {
		if (filteredKRs.length > 0) {
			const totalWeight = filteredKRs.reduce((sum, kr) => sum + (kr.weight || 1), 0);
			if (totalWeight === 0) return 0;
			return (
				filteredKRs.reduce((sum, kr) => sum + kr.progress * (kr.weight || 1), 0) / totalWeight
			);
		}
		if (relevantObjectives.length > 0) {
			const totalWeight = relevantObjectives.reduce((sum, obj) => sum + (obj.weight || 1), 0);
			if (totalWeight === 0) return 0;
			return (
				relevantObjectives.reduce((sum, obj) => sum + obj.progress * (obj.weight || 1), 0) /
				totalWeight
			);
		}
		return 0.2;
	});

	// Expected cycle progress based on date elapsed
	const expectedCycleProgress = $derived.by(() => {
		if (!selectedCycle) return 0.45;
		const start = new Date(selectedCycle.start_date).getTime();
		const end = new Date(selectedCycle.end_date).getTime();
		const now = Date.now();
		if (Number.isNaN(start) || Number.isNaN(end) || end <= start) return 0.45;
		if (now <= start) return 0.05;
		if (now >= end) return 1;
		const elapsed = (now - start) / (end - start);
		return Math.min(1, Math.max(0.1, elapsed));
	});

	// Pace feedback message for Card 1
	const paceMessage = $derived.by(() => {
		if (overallProgress >= expectedCycleProgress) {
			return { icon: 'speed', text: 'Ritmo no alvo para o fechamento do ciclo' };
		}
		const delta = expectedCycleProgress - overallProgress;
		if (delta > 0.15) {
			return { icon: 'speed', text: 'Ritmo requer aceleração no Q2' };
		}
		return { icon: 'speed', text: 'Ritmo ligeiramente abaixo da meta esperada' };
	});

	// Active and completed KRs count
	const completedKRsCount = $derived(
		filteredKRs.filter((k) => k.status === 'done' || k.progress >= 1).length
	);
	const krProgressRatio = $derived(
		filteredKRs.length > 0 ? (completedKRsCount / filteredKRs.length) * 100 : 0
	);

	// KPI update progress ratio for Card 4
	const updatedKPIsCount = $derived(filteredKPIs.filter((k) => k.metricUpdates.length > 0).length);
	const kpiProgressRatio = $derived(
		filteredKPIs.length > 0 ? (updatedKPIsCount / filteredKPIs.length) * 100 : 0
	);

	// Expected progress for individual attention items
	function getItemExpectedProgress(item: NodeWithExtras): number {
		if (item.cycle) {
			const start = new Date(item.cycle.start_date).getTime();
			const end = new Date(item.cycle.end_date).getTime();
			const now = Date.now();
			if (end > start) {
				return Math.min(1, Math.max(0.1, (now - start) / (end - start)));
			}
		}
		if (item.year) {
			const start = new Date(item.year, 0, 1).getTime();
			const end = new Date(item.year, 11, 31).getTime();
			const now = Date.now();
			if (end > start) {
				return Math.min(1, Math.max(0.1, (now - start) / (end - start)));
			}
		}
		return 0.7;
	}

	// Contextual delay info for attention items
	function getItemDelayContext(item: NodeWithExtras): { icon: string; text: string } {
		if (item.children.length > 0) {
			const total = item.children.length;
			const validated = item.children.filter((c) => c.status === 'done' || c.progress >= 1).length;
			if (validated < total) {
				return {
					icon: 'schedule',
					text: `Apenas ${validated} de ${total} entregáveis validados`
				};
			}
		}
		const lastUpdate = item.metricUpdates[0]?.created_at || item.updated_at;
		if (lastUpdate) {
			const days = Math.floor((Date.now() - new Date(lastUpdate).getTime()) / (1000 * 60 * 60 * 24));
			const weeks = Math.floor(days / 7);
			if (weeks >= 2) {
				return {
					icon: 'event_busy',
					text: `Defasagem de ${weeks} semanas sem check-in`
				};
			}
			if (days >= 5) {
				return {
					icon: 'event_busy',
					text: `Defasagem de ${days} dias sem check-in`
				};
			}
		}
		return {
			icon: 'event_busy',
			text: 'Defasagem de 3 semanas sem check-in'
		};
	}

	// Attention List (Objectives & KRs requiring critical attention)
	const attentionList = $derived.by(() => {
		return allStrategyNodes.filter((n) => {
			if (n.type !== 'objective' && n.type !== 'key_result') return false;
			if (!nodeMatchesCycle(n, selectedCycleId, selectedCycle)) return false;
			if (selectedTeamFilter !== 'all') {
				const teams = getNodeTeams(n);
				if (!teams.some((t) => t.id === selectedTeamFilter)) return false;
			}
			if (searchQuery.trim()) {
				const q = searchQuery.toLowerCase();
				const teams = getNodeTeams(n);
				const matchTitle = n.title.toLowerCase().includes(q);
				const matchTeam = teams.some((t) => t.name.toLowerCase().includes(q));
				if (!matchTitle && !matchTeam) return false;
			}
			return n.atRisk || n.status === 'at_risk' || n.status === 'off_track';
		});
	});

	// Organizational Values Distribution
	const valueStats = $derived.by(() => {
		const totalLinks = data.values.length || 1;
		const list = enriched.valuesList.map((val) => {
			const count = data.values.filter(
				(nv: { value_id: string }) => nv.value_id === val.id
			).length;
			const pct = (count / totalLinks) * 100;
			return { val, count, pct };
		});

		const withItems = list.filter((i) => i.count > 0).sort((a, b) => b.count - a.count);
		const withoutItems = list.filter((i) => i.count === 0);

		return { withItems, withoutItems, totalLinks };
	});

	// Sorted KPIs for the check-in queue
	const filteredSortedKPIs = $derived.by(() => {
		const items = [...filteredKPIs];
		if (kpiSortOrder === 'oldest') {
			items.sort((a, b) => {
				const aHasUpdate = a.metricUpdates.length > 0;
				const bHasUpdate = b.metricUpdates.length > 0;
				if (!aHasUpdate && bHasUpdate) return -1;
				if (aHasUpdate && !bHasUpdate) return 1;
				const aDate = a.metricUpdates[0]?.created_at ?? '1970-01-01';
				const bDate = b.metricUpdates[0]?.created_at ?? '1970-01-01';
				return aDate.localeCompare(bDate);
			});
		} else if (kpiSortOrder === 'newest') {
			items.sort((a, b) => {
				const aDate = a.metricUpdates[0]?.created_at ?? '1970-01-01';
				const bDate = b.metricUpdates[0]?.created_at ?? '1970-01-01';
				return bDate.localeCompare(aDate);
			});
		} else if (kpiSortOrder === 'lowest_progress') {
			items.sort((a, b) => a.progress - b.progress);
		} else if (kpiSortOrder === 'title') {
			items.sort((a, b) => a.title.localeCompare(b.title));
		}
		return items;
	});

	// Pagination
	const totalPages = $derived(Math.max(1, Math.ceil(filteredSortedKPIs.length / pageSize)));

	$effect(() => {
		if (currentPage > totalPages) {
			currentPage = totalPages;
		}
	});

	const paginatedKPIs = $derived(
		filteredSortedKPIs.slice((currentPage - 1) * pageSize, currentPage * pageSize)
	);

	// Currently selected node for modal display
	const selectedNode = $derived(
		selectedNodeId ? enriched.byId.get(selectedNodeId) ?? null : null
	);

	const currentSelectedKpi = $derived(
		quickKpiId ? enriched.byId.get(quickKpiId) ?? null : null
	);

	function openQuickCheckin(initialKpiId?: string) {
		quickKpiId = initialKpiId || (filteredSortedKPIs[0]?.id ?? '');
		const targetKpi = enriched.byId.get(quickKpiId);
		quickValue = targetKpi?.current_value != null ? String(targetKpi.current_value) : '';
		quickNote = '';
		quickModalOpen = true;
	}
</script>

<div class="flex flex-col w-full p-gutter lg:p-gutter-lg gap-y-space-lg">
	<!-- Section 0: Header -->
	<section
		class="flex flex-col xl:flex-row xl:items-end justify-between gap-space-md pb-space-xs"
	>
		<div class="flex flex-col gap-space-xs max-w-3xl">
			<div class="flex items-center gap-space-xs">
				<span
					class="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full bg-surface-container-high text-primary font-label-sm text-label-sm uppercase tracking-wider shadow-sm"
				>
					Ciclos &amp; Métricas • Acompanhamento Semestral e Rituais de Check-in
				</span>
			</div>
			<h1
				class="font-headline-xl text-headline-xl text-on-surface tracking-tight leading-tight"
			>
				Painel Executivo de Estratégia
			</h1>
			<p class="font-body-md text-body-md text-on-surface-variant">
				Visão consolidada em tempo real de Objetivos anuais, Resultados-Chave semestrais,
				alertas de risco e check-ins de KPIs.
			</p>
		</div>

		<div class="flex flex-wrap items-center gap-space-sm pt-2 xl:pt-0">
			<!-- Cycle Selector Dropdown -->
			<div
				class="relative flex items-center bg-surface-container-lowest rounded-lg shadow-sm px-3 py-1.5 focus-within:ring-2 focus-within:ring-primary/20"
			>
				<span class="material-symbols-outlined text-outline text-[18px] mr-2"
					>calendar_month</span
				>
				<label class="sr-only" for="cycle-select">Ciclo Semestral</label>
				<select
					bind:value={selectedCycleId}
					class="bg-transparent font-title-md text-body-sm text-on-surface outline-none cursor-pointer pr-5 appearance-none"
					id="cycle-select"
				>
					<option value="all">Todos os Ciclos</option>
					{#each data.cycles as cyc (cyc.id)}
						<option value={cyc.id}>
							{cyc.code}
							{cyc.id === 'cyc-2026-s1' || cyc.code.includes('2026-S1') ? '(Atual)' : ''}
						</option>
					{/each}
				</select>
				<span
					class="material-symbols-outlined text-outline text-[16px] absolute right-2 pointer-events-none"
				>
					expand_more
				</span>
			</div>

			<!-- Filter Toggle Button -->
			<button
				onclick={() => (showFilters = !showFilters)}
				class="flex items-center gap-1.5 px-3 py-2 rounded-lg bg-surface-container hover:bg-surface-container-high text-on-surface font-title-md text-body-sm shadow-sm transition-all {showFilters
					? 'ring-2 ring-primary/30 bg-surface-container-high'
					: ''}"
				type="button"
				title="Alternar filtros adicionais"
			>
				<span class="material-symbols-outlined text-[18px] text-on-surface-variant"
					>filter_list</span
				>
				<span>Filtros</span>
				{#if selectedTeamFilter !== 'all' || searchQuery.trim()}
					<span class="w-2 h-2 rounded-full bg-primary"></span>
				{/if}
			</button>

			<!-- Quick Check-in Button -->
			<button
				onclick={() => openQuickCheckin()}
				class="flex items-center gap-1.5 px-4 py-2 rounded-lg bg-primary text-on-primary font-title-md text-body-sm shadow-md hover:bg-primary-container active:scale-[0.98] transition-all"
				type="button"
			>
				<span class="material-symbols-outlined text-[18px]">add_circle</span>
				<span>+ Novo Check-in</span>
			</button>
		</div>
	</section>

	<!-- Optional Expandable Filter Bar -->
	{#if showFilters}
		<section
			class="p-4 rounded-xl bg-surface-container-low border border-outline-variant/40 flex flex-wrap items-center gap-3 transition-all"
		>
			<div class="relative flex-1 min-w-[220px]">
				<span
					class="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-outline text-[18px] pointer-events-none"
				>
					search
				</span>
				<input
					bind:value={searchQuery}
					placeholder="Buscar meta, indicador ou tag..."
					class="w-full pl-9 pr-3 py-1.5 bg-surface-container-lowest rounded-lg border border-outline-variant/60 font-body-sm text-body-sm text-on-surface placeholder:text-outline focus:outline-none focus:ring-1 focus:ring-primary"
				/>
			</div>

			<div class="flex items-center gap-2">
				<label
					for="filter-team"
					class="font-label-sm text-label-sm text-on-surface-variant uppercase tracking-wider"
				>
					Diretoria:
				</label>
				<select
					id="filter-team"
					bind:value={selectedTeamFilter}
					class="px-3 py-1.5 bg-surface-container-lowest rounded-lg border border-outline-variant/60 font-body-sm text-body-sm text-on-surface outline-none cursor-pointer"
				>
					<option value="all">Todas as Diretorias</option>
					{#each data.teams as t (t.id)}
						<option value={t.id}>{t.name}</option>
					{/each}
				</select>
			</div>

			{#if selectedTeamFilter !== 'all' || searchQuery.trim()}
				<button
					type="button"
					onclick={() => {
						selectedTeamFilter = 'all';
						searchQuery = '';
					}}
					class="px-2.5 py-1 text-xs font-semibold text-secondary hover:underline"
				>
					Limpar filtros
				</button>
			{/if}
		</section>
	{/if}

	<!-- Section 1: Top 4 KPI Summary Cards -->
	<section class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-space-md">
		<!-- Card 1: Progresso Estratégico -->
		<div
			class="flex flex-col justify-between p-space-md rounded-xl bg-surface-container-lowest shadow-sm hover:shadow-md transition-shadow"
		>
			<div class="flex items-start justify-between">
				<span class="font-label-sm text-label-sm uppercase tracking-wider text-on-surface-variant"
					>Progresso Estratégico</span
				>
				<span class="p-1.5 rounded-lg bg-surface-container text-primary">
					<span class="material-symbols-outlined text-[20px]">donut_large</span>
				</span>
			</div>
			<div class="mt-space-md">
				<div class="flex items-baseline gap-space-xs">
					<span
						class="font-headline-xl text-headline-xl text-on-surface font-semibold tracking-tight"
					>
						{formatPct(overallProgress)}
					</span>
					<span class="font-body-sm text-body-sm text-on-surface-variant">
						/ Meta {selectedCycle ? selectedCycle.code.split('-')[1] || 'S1' : 'S1'}: {formatPct(
							expectedCycleProgress
						)}
					</span>
				</div>
				<div class="w-full bg-surface-container rounded-full h-2 mt-2 overflow-hidden">
					<div
						class="bg-primary h-2 rounded-full transition-all duration-500"
						style="width: {Math.round(overallProgress * 100)}%"
					></div>
				</div>
			</div>
			<div
				class="flex items-center gap-1 mt-3 pt-2 text-on-surface-variant font-body-sm text-body-sm"
			>
				<span class="material-symbols-outlined text-outline text-[16px]">{paceMessage.icon}</span
				>
				<span>{paceMessage.text}</span>
			</div>
		</div>

		<!-- Card 2: Resultados-Chave Ativos -->
		<div
			class="flex flex-col justify-between p-space-md rounded-xl bg-surface-container-lowest shadow-sm hover:shadow-md transition-shadow"
		>
			<div class="flex items-start justify-between">
				<span class="font-label-sm text-label-sm uppercase tracking-wider text-on-surface-variant"
					>Resultados-Chave Ativos</span
				>
				<span class="p-1.5 rounded-lg bg-surface-container text-primary">
					<span class="material-symbols-outlined text-[20px]">key</span>
				</span>
			</div>
			<div class="mt-space-md">
				<div class="flex items-baseline gap-space-xs">
					<span
						class="font-headline-xl text-headline-xl text-on-surface font-semibold tracking-tight"
					>
						{filteredKRs.length}
					</span>
					<span class="font-title-md text-body-sm text-on-surface-variant">ativos</span>
				</div>
				<div class="w-full bg-surface-container rounded-full h-2 mt-2 overflow-hidden">
					<div
						class="bg-primary-container h-2 rounded-full transition-all duration-500"
						style="width: {krProgressRatio}%"
					></div>
				</div>
			</div>
			<div
				class="flex items-center gap-1 mt-3 pt-2 text-on-surface-variant font-body-sm text-body-sm"
			>
				<span class="material-symbols-outlined text-primary text-[16px]">check_circle</span>
				<span>
					<strong class="font-title-md text-on-surface">{completedKRsCount} concluído(s)</strong>
					no período
				</span>
			</div>
		</div>

		<!-- Card 3: Atenção Necessária -->
		<div
			class="flex flex-col justify-between p-space-md rounded-xl bg-error-container/40 shadow-sm hover:shadow-md transition-shadow"
		>
			<div class="flex items-start justify-between">
				<span class="font-label-sm text-label-sm uppercase tracking-wider text-error font-bold"
					>Atenção Necessária</span
				>
				<span class="p-1.5 rounded-lg bg-error-container text-error">
					<span class="material-symbols-outlined text-[20px]">warning</span>
				</span>
			</div>
			<div class="mt-space-md">
				<div class="flex items-baseline gap-space-xs">
					<span
						class="font-headline-xl text-headline-xl text-error font-bold tracking-tight"
					>
						{attentionList.length}
					</span>
					<span
						class="font-title-md text-label-md uppercase text-error tracking-wide font-semibold"
					>
						Críticos
					</span>
				</div>
				<div class="w-full bg-surface-container-highest rounded-full h-2 mt-2 overflow-hidden">
					<div
						class="bg-error h-2 rounded-full transition-all duration-500"
						style="width: {attentionList.length > 0 ? 100 : 0}%"
					></div>
				</div>
			</div>
			<div class="flex items-center gap-1 mt-3 pt-2 text-error font-body-sm text-body-sm">
				<span class="material-symbols-outlined text-[16px]">error</span>
				<span>Em Risco &amp; Abaixo do ritmo</span>
			</div>
		</div>

		<!-- Card 4: KPIs Monitorados -->
		<div
			class="flex flex-col justify-between p-space-md rounded-xl bg-surface-container-lowest shadow-sm hover:shadow-md transition-shadow"
		>
			<div class="flex items-start justify-between">
				<span class="font-label-sm text-label-sm uppercase tracking-wider text-on-surface-variant"
					>KPIs Monitorados</span
				>
				<span class="p-1.5 rounded-lg bg-surface-container text-primary">
					<span class="material-symbols-outlined text-[20px]">analytics</span>
				</span>
			</div>
			<div class="mt-space-md">
				<div class="flex items-baseline gap-space-xs">
					<span
						class="font-headline-xl text-headline-xl text-on-surface font-semibold tracking-tight"
					>
						{filteredKPIs.length}
					</span>
					<span class="font-title-md text-body-sm text-on-surface-variant">métricas</span>
				</div>
				<div class="w-full bg-surface-container rounded-full h-2 mt-2 overflow-hidden">
					<div
						class="bg-tertiary-container h-2 rounded-full transition-all duration-500"
						style="width: {kpiProgressRatio}%"
					></div>
				</div>
			</div>
			<div
				class="flex items-center gap-1 mt-3 pt-2 text-on-surface-variant font-body-sm text-body-sm"
			>
				<span class="material-symbols-outlined text-outline text-[16px]">history</span>
				<span>{data.metricUpdates.length} check-ins no histórico</span>
			</div>
		</div>
	</section>

	<!-- Section 2: Lista de Atenção (7 cols) + Valores Organizacionais (5 cols) -->
	<section class="grid grid-cols-1 xl:grid-cols-12 gap-space-md">
		<!-- Left 7 cols: Lista de Atenção -->
		<div
			class="xl:col-span-7 flex flex-col p-space-md lg:p-space-lg rounded-xl bg-surface-container-lowest shadow-sm gap-space-md"
		>
			<div class="flex items-center justify-between pb-space-xs">
				<div class="flex items-center gap-space-sm">
					<span class="material-symbols-outlined text-error text-[24px]">crisis_alert</span>
					<div>
						<h2 class="font-headline-sm text-headline-sm text-on-surface">Lista de Atenção</h2>
						<p class="font-body-sm text-body-sm text-on-surface-variant">
							Objetivos e KRs com atraso severo no marco temporal
						</p>
					</div>
				</div>
				<span
					class="px-2.5 py-1 rounded-full bg-error-container text-on-error-container font-label-sm text-label-sm font-semibold tracking-wide uppercase"
				>
					{attentionList.length} Itens Críticos
				</span>
			</div>

			<div class="flex flex-col gap-space-md">
				{#each attentionList as item (item.id)}
					{@const itemTeams = getNodeTeams(item)}
					{@const expPct = getItemExpectedProgress(item)}
					{@const contextNote = getItemDelayContext(item)}
					<div
						class="p-space-md rounded-xl bg-surface-container-low/70 flex flex-col gap-space-sm hover:shadow-md transition-shadow"
					>
						<div class="flex flex-wrap items-start justify-between gap-space-xs">
							<div class="flex flex-col">
								<div class="flex items-center gap-space-xs mb-1 flex-wrap">
									<span
										class="px-2 py-0.5 rounded bg-surface-container-high font-label-sm text-label-sm text-on-surface-variant font-semibold"
									>
										{item.year ? `${item.year}${item.quarter ? ` T${item.quarter}` : ''}` : item.cycle?.code ?? '2026'}
									</span>
									{#each itemTeams.slice(0, 2) as team (team.id)}
										{@const tTheme = getDossierTheme(team.color || '#0058bd')}
										<span
											class="inline-flex items-center gap-1 rounded-full border px-2 py-0.5 font-label-sm text-label-sm font-bold"
											title="Equipe: {team.name}"
											style="background-color: {tTheme.badgeBg}; border-color: {tTheme.badgeBorder}; color: {tTheme.badgeText};"
										>
											<span
												class="material-symbols-outlined text-[13px] shrink-0"
												style="color: {tTheme.accent};"
											>
												{getTeamIcon(team)}
											</span>
											<span class="max-w-[120px] truncate">{team.name}</span>
										</span>
									{/each}
									{#if itemTeams.length === 0}
										{@const tTheme = getDossierTheme('#0284c7')}
										<span
											class="inline-flex items-center gap-1 rounded-full border px-2 py-0.5 font-label-sm text-label-sm font-bold"
											title="Equipe: Geral"
											style="background-color: {tTheme.badgeBg}; border-color: {tTheme.badgeBorder}; color: {tTheme.badgeText};"
										>
											<span
												class="material-symbols-outlined text-[13px] shrink-0"
												style="color: {tTheme.accent};"
											>
												hub
											</span>
											<span class="max-w-[120px] truncate">Geral</span>
										</span>
									{/if}
								</div>
								<h3 class="font-title-md text-title-md text-on-surface font-semibold">
									{item.title}
								</h3>
							</div>
							<span
								class="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full bg-error-container text-error font-label-sm text-label-sm font-bold uppercase"
							>
								<span class="w-1.5 h-1.5 rounded-full bg-error"></span>
								Abaixo do ritmo
							</span>
						</div>

						<div class="flex flex-col gap-1 mt-1">
							<div
								class="flex justify-between items-center font-body-sm text-body-sm text-on-surface-variant"
							>
								<span>
									Progresso Atual: <strong class="text-error font-title-md">{formatPct(item.progress)}</strong>
								</span>
								<span>
									Meta Esperada: <strong class="text-on-surface font-title-md">{formatPct(expPct)}</strong>
								</span>
							</div>
							<div
								class="relative w-full bg-surface-container-high h-2.5 rounded-full overflow-hidden"
							>
								<div
									class="absolute left-0 top-0 h-full bg-error rounded-full transition-all duration-300"
									style="width: {Math.round(item.progress * 100)}%"
								></div>
								<div
									class="absolute top-0 bottom-0 w-0.5 bg-outline z-10"
									style="left: {Math.round(expPct * 100)}%"
									title="Meta Esperada ({formatPct(expPct)})"
								></div>
							</div>
						</div>

						<div class="flex items-center justify-between pt-2 flex-wrap gap-2">
							<span
								class="font-body-sm text-body-sm text-on-surface-variant flex items-center gap-1"
							>
								<span class="material-symbols-outlined text-[16px] text-outline">
									{contextNote.icon}
								</span>
								{contextNote.text}
							</span>
							<div class="flex items-center gap-space-xs">
								<button
									onclick={() => (selectedNodeId = item.id)}
									class="px-2.5 py-1 rounded-md bg-surface-container text-on-surface hover:bg-surface-container-high font-title-md text-body-sm transition-colors cursor-pointer"
									type="button"
								>
									Ver KRs Subordinados
								</button>
								<button
									onclick={() => (selectedNodeId = item.id)}
									class="px-2.5 py-1 rounded-md bg-error text-on-error font-title-md text-body-sm shadow-sm hover:opacity-90 transition-opacity cursor-pointer"
									type="button"
								>
									Ação Corretiva
								</button>
							</div>
						</div>
					</div>
				{:else}
					<div
						class="flex items-center gap-2 p-6 rounded-xl bg-surface-container-low text-on-surface-variant font-body-sm text-body-sm"
					>
						<span class="material-symbols-outlined text-primary text-[20px]">check_circle</span>
						<span>Nenhum objetivo ou resultado-chave com atraso crítico no ciclo selecionado.</span>
					</div>
				{/each}
			</div>
		</div>

		<!-- Right 5 cols: Valores Organizacionais -->
		<div
			class="xl:col-span-5 flex flex-col p-space-md lg:p-space-lg rounded-xl bg-surface-container-lowest shadow-sm justify-between gap-space-md"
		>
			<div>
				<div class="flex items-center justify-between pb-space-xs">
					<div class="flex items-center gap-space-xs">
						<span class="material-symbols-outlined text-primary text-[24px]">verified</span>
						<h2 class="font-headline-sm text-headline-sm text-on-surface">
							Valores Organizacionais
						</h2>
					</div>
					<a href="/identity" class="font-label-md text-label-md text-primary hover:underline">
						Matriz Completa →
					</a>
				</div>
				<p class="font-body-sm text-body-sm text-on-surface-variant mb-space-md">
					Distribuição e densidade de metas vinculadas a cada valor de cultura corporativa.
				</p>

				<div class="flex flex-col gap-space-md">
					{#each valueStats.withItems as item (item.val.id)}
						<div class="flex flex-col gap-1">
							<div class="flex justify-between items-center text-body-sm font-body-sm">
								<span class="font-title-md text-on-surface">{item.val.title}</span>
								<span class="font-label-md text-label-md text-on-surface-variant">
									{item.count}
									{item.count === 1 ? 'item' : 'itens'} ({item.pct.toFixed(1)}%)
								</span>
							</div>
							<div class="w-full bg-surface-container h-2 rounded-full overflow-hidden">
								<div
									class="h-2 rounded-full transition-all duration-300"
									style="width: {item.pct}%; background-color: {valueColor(item.val.id)}"
								></div>
							</div>
						</div>
					{/each}
				</div>
			</div>

			<!-- Sem Metas Vinculadas -->
			{#if valueStats.withoutItems.length > 0}
				<div
					class="pt-space-md bg-surface-container-low/40 p-space-sm rounded-lg flex flex-col gap-space-xs mt-4"
				>
					<span class="font-label-sm text-label-sm uppercase tracking-wider text-outline">
						Sem metas vinculadas
					</span>
					<div class="flex flex-wrap gap-space-xs">
						{#each valueStats.withoutItems as item (item.val.id)}
							<span
								class="px-2.5 py-1 rounded bg-surface-container-high text-on-surface-variant font-label-sm text-label-sm opacity-70"
							>
								{item.val.title} (0 itens)
							</span>
						{/each}
					</div>
				</div>
			{/if}
		</div>
	</section>

	<!-- Section 3: Fila de Check-In de KPIs (Tabela) -->
	<section
		class="flex flex-col p-space-md lg:p-space-lg rounded-xl bg-surface-container-lowest shadow-sm gap-space-md"
	>
		<div
			class="flex flex-col md:flex-row md:items-center justify-between gap-space-sm pb-space-xs"
		>
			<div class="flex flex-col">
				<div class="flex items-center gap-space-xs">
					<span class="material-symbols-outlined text-primary text-[24px]">fact_check</span>
					<h2 class="font-headline-sm text-headline-sm text-on-surface">
						Fila de Check-In de KPIs
					</h2>
				</div>
				<p class="font-body-sm text-body-sm text-on-surface-variant">
					Métricas com pendência de atualização ou rito vencido
				</p>
			</div>

			<div class="flex items-center gap-space-sm self-start md:self-auto">
				<span class="font-body-sm text-body-sm text-on-surface-variant">Ordenação:</span>
				<div
					class="relative flex items-center bg-surface-container px-3 py-1.5 rounded-lg text-body-sm font-title-md text-on-surface shadow-inner"
				>
					<select
						bind:value={kpiSortOrder}
						class="bg-transparent appearance-none pr-6 outline-none cursor-pointer"
					>
						<option value="oldest">Mais antigos primeiro</option>
						<option value="newest">Mais recentes primeiro</option>
						<option value="lowest_progress">Menor progresso</option>
						<option value="title">Ordem alfabética</option>
					</select>
					<span
						class="material-symbols-outlined text-outline text-[16px] absolute right-2 pointer-events-none"
					>
						sort
					</span>
				</div>
			</div>
		</div>

		<!-- Table -->
		<div class="w-full overflow-x-auto">
			<table class="w-full text-left font-body-sm text-body-sm border-collapse min-w-[900px]">
				<thead>
					<tr
						class="bg-surface-container text-on-surface-variant font-label-sm text-label-sm uppercase tracking-wider"
					>
						<th class="py-3 px-4 rounded-l-lg">KPI / Indicador &amp; Diretoria</th>
						<th class="py-3 px-4">Meta vs Realizado</th>
						<th class="py-3 px-4 w-36">Progresso</th>
						<th class="py-3 px-4">Status Atualização</th>
						<th class="py-3 px-4 rounded-r-lg min-w-[340px]">Registro Rápido</th>
					</tr>
				</thead>
				<tbody class="divide-y-0 text-on-surface">
					{#each paginatedKPIs as kpi, idx (kpi.id)}
						{@const kpiTeams = getNodeTeams(kpi)}
						{@const lastUpdate = kpi.metricUpdates[0]}
						{@const isSuccess = registeredKpiIds.has(kpi.id)}
						<tr
							class="{idx % 2 === 0
								? 'hover:bg-surface-container-low'
								: 'bg-surface-container-low/30 hover:bg-surface-container-low'} transition-colors group"
						>
							<!-- Column 1: KPI & Diretoria -->
							<td class="py-3 px-4 align-middle">
								<div class="flex flex-col">
									<button
										type="button"
										onclick={() => (selectedNodeId = kpi.id)}
										class="text-left font-title-md text-on-surface font-semibold hover:text-primary transition-colors cursor-pointer"
									>
										{kpi.title}
									</button>
									<div class="flex items-center gap-1.5 mt-0.5 flex-wrap">
										{#each kpiTeams.slice(0, 2) as team (team.id)}
											{@const tTheme = getDossierTheme(team.color || '#0058bd')}
											<span
												class="inline-flex items-center gap-1 rounded-full border px-2 py-0.5 font-label-sm text-label-sm font-bold"
												title="Equipe: {team.name}"
												style="background-color: {tTheme.badgeBg}; border-color: {tTheme.badgeBorder}; color: {tTheme.badgeText};"
											>
												<span
													class="material-symbols-outlined text-[13px] shrink-0"
													style="color: {tTheme.accent};"
												>
													{getTeamIcon(team)}
												</span>
												<span class="max-w-[120px] truncate">{team.name}</span>
											</span>
										{/each}
										{#if kpiTeams.length === 0}
											{@const tTheme = getDossierTheme('#0284c7')}
											<span
												class="inline-flex items-center gap-1 rounded-full border px-2 py-0.5 font-label-sm text-label-sm font-bold"
												title="Equipe: Geral"
												style="background-color: {tTheme.badgeBg}; border-color: {tTheme.badgeBorder}; color: {tTheme.badgeText};"
											>
												<span
													class="material-symbols-outlined text-[13px] shrink-0"
													style="color: {tTheme.accent};"
												>
													hub
												</span>
												<span class="max-w-[120px] truncate">Geral</span>
											</span>
										{/if}
									</div>
								</div>
							</td>

							<!-- Column 2: Meta vs Realizado -->
							<td class="py-3 px-4 align-middle whitespace-nowrap">
								<div class="flex flex-col">
									<span class="font-title-md text-on-surface">
										{formatNumber(kpi.current_value ?? 0, kpi.unit)}
									</span>
									<span class="font-body-sm text-body-sm text-on-surface-variant">
										de {formatNumber(kpi.target_value ?? 0, kpi.unit)}
									</span>
								</div>
							</td>

							<!-- Column 3: Progresso -->
							<td class="py-3 px-4 align-middle">
								<div class="flex flex-col gap-1">
									<span class="font-label-sm text-label-sm text-on-surface-variant font-semibold">
										{formatPct(kpi.progress)}
									</span>
									<div class="w-full bg-surface-container h-1.5 rounded-full overflow-hidden">
										<div
											class="bg-primary h-1.5 rounded-full transition-all duration-300"
											style="width: {Math.round(kpi.progress * 100)}%"
										></div>
									</div>
								</div>
							</td>

							<!-- Column 4: Status Atualização -->
							<td class="py-3 px-4 align-middle whitespace-nowrap">
								{#if lastUpdate}
									<span
										class="inline-flex items-center gap-1 px-2.5 py-1 rounded-full bg-surface-container-high text-primary font-label-sm text-label-sm font-semibold"
									>
										<span class="material-symbols-outlined text-[14px]">done_all</span>
										Atualizado em {lastUpdate.created_at.slice(0, 10)}
									</span>
								{:else}
									<span
										class="inline-flex items-center gap-1 px-2.5 py-1 rounded-full bg-tertiary-fixed text-on-tertiary-fixed font-label-sm text-label-sm font-semibold"
									>
										<span class="material-symbols-outlined text-[14px]">history</span>
										Nunca atualizado
									</span>
								{/if}
							</td>

							<!-- Column 5: Registro Rápido -->
							<td class="py-3 px-4 align-middle">
								{#if canEdit}
									<form
										method="POST"
										action="?/logMetric"
										use:enhance={() => {
											submittingKpiId = kpi.id;
											return async ({ result, update }) => {
												submittingKpiId = null;
												if (result.type === 'success') {
													registeredKpiIds.add(kpi.id);
													registeredKpiIds = new Set(registeredKpiIds);
													setTimeout(() => {
														registeredKpiIds.delete(kpi.id);
														registeredKpiIds = new Set(registeredKpiIds);
													}, 3000);
												}
												await update();
											};
										}}
										class="flex items-center gap-1.5"
									>
										<input type="hidden" name="nodeId" value={kpi.id} />
										<input
											name="value"
											type="number"
											step="any"
											required
											value={kpi.current_value != null ? kpi.current_value : ''}
											placeholder={kpi.unit ? `Valor (${kpi.unit})` : 'Valor'}
											class="w-28 px-2.5 py-1.5 bg-surface-container rounded font-title-md text-body-sm text-on-surface focus:outline-none focus:bg-surface-container-lowest shadow-inner"
										/>
										<input
											name="note"
											type="text"
											placeholder="Nota rápida..."
											class="flex-1 px-2.5 py-1.5 bg-surface-container rounded font-body-sm text-body-sm text-on-surface focus:outline-none focus:bg-surface-container-lowest shadow-inner"
										/>
										<button
											type="submit"
											disabled={submittingKpiId === kpi.id}
											class="px-3 py-1.5 rounded font-title-md text-body-sm shadow active:scale-95 transition-all whitespace-nowrap cursor-pointer {isSuccess
												? 'bg-surface-container text-on-surface-variant font-bold'
												: 'bg-primary text-on-primary hover:bg-primary-container'}"
										>
											{#if submittingKpiId === kpi.id}
												...
											{:else if isSuccess}
												Registrado ✓
											{:else}
												Registrar
											{/if}
										</button>
									</form>
								{:else}
									<div class="flex items-center gap-1.5 opacity-80">
										<input
											class="w-28 px-2.5 py-1.5 bg-surface-container-high rounded font-title-md text-body-sm text-on-surface-variant cursor-not-allowed"
											disabled
											type="text"
											value={kpi.current_value != null ? String(kpi.current_value) : '0'}
										/>
										<input
											class="flex-1 px-2.5 py-1.5 bg-surface-container-high rounded font-body-sm text-body-sm text-on-surface-variant cursor-not-allowed truncate"
											disabled
											type="text"
											value={lastUpdate?.note || 'Sem anotação'}
										/>
										<button
											class="px-3 py-1.5 rounded bg-surface-container text-on-surface-variant font-title-md text-body-sm cursor-not-allowed whitespace-nowrap"
											disabled
											type="button"
										>
											Registrado ✓
										</button>
									</div>
								{/if}
							</td>
						</tr>
					{:else}
						<tr>
							<td colspan="5" class="py-8 text-center text-on-surface-variant font-body-md">
								Nenhum KPI encontrado para os filtros selecionados.
							</td>
						</tr>
					{/each}
				</tbody>
			</table>
		</div>

		<!-- Pagination Footer -->
		<div
			class="flex flex-col sm:flex-row items-center justify-between gap-space-sm pt-space-xs text-body-sm text-on-surface-variant"
		>
			<span>
				Exibindo
				<strong>
					{filteredSortedKPIs.length > 0 ? (currentPage - 1) * pageSize + 1 : 0}
					a {Math.min(currentPage * pageSize, filteredSortedKPIs.length)} de {filteredSortedKPIs.length}
				</strong>
				KPIs estratégicos
			</span>
			<div class="flex items-center gap-space-xs">
				<button
					class="p-1.5 rounded bg-surface-container hover:bg-surface-container-high text-on-surface disabled:opacity-40 transition-colors cursor-pointer"
					disabled={currentPage <= 1}
					onclick={() => currentPage--}
					type="button"
					title="Página anterior"
				>
					<span class="material-symbols-outlined text-[18px]">chevron_left</span>
				</button>
				<span class="px-2 font-label-md text-label-md font-semibold text-on-surface">
					Página {currentPage} de {totalPages}
				</span>
				<button
					class="p-1.5 rounded bg-surface-container hover:bg-surface-container-high text-on-surface disabled:opacity-40 transition-colors cursor-pointer"
					disabled={currentPage >= totalPages}
					onclick={() => currentPage++}
					type="button"
					title="Próxima página"
				>
					<span class="material-symbols-outlined text-[18px]">chevron_right</span>
				</button>
			</div>
		</div>
	</section>
</div>

<!-- Modal: + Novo Check-in Rápido (Lazy Loaded) -->
{#if quickModalOpen}
	{#await import('$lib/components/modal/QuickCheckInModal.svelte') then { default: QuickCheckInModal }}
		<QuickCheckInModal
			{enriched}
			{filteredSortedKPIs}
			bind:open={quickModalOpen}
			initialKpiId={quickKpiId}
		/>
	{/await}
{/if}

<!-- Integrated Dossier Modals for Node Inspections / Corrective Actions (Lazy Loaded) -->
{#if selectedNode}
	{#if selectedNode.type === 'objective'}
		{#await import('$lib/components/modal/ObjectiveDossierModal.svelte') then { default: ObjectiveDossierModal }}
			<ObjectiveDossierModal
				node={selectedNode}
				allNodes={data.nodes}
				cycles={data.cycles}
				profiles={data.profiles}
				teams={data.teams}
				valuesList={enriched.valuesList}
				{canEdit}
				onClose={() => (selectedNodeId = null)}
				onAddChild={() => {}}
				onOpenNode={(id: string) => (selectedNodeId = id)}
			/>
		{/await}
	{:else if selectedNode.type === 'key_result'}
		{#await import('$lib/components/modal/KeyResultDossierModal.svelte') then { default: KeyResultDossierModal }}
			<KeyResultDossierModal
				node={selectedNode}
				allNodes={data.nodes}
				cycles={data.cycles}
				profiles={data.profiles}
				teams={data.teams}
				valuesList={enriched.valuesList}
				{canEdit}
				onClose={() => (selectedNodeId = null)}
				onAddChild={() => {}}
				onOpenNode={(id: string) => (selectedNodeId = id)}
			/>
		{/await}
	{:else if selectedNode.type === 'kpi'}
		{#await import('$lib/components/modal/KpiDossierModal.svelte') then { default: KpiDossierModal }}
			<KpiDossierModal
				node={selectedNode}
				allNodes={data.nodes}
				cycles={data.cycles}
				profiles={data.profiles}
				teams={data.teams}
				{canEdit}
				onClose={() => (selectedNodeId = null)}
				onOpenParent={(id: string) => (selectedNodeId = id)}
			/>
		{/await}
	{/if}
{/if}

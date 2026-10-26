<script lang="ts">
	import type { NodeWithExtras } from '$lib/types';
	import { formatNumber, getInitials, getTeamIcon } from '$lib/utils';
	import { getDossierTheme } from '$lib/dossier-theme';
	import { valueColor } from '$lib/value-colors';
	import { onMount, tick } from 'svelte';
	import AttributionPile from '$lib/components/ui/AttributionPile.svelte';

	interface Props {
		roots: NodeWithExtras[];
		visibleIds: Set<string>;
		highlightedIds: Set<string>;
		dimmedIds: Set<string>;
		selectedNodeId: string | null;
		activeYear: number;
		activeCycleCode: string;
		canEdit: boolean;
		onSelectNode: (id: string) => void;
		onAddChild: (parent: NodeWithExtras) => void;
		onCreateObjective: () => void;
	}

	let {
		roots,
		visibleIds,
		highlightedIds,
		dimmedIds,
		selectedNodeId,
		activeYear,
		activeCycleCode,
		canEdit,
		onSelectNode,
		onAddChild,
		onCreateObjective
	}: Props = $props();

	// Visible Objectives in Column 1
	const visibleObjectives = $derived(roots.filter((r) => visibleIds.has(r.id)));

	// Sets tracking which cards have their children expanded/visible
	let expandedObjIds = $state<Set<string>>(new Set());
	let expandedKrIds = $state<Set<string>>(new Set());
	let compactKpis = $state(false);
	let hasInitialized = false;

	// Automatically expand the first visible objective on initial mount
	$effect(() => {
		if (!hasInitialized && visibleObjectives.length > 0) {
			hasInitialized = true;
			expandedObjIds = new Set([visibleObjectives[0].id]);
			const firstKrs = visibleObjectives[0].children.filter(
				(c) => c.type === 'key_result' && visibleIds.has(c.id)
			);
			if (firstKrs.length > 0) {
				expandedKrIds = new Set([firstKrs[0].id]);
			}
		}
	});

	function toggleObjExpand(objId: string) {
		const next = new Set(expandedObjIds);
		if (next.has(objId)) {
			next.delete(objId);
		} else {
			next.add(objId);
		}
		expandedObjIds = next;
	}

	function toggleKrExpand(krId: string) {
		const next = new Set(expandedKrIds);
		if (next.has(krId)) {
			next.delete(krId);
		} else {
			next.add(krId);
		}
		expandedKrIds = next;
	}

	// Key Result Clusters grouped by Parent Objective (ordered top to bottom by number)
	const krClusters = $derived.by(() => {
		const clusters: {
			parentId: string;
			parentIndex: number;
			items: {
				kr: NodeWithExtras;
				code: string;
				parentIndex: number;
				parentId: string;
			}[];
		}[] = [];

		visibleObjectives.forEach((obj, oIdx) => {
			if (expandedObjIds.has(obj.id)) {
				const rawKrs = obj.children.filter(
					(c) => c.type === 'key_result' && visibleIds.has(c.id)
				);
				// Order top to bottom by number / sort_order
				const sortedKrs = [...rawKrs].sort((a, b) => {
					if (a.sort_order != null && b.sort_order != null && a.sort_order !== b.sort_order) {
						return a.sort_order - b.sort_order;
					}
					return (a.title || '').localeCompare(b.title || '', undefined, { numeric: true });
				});
				const items = sortedKrs.map((kr, kIdx) => ({
					kr,
					code: `KR ${oIdx + 1}.${kIdx + 1}`,
					parentIndex: oIdx + 1,
					parentId: obj.id
				}));
				if (items.length > 0) {
					clusters.push({
						parentId: obj.id,
						parentIndex: oIdx + 1,
						items
					});
				}
			}
		});

		return clusters;
	});

	// Key Results displayed in Column 2 (all KRs belonging to expanded objectives)
	const displayedKRs = $derived(krClusters.flatMap((c) => c.items));

	// Total available KPIs for displayed KRs & Objs
	const totalDisplayedKpisCount = $derived.by(() => {
		let count = 0;
		for (const obj of visibleObjectives) {
			if (expandedObjIds.has(obj.id)) {
				count += obj.children.filter((c) => c.type === 'kpi' && visibleIds.has(c.id)).length;
			}
		}
		for (const item of displayedKRs) {
			count += item.kr.children.filter((c) => c.type === 'kpi' && visibleIds.has(c.id)).length;
		}
		return count;
	});

	// KPI Clusters grouped by Parent KR (ordered top to bottom by number)
	const kpiClusters = $derived.by(() => {
		const clusters: {
			parentId: string;
			items: {
				kpi: NodeWithExtras;
				code: string;
				parentId: string;
			}[];
		}[] = [];

		// Direct KPIs on expanded objectives
		for (const obj of visibleObjectives) {
			if (expandedObjIds.has(obj.id)) {
				const oIdx = visibleObjectives.findIndex((o) => o.id === obj.id) + 1;
				const directKpis = obj.children
					.filter((c) => c.type === 'kpi' && visibleIds.has(c.id))
					.sort((a, b) => {
						if (a.sort_order != null && b.sort_order != null && a.sort_order !== b.sort_order) {
							return a.sort_order - b.sort_order;
						}
						return (a.title || '').localeCompare(b.title || '', undefined, { numeric: true });
					});
				if (directKpis.length > 0) {
					clusters.push({
						parentId: obj.id,
						items: directKpis.map((kpi, idx) => ({
							kpi,
							code: `KPI ${oIdx}.0.${idx + 1}`,
							parentId: obj.id
						}))
					});
				}
			}
		}

		// KPIs under expanded KRs
		for (const item of displayedKRs) {
			if (expandedKrIds.has(item.kr.id)) {
				const rawKpis = item.kr.children.filter((c) => c.type === 'kpi' && visibleIds.has(c.id));
				const sortedKpis = [...rawKpis].sort((a, b) => {
					if (a.sort_order != null && b.sort_order != null && a.sort_order !== b.sort_order) {
						return a.sort_order - b.sort_order;
					}
					return (a.title || '').localeCompare(b.title || '', undefined, { numeric: true });
				});
				const krShort = item.code.replace('KR ', '');
				if (sortedKpis.length > 0) {
					clusters.push({
						parentId: item.kr.id,
						items: sortedKpis.map((kpi, idx) => ({
							kpi,
							code: `KPI ${krShort}.${idx + 1}`,
							parentId: item.kr.id
						}))
					});
				}
			}
		}

		return clusters;
	});

	// Operational KPIs displayed in Column 3
	const displayedKPIs = $derived(kpiClusters.flatMap((c) => c.items));

	// Dynamic vertical alignment offsets for child clusters so they appear right on the side of their parent node
	let krOffsets = $state<Record<string, number>>({});
	let kpiOffsets = $state<Record<string, number>>({});

	// Dynamic SVG Bezier Curve Measurements
	let gridEl = $state<HTMLElement | null>(null);
	let objToKrPaths = $state<{ d: string; x2: number; y2: number }[]>([]);
	let krToKpiPaths = $state<{ d: string; x2: number; y2: number }[]>([]);

	let layoutRunId = 0;

	async function updateClusterLayout() {
		const runId = ++layoutRunId;
		await tick();
		if (runId !== layoutRunId || !gridEl) return;

		const GAP = 16;
		const col1El = gridEl.querySelector('[data-column="objs"]') as HTMLElement | null;
		const col2El = gridEl.querySelector('[data-column="krs"]') as HTMLElement | null;
		const col3El = gridEl.querySelector('[data-column="kpis"]') as HTMLElement | null;

		if (!col1El || !col2El) return;

		// Pass 1: Compute Column 2 KR cluster offsets based on Column 1 Objective cards
		const nextKrOffsets: Record<string, number> = {};
		let currentY2 = 0;
		const col2Rect = col2El.getBoundingClientRect();

		for (const cluster of krClusters) {
			const parentCard = col1El.querySelector(
				`[data-node-card="${cluster.parentId}"]`
			) as HTMLElement | null;
			const clusterEl = col2El.querySelector(
				`[data-cluster-parent="${cluster.parentId}"]`
			) as HTMLElement | null;

			if (parentCard) {
				const parentRect = parentCard.getBoundingClientRect();
				const parentTop = Math.round(parentRect.top - col2Rect.top);
				const nextMinTop = currentY2 === 0 ? 0 : currentY2 + GAP;
				const targetTop = Math.max(parentTop, nextMinTop);
				const marginTop = Math.max(0, targetTop - currentY2);
				nextKrOffsets[cluster.parentId] = marginTop;

				const clusterHeight = clusterEl?.offsetHeight || 180;
				currentY2 = targetTop + clusterHeight;
			}
		}

		krOffsets = nextKrOffsets;
		await tick();
		if (runId !== layoutRunId || !gridEl) return;

		// Pass 2: Compute Column 3 KPI cluster offsets based on Column 2 KR cards (or Column 1 Objectives)
		if (col3El) {
			const nextKpiOffsets: Record<string, number> = {};
			let currentY3 = 0;
			const col3Rect = col3El.getBoundingClientRect();

			for (const cluster of kpiClusters) {
				const parentCard = (col2El.querySelector(
					`[data-node-card="${cluster.parentId}"]`
				) ||
					col1El.querySelector(
						`[data-node-card="${cluster.parentId}"]`
					)) as HTMLElement | null;
				const clusterEl = col3El.querySelector(
					`[data-cluster-parent="${cluster.parentId}"]`
				) as HTMLElement | null;

				if (parentCard) {
					const parentRect = parentCard.getBoundingClientRect();
					const parentTop = Math.round(parentRect.top - col3Rect.top);
					const nextMinTop = currentY3 === 0 ? 0 : currentY3 + GAP;
					const targetTop = Math.max(parentTop, nextMinTop);
					const marginTop = Math.max(0, targetTop - currentY3);
					nextKpiOffsets[cluster.parentId] = marginTop;

					const clusterHeight = clusterEl?.offsetHeight || 140;
					currentY3 = targetTop + clusterHeight;
				}
			}

			kpiOffsets = nextKpiOffsets;
			await tick();
			if (runId !== layoutRunId || !gridEl) return;
		}

		recomputeConnectors();
		requestAnimationFrame(() => {
			if (runId === layoutRunId) {
				recomputeConnectors();
			}
		});
	}

	function recomputeConnectors() {
		if (!gridEl) return;
		const gridRect = gridEl.getBoundingClientRect();
		if (gridRect.width < 600) {
			objToKrPaths = [];
			krToKpiPaths = [];
			return;
		}

		const nextObjKr: { d: string; x2: number; y2: number }[] = [];
		const nextKrKpi: { d: string; x2: number; y2: number }[] = [];

		for (const item of displayedKRs) {
			const parentId = item.parentId || item.kr.parent_id;
			const parentEl = parentId
				? (gridEl.querySelector(`[data-node-card="${parentId}"]`) as HTMLElement | null)
				: null;
			const krEl = gridEl.querySelector(`[data-node-card="${item.kr.id}"]`) as HTMLElement | null;

			if (parentEl && krEl) {
				const expEl = parentEl.querySelector('.group\\/expander') as HTMLElement | null;
				const pRect = expEl ? expEl.getBoundingClientRect() : parentEl.getBoundingClientRect();
				const kRect = krEl.getBoundingClientRect();

				const x1 = Math.round(pRect.right - gridRect.left);
				const y1 = Math.round(pRect.top - gridRect.top + pRect.height * 0.5);
				const x2 = Math.round(kRect.left - gridRect.left);
				const y2 = Math.round(kRect.top - gridRect.top + kRect.height * 0.5);
				const dx = x2 - x1;
				const cx1 = Math.round(x1 + dx * 0.45);
				const cx2 = Math.round(x1 + dx * 0.55);

				nextObjKr.push({
					d: `M ${x1} ${y1} C ${cx1} ${y1}, ${cx2} ${y2}, ${x2} ${y2}`,
					x2,
					y2
				});
			}
		}

		for (const item of displayedKPIs) {
			const parentId = item.parentId || item.kpi.parent_id;
			const parentEl = parentId
				? (gridEl.querySelector(`[data-node-card="${parentId}"]`) as HTMLElement | null)
				: null;
			const kpiEl = gridEl.querySelector(
				`[data-node-card="${item.kpi.id}"]`
			) as HTMLElement | null;

			if (parentEl && kpiEl) {
				const expEl = parentEl.querySelector('.group\\/expander') as HTMLElement | null;
				const pRect = expEl ? expEl.getBoundingClientRect() : parentEl.getBoundingClientRect();
				const kRect = kpiEl.getBoundingClientRect();

				const x1 = Math.round(pRect.right - gridRect.left);
				const y1 = Math.round(pRect.top - gridRect.top + pRect.height * 0.5);
				const x2 = Math.round(kRect.left - gridRect.left);
				const y2 = Math.round(kRect.top - gridRect.top + kRect.height * 0.5);
				const dx = x2 - x1;
				const cx1 = Math.round(x1 + dx * 0.45);
				const cx2 = Math.round(x1 + dx * 0.55);

				nextKrKpi.push({
					d: `M ${x1} ${y1} C ${cx1} ${y1}, ${cx2} ${y2}, ${x2} ${y2}`,
					x2,
					y2
				});
			}
		}

		objToKrPaths = nextObjKr;
		krToKpiPaths = nextKrKpi;
	}

	$effect(() => {
		// Re-run whenever displayed nodes, clusters or expanded sets change
		krClusters;
		kpiClusters;
		expandedObjIds;
		expandedKrIds;
		compactKpis;
		updateClusterLayout();
	});

	onMount(() => {
		updateClusterLayout();
		let lastGridWidth = 0;
		const ro = new ResizeObserver((entries) => {
			for (const entry of entries) {
				const width = Math.round(entry.contentRect.width);
				if (width !== lastGridWidth) {
					lastGridWidth = width;
					updateClusterLayout();
				} else {
					recomputeConnectors();
				}
			}
		});
		if (gridEl) ro.observe(gridEl);
		window.addEventListener('resize', updateClusterLayout);
		if (typeof document !== 'undefined' && 'fonts' in document) {
			document.fonts.ready.then(() => {
				updateClusterLayout();
			});
		}
		return () => {
			ro.disconnect();
			window.removeEventListener('resize', updateClusterLayout);
		};
	});

	function buildMiniSparkline(kpi: NodeWithExtras): { path: string; endY: number } {
		const updates = [...kpi.metricUpdates].reverse();
		const vals = updates.map((u) => u.value);
		if (kpi.baseline != null) vals.unshift(kpi.baseline);
		if (kpi.current_value != null && vals.length === 0) vals.push(kpi.current_value);
		if (vals.length < 2) {
			const pct = Math.max(0.1, Math.min(1, kpi.progress));
			const endY = Math.round(17 - pct * 13);
			return {
				path: `M 0 16 Q 25 15, 45 10 T 80 ${endY}`,
				endY
			};
		}
		const min = Math.min(...vals);
		const max = Math.max(...vals);
		const range = max - min || 1;
		const pts = vals.map((v, idx) => {
			const x = Math.round((idx / (vals.length - 1)) * 80);
			const y = Math.round(17 - ((v - min) / range) * 14);
			return { x, y };
		});
		const d = pts.map((p, i) => (i === 0 ? `M ${p.x} ${p.y}` : `L ${p.x} ${p.y}`)).join(' ');
		return { path: d, endY: pts[pts.length - 1].y };
	}

	// Footnote statistics
	const totalKRsCount = $derived(
		visibleObjectives.reduce(
			(acc, o) => acc + o.children.filter((c) => c.type === 'key_result').length,
			0
		)
	);
	const krsWithKpisCount = $derived(
		visibleObjectives.reduce(
			(acc, o) =>
				acc +
				o.children.filter((c) => c.type === 'key_result' && c.children.length > 0).length,
			0
		)
	);
	const verticalAlignmentPct = $derived(
		totalKRsCount > 0 ? Math.round((krsWithKpisCount / totalKRsCount) * 100) : 100
	);
</script>

<!-- Interactive Cascade Board (Canvas Drafting Mat) -->
<section
	class="relative w-full rounded-2xl p-2.5 sm:p-space-md lg:p-space-lg overflow-x-auto overscroll-x-contain min-h-[580px] sm:min-h-[680px] bg-surface-container-low shadow-[inset_0_2px_6px_rgba(36,34,30,0.05),0_1px_0_#ffffff]"
>
	<!-- Visual Ledger Grid Ruler Top (Aligned with 12-column Board Layout) -->
	<div
		class="min-w-[820px] sm:min-w-[960px] lg:min-w-[1060px] grid grid-cols-12 gap-3.5 sm:gap-space-md lg:gap-space-lg pb-space-sm mb-space-md border-b border-outline-variant/30"
	>
		<!-- Level 1 Column Header -->
		<div class="col-span-4 flex flex-col items-start gap-1.5">
			<div class="flex items-center gap-1.5">
				<span class="w-3 h-3 rounded-full bg-primary/20 flex items-center justify-center">
					<span class="w-1.5 h-1.5 rounded-full bg-primary"></span>
				</span>
				<span
					class="font-label-sm text-label-sm uppercase tracking-widest text-on-surface-variant font-bold"
				>
					Nível 1 · Objetivos Anuais ({activeYear})
				</span>
			</div>
			{#if visibleObjectives.length > 0}
				{@const allExpanded = visibleObjectives.every((o) => expandedObjIds.has(o.id))}
				<button
					type="button"
					onclick={() => {
						if (allExpanded) {
							expandedObjIds = new Set();
						} else {
							expandedObjIds = new Set(visibleObjectives.map((o) => o.id));
						}
					}}
					class="px-2.5 py-1 rounded bg-surface-container hover:bg-surface-container-highest font-label-sm text-label-sm text-primary font-bold transition-all shadow-[0_1px_2px_rgba(36,34,30,0.05)] flex items-center gap-1.5"
				>
					<span class="material-symbols-outlined text-[16px]">
						{allExpanded ? 'unfold_less' : 'unfold_more'}
					</span>
					<span>{allExpanded ? 'Recolher Todos' : `Expandir Todos (${visibleObjectives.length})`}</span>
				</button>
			{/if}
		</div>

		<!-- Level 2 Column Header -->
		<div class="col-span-4 flex flex-col items-start gap-1.5">
			<div class="flex items-center gap-1.5">
				<span class="w-3 h-3 rounded-full bg-secondary/20 flex items-center justify-center">
					<span class="w-1.5 h-1.5 rounded-full bg-secondary"></span>
				</span>
				<span
					class="font-label-sm text-label-sm uppercase tracking-widest text-on-surface-variant font-bold"
				>
					Nível 2 · Key Results (Ciclo {activeCycleCode})
				</span>
			</div>
			{#if displayedKRs.length > 0}
				{@const allKrsExpanded = displayedKRs.every((item) => expandedKrIds.has(item.kr.id))}
				<button
					type="button"
					onclick={() => {
						if (allKrsExpanded) {
							expandedKrIds = new Set();
						} else {
							expandedKrIds = new Set(displayedKRs.map((item) => item.kr.id));
						}
					}}
					class="px-2.5 py-1 rounded bg-surface-container hover:bg-surface-container-highest font-label-sm text-label-sm text-secondary font-bold transition-all shadow-[0_1px_2px_rgba(36,34,30,0.05)] flex items-center gap-1.5"
				>
					<span class="material-symbols-outlined text-[16px]">
						{allKrsExpanded ? 'visibility_off' : 'visibility'}
					</span>
					<span>{allKrsExpanded ? 'Recolher KPIs Filhos' : `Expandir Filhos (${totalDisplayedKpisCount} KPIs)`}</span>
				</button>
			{/if}
		</div>

		<!-- Level 3 Column Header -->
		<div class="col-span-4 flex flex-col items-start gap-1.5">
			<div class="flex items-center gap-1.5">
				<span
					class="w-3 h-3 rounded-full bg-tertiary-fixed-dim/30 flex items-center justify-center"
				>
					<span class="w-1.5 h-1.5 rounded-full bg-tertiary"></span>
				</span>
				<span
					class="font-label-sm text-label-sm uppercase tracking-widest text-on-surface-variant font-bold"
				>
					Nível 3 · Indicadores Operacionais (KPIs)
				</span>
			</div>
			{#if displayedKPIs.length > 0}
				<button
					type="button"
					onclick={() => (compactKpis = !compactKpis)}
					class="px-2.5 py-1 rounded bg-surface-container hover:bg-surface-container-highest font-label-sm text-label-sm text-[#78350F] font-bold transition-all shadow-[0_1px_2px_rgba(36,34,30,0.05)] flex items-center gap-1.5"
				>
					<span class="material-symbols-outlined text-[16px]">
						{compactKpis ? 'unfold_more' : 'unfold_less'}
					</span>
					<span>{compactKpis ? 'Expandir Detalhes' : 'Compactar Cards'}</span>
				</button>
			{/if}
		</div>
	</div>

	{#if visibleObjectives.length === 0}
		<div
			class="flex flex-col items-center justify-center py-20 text-center bg-surface-container-lowest/60 rounded-xl border border-dashed border-outline-variant"
		>
			<span class="material-symbols-outlined text-[36px] text-outline mb-2">account_tree</span>
			<p class="font-title-md text-title-md text-on-surface">
				Nenhum objetivo estratégico encontrado para os filtros atuais
			</p>
			<p class="font-body-sm text-body-sm text-on-surface-variant mt-1 max-w-md">
				Ajuste o ano, semestre, equipe ou crie um novo Objetivo Anual para iniciar a árvore estratégica.
			</p>
			{#if canEdit}
				<button
					type="button"
					onclick={onCreateObjective}
					class="mt-4 px-4 py-2 bg-primary text-on-primary rounded-lg font-label-md text-label-md flex items-center gap-1.5 shadow-[0_2px_0_#004494]"
				>
					<span class="material-symbols-outlined text-[18px]">add</span>
					<span>Criar Primeiro Objetivo</span>
				</button>
			{/if}
		</div>
	{:else}
		<!-- Tree Matrix Grid Layout -->
		<div bind:this={gridEl} class="relative min-w-[820px] sm:min-w-[960px] lg:min-w-[1060px] grid grid-cols-12 gap-3.5 sm:gap-space-md lg:gap-space-lg">
			<!-- ================= SVG BRANCH CONNECTIONS OVERLAY ================= -->
			<svg
				class="absolute inset-0 w-full h-full pointer-events-none z-0"
				xmlns="http://www.w3.org/2000/svg"
			>
				<defs>
					<linearGradient id="curveGrad1" x1="0%" x2="100%" y1="0%" y2="0%">
						<stop offset="0%" stop-color="#0058bd" stop-opacity="0.45"></stop>
						<stop offset="100%" stop-color="#b30069" stop-opacity="0.65"></stop>
					</linearGradient>
					<linearGradient id="curveGradKPI1" x1="0%" x2="100%" y1="0%" y2="0%">
						<stop offset="0%" stop-color="#b30069" stop-opacity="0.5"></stop>
						<stop offset="100%" stop-color="#6c5e00" stop-opacity="0.65"></stop>
					</linearGradient>
				</defs>

				{#each objToKrPaths as conn}
					<path
						d={conn.d}
						fill="none"
						stroke="url(#curveGrad1)"
						stroke-dasharray="4 2"
						stroke-width="2.5"
					></path>
					<circle cx={conn.x2} cy={conn.y2} fill="#b30069" r="3.5"></circle>
				{/each}

				{#each krToKpiPaths as conn}
					<path d={conn.d} fill="none" stroke="url(#curveGradKPI1)" stroke-width="2"></path>
					<circle cx={conn.x2} cy={conn.y2} fill="#6c5e00" r="3"></circle>
				{/each}
			</svg>

			<!-- ================= COLUMN 1: OBJECTIVES (OKRs) ================= -->
			<div data-column="objs" class="col-span-4 flex flex-col gap-space-md relative z-10">
				{#each visibleObjectives as obj, idx (obj.id)}
					{@const isSelected = selectedNodeId === obj.id}
					{@const isHighlighted = highlightedIds.has(obj.id)}
					{@const isDimmed = dimmedIds.has(obj.id)}
					{@const isExpanded = expandedObjIds.has(obj.id)}
					{@const pct = Math.round(obj.progress * 100)}
					{@const code = `OBJ-${String(idx + 1).padStart(2, '0')}`}
					{@const krChildren = obj.children.filter(
						(c) => c.type === 'key_result' && visibleIds.has(c.id)
					)}
					{@const leader = obj.assignees[0]}
					{@const objColor = obj.color || (obj.alignedValues.length > 0 ? valueColor(obj.alignedValues[0].id) : (obj.teams[0]?.color || '#0058bd'))}
					{@const objTheme = getDossierTheme(objColor)}

					<!-- Tactile Executive Archival Paper Objective Card (with thin right section and attribution pile) -->
					<div
						data-node-card={obj.id}
						class="group/card relative rounded-xl shadow-[0_1px_1px_rgba(36,34,30,0.05),0_4px_10px_-1px_rgba(36,34,30,0.06),0_-1px_0_rgba(255,255,255,0.9)_inset] hover:shadow-[0_8px_18px_-2px_rgba(36,34,30,0.1),0_2px_4px_rgba(36,34,30,0.04)] transition-[box-shadow,background-color,border-color,opacity] duration-150 flex overflow-hidden {isSelected
							? 'ring-2'
							: ''} {isHighlighted ? 'ring-2 ring-tertiary-container scale-[1.01]' : ''} {isDimmed
							? 'opacity-40 hover:opacity-90'
							: ''}"
						style="background-color: {objTheme.folderBg}; border: 1.5px solid {objTheme.folderBorder}; {isSelected ? `ring-color: ${objTheme.accent}; --tw-ring-color: ${objTheme.accent};` : ''}"
					>
						<!-- Category Indicator Spine -->
						<div
							class="absolute left-0 top-3 bottom-3 w-1.5 rounded-r shadow-xs z-10"
							style="background-color: {objTheme.accent};"
						></div>

						<!-- Main Card Interactive Area -->
						<div
							role="button"
							tabindex="0"
							onclick={() => onSelectNode(obj.id)}
							onkeydown={(e) => {
								if (e.key === 'Enter' || e.key === ' ') {
									e.preventDefault();
									onSelectNode(obj.id);
								}
							}}
							class="flex-1 min-w-0 p-space-md pr-2 sm:pr-3 text-left cursor-pointer"
						>
							<!-- Top Meta Bar -->
							<div class="flex items-center justify-between gap-2 mb-space-sm pl-2">
								<div class="flex items-center gap-2">
									<span
										class="font-label-md text-label-md font-bold px-2 py-0.5 rounded shadow-xs"
										style="background-color: {objTheme.badgeBg}; color: {objTheme.badgeText}; border: 1px solid {objTheme.badgeBorder};"
									>
										{code}
									</span>
									<span
										class="font-label-sm text-label-sm font-bold tracking-wider uppercase"
										style="color: {objTheme.accent};"
									>
										ANNUAL {obj.year ?? activeYear}
									</span>
								</div>

								<!-- Status Pill -->
								<div
									class="flex items-center gap-1.5 px-2.5 py-0.5 rounded-full bg-white/85 shadow-[0_1px_2px_rgba(36,34,30,0.06)]"
									style="border: 1px solid {objTheme.cardBorder};"
								>
									<span
										class="w-2 h-2 rounded-full {obj.atRisk
											? 'bg-secondary animate-pulse'
											: ''}"
										style={!obj.atRisk ? `background-color: ${objTheme.accent};` : ''}
									></span>
									<span
										class="font-label-sm text-label-sm font-bold uppercase tracking-wider {obj.atRisk
											? 'text-secondary'
											: ''}"
										style={!obj.atRisk ? `color: ${objTheme.accentDark};` : ''}
									>
										{obj.atRisk ? `Em Risco (${pct}%)` : `No Ritmo (${pct}%)`}
									</span>
								</div>
							</div>

							<!-- Card Main Title -->
							<h2
								class="font-headline-sm text-headline-sm pl-2 mb-space-sm leading-snug"
								style="color: {objTheme.accentShadow};"
							>
								{obj.title}
							</h2>

							{#if obj.description}
								<p
									class="font-body-sm text-body-sm pl-2 mb-space-md line-clamp-2"
									style="color: {objTheme.accentDark};"
								>
									{obj.description}
								</p>
							{/if}

							<!-- Annual Progress Meter (Debossed Rail + Pasted Strip) -->
							<div class="pl-2 mb-space-md">
								<div class="flex justify-between items-center mb-1">
									<span
										class="font-label-sm text-label-sm uppercase tracking-wider font-bold"
										style="color: {objTheme.accentDark};"
									>
										Progresso Consolidado
									</span>
									<span class="font-label-md text-label-md font-bold" style="color: {objTheme.accentShadow};">{pct}%</span>
								</div>
								<div
									class="w-full h-3 rounded-full p-0.5 shadow-[inset_0_1px_2px_rgba(36,34,30,0.08)]"
									style="background-color: {objTheme.badgeBg}; border: 1px solid {objTheme.badgeBorder};"
								>
									<div
										class="h-full rounded-full transition-all duration-700 shadow-xs"
										style="width: {pct}%; background-color: {objTheme.accent};"
									></div>
								</div>
							</div>

							<!-- Card Bottom Footer / Metadata -->
							<div
								class="pt-space-sm pl-2 flex items-center justify-between border-t border-dashed"
								style="border-color: {objTheme.cardBorder};"
							>
								<!-- Left: Attribution Pile (Squircle Team Icon + Circle Member Initials/Photo) -->
								<AttributionPile
									teams={obj.teams}
									assignees={obj.assignees}
									leader={leader}
								/>

								<!-- Right: Active KRs indicator + Quick Actions -->
								<div class="flex items-center gap-1 shrink-0">
									<span
										class="px-2.5 py-0.5 rounded font-label-sm text-label-sm font-bold border"
										style="background-color: {objTheme.badgeBg}; color: {objTheme.badgeText}; border-color: {objTheme.badgeBorder};"
									>
										{krChildren.length} {krChildren.length === 1 ? 'KR Ativo' : 'KRs Ativos'}
									</span>
									{#if canEdit}
										<button
											type="button"
											onclick={(e) => {
												e.stopPropagation();
												onAddChild(obj);
											}}
											title="Vincular novo Key Result a este Objetivo"
											class="p-1 hover:bg-primary hover:text-on-primary rounded text-on-surface-variant transition-colors"
										>
											<span class="material-symbols-outlined text-[16px]">add</span>
										</button>
									{/if}
									<button
										type="button"
										onclick={(e) => {
											e.stopPropagation();
											onSelectNode(obj.id);
										}}
										title="Inspecionar e editar Objetivo"
										class="p-1 hover:bg-surface-container rounded text-on-surface-variant hover:text-on-surface transition-colors"
									>
										<span class="material-symbols-outlined text-[18px]">more_horiz</span>
									</button>
								</div>
							</div>
						</div>

						<!-- Small Thin Section on Right Side with Arrow -->
						<button
							type="button"
							onclick={(e) => {
								e.stopPropagation();
								toggleObjExpand(obj.id);
							}}
							disabled={krChildren.length === 0}
							class="group/expander w-8 sm:w-9 shrink-0 flex items-center justify-center border-l border-dashed transition-colors select-none hover:bg-black/5 active:bg-black/10 {krChildren.length === 0 ? 'opacity-40 pointer-events-none cursor-default' : 'cursor-pointer'}"
							style="border-color: {objTheme.cardBorder};"
							title={krChildren.length === 0
								? 'Sem Key Results vinculados'
								: isExpanded
									? `Ocultar ${krChildren.length} KRs filhos`
									: `Mostrar ${krChildren.length} KRs filhos`}
							aria-expanded={isExpanded}
						>
							<span
								class="material-symbols-outlined text-[18px] transition-transform duration-200 group-hover/expander:scale-115 {isExpanded ? 'group-hover/expander:-translate-x-0.5' : 'group-hover/expander:translate-x-0.5'}"
								style="color: {objTheme.accentDark};"
							>
								{isExpanded ? 'chevron_left' : 'chevron_right'}
							</span>
						</button>
					</div>
				{/each}
			</div>

			<!-- ================= COLUMN 2: KEY RESULTS (KRs) ================= -->
			<div data-column="krs" class="col-span-4 flex flex-col relative z-10">
				{#each krClusters as cluster (cluster.parentId)}
					{@const marginTop = krOffsets[cluster.parentId] ?? 0}
					<div
						data-cluster-parent={cluster.parentId}
						class="flex flex-col gap-space-lg"
						style={marginTop > 0 ? `margin-top: ${marginTop}px;` : ''}
					>
						{#each cluster.items as item (item.kr.id)}
							{@const kr = item.kr}
							{@const pct = Math.round(kr.progress * 100)}
							{@const isAtRisk = kr.atRisk || kr.status === 'at_risk' || kr.status === 'off_track'}
							{@const isSelected = selectedNodeId === kr.id}
							{@const isHighlighted = highlightedIds.has(kr.id)}
							{@const isDimmed = dimmedIds.has(kr.id)}
							{@const isKrExpanded = expandedKrIds.has(kr.id)}
							{@const kpiCount = kr.children.filter(
								(c) => c.type === 'kpi' && visibleIds.has(c.id)
							).length}
							{@const owner = kr.assignees[0]}
							{@const krColor = kr.color || (kr.teams[0]?.color || (isAtRisk ? '#be123c' : '#ca8a04'))}
							{@const krTheme = getDossierTheme(krColor)}

							<!-- KR Pastel Tactile Dossier Card with Right Thin Section and Attribution Pile -->
							<div
								data-node-card={kr.id}
								class="group/card relative rounded-xl shadow-[0_2px_6px_rgba(36,34,30,0.06),0_1px_0_rgba(255,255,255,0.8)_inset] hover:shadow-[0_8px_16px_rgba(36,34,30,0.09)] transition-[box-shadow,background-color,border-color,opacity] duration-150 flex overflow-hidden {isSelected
									? 'ring-2 ring-on-surface'
									: ''} {isHighlighted ? 'ring-2 ring-primary scale-[1.01]' : ''} {isDimmed
									? 'opacity-40'
									: ''}"
								style="background-color: {krTheme.folderBg}; border: 1.5px solid {krTheme.folderBorder}; color: {krTheme.accentDark};"
							>
								<!-- Main Card Interactive Area -->
								<div
									role="button"
									tabindex="0"
									onclick={() => onSelectNode(kr.id)}
									onkeydown={(e) => {
										if (e.key === 'Enter' || e.key === ' ') {
											e.preventDefault();
											onSelectNode(kr.id);
										}
									}}
									class="flex-1 min-w-0 p-space-md pr-2 sm:pr-3 text-left cursor-pointer"
								>
									<div class="flex items-center justify-between gap-2 mb-2 pr-1">
										<div class="flex items-center gap-1.5">
											<span
												class="font-label-sm text-label-sm font-bold px-2 py-0.5 rounded shadow-[inset_0_1px_1px_rgba(255,255,255,0.6)]"
												style="background-color: {krTheme.badgeBg}; color: {krTheme.badgeText}; border: 1px solid {krTheme.badgeBorder};"
											>
												{item.code}
											</span>
											<span
												class="font-label-sm text-label-sm uppercase tracking-wider font-semibold"
												style="color: {krTheme.accent};"
											>
												{kr.cycle?.code ?? activeCycleCode}
											</span>
										</div>

										{#if isAtRisk}
											<span
												class="inline-flex items-center gap-1 px-2 py-0.5 rounded-full bg-white/80 font-label-sm text-label-sm font-bold text-[#BE123C] shadow-[0_1px_2px_rgba(36,34,30,0.04)]"
											>
												<span class="w-1.5 h-1.5 rounded-full bg-red-500 animate-pulse"></span>
												Em Risco ({pct}%)
											</span>
										{:else if pct >= 100}
											<span
												class="inline-flex items-center gap-1 px-2 py-0.5 rounded-full bg-white/80 font-label-sm text-label-sm font-bold text-[#166534] shadow-[0_1px_2px_rgba(36,34,30,0.04)]"
											>
												<span class="w-1.5 h-1.5 rounded-full bg-emerald-500"></span>
												Concluído
											</span>
										{:else}
											<span
												class="inline-flex items-center gap-1 px-2 py-0.5 rounded-full bg-white/80 font-label-sm text-label-sm font-bold shadow-[0_1px_2px_rgba(36,34,30,0.04)]"
												style="color: {krTheme.accentDark};"
											>
												<span class="w-1.5 h-1.5 rounded-full" style="background-color: {krTheme.accent};"></span>
												No Alvo
											</span>
										{/if}
									</div>

									<h3
										class="font-title-md text-title-md mb-space-sm leading-snug line-clamp-2"
										style="color: {krTheme.accentShadow};"
									>
										{kr.title}
									</h3>

									<!-- Progress Ledger Row -->
									<div
										class="mb-space-md bg-white/60 p-2.5 rounded-lg shadow-[inset_0_1px_2px_rgba(36,34,30,0.05)]"
										style="border: 1px solid {krTheme.cardBorder};"
									>
										<div
											class="flex justify-between items-center text-xs font-semibold mb-1"
											style="color: {krTheme.accentDark};"
										>
											<span class="truncate">
												{kr.description ? kr.description : 'Execução no Ciclo'}
											</span>
											<span class="font-bold shrink-0 ml-2" style="color: {krTheme.accentShadow};">
												{pct}% Concluído
											</span>
										</div>
										<div
											class="w-full h-2.5 rounded-full p-0.5"
											style="background-color: {krTheme.badgeBg}; border: 1px solid {krTheme.badgeBorder};"
										>
											<div
												class="h-full rounded-full shadow-[0_1px_2px_rgba(0,0,0,0.1)] transition-all duration-500"
												style="width: {pct}%; background-color: {krTheme.accent};"
											></div>
										</div>
									</div>

									<!-- Footer: Attribution Pile + Indicator Count & Quick Add -->
									<div
										class="flex items-center justify-between text-xs pt-2 border-t border-dashed"
										style="border-color: {krTheme.cardBorder};"
									>
										<AttributionPile
											teams={kr.teams}
											assignees={kr.assignees}
											leader={owner}
										/>

										<div class="flex items-center gap-1.5 shrink-0">
											<span
												class="px-2 py-0.5 rounded font-label-sm text-label-sm font-bold border"
												style="background-color: {krTheme.badgeBg}; color: {krTheme.badgeText}; border-color: {krTheme.badgeBorder};"
											>
												{kpiCount} {kpiCount === 1 ? 'Indicador' : 'Indicadores'}
											</span>
											{#if canEdit}
												<button
													type="button"
													onclick={(e) => {
														e.stopPropagation();
														onAddChild(kr);
													}}
													title="Adicionar Indicador KPI"
													class="p-1 rounded bg-white/70 hover:bg-white transition-colors"
													style="color: {krTheme.accentShadow};"
												>
													<span class="material-symbols-outlined text-[14px]">add</span>
												</button>
											{/if}
											<button
												type="button"
												onclick={(e) => {
													e.stopPropagation();
													onSelectNode(kr.id);
												}}
												title="Inspecionar Key Result"
												class="p-1 rounded hover:bg-white/60 transition-colors"
												style="color: {krTheme.accentShadow};"
											>
												<span class="material-symbols-outlined text-[16px]">more_horiz</span>
											</button>
										</div>
									</div>
								</div>

								<!-- Small Thin Section on Right Side with Chevron Expander -->
								<button
									type="button"
									onclick={(e) => {
										e.stopPropagation();
										toggleKrExpand(kr.id);
									}}
									disabled={kpiCount === 0}
									class="group/expander w-8 sm:w-9 shrink-0 flex items-center justify-center border-l border-dashed transition-colors select-none hover:bg-black/5 active:bg-black/10 {kpiCount === 0 ? 'opacity-40 pointer-events-none cursor-default' : 'cursor-pointer'}"
									style="border-color: {krTheme.cardBorder};"
									title={kpiCount === 0
										? 'Sem indicadores vinculados'
										: isKrExpanded
											? `Ocultar ${kpiCount} KPIs filhos`
											: `Mostrar ${kpiCount} KPIs filhos`}
									aria-expanded={isKrExpanded}
								>
									<span
										class="material-symbols-outlined text-[18px] transition-transform duration-200 group-hover/expander:scale-115 {isKrExpanded ? 'group-hover/expander:-translate-x-0.5' : 'group-hover/expander:translate-x-0.5'}"
										style="color: {krTheme.accentDark};"
									>
										{isKrExpanded ? 'chevron_left' : 'chevron_right'}
									</span>
								</button>
							</div>
						{/each}
					</div>
				{:else}
					<div
						class="rounded-xl bg-surface-container-lowest/60 border border-dashed border-outline-variant p-6 text-center"
					>
						{#if expandedObjIds.size === 0}
							<span class="material-symbols-outlined text-[28px] text-outline mb-2">subdirectory_arrow_right</span>
							<p class="font-title-md text-title-md text-on-surface-variant">
								Nenhum Key Result visível
							</p>
							<p class="font-body-sm text-body-sm text-outline mt-1">
								Clique na seta lateral (&gt;) de um Objetivo para exibir seus Key Results.
							</p>
						{:else}
							<p class="font-title-md text-title-md text-on-surface-variant">
								Nenhum Key Result neste objetivo
							</p>
							{#if canEdit && visibleObjectives.length > 0}
								{@const targetObj = visibleObjectives.find((o) => expandedObjIds.has(o.id)) || visibleObjectives[0]}
								<button
									type="button"
									onclick={() => onAddChild(targetObj)}
									class="mt-3 px-3 py-1.5 rounded-lg bg-secondary text-on-secondary font-label-sm text-label-sm font-bold shadow-[0_2px_0_#8d0051]"
								>
									+ Adicionar Key Result
								</button>
							{/if}
						{/if}
					</div>
				{/each}
			</div>

			<!-- ================= COLUMN 3: OPERATIONAL KPIS ================= -->
			<div data-column="kpis" class="col-span-4 flex flex-col relative z-10">
				{#each kpiClusters as cluster (cluster.parentId)}
					{@const marginTop = kpiOffsets[cluster.parentId] ?? 0}
					<div
						data-cluster-parent={cluster.parentId}
						class="flex flex-col gap-space-md"
						style={marginTop > 0 ? `margin-top: ${marginTop}px;` : ''}
					>
						{#each cluster.items as item, kIdx (item.kpi.id)}
							{@const kpi = item.kpi}
							{@const defaultKpiColors = ['#059669', '#0058bd', '#ea580c', '#7c3aed', '#00665a']}
							{@const kpiColor = kpi.color || (kpi.teams[0]?.color || defaultKpiColors[kIdx % defaultKpiColors.length])}
							{@const kpiTheme = getDossierTheme(kpiColor)}
							{@const isSelected = selectedNodeId === kpi.id}
							{@const isHighlighted = highlightedIds.has(kpi.id)}
							{@const isDimmed = dimmedIds.has(kpi.id)}
							{@const spark = buildMiniSparkline(kpi)}
							{@const lastUpdate = kpi.metricUpdates[0]}
							{@const owner = kpi.assignees[0]}
							{@const pct = Math.round(kpi.progress * 100)}
							{@const trendIcon = kpi.direction === 'down' ? 'trending_down' : pct >= 100 ? 'check_circle' : 'trending_up'}

							<div
								data-node-card={kpi.id}
								role="button"
								tabindex="0"
								onclick={() => onSelectNode(kpi.id)}
								onkeydown={(e) => {
									if (e.key === 'Enter' || e.key === ' ') {
										e.preventDefault();
										onSelectNode(kpi.id);
									}
								}}
								class="relative cursor-pointer rounded-xl p-space-md shadow-[0_2px_5px_rgba(36,34,30,0.05),0_1px_0_rgba(255,255,255,0.7)_inset] hover:shadow-[0_6px_14px_rgba(36,34,30,0.08)] transition-[box-shadow,background-color,border-color,opacity] duration-150 {isSelected
									? 'ring-2 ring-on-surface'
									: ''} {isHighlighted ? 'ring-2 ring-primary scale-[1.01]' : ''} {isDimmed
									? 'opacity-40'
									: ''}"
								style="background-color: {kpiTheme.folderBg}; border: 1.5px solid {kpiTheme.folderBorder}; color: {kpiTheme.accentDark};"
							>
								<div class="flex items-center justify-between gap-2 mb-2">
									<div class="flex items-center gap-1.5 flex-wrap">
										<span
											class="font-label-sm text-label-sm font-bold px-1.5 py-0.5 rounded shadow-xs"
											style="background-color: {kpiTheme.badgeBg}; color: {kpiTheme.badgeText}; border: 1px solid {kpiTheme.badgeBorder};"
										>
											{item.code}
										</span>
										{#if kpi.teams.length > 0}
											{@const ktTheme = getDossierTheme(kpi.teams[0].color || '#0058bd')}
											<span
												class="inline-flex items-center gap-1 px-1.5 py-0.5 rounded-full text-[9.5px] font-bold border"
												style="background-color: {ktTheme.badgeBg}; border-color: {ktTheme.badgeBorder}; color: {ktTheme.badgeText};"
											>
												<span
													class="material-symbols-outlined text-[12px] shrink-0"
													style="color: {ktTheme.accent};"
												>
													{getTeamIcon(kpi.teams[0])}
												</span>
												<span class="max-w-[75px] truncate">{kpi.teams[0].name}</span>
											</span>
										{:else}
											<span
												class="font-label-sm text-label-sm uppercase tracking-wider font-semibold"
												style="color: {kpiTheme.accentDark};"
											>
												{kpi.cycle?.code ?? 'Operacional'}
											</span>
										{/if}
									</div>
									<div
										class="flex items-center gap-1 font-bold text-xs bg-white/80 px-2 py-0.5 rounded-full shadow-xs"
										style="color: {kpiTheme.accentDark}; border: 1px solid {kpiTheme.cardBorder};"
									>
										<span class="material-symbols-outlined text-[14px]">{trendIcon}</span>
										<span>{pct}%</span>
									</div>
								</div>

								<h4
									class="font-title-md text-title-md {compactKpis ? 'mb-1' : 'mb-space-sm'} leading-tight"
									style="color: {kpiTheme.accentShadow};"
								>
									{kpi.title}
								</h4>

								{#if compactKpis}
									<!-- Compact Metric Snapshot -->
									<div
										class="flex items-center justify-between pt-1 border-t text-xs"
										style="border-color: {kpiTheme.cardBorder};"
									>
										<span class="font-label-sm text-label-sm" style="color: {kpiTheme.accentDark};">
											Meta: <strong style="color: {kpiTheme.accentShadow};">{formatNumber(kpi.target_value, kpi.unit)}</strong>
										</span>
										<span class="font-label-sm text-label-sm font-bold" style="color: {kpiTheme.accent};">
											Atual: {formatNumber(kpi.current_value, kpi.unit)}
										</span>
									</div>
								{:else}
									<!-- Detailed Metric Comparison Ledger -->
									<div
										class="grid grid-cols-3 gap-2 bg-white/70 p-2.5 rounded-lg mb-space-sm shadow-[inset_0_1px_2px_rgba(36,34,30,0.04)]"
										style="border: 1px solid {kpiTheme.cardBorder};"
									>
										<div>
											<span class="block font-label-sm text-label-sm uppercase" style="color: {kpiTheme.accent};">
												Base
											</span>
											<span class="font-label-md text-label-md font-bold" style="color: {kpiTheme.accentDark};">
												{formatNumber(kpi.baseline, kpi.unit)}
											</span>
										</div>
										<div>
											<span class="block font-label-sm text-label-sm uppercase" style="color: {kpiTheme.accent};">
												Meta
											</span>
											<span class="font-label-md text-label-md font-bold" style="color: {kpiTheme.accentDark};">
												{formatNumber(kpi.target_value, kpi.unit)}
											</span>
										</div>
										<div>
											<span class="block font-label-sm text-label-sm uppercase" style="color: {kpiTheme.accent};">
												Atual
											</span>
											<span class="font-label-md text-label-md font-bold" style="color: {kpiTheme.accentDark}; font-weight: 800;">
												{formatNumber(kpi.current_value, kpi.unit)}
											</span>
										</div>
									</div>

									<!-- Sparkline Mini Chart Visualizer & Responsible Pile -->
									<div class="flex items-center justify-between pt-2 border-t border-dashed gap-2" style="border-color: {kpiTheme.cardBorder};">
										<div class="flex items-center gap-2 min-w-0">
											<AttributionPile
												teams={kpi.teams}
												assignees={kpi.assignees}
												leader={owner}
												size="sm"
											/>
											<span class="text-[10px] font-medium truncate" style="color: {kpiTheme.accentDark};">
												{#if lastUpdate}
													{lastUpdate.created_at.slice(0, 10)}
												{:else}
													Sem check-in
												{/if}
											</span>
										</div>
										<svg class="w-16 h-4 shrink-0" fill="none" viewBox="0 0 80 20">
											<path
												d={spark.path}
												stroke={kpiTheme.accent}
												stroke-linecap="round"
												stroke-width="2"
											></path>
											<circle cx="80" cy={spark.endY} fill={kpiTheme.accentDark} r="2.5"></circle>
										</svg>
									</div>
								{/if}
							</div>
						{/each}
					</div>
				{:else}
					<div
						class="rounded-xl bg-surface-container-lowest/60 border border-dashed border-outline-variant p-6 text-center"
					>
						{#if expandedKrIds.size === 0 && displayedKRs.length > 0}
							<span class="material-symbols-outlined text-[28px] text-outline mb-2">subdirectory_arrow_right</span>
							<p class="font-title-md text-title-md text-on-surface-variant">
								Nenhum indicador expandido
							</p>
							<p class="font-body-sm text-body-sm text-outline mt-1">
								Clique na seta lateral (&gt;) de um Key Result para visualizar seus KPIs vinculados.
							</p>
						{:else}
							<p class="font-title-md text-title-md text-on-surface-variant">
								Nenhum indicador operacional vinculado
							</p>
							<p class="font-body-sm text-body-sm text-outline mt-1">
								Clique no botão + em um Key Result para adicionar um KPI.
							</p>
						{/if}
					</div>
				{/each}
			</div>
		</div>
	{/if}
</section>

<!-- Interactive Inspector Drawer / Operational Footnote Ledger -->
<section class="mt-space-lg w-full grid grid-cols-1 md:grid-cols-3 gap-space-md">
	<!-- Health Summary Note -->
	<div
		class="bg-surface-container rounded-xl p-space-md shadow-[0_1px_1px_rgba(36,34,30,0.05),inset_0_1px_0_#ffffff] flex items-start gap-space-sm"
	>
		<div
			class="w-8 h-8 rounded-lg bg-surface-container-lowest flex items-center justify-center shrink-0 shadow-sm text-primary"
		>
			<span class="material-symbols-outlined text-[20px]">verified</span>
		</div>
		<div>
			<h5 class="font-title-md text-title-md text-on-surface">
				Alinhamento Vertical {verticalAlignmentPct}%
			</h5>
			<p class="font-body-sm text-body-sm text-on-surface-variant mt-0.5">
				{krsWithKpisCount} de {totalKRsCount} Key Results ativos no ciclo {activeCycleCode} possuem indicadores
				operacionais (KPIs) vinculados.
			</p>
		</div>
	</div>

	<!-- Cycle Cadence Ledger -->
	<div
		class="bg-surface-container rounded-xl p-space-md shadow-[0_1px_1px_rgba(36,34,30,0.05),inset_0_1px_0_#ffffff] flex items-start gap-space-sm"
	>
		<div
			class="w-8 h-8 rounded-lg bg-surface-container-lowest flex items-center justify-center shrink-0 shadow-sm text-secondary"
		>
			<span class="material-symbols-outlined text-[20px]">update</span>
		</div>
		<div>
			<h5 class="font-title-md text-title-md text-on-surface">Próximo Rito de Check-in</h5>
			<p class="font-body-sm text-body-sm text-on-surface-variant mt-0.5">
				Comitê Quinzenal de Governança Estratégica agendado com Diretoria Executiva e Lideranças.
			</p>
		</div>
	</div>

	<!-- Quick Export Utility -->
	<div
		class="bg-surface-container rounded-xl p-space-md shadow-[0_1px_1px_rgba(36,34,30,0.05),inset_0_1px_0_#ffffff] flex items-center justify-between"
	>
		<div class="flex items-center gap-space-sm">
			<div
				class="w-8 h-8 rounded-lg bg-surface-container-lowest flex items-center justify-center shrink-0 shadow-sm text-tertiary"
			>
				<span class="material-symbols-outlined text-[20px]">ios_share</span>
			</div>
			<div>
				<h5 class="font-title-md text-title-md text-on-surface">Exportação Executiva</h5>
				<span class="font-label-sm text-label-sm text-on-surface-variant">
					PDF Vetorial &amp; Relatório Board
				</span>
			</div>
		</div>
		<button
			type="button"
			onclick={() => window.print()}
			title="Imprimir / Exportar PDF Vetorial"
			class="p-2 bg-surface-container-lowest hover:bg-surface-container-highest rounded-lg text-on-surface shadow-sm transition-colors"
		>
			<span class="material-symbols-outlined text-[18px]">download</span>
		</button>
	</div>
</section>

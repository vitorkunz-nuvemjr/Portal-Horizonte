<script lang="ts">
	import type { NodeWithExtras } from '$lib/types';
	import { formatNumber, getInitials } from '$lib/utils';
	import { getDossierTheme } from '$lib/dossier-theme';
	import { valueColor } from '$lib/value-colors';
	import { onMount, tick } from 'svelte';

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

	let focusedObjId = $state<string | null>(null);
	let expandAllObjectives = $state(false);
	let expandAllKpis = $state(true);
	let compactKpis = $state(false);

	const activeObj = $derived.by(() => {
		if (visibleObjectives.length === 0) return null;
		if (focusedObjId) {
			const found = visibleObjectives.find((o) => o.id === focusedObjId);
			if (found) return found;
		}
		return visibleObjectives[0];
	});

	const activeObjIndex = $derived(
		activeObj ? visibleObjectives.findIndex((o) => o.id === activeObj.id) : 0
	);

	// Key Results displayed in Column 2
	const displayedKRs = $derived.by(() => {
		if (expandAllObjectives) {
			return visibleObjectives.flatMap((o, oIdx) =>
				o.children
					.filter((c) => c.type === 'key_result' && visibleIds.has(c.id))
					.map((kr, kIdx) => ({
						kr,
						code: `KR ${oIdx + 1}.${kIdx + 1}`,
						parentIndex: oIdx + 1
					}))
			);
		}
		if (!activeObj) return [];
		const oIdx = activeObjIndex + 1;
		return activeObj.children
			.filter((c) => c.type === 'key_result' && visibleIds.has(c.id))
			.map((kr, kIdx) => ({
				kr,
				code: `KR ${oIdx}.${kIdx + 1}`,
				parentIndex: oIdx
			}));
	});

	// Total available KPIs for displayed KRs & Objs
	const totalDisplayedKpisCount = $derived.by(() => {
		const targetObjs = expandAllObjectives
			? visibleObjectives
			: activeObj
				? [activeObj]
				: [];
		let count = 0;
		for (const obj of targetObjs) {
			count += obj.children.filter((c) => c.type === 'kpi' && visibleIds.has(c.id)).length;
		}
		for (const item of displayedKRs) {
			count += item.kr.children.filter((c) => c.type === 'kpi' && visibleIds.has(c.id)).length;
		}
		return count;
	});

	// Operational KPIs displayed in Column 3
	const displayedKPIs = $derived.by(() => {
		if (!expandAllKpis) return [];

		const list: {
			kpi: NodeWithExtras;
			code: string;
			parentId: string;
		}[] = [];

		// Direct KPIs on active objective(s)
		const targetObjs = expandAllObjectives
			? visibleObjectives
			: activeObj
				? [activeObj]
				: [];

		for (const obj of targetObjs) {
			const oIdx = visibleObjectives.findIndex((o) => o.id === obj.id) + 1;
			const directKpis = obj.children.filter((c) => c.type === 'kpi' && visibleIds.has(c.id));
			directKpis.forEach((kpi, idx) => {
				list.push({
					kpi,
					code: `KPI ${oIdx}.0.${idx + 1}`,
					parentId: obj.id
				});
			});
		}

		// KPIs under displayed KRs
		for (const item of displayedKRs) {
			const kpis = item.kr.children.filter((c) => c.type === 'kpi' && visibleIds.has(c.id));
			const krShort = item.code.replace('KR ', '');
			kpis.forEach((kpi, idx) => {
				list.push({
					kpi,
					code: `KPI ${krShort}.${idx + 1}`,
					parentId: item.kr.id
				});
			});
		}

		return list;
	});

	// Dynamic SVG Bezier Curve Measurements
	let gridEl = $state<HTMLElement | null>(null);
	let objToKrPaths = $state<{ d: string; x2: number; y2: number }[]>([]);
	let krToKpiPaths = $state<{ d: string; x2: number; y2: number }[]>([]);

	async function recomputeConnectors() {
		await tick();
		if (!gridEl) return;
		const gridRect = gridEl.getBoundingClientRect();
		if (gridRect.width < 900) {
			objToKrPaths = [];
			krToKpiPaths = [];
			return;
		}

		const nextObjKr: { d: string; x2: number; y2: number }[] = [];
		const nextKrKpi: { d: string; x2: number; y2: number }[] = [];

		for (const item of displayedKRs) {
			const parentEl = gridEl.querySelector(
				`[data-node-card="${item.kr.parent_id}"]`
			) as HTMLElement | null;
			const krEl = gridEl.querySelector(`[data-node-card="${item.kr.id}"]`) as HTMLElement | null;
			if (parentEl && krEl) {
				const pRect = parentEl.getBoundingClientRect();
				const kRect = krEl.getBoundingClientRect();
				const x1 = Math.round(pRect.right - gridRect.left);
				const y1 = Math.round(pRect.top - gridRect.top + Math.min(pRect.height * 0.55, 160));
				const x2 = Math.round(kRect.left - gridRect.left);
				const y2 = Math.round(kRect.top - gridRect.top + kRect.height * 0.45);
				const cx1 = Math.round(x1 + (x2 - x1) * 0.45);
				const cx2 = Math.round(x1 + (x2 - x1) * 0.55);
				nextObjKr.push({
					d: `M ${x1} ${y1} C ${cx1} ${y1}, ${cx2} ${y2}, ${x2} ${y2}`,
					x2,
					y2
				});
			}
		}

		for (const item of displayedKPIs) {
			const parentEl = gridEl.querySelector(
				`[data-node-card="${item.parentId}"]`
			) as HTMLElement | null;
			const kpiEl = gridEl.querySelector(
				`[data-node-card="${item.kpi.id}"]`
			) as HTMLElement | null;
			if (parentEl && kpiEl) {
				const pRect = parentEl.getBoundingClientRect();
				const kRect = kpiEl.getBoundingClientRect();
				const x1 = Math.round(pRect.right - gridRect.left);
				const y1 = Math.round(pRect.top - gridRect.top + pRect.height * 0.5);
				const x2 = Math.round(kRect.left - gridRect.left);
				const y2 = Math.round(kRect.top - gridRect.top + kRect.height * 0.5);
				const cx1 = Math.round(x1 + (x2 - x1) * 0.45);
				const cx2 = Math.round(x1 + (x2 - x1) * 0.55);
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
		// Re-run whenever displayed nodes change
		displayedKRs;
		displayedKPIs;
		activeObj;
		expandAllObjectives;
		expandAllKpis;
		compactKpis;
		recomputeConnectors();
	});

	onMount(() => {
		recomputeConnectors();
		const ro = new ResizeObserver(() => recomputeConnectors());
		if (gridEl) ro.observe(gridEl);
		window.addEventListener('resize', recomputeConnectors);
		return () => {
			ro.disconnect();
			window.removeEventListener('resize', recomputeConnectors);
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
	class="relative w-full rounded-2xl p-space-md lg:p-space-lg overflow-x-auto min-h-[680px] bg-surface-container-low shadow-[inset_0_2px_6px_rgba(36,34,30,0.05),0_1px_0_#ffffff]"
>
	<!-- Visual Ledger Grid Ruler Top (Aligned with 12-column Board Layout) -->
	<div
		class="min-w-[1060px] grid grid-cols-12 gap-space-lg pb-space-sm mb-space-md border-b border-outline-variant/30"
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
			{#if visibleObjectives.length > 1}
				<button
					type="button"
					onclick={() => (expandAllObjectives = !expandAllObjectives)}
					class="px-2.5 py-1 rounded bg-surface-container hover:bg-surface-container-highest font-label-sm text-label-sm text-primary font-bold transition-all shadow-[0_1px_2px_rgba(36,34,30,0.05)] flex items-center gap-1.5"
				>
					<span class="material-symbols-outlined text-[16px]">
						{expandAllObjectives ? 'filter_center_focus' : 'unfold_more'}
					</span>
					<span>{expandAllObjectives ? 'Focar 1 Objetivo' : `Expandir Todos (${visibleObjectives.length})`}</span>
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
			{#if totalDisplayedKpisCount > 0}
				<button
					type="button"
					onclick={() => (expandAllKpis = !expandAllKpis)}
					class="px-2.5 py-1 rounded bg-surface-container hover:bg-surface-container-highest font-label-sm text-label-sm text-secondary font-bold transition-all shadow-[0_1px_2px_rgba(36,34,30,0.05)] flex items-center gap-1.5"
				>
					<span class="material-symbols-outlined text-[16px]">
						{expandAllKpis ? 'visibility_off' : 'visibility'}
					</span>
					<span>{expandAllKpis ? 'Recolher KPIs Filhos' : `Expandir Filhos (${totalDisplayedKpisCount} KPIs)`}</span>
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
		<div bind:this={gridEl} class="relative min-w-[1060px] grid grid-cols-12 gap-space-lg">
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
			<div class="col-span-4 flex flex-col gap-space-md relative z-10">
				{#each visibleObjectives as obj, idx (obj.id)}
					{@const isFocused = expandAllObjectives || activeObj?.id === obj.id}
					{@const isSelected = selectedNodeId === obj.id}
					{@const isHighlighted = highlightedIds.has(obj.id)}
					{@const isDimmed = dimmedIds.has(obj.id)}
					{@const pct = Math.round(obj.progress * 100)}
					{@const code = `OBJ-${String(idx + 1).padStart(2, '0')}`}
					{@const krChildren = obj.children.filter(
						(c) => c.type === 'key_result' && visibleIds.has(c.id)
					)}
					{@const leader = obj.assignees[0]}
					{@const teamNames =
						obj.teams.length > 0
							? obj.teams.map((t) => t.name).join(' & ')
							: 'Diretoria Executiva'}
					{@const objColor = obj.color || (obj.alignedValues.length > 0 ? valueColor(obj.alignedValues[0].id) : (obj.teams[0]?.color || '#0058bd'))}
					{@const objTheme = getDossierTheme(objColor)}

					{#if isFocused}
						<!-- Expanded Tactile Executive Archival Paper Objective Card -->
						<div
							data-node-card={obj.id}
							role="button"
							tabindex="0"
							onclick={() => {
								focusedObjId = obj.id;
								onSelectNode(obj.id);
							}}
							onkeydown={(e) => {
								if (e.key === 'Enter' || e.key === ' ') {
									e.preventDefault();
									focusedObjId = obj.id;
									onSelectNode(obj.id);
								}
							}}
							class="group relative cursor-pointer bg-surface-container-lowest rounded-xl p-space-md shadow-[0_1px_1px_rgba(36,34,30,0.05),0_4px_10px_-1px_rgba(36,34,30,0.06),0_-1px_0_rgba(255,255,255,0.9)_inset] hover:shadow-[0_8px_18px_-2px_rgba(36,34,30,0.1),0_2px_4px_rgba(36,34,30,0.04)] transition-all {isSelected
								? 'ring-2'
								: ''} {isHighlighted ? 'ring-2 ring-tertiary-container scale-[1.01]' : ''} {isDimmed
								? 'opacity-40 hover:opacity-90'
								: ''}"
							style="border: 1.5px solid {objTheme.cardBorder}; {isSelected ? `ring-color: ${objTheme.accent}; --tw-ring-color: ${objTheme.accent};` : ''}"
						>
							<!-- Category Indicator Spine -->
							<div class="absolute left-0 top-3 bottom-3 w-1.5 rounded-r shadow-xs" style="background-color: {objTheme.accent};"></div>

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
										class="font-label-sm text-label-sm text-on-surface-variant font-bold tracking-wider uppercase"
									>
										ANNUAL {obj.year ?? activeYear}
									</span>
								</div>

								<!-- Status Pill -->
								<div
									class="flex items-center gap-1.5 px-2.5 py-0.5 rounded-full bg-surface-container text-on-surface shadow-[inset_0_1px_2px_rgba(36,34,30,0.08)]"
								>
									<span
										class="w-2 h-2 rounded-full {obj.atRisk
											? 'bg-secondary animate-pulse'
											: 'bg-tertiary-fixed-dim'}"
									></span>
									<span
										class="font-label-sm text-label-sm font-bold uppercase tracking-wider {obj.atRisk
											? 'text-secondary'
											: 'text-tertiary'}"
									>
										{obj.atRisk ? `Em Risco (${pct}%)` : `No Ritmo (${pct}%)`}
									</span>
								</div>
							</div>

							<!-- Card Main Title -->
							<h2
								class="font-headline-sm text-headline-sm text-on-surface pl-2 mb-space-sm leading-snug"
							>
								{obj.title}
							</h2>

							{#if obj.description}
								<p class="font-body-sm text-body-sm text-on-surface-variant pl-2 mb-space-md">
									{obj.description}
								</p>
							{/if}

							<!-- Annual Progress Meter (Debossed Rail + Pasted Strip) -->
							<div class="pl-2 mb-space-md">
								<div class="flex justify-between items-center mb-1">
									<span
										class="font-label-sm text-label-sm uppercase tracking-wider text-on-surface-variant font-bold"
									>
										Progresso Consolidado
									</span>
									<span class="font-label-md text-label-md font-bold" style="color: {objTheme.accentDark};">{pct}%</span>
								</div>
								<div
									class="w-full h-3 rounded-full bg-surface-container-high p-0.5 shadow-[inset_0_2px_4px_rgba(36,34,30,0.09)]"
								>
									<div
										class="h-full rounded-full transition-all duration-700 shadow-xs"
										style="width: {pct}%; background-color: {objTheme.accent};"
									></div>
								</div>
							</div>

							<!-- Card Bottom Footer / Metadata -->
							<div
								class="pt-space-sm pl-2 flex items-center justify-between border-t border-dashed border-outline-variant/50"
							>
								<div class="flex items-center gap-space-xs min-w-0">
									<div class="relative shrink-0">
										<div
											class="w-7 h-7 rounded-full flex items-center justify-center text-[10px] font-bold text-white shadow-[0_1px_2px_rgba(36,34,30,0.1)]"
											style="background-color: {leader?.color || '#0058bd'}"
										>
											{getInitials(leader?.name || teamNames)}
										</div>
										<span
											class="absolute -bottom-0.5 -right-0.5 w-2.5 h-2.5 rounded-full bg-primary ring-1 ring-white"
										></span>
									</div>
									<div class="flex flex-col min-w-0">
										<span class="font-label-sm text-label-sm font-bold text-on-surface truncate">
											{teamNames}
										</span>
										<span class="font-label-sm text-label-sm text-on-surface-variant truncate">
											{leader ? leader.name : 'Liderança Executiva'}
										</span>
									</div>
								</div>

								<div class="flex items-center gap-1 shrink-0">
									<span
										class="px-2 py-0.5 rounded bg-surface-container font-label-sm text-label-sm text-on-surface-variant"
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
					{:else}
						<!-- Compact Objective Preview Card (like OBJ-02 in Screenshot 1) -->
						<div
							role="button"
							tabindex="0"
							onclick={() => (focusedObjId = obj.id)}
							onkeydown={(e) => {
								if (e.key === 'Enter' || e.key === ' ') {
									e.preventDefault();
									focusedObjId = obj.id;
								}
							}}
							class="relative cursor-pointer bg-surface-container-lowest/75 hover:bg-surface-container-lowest rounded-xl p-space-md shadow-[0_1px_2px_rgba(36,34,30,0.04)] opacity-80 hover:opacity-100 transition-all {isDimmed
								? 'opacity-35'
								: ''}"
							style="border: 1px solid {objTheme.cardBorder};"
						>
							<div
								class="absolute left-0 top-3 bottom-3 w-1.5 rounded-r shadow-xs"
								style="background-color: {objTheme.accent};"
							></div>
							<div class="flex items-center justify-between gap-2 mb-1 pl-2">
								<span class="font-label-md text-label-md font-bold text-on-surface-variant">
									{code} · ANNUAL {obj.year ?? activeYear}
								</span>
								<span
									class="font-label-sm text-label-sm px-2 py-0.5 rounded font-bold shadow-xs"
									style="background-color: {objTheme.badgeBg}; color: {objTheme.badgeText}; border: 1px solid {objTheme.badgeBorder};"
								>
									{pct}%
								</span>
							</div>
							<h3 class="font-title-md text-title-md text-on-surface pl-2 line-clamp-1">
								{obj.title}
							</h3>
							<div
								class="mt-2 pl-2 flex items-center justify-between text-on-surface-variant font-body-sm text-body-sm"
							>
								<span class="truncate">{teamNames} · {krChildren.length} KRs</span>
								<div class="flex items-center gap-1">
									<button
										type="button"
										onclick={(e) => {
											e.stopPropagation();
											onSelectNode(obj.id);
										}}
										title="Abrir detalhes"
										class="p-0.5 rounded hover:bg-surface-container"
									>
										<span class="material-symbols-outlined text-[16px]">edit</span>
									</button>
									<span class="material-symbols-outlined text-[16px]">chevron_right</span>
								</div>
							</div>
						</div>
					{/if}
				{/each}
			</div>

			<!-- ================= COLUMN 2: KEY RESULTS (KRs) ================= -->
			<div class="col-span-4 flex flex-col gap-space-lg relative z-10">
				{#each displayedKRs as item (item.kr.id)}
					{@const kr = item.kr}
					{@const pct = Math.round(kr.progress * 100)}
					{@const isAtRisk = kr.atRisk || kr.status === 'at_risk' || kr.status === 'off_track'}
					{@const isSelected = selectedNodeId === kr.id}
					{@const isHighlighted = highlightedIds.has(kr.id)}
					{@const isDimmed = dimmedIds.has(kr.id)}
					{@const kpiCount = kr.children.filter(
						(c) => c.type === 'kpi' && visibleIds.has(c.id)
					).length}
					{@const owner = kr.assignees[0]}
					{@const krColor = kr.color || (isAtRisk ? '#be123c' : '#ca8a04')}
					{@const krTheme = getDossierTheme(krColor)}

					<!-- KR Pastel Tactile Dossier Card (Color reflects chosen theme) -->
					<div
						data-node-card={kr.id}
						role="button"
						tabindex="0"
						onclick={() => onSelectNode(kr.id)}
						onkeydown={(e) => {
							if (e.key === 'Enter' || e.key === ' ') {
								e.preventDefault();
								onSelectNode(kr.id);
							}
						}}
						class="relative cursor-pointer rounded-xl p-space-md shadow-[0_2px_6px_rgba(36,34,30,0.06),0_1px_0_rgba(255,255,255,0.8)_inset] hover:shadow-[0_8px_16px_rgba(36,34,30,0.09)] transition-all {isSelected
							? 'ring-2 ring-on-surface'
							: ''} {isHighlighted ? 'ring-2 ring-primary scale-[1.01]' : ''} {isDimmed
							? 'opacity-40'
							: ''}"
						style="background-color: {krTheme.folderBg}; border: 1.5px solid {krTheme.folderBorder}; color: {krTheme.accentDark};"
					>
						<!-- Tactile Folded Corner Tab -->
						<div
							class="absolute top-0 right-0 w-5 h-5 rounded-bl-lg shadow-[-1px_1px_2px_rgba(36,34,30,0.08)]"
							style="background-color: {krTheme.folderBorder};"
						></div>

						<div class="flex items-center justify-between gap-2 mb-2 pr-3">
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
							class="font-title-md text-title-md mb-space-sm leading-snug"
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

						<!-- Responsible & Duo-tone action -->
						<div
							class="flex items-center justify-between text-xs pt-1 border-t border-dashed"
							style="border-color: {krTheme.cardBorder};"
						>
							<div class="flex items-center gap-2 min-w-0">
								<div
									class="w-6 h-6 rounded-full flex items-center justify-center text-[9px] font-bold text-white shadow-[0_1px_2px_rgba(0,0,0,0.15)] shrink-0"
									style="background-color: {owner?.color || krTheme.accent};"
								>
									{getInitials(owner?.name || kr.teams[0]?.name || 'KR')}
								</div>
								<span class="font-label-sm text-label-sm font-bold truncate" style="color: {krTheme.accentShadow};">
									{owner?.name ?? kr.teams[0]?.name ?? 'Equipe Responsável'}
								</span>
							</div>
							<div class="flex items-center gap-1.5 shrink-0">
								<span class="font-label-sm text-label-sm font-semibold" style="color: {krTheme.accent};">
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
										class="p-0.5 rounded bg-white/70 hover:bg-white transition-colors"
										style="color: {krTheme.accentShadow};"
									>
										<span class="material-symbols-outlined text-[14px]">add</span>
									</button>
								{/if}
							</div>
						</div>
					</div>
				{:else}
					<div
						class="rounded-xl bg-surface-container-lowest/60 border border-dashed border-outline-variant p-6 text-center"
					>
						<p class="font-title-md text-title-md text-on-surface-variant">
							Nenhum Key Result neste objetivo
						</p>
						{#if canEdit && activeObj}
							<button
								type="button"
								onclick={() => onAddChild(activeObj)}
								class="mt-3 px-3 py-1.5 rounded-lg bg-secondary text-on-secondary font-label-sm text-label-sm font-bold shadow-[0_2px_0_#8d0051]"
							>
								+ Adicionar Key Result
							</button>
						{/if}
					</div>
				{/each}
			</div>

			<!-- ================= COLUMN 3: OPERATIONAL KPIS ================= -->
			<div class="col-span-4 flex flex-col gap-space-md relative z-10">
				{#each displayedKPIs as item, kIdx (item.kpi.id)}
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
						class="relative cursor-pointer rounded-xl p-space-md shadow-[0_2px_5px_rgba(36,34,30,0.05),0_1px_0_rgba(255,255,255,0.7)_inset] hover:shadow-[0_6px_14px_rgba(36,34,30,0.08)] transition-all {isSelected
							? 'ring-2 ring-on-surface'
							: ''} {isHighlighted ? 'ring-2 ring-primary scale-[1.01]' : ''} {isDimmed
							? 'opacity-40'
							: ''}"
						style="background-color: {kpiTheme.folderBg}; border: 1.5px solid {kpiTheme.folderBorder}; color: {kpiTheme.accentDark};"
					>
						<div class="flex items-center justify-between gap-2 mb-2">
							<div class="flex items-center gap-1.5">
								<span
									class="font-label-sm text-label-sm font-bold px-1.5 py-0.5 rounded shadow-xs"
									style="background-color: {kpiTheme.badgeBg}; color: {kpiTheme.badgeText}; border: 1px solid {kpiTheme.badgeBorder};"
								>
									{item.code}
								</span>
								<span
									class="font-label-sm text-label-sm uppercase tracking-wider font-semibold"
									style="color: {kpiTheme.accentDark};"
								>
									{kpi.cycle?.code ?? 'Operacional'}
								</span>
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

							<!-- Sparkline Mini Chart Visualizer -->
							<div class="flex items-center justify-between pt-1 border-t border-dashed" style="border-color: {kpiTheme.cardBorder};">
								<div class="flex items-center gap-1 text-[11px] truncate pr-2" style="color: {kpiTheme.accentDark};">
									<span class="material-symbols-outlined text-[14px]">history</span>
									<span class="truncate">
										{#if lastUpdate}
											Check-in: {lastUpdate.created_at.slice(0, 10)}{owner
												? ` por ${owner.name.split(' ')[0]}`
												: ''}
										{:else if owner}
											Responsável: {owner.name}
										{:else}
											Clique para registrar check-in
										{/if}
									</span>
								</div>
								<svg class="w-20 h-5 shrink-0" fill="none" viewBox="0 0 80 20">
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
				{:else}
					<div
						class="rounded-xl bg-surface-container-lowest/60 border border-dashed border-outline-variant p-6 text-center"
					>
						<p class="font-title-md text-title-md text-on-surface-variant">
							Nenhum indicador operacional vinculado
						</p>
						<p class="font-body-sm text-body-sm text-outline mt-1">
							Clique no botão + em um Key Result para adicionar um KPI.
						</p>
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

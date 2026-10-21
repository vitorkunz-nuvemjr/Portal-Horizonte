<script lang="ts">
	import type { NodeWithExtras } from '$lib/types';
	import { formatNumber, formatPct, getInitials, getTeamIcon } from '$lib/utils';
	import { valueColor } from '$lib/value-colors';
	import { getDossierTheme } from '$lib/dossier-theme';
	import {
		ChevronRight,
		ChevronDown,
		ChevronsDownUp,
		ChevronsUpDown,
		Target,
		Flag,
		Activity,
		Plus,
		AlertTriangle,
		Compass,
		Eye,
		EyeOff
	} from 'lucide-svelte';

	interface Props {
		roots: NodeWithExtras[];
		activeMission?: NodeWithExtras | null;
		visibleIds: Set<string>;
		highlightedIds: Set<string>;
		dimmedIds: Set<string>;
		selectedNodeId: string | null;
		collapsedIds: Set<string>;
		canEdit: boolean;
		onSelectNode: (id: string) => void;
		onAddChild: (parent: NodeWithExtras) => void;
		onToggleCollapse: (id: string) => void;
		onCollapseAll: () => void;
		onExpandAll: () => void;
	}

	let {
		roots,
		activeMission = null,
		visibleIds,
		highlightedIds,
		dimmedIds,
		selectedNodeId,
		collapsedIds,
		canEdit,
		onSelectNode,
		onAddChild,
		onToggleCollapse,
		onCollapseAll,
		onExpandAll
	}: Props = $props();

	const visibleRoots = $derived(roots.filter((r) => visibleIds.has(r.id)));
</script>

{#snippet renderTree(node: NodeWithExtras, depth: number)}
	{#if visibleIds.has(node.id)}
		{@const visibleChildren = node.children.filter((c) => visibleIds.has(c.id))}
		{@const isCollapsed = collapsedIds.has(node.id)}
		{@const isHighlighted = highlightedIds.has(node.id)}
		{@const isDimmed = dimmedIds.has(node.id)}
		{@const isSelected = selectedNodeId === node.id}
		{@const pct = Math.round(node.progress * 100)}
		{@const nodeColor = node.color || (node.teams[0]?.color || (node.type === 'objective' ? '#0058bd' : node.type === 'key_result' ? '#b30069' : '#00665a'))}
		{@const nodeTheme = getDossierTheme(nodeColor)}

		<div
			class="transition-opacity {isDimmed ? 'opacity-35 hover:opacity-80' : ''}"
			style="margin-left: {depth * 24}px"
		>
			<div
				role="button"
				tabindex="0"
				onclick={() => onSelectNode(node.id)}
				onkeydown={(e) => {
					if (e.key === 'Enter' || e.key === ' ') {
						e.preventDefault();
						onSelectNode(node.id);
					}
				}}
				class="group relative mb-2.5 flex items-center justify-between gap-4 rounded-xl px-4 py-3.5 shadow-[0_1px_1px_rgba(36,34,30,0.05),0_3px_6px_-1px_rgba(36,34,30,0.04),0_-1px_0_rgba(255,255,255,0.8)_inset] transition-all hover:shadow-[0_6px_14px_rgba(36,34,30,0.08)] {isSelected
					? 'ring-2 ring-primary'
					: ''} {isHighlighted ? 'ring-2 ring-tertiary-container' : ''}"
				style="background-color: {nodeTheme.folderBg}; border: 1.5px solid {nodeTheme.folderBorder};"
			>
				<!-- Left Spine Accent -->
				<div
					class="absolute left-0 top-2.5 bottom-2.5 w-1.5 rounded-r"
					style="background-color: {nodeTheme.accent};"
				></div>

				<!-- Left: Expand button + Type icon + Title + Meta -->
				<div class="flex min-w-0 flex-1 items-center gap-2.5 pl-1">
					{#if visibleChildren.length > 0}
						<button
							type="button"
							onclick={(e) => {
								e.stopPropagation();
								onToggleCollapse(node.id);
							}}
							title={isCollapsed
								? `Mostrar filhos (${visibleChildren.length})`
								: `Ocultar filhos (${visibleChildren.length})`}
							aria-expanded={!isCollapsed}
							class="rounded p-1 text-on-surface-variant hover:bg-surface-container hover:text-on-surface"
						>
							{#if isCollapsed}
								<ChevronRight class="h-4 w-4" />
							{:else}
								<ChevronDown class="h-4 w-4" />
							{/if}
						</button>
					{:else}
						<span class="w-6"></span>
					{/if}

					<!-- Type Badge -->
					{#if node.type === 'objective'}
						<span
							class="inline-flex shrink-0 items-center gap-1 rounded border px-2 py-0.5 font-label-sm text-label-sm font-bold uppercase"
							style="background-color: {nodeTheme.badgeBg}; border-color: {nodeTheme.badgeBorder}; color: {nodeTheme.badgeText};"
						>
							<Target class="h-3 w-3" />
							OBJ · {node.year}{node.quarter ? ` Q${node.quarter}` : ''}
						</span>
					{:else if node.type === 'key_result'}
						<span
							class="inline-flex shrink-0 items-center gap-1 rounded border px-2 py-0.5 font-label-sm text-label-sm font-bold uppercase"
							style="background-color: {nodeTheme.badgeBg}; border-color: {nodeTheme.badgeBorder}; color: {nodeTheme.badgeText};"
						>
							<Flag class="h-3 w-3" />
							KR {node.cycle ? `· ${node.cycle.code}` : ''}
						</span>
					{:else}
						<span
							class="inline-flex shrink-0 items-center gap-1 rounded border px-2 py-0.5 font-label-sm text-label-sm font-bold uppercase"
							style="background-color: {nodeTheme.badgeBg}; border-color: {nodeTheme.badgeBorder}; color: {nodeTheme.badgeText};"
						>
							<Activity class="h-3 w-3" />
							KPI
						</span>
					{/if}

					<div class="min-w-0 flex-1">
						<div class="flex items-center gap-2">
							<span
								class="truncate font-body-md text-body-md font-bold"
								style="color: {nodeTheme.accentShadow};"
							>
								{node.title}
							</span>
							{#if isCollapsed && visibleChildren.length > 0}
								<button
									type="button"
									onclick={(e) => {
										e.stopPropagation();
										onToggleCollapse(node.id);
									}}
									class="inline-flex shrink-0 items-center gap-1 rounded-full bg-primary px-2 py-0.5 font-label-sm text-label-sm font-bold text-on-primary"
									title="Mostrar filhos"
								>
									<ChevronRight class="h-2.5 w-2.5" />
									{visibleChildren.length} {visibleChildren.length === 1 ? 'oculto' : 'ocultos'}
								</button>
							{/if}
							{#if node.atRisk && node.status !== 'done'}
								<span
									class="inline-flex items-center gap-1 rounded-full bg-secondary-fixed px-2 py-0.5 font-label-sm text-label-sm font-bold text-on-secondary-fixed-variant"
								>
									<AlertTriangle class="h-3 w-3" />
									Em Risco
								</span>
							{/if}
						</div>
						{#if node.alignedValues.length > 0}
							<div class="mt-1 flex flex-wrap items-center gap-1">
								{#each node.alignedValues as val (val.id)}
									<span
										class="inline-flex items-center gap-1 rounded-full bg-surface-container px-2 py-0.5 font-label-sm text-label-sm text-on-surface-variant"
									>
										<span
											class="h-1.5 w-1.5 rounded-full"
											style="background-color: {valueColor(val.id)}"
										></span>
										{val.title}
									</span>
								{/each}
							</div>
						{/if}
						{#if (node.type === 'objective' || node.type === 'key_result') && node.teams && node.teams.length > 0}
							<div class="mt-1 flex flex-wrap items-center gap-1">
								{#each node.teams as t (t.id)}
									{@const tTheme = getDossierTheme(t.color || '#0058bd')}
									<span
										class="inline-flex items-center gap-1 rounded-full border px-2 py-0.5 font-label-sm text-label-sm font-bold"
										style="background-color: {tTheme.badgeBg}; border-color: {tTheme.badgeBorder}; color: {tTheme.badgeText};"
										title="Equipe: {t.name}"
									>
										<span
											class="material-symbols-outlined text-[13px] shrink-0"
											style="color: {tTheme.accent};"
										>
											{getTeamIcon(t)}
										</span>
										<span class="max-w-[120px] truncate">{t.name}</span>
									</span>
								{/each}
							</div>
						{/if}
					</div>
				</div>

				<!-- Right: KPI Metrics / Progress + Assignees + Quick Add -->
				<div class="flex shrink-0 items-center gap-4">
					{#if node.type === 'kpi'}
						<div class="text-right text-xs">
							<div class="font-bold" style="color: {nodeTheme.accentShadow};">
								{formatNumber(node.current_value, node.unit)}
								<span class="font-medium" style="color: {nodeTheme.accentDark};">
									/ {formatNumber(node.target_value, node.unit)}
								</span>
							</div>
							<div class="text-[10px] font-semibold" style="color: {nodeTheme.accent};">
								Base: {formatNumber(node.baseline, node.unit)}
							</div>
						</div>
					{/if}

					<div class="w-28">
						<div class="flex justify-between font-label-sm text-label-sm font-bold" style="color: {nodeTheme.accentShadow};">
							<span>{formatPct(node.progress)}</span>
						</div>
						<div
							class="mt-1 h-2.5 w-full overflow-hidden rounded-full p-0.5 shadow-[inset_0_1px_2px_rgba(36,34,30,0.08)]"
							style="background-color: {nodeTheme.badgeBg}; border: 1px solid {nodeTheme.badgeBorder};"
						>
							<div
								class="h-full rounded-full"
								style="width: {pct}%; background-color: {nodeTheme.accent};"
							></div>
						</div>
					</div>

					<!-- Teams & Assignees -->
					<div class="flex items-center gap-1.5 justify-end min-w-[32px]">
						{#if node.type === 'kpi' && node.teams && node.teams.length > 0}
							<div class="flex items-center gap-1">
								{#each node.teams.slice(0, 1) as t (t.id)}
									{@const tTheme = getDossierTheme(t.color || '#0058bd')}
									<span
										class="inline-flex items-center gap-1 rounded-full border px-2 py-0.5 font-label-sm text-label-sm font-bold"
										style="background-color: {tTheme.badgeBg}; border-color: {tTheme.badgeBorder}; color: {tTheme.badgeText};"
										title="Equipe: {t.name}"
									>
										<span
											class="material-symbols-outlined text-[13px] shrink-0"
											style="color: {tTheme.accent};"
										>
											{getTeamIcon(t)}
										</span>
										<span class="max-w-[68px] truncate">{t.name}</span>
									</span>
								{/each}
							</div>
						{/if}
						<div class="flex -space-x-1.5">
							{#each node.assignees.slice(0, 3) as person (person.id)}
								<span
									class="inline-flex h-6 w-6 items-center justify-center rounded-full text-[10px] font-bold text-white ring-2 ring-surface-container-lowest"
									style="background-color: {person.color || '#0058bd'}"
									title={person.name}
								>
									{getInitials(person.name)}
								</span>
							{/each}
						</div>
					</div>

					{#if visibleChildren.length > 0}
						<button
							type="button"
							onclick={(e) => {
								e.stopPropagation();
								onToggleCollapse(node.id);
							}}
							class="inline-flex items-center gap-1 rounded-lg px-2.5 py-1 font-label-sm text-label-sm font-bold transition {isCollapsed
								? 'bg-primary text-on-primary shadow-sm'
								: 'bg-surface-container text-on-surface-variant hover:bg-surface-container-high hover:text-on-surface'}"
							title={isCollapsed
								? `Mostrar ${visibleChildren.length} ${visibleChildren.length === 1 ? 'item filho' : 'itens filhos'}`
								: `Ocultar ${visibleChildren.length} ${visibleChildren.length === 1 ? 'item filho' : 'itens filhos'}`}
							aria-expanded={!isCollapsed}
						>
							{#if isCollapsed}
								<Eye class="h-3.5 w-3.5" />
								Mostrar ({visibleChildren.length})
							{:else}
								<EyeOff class="h-3.5 w-3.5" />
								Ocultar ({visibleChildren.length})
							{/if}
						</button>
					{/if}

					{#if canEdit && (node.type === 'objective' || node.type === 'key_result')}
						<button
							type="button"
							onclick={(e) => {
								e.stopPropagation();
								onAddChild(node);
							}}
							class="inline-flex items-center gap-1 rounded-lg bg-surface-container px-2.5 py-1 font-label-sm text-label-sm font-bold text-on-surface hover:bg-primary hover:text-on-primary transition-colors"
						>
							<Plus class="h-3.5 w-3.5" />
							{node.type === 'objective' ? 'KR' : 'KPI'}
						</button>
					{:else}
						<span class="w-12"></span>
					{/if}
				</div>
			</div>

			{#if !isCollapsed && visibleChildren.length > 0}
				{#each visibleChildren as child (child.id)}
					{@render renderTree(child, depth + 1)}
				{/each}
			{/if}
		</div>
	{/if}
{/snippet}

<div class="w-full">
	{#if visibleRoots.length > 0}
		<div class="mb-4 flex items-center justify-between gap-2">
			<span class="font-label-sm text-label-sm uppercase tracking-widest text-on-surface-variant font-bold">
				Livro-Razão Hierárquico (Visão em Lista)
			</span>
			<div class="flex items-center gap-1.5">
				<button
					type="button"
					onclick={onExpandAll}
					disabled={collapsedIds.size === 0}
					class="inline-flex items-center gap-1 rounded-lg bg-surface-container-lowest px-2.5 py-1 font-label-sm text-label-sm font-bold text-on-surface shadow-xs transition hover:bg-surface-container disabled:cursor-not-allowed disabled:opacity-40"
				>
					<ChevronsUpDown class="h-3.5 w-3.5" />
					Expandir tudo
				</button>
				<button
					type="button"
					onclick={onCollapseAll}
					class="inline-flex items-center gap-1 rounded-lg bg-surface-container-lowest px-2.5 py-1 font-label-sm text-label-sm font-bold text-on-surface shadow-xs transition hover:bg-surface-container"
				>
					<ChevronsDownUp class="h-3.5 w-3.5" />
					Recolher filhos
				</button>
			</div>
		</div>
	{/if}

	{#if !activeMission || !collapsedIds.has(activeMission.id)}
		{#each roots as root (root.id)}
			{@render renderTree(root, 0)}
		{:else}
			<div
				class="rounded-2xl border border-dashed border-outline-variant bg-surface-container-lowest p-12 text-center"
			>
				<p class="font-title-md text-title-md text-on-surface">
					Nenhum objetivo estratégico cadastrado ainda
				</p>
				<p class="mt-1 font-body-sm text-body-sm text-on-surface-variant">
					Clique em "+ Novo Objetivo" na barra superior para começar a construir sua árvore estratégica.
				</p>
			</div>
		{/each}
	{/if}
</div>

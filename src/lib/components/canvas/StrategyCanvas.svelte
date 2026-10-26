<script lang="ts">
	import {
		SvelteFlow,
		Controls,
		MiniMap,
		Background,
		BackgroundVariant,
		type Node,
		type Edge,
		type NodeTypes
	} from '@xyflow/svelte';
	import '@xyflow/svelte/dist/style.css';
	import { writable } from 'svelte/store';
	import StrategyNodeCard from './StrategyNodeCard.svelte';
	import StrategyMissionCard from './StrategyMissionCard.svelte';
	import { layoutNodes } from './layout';
	import type { NodeWithExtras } from '$lib/types';
	import { ArrowDownUp, ArrowLeftRight, ChevronsDownUp, ChevronsUpDown } from 'lucide-svelte';

	interface Props {
		visibleNodes: NodeWithExtras[];
		activeMission?: NodeWithExtras | null;
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
		visibleNodes,
		activeMission = null,
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

	let direction = $state<'TB' | 'LR'>('TB');

	const nodeTypes: NodeTypes = {
		strategyCard: StrategyNodeCard as unknown as NodeTypes[string],
		missionCard: StrategyMissionCard as unknown as NodeTypes[string]
	};

	const visibleSet = $derived(new Set(visibleNodes.map((n) => n.id)));
	const nodeById = $derived(new Map(visibleNodes.map((n) => [n.id, n])));

	const childCountById = $derived.by(() => {
		const counts = new Map<string, number>();
		if (activeMission) {
			const rootObjs = visibleNodes.filter(
				(n) => n.type === 'objective' && n.parent_id == null
			).length;
			counts.set(activeMission.id, rootObjs);
		}
		for (const n of visibleNodes) {
			if (n.parent_id && visibleSet.has(n.parent_id)) {
				counts.set(n.parent_id, (counts.get(n.parent_id) ?? 0) + 1);
			}
		}
		return counts;
	});

	// Filter out nodes whose ancestors are collapsed
	const canvasNodes = $derived.by<NodeWithExtras[]>(() => {
		if (activeMission && collapsedIds.has(activeMission.id)) {
			return [];
		}
		return visibleNodes.filter((n) => {
			let cur = n.parent_id;
			while (cur && visibleSet.has(cur)) {
				if (collapsedIds.has(cur)) return false;
				cur = nodeById.get(cur)?.parent_id ?? null;
			}
			return true;
		});
	});

	const canvasSet = $derived(new Set(canvasNodes.map((n) => n.id)));

	const rawEdges = $derived.by<Edge[]>(() => {
		const list: Edge[] = [];

		// Connect active Mission to top-level Annual Objectives
		if (activeMission) {
			const rootObjectives = canvasNodes.filter(
				(n) => n.type === 'objective' && n.parent_id == null
			);
			for (const obj of rootObjectives) {
				const isObjHighlighted = highlightedIds.has(obj.id);
				list.push({
					id: `e-mission-${activeMission.id}-${obj.id}`,
					source: activeMission.id,
					target: obj.id,
					animated: isObjHighlighted,
					style: isObjHighlighted
						? 'stroke: #f59e0b; stroke-width: 2.5px;'
						: 'stroke: #0f172a; stroke-width: 2px; stroke-dasharray: 4 2;'
				});
			}
		}

		// Connect parent strategy nodes to child strategy nodes
		for (const n of canvasNodes) {
			if (n.parent_id && canvasSet.has(n.parent_id)) {
				const isDimmed = dimmedIds.has(n.id) && dimmedIds.has(n.parent_id);
				const isHighlighted = highlightedIds.has(n.id) || highlightedIds.has(n.parent_id);
				list.push({
					id: `e-${n.parent_id}-${n.id}`,
					source: n.parent_id,
					target: n.id,
					animated: isHighlighted,
					style: isDimmed
						? 'stroke: #cbd5e1; stroke-width: 1.5px; opacity: 0.3;'
						: isHighlighted
							? 'stroke: #f59e0b; stroke-width: 2.5px;'
							: 'stroke: #94a3b8; stroke-width: 2px;'
				});
			}
		}
		return list;
	});

	const laidOutNodes = $derived.by<Node[]>(() => {
		const rawNodes: Node[] = [];

		// Add active Mission card at the root if available
		if (activeMission && visibleNodes.length > 0) {
			rawNodes.push({
				id: activeMission.id,
				type: 'missionCard',
				position: { x: 0, y: 0 },
				data: {
					node: activeMission,
					direction,
					childCount: childCountById.get(activeMission.id) ?? 0,
					collapsed: collapsedIds.has(activeMission.id),
					onSelect: onSelectNode,
					onToggleCollapse
				}
			});
		}

		// Add all non-collapsed visible strategy nodes
		for (const n of canvasNodes) {
			rawNodes.push({
				id: n.id,
				type: 'strategyCard',
				position: { x: 0, y: 0 },
				data: {
					node: n,
					highlighted: highlightedIds.has(n.id),
					dimmed: dimmedIds.has(n.id),
					selected: selectedNodeId === n.id,
					canEdit,
					direction,
					childCount: childCountById.get(n.id) ?? 0,
					collapsed: collapsedIds.has(n.id),
					onSelect: onSelectNode,
					onAddChild,
					onToggleCollapse
				}
			});
		}

		return layoutNodes(rawNodes, rawEdges, direction);
	});

	const flowNodes = writable<Node[]>([]);
	const flowEdges = writable<Edge[]>([]);

	$effect(() => {
		flowNodes.set(laidOutNodes);
		flowEdges.set(rawEdges);
	});
</script>

<div class="relative h-full w-full bg-surface-container-low">
	<!-- Direction & Collapse Switcher Overlay -->
	<div
		class="absolute top-2 right-2 sm:top-3 sm:right-3 z-10 flex items-center gap-1 max-w-[calc(100vw-36px)] overflow-x-auto no-scrollbar rounded-xl bg-surface-container-lowest p-1 sm:p-1.5 shadow-[0_2px_8px_rgba(36,34,30,0.08)]"
	>
		<button
			type="button"
			onclick={onExpandAll}
			disabled={collapsedIds.size === 0}
			class="flex items-center gap-1 rounded-lg px-2.5 py-1 font-label-sm text-label-sm font-bold text-on-surface-variant transition hover:bg-surface-container hover:text-on-surface disabled:cursor-not-allowed disabled:opacity-40"
			title="Expandir todos os nós"
		>
			<ChevronsUpDown class="h-3.5 w-3.5" />
			Expandir
		</button>
		<button
			type="button"
			onclick={onCollapseAll}
			class="flex items-center gap-1 rounded-lg px-2.5 py-1 font-label-sm text-label-sm font-bold text-on-surface-variant transition hover:bg-surface-container hover:text-on-surface"
			title="Recolher filhos de todos os Objetivos e Resultados-Chave"
		>
			<ChevronsDownUp class="h-3.5 w-3.5" />
			Recolher
		</button>

		<div class="mx-0.5 h-4 w-px bg-outline-variant/60"></div>

		<button
			type="button"
			onclick={() => (direction = 'TB')}
			class="flex items-center gap-1 rounded-lg px-2.5 py-1 font-label-sm text-label-sm font-bold transition {direction ===
			'TB'
				? 'bg-primary text-on-primary shadow-xs'
				: 'text-on-surface-variant hover:bg-surface-container hover:text-on-surface'}"
			title="Hierarquia Vertical (Cima para Baixo)"
		>
			<ArrowDownUp class="h-3.5 w-3.5" />
			Vertical
		</button>
		<button
			type="button"
			onclick={() => (direction = 'LR')}
			class="flex items-center gap-1 rounded-lg px-2.5 py-1 font-label-sm text-label-sm font-bold transition {direction ===
			'LR'
				? 'bg-primary text-on-primary shadow-xs'
				: 'text-on-surface-variant hover:bg-surface-container hover:text-on-surface'}"
			title="Hierarquia Horizontal (Esquerda para Direita)"
		>
			<ArrowLeftRight class="h-3.5 w-3.5" />
			Horizontal
		</button>
	</div>

	{#if visibleNodes.length === 0}
		<div class="flex h-full flex-col items-center justify-center p-8 text-center">
			<p class="font-title-md text-title-md text-on-surface">
				Nenhum nó estratégico corresponde ao filtro atual
			</p>
			<p class="mt-1 font-body-sm text-body-sm text-on-surface-variant">
				Tente selecionar outros anos/semestres ou desativar o modo Estrito.
			</p>
		</div>
	{:else}
		<SvelteFlow
			nodes={flowNodes}
			edges={flowEdges}
			{nodeTypes}
			fitView
			minZoom={0.2}
			maxZoom={1.5}
			class="h-full w-full"
		>
			<Background variant={BackgroundVariant.Dots} gap={24} size={1.5} />
			<Controls />
			<MiniMap zoomable pannable />
		</SvelteFlow>
	{/if}
</div>

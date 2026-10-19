import dagre from '@dagrejs/dagre';
import type { Edge, Node } from '@xyflow/svelte';

export const NODE_W = 290;
export const NODE_H = 148;

export const MISSION_NODE_W = 560;
export const MISSION_NODE_H = 110;

export function layoutNodes<T extends Record<string, unknown>>(
	nodes: Node<T>[],
	edges: Edge[],
	direction: 'TB' | 'LR' = 'TB'
): Node<T>[] {
	if (nodes.length === 0) return [];

	const g = new dagre.graphlib.Graph();
	g.setDefaultEdgeLabel(() => ({}));
	g.setGraph({
		rankdir: direction,
		nodesep: direction === 'TB' ? 42 : 36,
		ranksep: direction === 'TB' ? 84 : 96,
		marginx: 40,
		marginy: 40
	});

	const dimensions = new Map<string, { w: number; h: number }>();

	for (const n of nodes) {
		const isMission = n.type === 'missionCard';
		const w = isMission ? MISSION_NODE_W : NODE_W;
		const h = isMission ? MISSION_NODE_H : NODE_H;
		dimensions.set(n.id, { w, h });
		g.setNode(n.id, { width: w, height: h });
	}

	for (const e of edges) {
		g.setEdge(e.source, e.target);
	}

	dagre.layout(g);

	return nodes.map((n) => {
		const p = g.node(n.id);
		const dim = dimensions.get(n.id) ?? { w: NODE_W, h: NODE_H };
		if (!p) return n;
		return {
			...n,
			position: {
				x: Math.round(p.x - dim.w / 2),
				y: Math.round(p.y - dim.h / 2)
			}
		};
	});
}

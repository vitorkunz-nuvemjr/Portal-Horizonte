import type {
	Cycle,
	CycleFilter,
	MetricUpdate,
	Node,
	NodeAssignee,
	NodeTeam,
	NodeValue,
	NodeWithExtras,
	Profile,
	StrategicEra,
	Team,
	TeamMember
} from './types';

/**
 * §13.1 KPI progress
 */
export function kpiProgress(n: Node): number {
	if (n.type !== 'kpi' || n.current_value == null) return 0;
	const { baseline, target_value, current_value, direction } = n;
	if (baseline == null || target_value == null || baseline === target_value) return 0;
	const raw = (current_value - baseline) / (target_value - baseline);
	// Note: when direction === 'down' (e.g. reducing churn from 10% baseline to 2% target),
	// target_value - baseline is negative (-8). If current_value is 6%, (6 - 10) / (2 - 10) = +0.5.
	// However, if baseline > target_value is not set or user sets positive delta, we support both:
	// Follow exact spec if target_value > baseline with 'down', or natural ratio when target_value < baseline.
	if (direction === 'down' && target_value > baseline) {
		return Math.min(1, Math.max(0, -raw));
	}
	return Math.min(1, Math.max(0, raw));
}

/**
 * §13.2 Rollup with memoization by updated_at signature
 */
const progressCache = new Map<string, number>();

function nodeSignature(n: NodeWithExtras): string {
	const childSigs = n.children.map(nodeSignature).join('|');
	return `${n.id}:${n.updated_at}:${n.current_value}:${n.manual_progress}:${n.weight}:[${childSigs}]`;
}

export function computeProgress(n: NodeWithExtras): number {
	const sig = nodeSignature(n);
	const cached = progressCache.get(sig);
	if (cached !== undefined) return cached;

	let result = 0;
	if (n.type === 'kpi') {
		result = kpiProgress(n);
	} else if (n.type === 'key_result' || n.type === 'objective') {
		const targetChildType = n.type === 'objective' ? 'key_result' : 'kpi';
		let children = n.children.filter((c) => c.type === targetChildType);
		// Fallback if an objective has direct KPIs and no KRs
		if (n.type === 'objective' && children.length === 0) {
			children = n.children.filter((c) => c.type === 'kpi');
		}
		if (children.length === 0) {
			result = n.manual_progress ?? 0;
		} else {
			const total = children.reduce((s, c) => s + (c.weight || 1), 0);
			result =
				total > 0
					? children.reduce((s, c) => s + computeProgress(c) * (c.weight || 1), 0) / total
					: 0;
		}
	}

	progressCache.set(sig, result);
	return result;
}

/**
 * §13.3 At-risk detection for cycle-scoped nodes (KRs / KPIs)
 */
export function isAtRisk(n: NodeWithExtras, cycle: Cycle | null, nowMs: number = Date.now()): boolean {
	if (n.status === 'done') return false;
	if (n.status === 'at_risk' || n.status === 'off_track') return true;
	if (!cycle) return false;
	const start = +new Date(cycle.start_date);
	const end = +new Date(cycle.end_date);
	if (nowMs < start || nowMs > end || end <= start) return false;
	const elapsed = (nowMs - start) / (end - start);
	return computeProgress(n) + 0.2 < elapsed;
}

/**
 * §13.3 At-risk detection for annual objectives
 */
export function isObjectiveAtRisk(n: NodeWithExtras, nowMs: number = Date.now()): boolean {
	if (n.type !== 'objective' || n.status === 'done') return false;
	if (n.status === 'at_risk' || n.status === 'off_track') return true;
	if (!n.year) return false;
	const yearStart = new Date(n.year, 0, 1).getTime();
	const yearEnd = new Date(n.year, 11, 31, 23, 59, 59).getTime();
	if (nowMs < yearStart || nowMs > yearEnd) return false;
	const elapsed = (nowMs - yearStart) / (yearEnd - yearStart);
	return computeProgress(n) + 0.2 < elapsed;
}

/**
 * §13.4 Cycle filter predicate
 */
export function filterVisible(nodes: Node[], cycles: Cycle[], filter: CycleFilter): Set<string> {
	const cycleById = new Map(cycles.map((c) => [c.id, c]));
	const visible = new Set<string>();

	const rootVisible = (n: Node) => {
		if (n.type === 'objective') {
			return filter.years.length === 0 || (n.year != null && filter.years.includes(n.year));
		}
		if (n.type === 'mission') return filter.includePermanent;
		return true;
	};

	for (const n of nodes) {
		if (n.parent_id == null && rootVisible(n)) {
			visible.add(n.id);
		}
	}

	let changed = true;
	while (changed) {
		changed = false;
		for (const n of nodes) {
			if (n.parent_id == null || !visible.has(n.parent_id)) continue;
			if (visible.has(n.id)) continue;
			if (filter.strict && n.cycle_id) {
				const c = cycleById.get(n.cycle_id);
				const yearMatch = filter.years.length === 0 || (c != null && filter.years.includes(c.year));
				const semMatch =
					filter.semesters.length === 0 || (c != null && filter.semesters.includes(c.semester));
				if (!c || !yearMatch || !semMatch) continue;
			}
			visible.add(n.id);
			changed = true;
		}
	}
	return visible;
}

/**
 * §13.5 Value lens
 */
export function applyValueLens(
	nodes: Node[],
	nodeValues: { node_id: string; value_id: string }[],
	lensValueId: string | null
): { highlighted: Set<string>; dimmed: Set<string> } {
	if (!lensValueId) return { highlighted: new Set(), dimmed: new Set() };
	const highlighted = new Set<string>(
		nodeValues.filter((nv) => nv.value_id === lensValueId).map((nv) => nv.node_id)
	);
	const dimmed = new Set<string>(
		nodes.filter((n) => n.tree === 'strategy' && !highlighted.has(n.id)).map((n) => n.id)
	);
	return { highlighted, dimmed };
}

/**
 * Helper to enrich flat DB rows into a rich tree of NodeWithExtras
 */
export function enrichNodes(
	nodes: Node[],
	assigns: NodeAssignee[],
	nodeValues: NodeValue[],
	profiles: Profile[],
	cycles: Cycle[],
	metricUpdates: MetricUpdate[] = [],
	teams: Team[] = [],
	teamMembers: TeamMember[] = [],
	nodeTeams: NodeTeam[] = []
): {
	byId: Map<string, NodeWithExtras>;
	strategyRoots: NodeWithExtras[];
	identityRoots: NodeWithExtras[];
	valuesList: NodeWithExtras[];
	eras: StrategicEra[];
	profilesWithTeams: Profile[];
} {
	const teamById = new Map(teams.map((t) => [t.id, t]));

	// Enrich profiles with their member teams
	const userTeamsMap = new Map<string, Team[]>();
	for (const tm of teamMembers) {
		const team = teamById.get(tm.team_id);
		if (team) {
			if (!userTeamsMap.has(tm.user_id)) userTeamsMap.set(tm.user_id, []);
			userTeamsMap.get(tm.user_id)!.push(team);
		}
	}

	const profilesWithTeams: Profile[] = profiles.map((p) => ({
		...p,
		teams: userTeamsMap.get(p.id) ?? []
	}));

	const profileById = new Map(profilesWithTeams.map((p) => [p.id, p]));
	const cycleById = new Map(cycles.map((c) => [c.id, c]));
	const nodeById = new Map(nodes.map((n) => [n.id, n]));

	const byId = new Map<string, NodeWithExtras>();

	// Sort nodes by sort_order then created_at
	const sorted = [...nodes].sort((a, b) => {
		if (a.sort_order !== b.sort_order) return a.sort_order - b.sort_order;
		return a.created_at.localeCompare(b.created_at);
	});

	for (const n of sorted) {
		const effectiveCycleId =
			n.cycle_id ?? (n.parent_id ? nodeById.get(n.parent_id)?.cycle_id ?? null : null);
		const cycle = effectiveCycleId ? cycleById.get(effectiveCycleId) ?? null : null;

		byId.set(n.id, {
			...n,
			children: [],
			assignees: [],
			teams: [],
			alignedValues: [],
			cycle,
			metricUpdates: [],
			progress: 0,
			atRisk: false
		});
	}

	// Attach assignees (individual users)
	for (const a of assigns) {
		const node = byId.get(a.node_id);
		const prof = profileById.get(a.user_id);
		if (node && prof) {
			node.assignees.push(prof);
		}
	}

	// Attach assigned teams (departments)
	for (const nt of nodeTeams) {
		const node = byId.get(nt.node_id);
		const team = teamById.get(nt.team_id);
		if (node && team) {
			node.teams.push(team);
		}
	}

	// Attach aligned values
	for (const nv of nodeValues) {
		const node = byId.get(nv.node_id);
		const valNode = nodeById.get(nv.value_id);
		if (node && valNode) {
			node.alignedValues.push(valNode);
		}
	}

	// Attach metric updates (sorted newest first)
	const sortedMetrics = [...metricUpdates].sort((a, b) =>
		b.created_at.localeCompare(a.created_at)
	);
	for (const mu of sortedMetrics) {
		const node = byId.get(mu.node_id);
		if (node) {
			node.metricUpdates.push(mu);
		}
	}

	// Build parent-child hierarchy
	const strategyRoots: NodeWithExtras[] = [];
	const identityRoots: NodeWithExtras[] = [];
	const valuesList: NodeWithExtras[] = [];

	for (const n of sorted) {
		const rich = byId.get(n.id)!;
		if (n.type === 'value') {
			valuesList.push(rich);
		}
		if (n.parent_id && byId.has(n.parent_id)) {
			byId.get(n.parent_id)!.children.push(rich);
		} else if (n.tree === 'strategy') {
			strategyRoots.push(rich);
		} else if (n.tree === 'identity') {
			identityRoots.push(rich);
		}
	}

	// Compute progress & at-risk bottom-up
	const finalize = (node: NodeWithExtras) => {
		for (const child of node.children) {
			finalize(child);
		}
		node.progress = computeProgress(node);
		node.atRisk =
			node.type === 'objective'
				? isObjectiveAtRisk(node)
				: node.type === 'key_result' || node.type === 'kpi'
					? isAtRisk(node, node.cycle)
					: false;
	};

	for (const r of strategyRoots) finalize(r);
	for (const r of identityRoots) finalize(r);

	const eras = groupEras(identityRoots, valuesList);

	return { byId, strategyRoots, identityRoots, valuesList, eras, profilesWithTeams };
}

/**
 * Returns the active Mission node for a given calendar year.
 */
export function getActiveMissionForYear(
	identityRoots: NodeWithExtras[],
	year: number
): NodeWithExtras | null {
	const missions = identityRoots.filter((n) => n.type === 'mission');
	if (missions.length === 0) return null;

	const matching = missions.find(
		(m) =>
			(m.start_year == null || m.start_year <= year) &&
			(m.end_year == null || m.end_year >= year)
	);
	if (matching) return matching;

	// Fallback: active mission (end_year is null) or the closest by year
	const active = missions.find((m) => m.end_year == null);
	if (active) return active;

	return [...missions].sort((a, b) => (b.start_year ?? 0) - (a.start_year ?? 0))[0] ?? null;
}

/**
 * Returns the active Core Values for the filtered set of years.
 */
export function getActiveValuesForYears(
	valuesList: NodeWithExtras[],
	years: number[]
): NodeWithExtras[] {
	if (years.length === 0) return valuesList;
	return valuesList.filter((v) =>
		years.some(
			(yr) =>
				(v.start_year == null || v.start_year <= yr) &&
				(v.end_year == null || v.end_year >= yr)
		)
	);
}

/**
 * Groups identity nodes into structured StrategicEras (e.g. 2024–Present, 2021–2023)
 */
export function groupEras(
	identityRoots: NodeWithExtras[],
	valuesList: NodeWithExtras[]
): import('./types').StrategicEra[] {
	const missions = identityRoots.filter((n) => n.type === 'mission');
	const eras: import('./types').StrategicEra[] = [];

	for (const m of missions) {
		const start_year = m.start_year ?? 2024;
		const end_year = m.end_year ?? null;
		const isCurrent = end_year == null;
		const key = `${start_year}-${end_year ?? 'present'}`;
		const label = isCurrent
			? `Era Ativa (${start_year}–Presente)`
			: `Ciclo Estratégico (${start_year}–${end_year})`;

		// Values under this mission or matching the era year window
		const values = valuesList.filter(
			(v) =>
				v.parent_id === m.id ||
				((v.start_year == null || v.start_year <= (end_year ?? 9999)) &&
					(v.end_year == null ? isCurrent : v.end_year >= start_year))
		);

		eras.push({
			id: m.id,
			key,
			label,
			start_year,
			end_year,
			isCurrent,
			mission: m,
			values
		});
	}

	// Sort eras newest first (active/current on top)
	return eras.sort((a, b) => {
		if (a.isCurrent && !b.isCurrent) return -1;
		if (!a.isCurrent && b.isCurrent) return 1;
		return b.start_year - a.start_year;
	});
}

/**
 * Checks if a team represents cross-cutting / transversal team ("Todas as Diretorias")
 */
export function isTransversalTeam(team: { id: string; name?: string | null }): boolean {
	if (team.id === 't-todas') return true;
	if (team.name && (team.name.toLowerCase().includes('todas') || team.name.toLowerCase().includes('geral'))) {
		return true;
	}
	return false;
}

/**
 * Determines if a node is associated with a given teamId.
 * - For specific teams (e.g. t-comercial): requires strict and direct team assignment
 *   on the node (node.teams.some(t => t.id === teamId)).
 * - For transversal team ('t-todas'): matches nodes directly assigned to 't-todas' or transversal.
 * - For child KPIs without explicit teams: inherits from parent KR.
 */
export function nodeMatchesTeam(
	node: NodeWithExtras,
	teamId: string,
	byId?: Map<string, NodeWithExtras>
): boolean {
	if (!teamId || teamId === 'all') return true;

	// 1. Filter specifically for transversal team ("Todas as Diretorias")
	if (teamId === 't-todas') {
		return node.teams.some((t) => t.id === 't-todas' || isTransversalTeam(t));
	}

	// 2. Strict direct team assignment on this node
	if (node.teams.some((t) => t.id === teamId)) {
		return true;
	}

	// 3. Child KPI without explicit teams inherits from parent KR
	if (node.type === 'kpi' && node.parent_id && byId) {
		const parent = byId.get(node.parent_id);
		if (parent && node.teams.length === 0 && nodeMatchesTeam(parent, teamId, byId)) {
			return true;
		}
	}

	return false;
}

/**
 * Determines if a node is associated with a given userId.
 * Supports:
 * - Direct node assignees (node_assignees)
 * - Creator fallback only when node has no assignees
 * - Child KPI inheritance from parent KR
 */
export function nodeMatchesUser(
	node: NodeWithExtras,
	userId: string,
	byId?: Map<string, NodeWithExtras>
): boolean {
	if (!userId || userId === 'all') return true;

	// 1. Direct assignee
	if (node.assignees.some((a) => a.id === userId)) {
		return true;
	}

	// 2. Creator fallback only if node has no assignees
	if (node.assignees.length === 0 && node.created_by === userId) {
		return true;
	}

	// 3. KPI inherits from parent KR
	if (node.type === 'kpi' && node.parent_id && byId) {
		const parent = byId.get(node.parent_id);
		if (parent && nodeMatchesUser(parent, userId, byId)) return true;
	}

	return false;
}

/**
 * Filters strategy nodes by search query, team, and user,
 * keeping ancestor objectives intact for UI hierarchy while preventing
 * foreign KRs/KPIs of other departments/users from leaking into the view.
 */
export function filterStrategyNodes(
	enriched: { byId: Map<string, NodeWithExtras> },
	baseVisible: Set<string>,
	options: {
		searchQuery?: string;
		teamId?: string;
		userId?: string;
	}
): Set<string> {
	const q = options.searchQuery?.trim().toLowerCase() ?? '';
	const teamId = options.teamId ?? 'all';
	const userId = options.userId ?? 'all';

	const hasTeamFilter = teamId !== 'all';
	const hasUserFilter = userId !== 'all';
	const hasQuery = q.length > 0;

	if (!hasTeamFilter && !hasUserFilter && !hasQuery) {
		return baseVisible;
	}

	const matched = new Set<string>();

	for (const id of baseVisible) {
		const n = enriched.byId.get(id);
		if (!n) continue;

		const mSearch =
			!hasQuery ||
			n.title.toLowerCase().includes(q) ||
			Boolean(n.description && n.description.toLowerCase().includes(q));

		const mTeam = nodeMatchesTeam(n, teamId, enriched.byId);
		const mUser = nodeMatchesUser(n, userId, enriched.byId);

		if (mSearch && mTeam && mUser) {
			matched.add(n.id);

			// Preserve ancestors for visual hierarchy
			let cur = n.parent_id;
			while (cur) {
				matched.add(cur);
				cur = enriched.byId.get(cur)?.parent_id ?? null;
			}

			// If Key Result matched, include child KPIs that match user filter
			if (n.type === 'key_result') {
				for (const child of n.children) {
					if (baseVisible.has(child.id) && nodeMatchesUser(child, userId, enriched.byId)) {
						matched.add(child.id);
					}
				}
			}

			// If Objective matched via pure search query (no team or user filter active),
			// keep child KRs and KPIs for search navigation
			if (n.type === 'objective' && !hasTeamFilter && !hasUserFilter) {
				for (const child of n.children) {
					if (baseVisible.has(child.id)) {
						matched.add(child.id);
						for (const kpi of child.children) {
							if (baseVisible.has(kpi.id)) matched.add(kpi.id);
						}
					}
				}
			}
		}
	}

	return matched;
}


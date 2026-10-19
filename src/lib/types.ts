export type NodeTree = 'strategy' | 'identity';
export type NodeType = 'objective' | 'key_result' | 'kpi' | 'mission' | 'value';
export type NodeStatus = 'not_started' | 'on_track' | 'at_risk' | 'off_track' | 'done';
export type UserRole = 'admin' | 'member' | 'viewer';
export type KpiDirection = 'up' | 'down';

export interface Team {
	id: string;
	name: string;
	description: string | null;
	color: string | null;
	created_at: string;
}

export interface TeamMember {
	team_id: string;
	user_id: string;
}

export interface Profile {
	id: string;
	name: string;
	email?: string;
	role: UserRole;
	color: string | null;
	teams?: Team[];
	created_at: string;
}

export interface Cycle {
	id: string;
	code: string;
	year: number;
	semester: 1 | 2;
	start_date: string;
	end_date: string;
	created_at: string;
}

export interface StrategyNode {
	id: string;
	parent_id: string | null;
	tree: NodeTree;
	type: NodeType;
	title: string;
	description: string | null;

	// Scope columns
	year: number | null;
	quarter: 1 | 2 | 3 | 4 | null;
	cycle_id: string | null;

	// Temporal era scoping for Mission & Values (e.g. 2024–2026 or 2024–present)
	start_year: number | null;
	end_year: number | null;

	status: NodeStatus;
	weight: number;
	sort_order: number;

	// KPI-only
	unit: string | null;
	baseline: number | null;
	target_value: number | null;
	current_value: number | null;
	direction: KpiDirection | null;

	// Manual override (for KRs without KPIs)
	manual_progress: number | null;

	// Meta
	created_by: string | null;
	created_at: string;
	updated_at: string;
}

// Alias for compatibility with plan snippets
export type Node = StrategyNode;

export interface NodeAssignee {
	node_id: string;
	user_id: string;
}

export interface NodeTeam {
	node_id: string;
	team_id: string;
}

export interface NodeValue {
	node_id: string;
	value_id: string;
}

export interface MetricUpdate {
	id: string;
	node_id: string;
	value: number;
	note: string | null;
	user_id: string | null;
	created_at: string;
}

export interface NodeWithExtras extends StrategyNode {
	children: NodeWithExtras[];
	assignees: Profile[];
	teams: Team[];
	alignedValues: StrategyNode[];
	cycle: Cycle | null;
	metricUpdates: MetricUpdate[];
	progress: number;
	atRisk: boolean;
}

export interface StrategicEra {
	id: string;
	key: string;
	label: string;
	start_year: number;
	end_year: number | null;
	isCurrent: boolean;
	mission: NodeWithExtras | null;
	values: NodeWithExtras[];
}

export interface CycleFilter {
	years: number[];
	semesters: number[];
	strict: boolean;
	includePermanent: boolean;
}

export interface DatabaseSnapshot {
	version: number;
	exported_at: string;
	profiles: Profile[];
	teams: Team[];
	team_members: TeamMember[];
	cycles: Cycle[];
	nodes: StrategyNode[];
	node_assignees: NodeAssignee[];
	node_teams: NodeTeam[];
	node_values: NodeValue[];
	metric_updates: MetricUpdate[];
}

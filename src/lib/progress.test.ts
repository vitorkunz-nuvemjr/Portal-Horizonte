import { describe, expect, it } from 'vitest';
import {
	applyValueLens,
	computeProgress,
	enrichNodes,
	filterVisible,
	getActiveMissionForYear,
	getActiveValuesForYears,
	groupEras,
	isAtRisk,
	isObjectiveAtRisk,
	kpiProgress,
	nodeMatchesTeam,
	nodeMatchesUser,
	filterStrategyNodes
} from './progress';
import type { Cycle, Node, NodeWithExtras } from './types';

function makeNode(overrides: Partial<Node> & { id: string; type: Node['type'] }): Node {
	return {
		parent_id: null,
		tree: overrides.type === 'mission' || overrides.type === 'value' ? 'identity' : 'strategy',
		title: overrides.id,
		description: null,
		year: overrides.type === 'objective' ? 2026 : null,
		quarter: null,
		cycle_id: null,
		start_year: null,
		end_year: null,
		status: 'on_track',
		weight: 1,
		sort_order: 1,
		unit: null,
		baseline: null,
		target_value: null,
		current_value: null,
		direction: 'up',
		manual_progress: null,
		created_by: null,
		created_at: '2026-01-01T00:00:00.000Z',
		updated_at: '2026-01-01T00:00:00.000Z',
		...overrides
	};
}

describe('progress business logic (§13)', () => {
	it('computes kpiProgress for up and down directions', () => {
		const upKpi = makeNode({
			id: 'k1',
			type: 'kpi',
			baseline: 100,
			target_value: 200,
			current_value: 150,
			direction: 'up'
		});
		expect(kpiProgress(upKpi)).toBeCloseTo(0.5);

		const downKpi = makeNode({
			id: 'k2',
			type: 'kpi',
			baseline: 60,
			target_value: 40,
			current_value: 45,
			direction: 'down'
		});
		expect(kpiProgress(downKpi)).toBeCloseTo(0.75);
	});

	it('rolls up weighted progress from KPI -> KR -> Objective', () => {
		const obj = makeNode({ id: 'obj-1', type: 'objective', year: 2026 });
		const kr1 = makeNode({ id: 'kr-1', type: 'key_result', parent_id: 'obj-1', weight: 1 });
		const kr2 = makeNode({
			id: 'kr-2',
			type: 'key_result',
			parent_id: 'obj-1',
			weight: 3,
			manual_progress: 0.8
		});
		const kpi1 = makeNode({
			id: 'kpi-1',
			type: 'kpi',
			parent_id: 'kr-1',
			baseline: 0,
			target_value: 100,
			current_value: 40,
			direction: 'up'
		});

		const { byId } = enrichNodes([obj, kr1, kr2, kpi1], [], [], [], []);
		const richObj = byId.get('obj-1')!;
		expect(computeProgress(byId.get('kr-1')!)).toBeCloseTo(0.4);
		expect(computeProgress(byId.get('kr-2')!)).toBeCloseTo(0.8);
		// Weighted average: (0.4 * 1 + 0.8 * 3) / 4 = 2.8 / 4 = 0.7
		expect(richObj.progress).toBeCloseTo(0.7);
	});

	it('detects at-risk KRs and annual objectives based on elapsed time', () => {
		const cycle: Cycle = {
			id: 'c1',
			code: '2026-S2',
			year: 2026,
			semester: 2,
			start_date: '2026-07-01',
			end_date: '2026-12-31',
			created_at: '2026-01-01T00:00:00.000Z'
		};
		const kr = makeNode({
			id: 'kr-1',
			type: 'key_result',
			cycle_id: 'c1',
			manual_progress: 0.1
		});
		const { byId } = enrichNodes([kr], [], [], [], [cycle]);
		const richKr = byId.get('kr-1') as NodeWithExtras;

		// Mid-October (~60% elapsed): 0.1 + 0.2 < 0.6 => at risk
		const octMs = new Date('2026-10-18T12:00:00Z').getTime();
		expect(isAtRisk(richKr, cycle, octMs)).toBe(true);

		const obj = makeNode({
			id: 'obj-1',
			type: 'objective',
			year: 2026,
			manual_progress: 0.2
		});
		const { byId: objMap } = enrichNodes([obj], [], [], [], []);
		expect(isObjectiveAtRisk(objMap.get('obj-1')!, octMs)).toBe(true);
	});

	it('filters visible nodes by year and strict semester cycle', () => {
		const c1: Cycle = {
			id: 'c-s1',
			code: '2026-S1',
			year: 2026,
			semester: 1,
			start_date: '2026-01-01',
			end_date: '2026-06-30',
			created_at: ''
		};
		const c2: Cycle = {
			id: 'c-s2',
			code: '2026-S2',
			year: 2026,
			semester: 2,
			start_date: '2026-07-01',
			end_date: '2026-12-31',
			created_at: ''
		};
		const obj2026 = makeNode({ id: 'o26', type: 'objective', year: 2026 });
		const krS1 = makeNode({ id: 'kr1', type: 'key_result', parent_id: 'o26', cycle_id: 'c-s1' });
		const krS2 = makeNode({ id: 'kr2', type: 'key_result', parent_id: 'o26', cycle_id: 'c-s2' });

		const visibleStrictS2 = filterVisible([obj2026, krS1, krS2], [c1, c2], {
			years: [2026],
			semesters: [2],
			strict: true,
			includePermanent: false
		});

		expect(visibleStrictS2.has('o26')).toBe(true);
		expect(visibleStrictS2.has('kr1')).toBe(false);
		expect(visibleStrictS2.has('kr2')).toBe(true);
	});

	it('applies value lens highlighting and dimming', () => {
		const n1 = makeNode({ id: 'n1', type: 'objective', year: 2026 });
		const n2 = makeNode({ id: 'n2', type: 'key_result', parent_id: 'n1' });
		const { highlighted, dimmed } = applyValueLens(
			[n1, n2],
			[{ node_id: 'n1', value_id: 'val-1' }],
			'val-1'
		);
		expect(highlighted.has('n1')).toBe(true);
		expect(dimmed.has('n2')).toBe(true);
	});

	it('resolves active mission and core values across strategic eras', () => {
		const missionCurrent = makeNode({
			id: 'm-current',
			type: 'mission',
			start_year: 2024,
			end_year: null
		});
		const missionHistorical = makeNode({
			id: 'm-past',
			type: 'mission',
			start_year: 2021,
			end_year: 2023
		});
		const valCurrent = makeNode({
			id: 'v-current',
			type: 'value',
			parent_id: 'm-current',
			start_year: 2024,
			end_year: null
		});
		const valPast = makeNode({
			id: 'v-past',
			type: 'value',
			parent_id: 'm-past',
			start_year: 2021,
			end_year: 2023
		});

		const { identityRoots, valuesList, eras } = enrichNodes(
			[missionCurrent, missionHistorical, valCurrent, valPast],
			[],
			[],
			[],
			[]
		);

		// Year 2026 -> Current mission
		const m2026 = getActiveMissionForYear(identityRoots, 2026);
		expect(m2026?.id).toBe('m-current');

		// Year 2022 -> Past mission
		const m2022 = getActiveMissionForYear(identityRoots, 2022);
		expect(m2022?.id).toBe('m-past');

		// Values active in 2026
		const vals2026 = getActiveValuesForYears(valuesList, [2026]);
		expect(vals2026.map((v) => v.id)).toContain('v-current');
		expect(vals2026.map((v) => v.id)).not.toContain('v-past');

		// StrategicEras grouping
		expect(eras.length).toBe(2);
		expect(eras[0].isCurrent).toBe(true);
		expect(eras[0].key).toBe('2024-present');
		expect(eras[1].isCurrent).toBe(false);
		expect(eras[1].key).toBe('2021-2023');
	});

	it('supports multi-team membership and assigning both teams and members to nodes', () => {
		const obj = makeNode({ id: 'obj-test', type: 'objective', year: 2026 });
		const kr = makeNode({ id: 'kr-test', type: 'key_result', parent_id: 'obj-test' });

		const teamSales = {
			id: 't-sales',
			name: 'Sales',
			description: 'Sales team',
			color: '#059669',
			created_at: '2026-01-01T00:00:00Z'
		};
		const teamProjects = {
			id: 't-proj',
			name: 'Projects',
			description: 'Projects team',
			color: '#7c3aed',
			created_at: '2026-01-01T00:00:00Z'
		};

		const userAlice = {
			id: 'u-alice',
			name: 'Alice',
			role: 'member' as const,
			color: '#2563eb',
			created_at: '2026-01-01T00:00:00Z'
		};
		const userBob = {
			id: 'u-bob',
			name: 'Bob (Unassigned)',
			role: 'viewer' as const,
			color: '#64748b',
			created_at: '2026-01-01T00:00:00Z'
		};

		// Alice belongs to both Sales and Projects, Bob belongs to none
		const teamMembers = [
			{ team_id: 't-sales', user_id: 'u-alice' },
			{ team_id: 't-proj', user_id: 'u-alice' }
		];

		// Node obj-test is assigned to Sales team AND Alice directly
		// Node kr-test is assigned only to Projects team
		const assigns = [{ node_id: 'obj-test', user_id: 'u-alice' }];
		const nodeTeams = [
			{ node_id: 'obj-test', team_id: 't-sales' },
			{ node_id: 'kr-test', team_id: 't-proj' }
		];

		const enriched = enrichNodes(
			[obj, kr],
			assigns,
			[],
			[userAlice, userBob],
			[],
			[],
			[teamSales, teamProjects],
			teamMembers,
			nodeTeams
		);

		// Alice has both teams
		const enrichedAlice = enriched.profilesWithTeams.find((p) => p.id === 'u-alice');
		expect(enrichedAlice?.teams?.length).toBe(2);
		expect(enrichedAlice?.teams?.map((t) => t.id)).toContain('t-sales');
		expect(enrichedAlice?.teams?.map((t) => t.id)).toContain('t-proj');

		// Bob has 0 teams (unassigned)
		const enrichedBob = enriched.profilesWithTeams.find((p) => p.id === 'u-bob');
		expect(enrichedBob?.teams?.length).toBe(0);

		// Node obj-test has both team 't-sales' and assignee 'Alice'
		const richObj = enriched.byId.get('obj-test')!;
		expect(richObj.teams.length).toBe(1);
		expect(richObj.teams[0].id).toBe('t-sales');
		expect(richObj.assignees.length).toBe(1);
		expect(richObj.assignees[0].id).toBe('u-alice');

		// Node kr-test has team 't-proj' and 0 assignees
		const richKr = enriched.byId.get('kr-test')!;
		expect(richKr.teams.length).toBe(1);
		expect(richKr.teams[0].id).toBe('t-proj');
		expect(richKr.assignees.length).toBe(0);
	});

	it('strictly isolates KRs by team and user and prevents descendant leakage', () => {
		// Multi-team corporate objective (e.g. Sales + Projects)
		const corpObj = makeNode({ id: 'obj-corp', type: 'objective', year: 2026 });
		const krSales = makeNode({ id: 'kr-sales', type: 'key_result', parent_id: 'obj-corp' });
		const kpiSales = makeNode({ id: 'kpi-sales', type: 'kpi', parent_id: 'kr-sales', baseline: 0, target_value: 100, current_value: 50 });
		const krProj = makeNode({ id: 'kr-proj', type: 'key_result', parent_id: 'obj-corp' });
		const kpiProj = makeNode({ id: 'kpi-proj', type: 'kpi', parent_id: 'kr-proj', baseline: 0, target_value: 10, current_value: 2 });
		const krTrans = makeNode({ id: 'kr-trans', type: 'key_result', parent_id: 'obj-corp' });

		const teamSales = { id: 't-sales', name: 'Comercial', color: '#059669', created_at: '2026-01-01T00:00:00Z', description: null };
		const teamProj = { id: 't-proj', name: 'Projetos', color: '#7c3aed', created_at: '2026-01-01T00:00:00Z', description: null };
		const teamTodas = { id: 't-todas', name: 'Todas as Diretorias', color: '#64748b', created_at: '2026-01-01T00:00:00Z', description: null };

		const userAlice = { id: 'u-alice', name: 'Alice', role: 'member' as const, color: '#2563eb', created_at: '2026-01-01T00:00:00Z' };
		const userBob = { id: 'u-bob', name: 'Bob', role: 'member' as const, color: '#dc2626', created_at: '2026-01-01T00:00:00Z' };

		const nodeTeams = [
			{ node_id: 'obj-corp', team_id: 't-sales' },
			{ node_id: 'obj-corp', team_id: 't-proj' },
			{ node_id: 'kr-sales', team_id: 't-sales' },
			{ node_id: 'kr-proj', team_id: 't-proj' },
			{ node_id: 'kr-trans', team_id: 't-todas' }
		];

		const assigns = [
			{ node_id: 'kr-sales', user_id: 'u-alice' },
			{ node_id: 'kr-proj', user_id: 'u-bob' }
		];

		const enriched = enrichNodes(
			[corpObj, krSales, kpiSales, krProj, kpiProj, krTrans],
			assigns,
			[],
			[userAlice, userBob],
			[],
			[],
			[teamSales, teamProj, teamTodas],
			[{ team_id: 't-sales', user_id: 'u-alice' }, { team_id: 't-proj', user_id: 'u-bob' }],
			nodeTeams
		);

		const baseVisible = new Set(['obj-corp', 'kr-sales', 'kpi-sales', 'kr-proj', 'kpi-proj', 'kr-trans']);

		// 1. Filter by Projects team:
		// Expect: obj-corp (ancestor), kr-proj, kpi-proj, kr-trans (transversal).
		// Must NOT contain kr-sales or kpi-sales!
		const projResult = filterStrategyNodes(enriched, baseVisible, { teamId: 't-proj' });
		expect(projResult.has('obj-corp')).toBe(true);
		expect(projResult.has('kr-proj')).toBe(true);
		expect(projResult.has('kpi-proj')).toBe(true);
		expect(projResult.has('kr-trans')).toBe(true);
		expect(projResult.has('kr-sales')).toBe(false);
		expect(projResult.has('kpi-sales')).toBe(false);

		// 2. Filter by Sales team:
		// Expect: obj-corp (ancestor), kr-sales, kpi-sales, kr-trans.
		// Must NOT contain kr-proj or kpi-proj!
		const salesResult = filterStrategyNodes(enriched, baseVisible, { teamId: 't-sales' });
		expect(salesResult.has('obj-corp')).toBe(true);
		expect(salesResult.has('kr-sales')).toBe(true);
		expect(salesResult.has('kpi-sales')).toBe(true);
		expect(salesResult.has('kr-trans')).toBe(true);
		expect(salesResult.has('kr-proj')).toBe(false);
		expect(salesResult.has('kpi-proj')).toBe(false);

		// 3. Filter by User Alice (Sales member):
		// Expect: obj-corp (ancestor), kr-sales, kpi-sales.
		const aliceResult = filterStrategyNodes(enriched, baseVisible, { userId: 'u-alice' });
		expect(aliceResult.has('obj-corp')).toBe(true);
		expect(aliceResult.has('kr-sales')).toBe(true);
		expect(aliceResult.has('kpi-sales')).toBe(true);
		expect(aliceResult.has('kr-proj')).toBe(false);
		expect(aliceResult.has('kr-trans')).toBe(false);

		// 4. Combined Filter: Sales team + Bob (Bob is in Projects, not Sales):
		// Expect empty
		const mismatchResult = filterStrategyNodes(enriched, baseVisible, { teamId: 't-sales', userId: 'u-bob' });
		expect(mismatchResult.size).toBe(0);

		// 5. Pure search query "Projetos"
		const searchResult = filterStrategyNodes(enriched, baseVisible, { searchQuery: 'sales' });
		expect(searchResult.has('kr-sales')).toBe(true);
		expect(searchResult.has('kpi-sales')).toBe(true);
		expect(searchResult.has('kr-proj')).toBe(false);
	});
});

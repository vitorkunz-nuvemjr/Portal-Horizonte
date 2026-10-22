import { redirect } from '@sveltejs/kit';
import type { LayoutServerLoad } from './$types';
import type { StrategyNode } from '$lib/types';

export const load: LayoutServerLoad = async ({ locals }) => {
	const { user } = await locals.safeGetSession();
	if (!user) {
		throw redirect(303, '/login');
	}

	if (locals.supabase) {
		const selectNodesWithIcon =
			'id, parent_id, tree, type, title, description, color, icon, year, quarter, cycle_id, start_year, end_year, status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_by, created_at, updated_at';
		const selectNodesWithoutIcon =
			'id, parent_id, tree, type, title, description, color, year, quarter, cycle_id, start_year, end_year, status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_by, created_at, updated_at';

		const nodesPromise = locals.supabase.from('nodes').select(selectNodesWithIcon);
		const teamsPromise = locals.supabase.from('teams').select('id, name, description, color, icon, created_at');
		const profilesPromise = locals.supabase.from('profiles').select('id, name, email, role, color, avatar_url, created_at');

		const [assigns, values, cycles, metricUpdates, teamMembers, nodeTeams] = await Promise.all([
			locals.supabase.from('node_assignees').select('node_id, user_id'),
			locals.supabase.from('node_values').select('node_id, value_id'),
			locals.supabase.from('cycles').select('*').order('code', { ascending: true }),
			locals.supabase
				.from('metric_updates')
				.select('id, node_id, value, note, user_id, created_at')
				.order('created_at', { ascending: false })
				.limit(200),
			locals.supabase.from('team_members').select('team_id, user_id'),
			locals.supabase.from('node_teams').select('node_id, team_id')
		]);

		let nodes = await nodesPromise;
		if (nodes.error && nodes.error.message?.includes('icon')) {
			nodes = await locals.supabase.from('nodes').select(selectNodesWithoutIcon);
		}

		let teams = await teamsPromise;
		if (teams.error && teams.error.message?.includes('icon')) {
			teams = await locals.supabase.from('teams').select('id, name, description, color, created_at');
		}

		let profiles = await profilesPromise;
		if (profiles.error && profiles.error.message?.includes('avatar_url')) {
			profiles = await locals.supabase.from('profiles').select('id, name, email, role, color, created_at');
		}

		if (nodes.error) console.error('[Supabase Load] Error fetching nodes:', nodes.error);
		if (teams.error) console.error('[Supabase Load] Error fetching teams:', teams.error);
		if (profiles.error) console.error('[Supabase Load] Error fetching profiles:', profiles.error);
		if (cycles.error) console.error('[Supabase Load] Error fetching cycles:', cycles.error);
		if (teamMembers.error) console.error('[Supabase Load] Error fetching team_members:', teamMembers.error);
		if (nodeTeams.error) console.error('[Supabase Load] Error fetching node_teams:', nodeTeams.error);
		if (assigns.error) console.error('[Supabase Load] Error fetching node_assignees:', assigns.error);
		if (values.error) console.error('[Supabase Load] Error fetching node_values:', values.error);

		return {
			user,
			mode: 'supabase' as const,
			nodes: (nodes.data ?? []) as StrategyNode[],
			assigns: assigns.data ?? [],
			values: values.data ?? [],
			cycles: cycles.data ?? [],
			profiles: profiles.data ?? [],
			metricUpdates: metricUpdates.data ?? [],
			teams: teams.data ?? [],
			teamMembers: teamMembers.data ?? [],
			nodeTeams: nodeTeams.data ?? []
		};
	}

	return {
		user,
		mode: 'supabase' as const,
		nodes: [] as StrategyNode[],
		assigns: [],
		values: [],
		cycles: [],
		profiles: [],
		metricUpdates: [],
		teams: [],
		teamMembers: [],
		nodeTeams: []
	};
};

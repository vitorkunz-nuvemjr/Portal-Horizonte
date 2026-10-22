import { redirect } from '@sveltejs/kit';
import type { LayoutServerLoad } from './$types';
import { readDb } from '$lib/server/store';

export const load: LayoutServerLoad = async ({ locals }) => {
	const { user } = await locals.safeGetSession();
	if (!user) {
		throw redirect(303, '/login');
	}

	if (locals.mode === 'supabase' && locals.supabase) {
		const [nodes, assigns, values, cycles, profiles, metricUpdates, teams, teamMembers, nodeTeams] = await Promise.all([
			locals.supabase
				.from('nodes')
				.select(
					'id, parent_id, tree, type, title, description, color, year, quarter, cycle_id, start_year, end_year, status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_by, created_at, updated_at'
				),
			locals.supabase.from('node_assignees').select('node_id, user_id'),
			locals.supabase.from('node_values').select('node_id, value_id'),
			locals.supabase.from('cycles').select('*').order('code', { ascending: true }),
			locals.supabase.from('profiles').select('id, name, email, role, color, avatar_url, created_at'),
			locals.supabase
				.from('metric_updates')
				.select('id, node_id, value, note, user_id, created_at')
				.order('created_at', { ascending: false })
				.limit(200),
			locals.supabase.from('teams').select('id, name, description, color, icon, created_at'),
			locals.supabase.from('team_members').select('team_id, user_id'),
			locals.supabase.from('node_teams').select('node_id, team_id')
		]);

		return {
			user,
			mode: locals.mode,
			nodes: nodes.data ?? [],
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

	const db = readDb();
	return {
		user,
		mode: locals.mode,
		nodes: db.nodes,
		assigns: db.node_assignees,
		values: db.node_values,
		cycles: db.cycles,
		profiles: db.profiles,
		metricUpdates: db.metric_updates,
		teams: db.teams ?? [],
		teamMembers: db.team_members ?? [],
		nodeTeams: db.node_teams ?? []
	};
};

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
			locals.supabase.from('nodes').select('*'),
			locals.supabase.from('node_assignees').select('*'),
			locals.supabase.from('node_values').select('*'),
			locals.supabase.from('cycles').select('*').order('code', { ascending: true }),
			locals.supabase.from('profiles').select('*'),
			locals.supabase
				.from('metric_updates')
				.select('*')
				.order('created_at', { ascending: false }),
			locals.supabase.from('teams').select('*'),
			locals.supabase.from('team_members').select('*'),
			locals.supabase.from('node_teams').select('*')
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

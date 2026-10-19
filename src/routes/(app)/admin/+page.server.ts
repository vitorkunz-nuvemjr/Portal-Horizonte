import { fail } from '@sveltejs/kit';
import type { Actions, PageServerLoad } from './$types';
import {
	createCycleRecord,
	createTeamRecord,
	deleteCycleRecord,
	deleteTeamRecord,
	importDatabaseSnapshot,
	readDb,
	resetToSeedTemplate,
	setUserTeamsRecord,
	updateTeamRecord,
	upsertProfileRecord
} from '$lib/server/store';
import type { UserRole } from '$lib/types';

export const load: PageServerLoad = async ({ locals }) => {
	if (locals.mode === 'supabase' && locals.supabase) {
		const [nodes, assigns, values, cycles, profiles, metricUpdates, teams, teamMembers, nodeTeams] =
			await Promise.all([
				locals.supabase.from('nodes').select('*'),
				locals.supabase.from('node_assignees').select('*'),
				locals.supabase.from('node_values').select('*'),
				locals.supabase.from('cycles').select('*').order('code', { ascending: true }),
				locals.supabase.from('profiles').select('*'),
				locals.supabase.from('metric_updates').select('*'),
				locals.supabase.from('teams').select('*'),
				locals.supabase.from('team_members').select('*'),
				locals.supabase.from('node_teams').select('*')
			]);

		const snapshot = {
			version: 4,
			exported_at: new Date().toISOString(),
			profiles: profiles.data ?? [],
			teams: teams.data ?? [],
			team_members: teamMembers.data ?? [],
			cycles: cycles.data ?? [],
			nodes: nodes.data ?? [],
			node_assignees: assigns.data ?? [],
			node_teams: nodeTeams.data ?? [],
			node_values: values.data ?? [],
			metric_updates: metricUpdates.data ?? []
		};

		return {
			snapshotJson: JSON.stringify(snapshot, null, 2)
		};
	}

	const snapshot = readDb();
	return {
		snapshotJson: JSON.stringify(snapshot, null, 2)
	};
};

export const actions: Actions = {
	createUser: async ({ request, locals }) => {
		const { user } = await locals.safeGetSession();
		const formData = await request.formData();
		const name = (formData.get('name') as string) ?? '';
		const email = (formData.get('email') as string) ?? '';
		const role = ((formData.get('role') as UserRole) || 'member') as UserRole;
		const color = (formData.get('color') as string) || '#2563eb';

		if (locals.mode === 'supabase' && locals.supabase) {
			return fail(400, {
				message: 'No modo Supabase, os usuários criam suas contas pelo Auth do Supabase ou são convidados pelo painel.'
			});
		}

		try {
			upsertProfileRecord(user, { name, email, role, color });
			return { success: true, notice: `Usuário ${name} adicionado com sucesso.` };
		} catch (e: any) {
			return fail(400, { message: e?.message ?? 'Falha ao criar usuário.' });
		}
	},

	updateUserRole: async ({ request, locals }) => {
		const { user } = await locals.safeGetSession();
		const formData = await request.formData();
		const id = formData.get('id') as string;
		const name = formData.get('name') as string;
		const role = formData.get('role') as UserRole;

		const roleLabel =
			role === 'admin' ? 'Administrador' : role === 'member' ? 'Membro' : 'Visualizador';

		if (locals.mode === 'supabase' && locals.supabase) {
			try {
				const { error } = await locals.supabase.from('profiles').update({ role }).eq('id', id);
				if (error) return fail(400, { message: error.message });
				return { success: true, notice: `Cargo de ${name} atualizado para ${roleLabel}.` };
			} catch (e: any) {
				return fail(400, { message: e?.message ?? 'Falha ao atualizar cargo.' });
			}
		}

		try {
			upsertProfileRecord(user, { id, name, role });
			return { success: true, notice: `Cargo de ${name} atualizado para ${roleLabel}.` };
		} catch (e: any) {
			return fail(400, { message: e?.message ?? 'Falha ao atualizar cargo.' });
		}
	},

	updateUserTeams: async ({ request, locals }) => {
		const { user } = await locals.safeGetSession();
		const formData = await request.formData();
		const userId = formData.get('userId') as string;
		const teamIds = formData.getAll('teamIds').map(String);

		if (locals.mode === 'supabase' && locals.supabase) {
			try {
				await locals.supabase.from('team_members').delete().eq('user_id', userId);
				if (teamIds.length > 0) {
					await locals.supabase
						.from('team_members')
						.insert(teamIds.map((tid) => ({ team_id: tid, user_id: userId })));
				}
				return { success: true, notice: 'Vínculos de equipes do usuário atualizados.' };
			} catch (e: any) {
				return fail(400, { message: e?.message ?? 'Falha ao atualizar vínculos de equipes.' });
			}
		}

		try {
			setUserTeamsRecord(user, userId, teamIds);
			return { success: true, notice: 'Vínculos de equipes do usuário atualizados.' };
		} catch (e: any) {
			return fail(400, { message: e?.message ?? 'Falha ao atualizar vínculos de equipes.' });
		}
	},

	createTeam: async ({ request, locals }) => {
		const { user } = await locals.safeGetSession();
		const formData = await request.formData();
		const name = (formData.get('name') as string) ?? '';
		const description = (formData.get('description') as string) || null;
		const color = (formData.get('color') as string) || '#2563eb';

		if (locals.mode === 'supabase' && locals.supabase) {
			try {
				const { data, error } = await locals.supabase
					.from('teams')
					.insert({ name, description, color })
					.select()
					.single();
				if (error) return fail(400, { message: error.message });
				return { success: true, notice: `Equipe "${data.name}" criada com sucesso.` };
			} catch (e: any) {
				return fail(400, { message: e?.message ?? 'Falha ao criar equipe.' });
			}
		}

		try {
			const team = createTeamRecord(user, { name, description, color });
			return { success: true, notice: `Equipe "${team.name}" criada com sucesso.` };
		} catch (e: any) {
			return fail(400, { message: e?.message ?? 'Falha ao criar equipe.' });
		}
	},

	updateTeam: async ({ request, locals }) => {
		const { user } = await locals.safeGetSession();
		const formData = await request.formData();
		const teamId = formData.get('teamId') as string;
		const name = formData.get('name') as string;
		const description = (formData.get('description') as string) ?? null;
		const color = formData.get('color') as string;

		if (locals.mode === 'supabase' && locals.supabase) {
			try {
				const { error } = await locals.supabase
					.from('teams')
					.update({ name, description, color })
					.eq('id', teamId);
				if (error) return fail(400, { message: error.message });
				return { success: true, notice: `Equipe "${name}" atualizada com sucesso.` };
			} catch (e: any) {
				return fail(400, { message: e?.message ?? 'Falha ao atualizar equipe.' });
			}
		}

		try {
			const team = updateTeamRecord(user, teamId, { name, description, color });
			return { success: true, notice: `Equipe "${team.name}" atualizada com sucesso.` };
		} catch (e: any) {
			return fail(400, { message: e?.message ?? 'Falha ao atualizar equipe.' });
		}
	},

	deleteTeam: async ({ request, locals }) => {
		const { user } = await locals.safeGetSession();
		const formData = await request.formData();
		const teamId = formData.get('teamId') as string;

		if (locals.mode === 'supabase' && locals.supabase) {
			try {
				const { error } = await locals.supabase.from('teams').delete().eq('id', teamId);
				if (error) return fail(400, { message: error.message });
				return { success: true, notice: 'Equipe excluída e membros desvinculados.' };
			} catch (e: any) {
				return fail(400, { message: e?.message ?? 'Falha ao excluir equipe.' });
			}
		}

		try {
			deleteTeamRecord(user, teamId);
			return { success: true, notice: 'Equipe excluída e membros desvinculados.' };
		} catch (e: any) {
			return fail(400, { message: e?.message ?? 'Falha ao excluir equipe.' });
		}
	},

	createCycle: async ({ request, locals }) => {
		const { user } = await locals.safeGetSession();
		const formData = await request.formData();
		const year = Number(formData.get('year'));
		const semester = Number(formData.get('semester')) as 1 | 2;
		const start_date = formData.get('start_date') as string;
		const end_date = formData.get('end_date') as string;
		const code = `${year}-S${semester}`;

		if (locals.mode === 'supabase' && locals.supabase) {
			try {
				const { error } = await locals.supabase.from('cycles').insert({
					code,
					year,
					semester,
					start_date,
					end_date
				});
				if (error) return fail(400, { message: error.message });
				return { success: true, notice: `Ciclo ${code} criado com sucesso.` };
			} catch (e: any) {
				return fail(400, { message: e?.message ?? 'Falha ao criar ciclo.' });
			}
		}

		try {
			const c = createCycleRecord(user, { year, semester, start_date, end_date });
			return { success: true, notice: `Ciclo ${c.code} criado com sucesso.` };
		} catch (e: any) {
			return fail(400, { message: e?.message ?? 'Falha ao criar ciclo.' });
		}
	},

	deleteCycle: async ({ request, locals }) => {
		const { user } = await locals.safeGetSession();
		const formData = await request.formData();
		const cycleId = formData.get('cycleId') as string;

		if (locals.mode === 'supabase' && locals.supabase) {
			try {
				const { error } = await locals.supabase.from('cycles').delete().eq('id', cycleId);
				if (error) return fail(400, { message: error.message });
				return { success: true, notice: 'Ciclo excluído.' };
			} catch (e: any) {
				return fail(400, { message: e?.message ?? 'Falha ao excluir ciclo.' });
			}
		}

		try {
			deleteCycleRecord(user, cycleId);
			return { success: true, notice: 'Ciclo excluído.' };
		} catch (e: any) {
			return fail(400, { message: e?.message ?? 'Falha ao excluir ciclo.' });
		}
	},

	resetTemplate: async ({ locals }) => {
		const { user } = await locals.safeGetSession();
		if (user?.role !== 'admin') {
			return fail(403, { message: 'Apenas administradores podem restaurar o modelo estratégico padrão.' });
		}
		resetToSeedTemplate();
		return {
			success: true,
			notice: 'Modelo padrão do JE Strategy OS carregado com sucesso.'
		};
	},

	importJson: async ({ request, locals }) => {
		const { user } = await locals.safeGetSession();
		const formData = await request.formData();
		const jsonText = (formData.get('jsonText') as string) ?? '';

		try {
			importDatabaseSnapshot(user, jsonText);
			return { success: true, notice: 'Snapshot JSON importado com sucesso.' };
		} catch (e: any) {
			return fail(400, { message: e?.message ?? 'Falha ao importar JSON.' });
		}
	}
};

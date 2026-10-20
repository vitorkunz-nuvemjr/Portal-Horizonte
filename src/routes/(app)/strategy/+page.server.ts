import { fail } from '@sveltejs/kit';
import type { Actions } from './$types';
import {
	createNodeRecord,
	deleteNodeRecord,
	logMetricUpdateRecord,
	setNodeAssigneesRecord,
	setNodeTeamsRecord,
	setNodeValuesRecord,
	updateNodeRecord
} from '$lib/server/store';
import type { KpiDirection, NodeStatus, NodeType } from '$lib/types';

export const actions: Actions = {
	createNode: async ({ request, locals }) => {
		const { user } = await locals.safeGetSession();
		const formData = await request.formData();

		const type = (formData.get('type') as NodeType) || 'objective';
		const parent_id = ((formData.get('parentId') as string) || '').trim() || null;
		const title = ((formData.get('title') as string) || '').trim();
		const description = ((formData.get('description') as string) || '').trim() || null;
		const yearStr = formData.get('year') as string | null;
		const quarterStr = formData.get('quarter') as string | null;
		const cycle_id = ((formData.get('cycle_id') as string) || '').trim() || null;
		const unit = ((formData.get('unit') as string) || '').trim() || null;
		const baselineStr = formData.get('baseline') as string | null;
		const targetStr = formData.get('target_value') as string | null;
		const currentStr = formData.get('current_value') as string | null;
		const direction = ((formData.get('direction') as KpiDirection) || 'up') as KpiDirection;
		const color = ((formData.get('color') as string) || '').trim() || null;

		if (locals.mode === 'supabase' && locals.supabase) {
			try {
				const tree = type === 'mission' || type === 'value' ? 'identity' : 'strategy';
				const insertPayload: Record<string, any> = {
					parent_id,
					tree,
					type,
					title,
					description,
					color,
					year: yearStr ? Number(yearStr) : null,
					quarter: quarterStr ? Number(quarterStr) : null,
					cycle_id,
					unit,
					baseline: baselineStr != null && baselineStr !== '' ? Number(baselineStr) : null,
					target_value: targetStr != null && targetStr !== '' ? Number(targetStr) : null,
					current_value: currentStr != null && currentStr !== '' ? Number(currentStr) : null,
					direction,
					created_by: user?.id ?? null
				};

				let { data, error } = await locals.supabase
					.from('nodes')
					.insert(insertPayload)
					.select()
					.single();

				// Graceful schema fallback: if 'color' column doesn't exist yet in Supabase schema cache
				if (error && error.message?.includes('color') && 'color' in insertPayload) {
					delete insertPayload.color;
					const retry = await locals.supabase
						.from('nodes')
						.insert(insertPayload)
						.select()
						.single();
					data = retry.data;
					error = retry.error;
				}

				if (error) return fail(400, { message: error.message });
				return { success: true, createdId: data.id };
			} catch (e: any) {
				return fail(400, { message: e?.message ?? 'Falha ao criar item.' });
			}
		}

		try {
			const created = createNodeRecord(user, {
				parent_id,
				type,
				title,
				description,
				year: yearStr ? Number(yearStr) : null,
				quarter: quarterStr ? Number(quarterStr) : null,
				cycle_id,
				unit,
				baseline: baselineStr != null && baselineStr !== '' ? Number(baselineStr) : null,
				target_value: targetStr != null && targetStr !== '' ? Number(targetStr) : null,
				current_value: currentStr != null && currentStr !== '' ? Number(currentStr) : null,
				direction,
				color
			});
			return { success: true, createdId: created.id };
		} catch (e: any) {
			return fail(400, { message: e?.message ?? 'Falha ao criar item.' });
		}
	},

	updateNode: async ({ request, locals }) => {
		const { user } = await locals.safeGetSession();
		const formData = await request.formData();

		const nodeId = formData.get('nodeId') as string;
		const title = formData.get('title') as string;
		const description = (formData.get('description') as string) ?? null;
		const status = (formData.get('status') as NodeStatus) ?? 'not_started';
		const weightStr = formData.get('weight') as string | null;
		const yearStr = formData.get('year') as string | null;
		const quarterStr = formData.get('quarter') as string | null;
		const cycle_id = ((formData.get('cycle_id') as string) || '').trim() || null;
		const parent_id = ((formData.get('parent_id') as string) || '').trim() || null;
		const manualPctStr = formData.get('manual_progress_pct') as string | null;

		const unit = formData.get('unit') as string | null;
		const baselineStr = formData.get('baseline') as string | null;
		const targetStr = formData.get('target_value') as string | null;
		const direction = formData.get('direction') as KpiDirection | null;
		const color = formData.get('color') as string | null;

		if (locals.mode === 'supabase' && locals.supabase) {
			try {
				const payload: Record<string, any> = {
					title,
					description,
					status,
					weight: weightStr ? Number(weightStr) : 1,
					year: yearStr ? Number(yearStr) : null,
					quarter: quarterStr ? Number(quarterStr) : null,
					cycle_id,
					parent_id
				};
				if (manualPctStr != null && manualPctStr !== '') {
					payload.manual_progress = Math.max(0, Math.min(1, Number(manualPctStr) / 100));
				}
				if (unit !== null) payload.unit = unit.trim() || null;
				if (baselineStr != null && baselineStr !== '') payload.baseline = Number(baselineStr);
				if (targetStr != null && targetStr !== '') payload.target_value = Number(targetStr);
				if (direction) payload.direction = direction;
				if (color !== null) payload.color = color.trim() || null;

				let { error } = await locals.supabase.from('nodes').update(payload).eq('id', nodeId);

				// Graceful schema fallback: if 'color' column doesn't exist yet in Supabase schema cache
				if (error && error.message?.includes('color') && 'color' in payload) {
					delete payload.color;
					const retry = await locals.supabase.from('nodes').update(payload).eq('id', nodeId);
					error = retry.error;
				}

				if (error) return fail(400, { message: error.message });
				return { success: true };
			} catch (e: any) {
				return fail(400, { message: e?.message ?? 'Falha ao atualizar item.' });
			}
		}

		try {
			updateNodeRecord(user, nodeId, {
				title,
				description,
				status,
				weight: weightStr ? Number(weightStr) : 1,
				year: yearStr ? Number(yearStr) : null,
				quarter: quarterStr ? (Number(quarterStr) as 1 | 2 | 3 | 4) : null,
				cycle_id,
				parent_id,
				...(manualPctStr != null && manualPctStr !== ''
					? { manual_progress: Math.max(0, Math.min(1, Number(manualPctStr) / 100)) }
					: {}),
				...(unit !== null ? { unit: unit.trim() || null } : {}),
				...(baselineStr != null && baselineStr !== '' ? { baseline: Number(baselineStr) } : {}),
				...(targetStr != null && targetStr !== '' ? { target_value: Number(targetStr) } : {}),
				...(direction ? { direction } : {}),
				...(color !== null ? { color: color.trim() || null } : {})
			});
			return { success: true };
		} catch (e: any) {
			return fail(400, { message: e?.message ?? 'Falha ao atualizar item.' });
		}
	},

	deleteNode: async ({ request, locals }) => {
		const { user } = await locals.safeGetSession();
		const formData = await request.formData();
		const nodeId = formData.get('nodeId') as string;
		const promote = formData.get('promote') === '1';

		if (locals.mode === 'supabase' && locals.supabase) {
			try {
				if (promote) {
					const { data: targetNode } = await locals.supabase
						.from('nodes')
						.select('parent_id')
						.eq('id', nodeId)
						.single();
					const parentOfDeleted = targetNode?.parent_id ?? null;
					await locals.supabase
						.from('nodes')
						.update({ parent_id: parentOfDeleted })
						.eq('parent_id', nodeId);
				}
				const { error } = await locals.supabase.from('nodes').delete().eq('id', nodeId);
				if (error) return fail(400, { message: error.message });
				return { success: true, deletedId: nodeId };
			} catch (e: any) {
				return fail(400, { message: e?.message ?? 'Falha ao excluir item.' });
			}
		}

		try {
			deleteNodeRecord(user, nodeId, promote);
			return { success: true, deletedId: nodeId };
		} catch (e: any) {
			return fail(400, { message: e?.message ?? 'Falha ao excluir item.' });
		}
	},

	setValues: async ({ request, locals }) => {
		const { user } = await locals.safeGetSession();
		const formData = await request.formData();
		const nodeId = formData.get('nodeId') as string;
		const valueIds = formData.getAll('valueIds').map(String);

		if (locals.mode === 'supabase' && locals.supabase) {
			try {
				const { error: rpcErr } = await locals.supabase.rpc('set_node_values', {
					p_node: nodeId,
					p_values: valueIds
				});
				if (rpcErr) {
					await locals.supabase.from('node_values').delete().eq('node_id', nodeId);
					if (valueIds.length > 0) {
						await locals.supabase
							.from('node_values')
							.insert(valueIds.map((v) => ({ node_id: nodeId, value_id: v })));
					}
				}
				return { success: true };
			} catch (e: any) {
				return fail(400, { message: e?.message ?? 'Falha ao atualizar alinhamento com valores.' });
			}
		}

		try {
			setNodeValuesRecord(user, nodeId, valueIds);
			return { success: true };
		} catch (e: any) {
			return fail(400, { message: e?.message ?? 'Falha ao atualizar alinhamento com valores.' });
		}
	},

	setAssignees: async ({ request, locals }) => {
		const { user } = await locals.safeGetSession();
		const formData = await request.formData();
		const nodeId = formData.get('nodeId') as string;
		const userIds = formData.getAll('userIds').map(String);
		const teamIds = formData.getAll('teamIds').map(String);

		if (locals.mode === 'supabase' && locals.supabase) {
			try {
				await locals.supabase.from('node_assignees').delete().eq('node_id', nodeId);
				if (userIds.length > 0) {
					await locals.supabase
						.from('node_assignees')
						.insert(userIds.map((u) => ({ node_id: nodeId, user_id: u })));
				}
				await locals.supabase.from('node_teams').delete().eq('node_id', nodeId);
				if (teamIds.length > 0) {
					await locals.supabase
						.from('node_teams')
						.insert(teamIds.map((t) => ({ node_id: nodeId, team_id: t })));
				}
				return { success: true };
			} catch (e: any) {
				return fail(400, { message: e?.message ?? 'Falha ao atualizar responsáveis e equipes.' });
			}
		}

		try {
			setNodeAssigneesRecord(user, nodeId, userIds);
			setNodeTeamsRecord(user, nodeId, teamIds);
			return { success: true };
		} catch (e: any) {
			return fail(400, { message: e?.message ?? 'Falha ao atualizar responsáveis e equipes.' });
		}
	},

	logMetric: async ({ request, locals }) => {
		const { user } = await locals.safeGetSession();
		const formData = await request.formData();
		const nodeId = formData.get('nodeId') as string;
		const valStr = formData.get('value') as string;
		const note = (formData.get('note') as string) || null;

		if (locals.mode === 'supabase' && locals.supabase) {
			try {
				const val = Number(valStr);
				const { error } = await locals.supabase.from('metric_updates').insert({
					node_id: nodeId,
					value: val,
					note,
					user_id: user?.id ?? null
				});
				if (error) return fail(400, { message: error.message });
				await locals.supabase
					.from('nodes')
					.update({ current_value: val })
					.eq('id', nodeId);
				return { success: true };
			} catch (e: any) {
				return fail(400, { message: e?.message ?? 'Falha ao registrar atualização de métrica.' });
			}
		}

		try {
			logMetricUpdateRecord(user, nodeId, Number(valStr), note);
			return { success: true };
		} catch (e: any) {
			return fail(400, { message: e?.message ?? 'Falha ao registrar atualização de métrica.' });
		}
	}
};

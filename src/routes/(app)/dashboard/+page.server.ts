import { fail } from '@sveltejs/kit';
import type { Actions } from './$types';
import { logMetricUpdateRecord } from '$lib/server/store';

export const actions: Actions = {
	logMetric: async ({ request, locals }) => {
		const { user } = await locals.safeGetSession();
		const formData = await request.formData();
		const nodeId = formData.get('nodeId') as string;
		const valStr = formData.get('value') as string;
		const note = (formData.get('note') as string) || null;

		if (!nodeId || valStr == null || valStr.trim() === '') {
			return fail(400, { message: 'Valor e identificador do KPI são obrigatórios.' });
		}

		const val = Number(valStr);
		if (Number.isNaN(val)) {
			return fail(400, { message: 'O valor informado deve ser um número válido.' });
		}

		if (locals.mode === 'supabase' && locals.supabase) {
			try {
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

				return { success: true, nodeId };
			} catch (e: any) {
				return fail(400, { message: e?.message ?? 'Falha ao registrar check-in de métrica.' });
			}
		}

		try {
			logMetricUpdateRecord(user, nodeId, val, note);
			return { success: true, nodeId };
		} catch (e: any) {
			return fail(400, { message: e?.message ?? 'Falha ao registrar check-in de métrica.' });
		}
	}
};

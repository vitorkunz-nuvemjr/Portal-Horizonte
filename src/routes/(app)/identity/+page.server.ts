import { fail } from '@sveltejs/kit';
import type { Actions } from './$types';
import {
	archiveAndCreateEraRecord,
	createNodeRecord,
	deleteNodeRecord,
	updateNodeRecord
} from '$lib/server/store';

export const actions: Actions = {
	createMission: async ({ request, locals }) => {
		const { user } = await locals.safeGetSession();
		const formData = await request.formData();
		const title = ((formData.get('title') as string) ?? '').trim();
		const description = ((formData.get('description') as string) || '').trim() || null;
		const startYearStr = formData.get('start_year') as string | null;
		const endYearStr = formData.get('end_year') as string | null;

		if (locals.mode === 'supabase' && locals.supabase) {
			try {
				const { error } = await locals.supabase.from('nodes').insert({
					parent_id: null,
					tree: 'identity',
					type: 'mission',
					title,
					description,
					start_year: startYearStr ? Number(startYearStr) : 2026,
					end_year: endYearStr ? Number(endYearStr) : null,
					status: 'on_track',
					created_by: user?.id ?? null
				});
				if (error) return fail(400, { message: error.message });
				return { success: true };
			} catch (e: any) {
				return fail(400, { message: e?.message ?? 'Falha ao criar missão.' });
			}
		}

		try {
			createNodeRecord(user, {
				parent_id: null,
				type: 'mission',
				title,
				description,
				start_year: startYearStr ? Number(startYearStr) : 2024,
				end_year: endYearStr ? Number(endYearStr) : null
			});
			return { success: true };
		} catch (e: any) {
			return fail(400, { message: e?.message ?? 'Falha ao criar missão.' });
		}
	},

	createValue: async ({ request, locals }) => {
		const { user } = await locals.safeGetSession();
		const formData = await request.formData();
		const parentId = formData.get('parentId') as string;
		const title = ((formData.get('title') as string) ?? '').trim();
		const description = ((formData.get('description') as string) || '').trim() || null;
		const color = (formData.get('color') as string) || null;
		const icon = (formData.get('icon') as string) || null;
		const startYearStr = formData.get('start_year') as string | null;
		const endYearStr = formData.get('end_year') as string | null;

		if (locals.mode === 'supabase' && locals.supabase) {
			try {
				const insertPayload: any = {
					parent_id: parentId,
					tree: 'identity',
					type: 'value',
					title,
					description,
					color,
					start_year: startYearStr ? Number(startYearStr) : null,
					end_year: endYearStr ? Number(endYearStr) : null,
					status: 'on_track',
					created_by: user?.id ?? null
				};
				if (icon) insertPayload.icon = icon;
				let { error } = await locals.supabase.from('nodes').insert(insertPayload);
				if (error && error.message?.includes('icon') && 'icon' in insertPayload) {
					delete insertPayload.icon;
					const retry = await locals.supabase.from('nodes').insert(insertPayload);
					if (retry.error) return fail(400, { message: retry.error.message });
				} else if (error) {
					return fail(400, { message: error.message });
				}
				return { success: true };
			} catch (e: any) {
				return fail(400, { message: e?.message ?? 'Falha ao criar valor.' });
			}
		}

		try {
			createNodeRecord(user, {
				parent_id: parentId,
				type: 'value',
				title,
				description,
				color,
				icon,
				start_year: startYearStr ? Number(startYearStr) : null,
				end_year: endYearStr ? Number(endYearStr) : null
			});
			return { success: true };
		} catch (e: any) {
			return fail(400, { message: e?.message ?? 'Falha ao criar valor.' });
		}
	},

	updateIdentityNode: async ({ request, locals }) => {
		const { user } = await locals.safeGetSession();
		const formData = await request.formData();
		const nodeId = formData.get('nodeId') as string;
		const title = ((formData.get('title') as string) ?? '').trim();
		const description = (formData.get('description') as string) || null;
		const color = (formData.get('color') as string) || null;
		const icon = (formData.get('icon') as string) || null;
		const startYearStr = formData.get('start_year') as string | null;
		const endYearStr = formData.get('end_year') as string | null;

		if (locals.mode === 'supabase' && locals.supabase) {
			try {
				const updatePayload: any = {
					title,
					description,
					color,
					start_year: startYearStr ? Number(startYearStr) : null,
					end_year: endYearStr ? Number(endYearStr) : null
				};
				if (icon) updatePayload.icon = icon;
				let { error } = await locals.supabase
					.from('nodes')
					.update(updatePayload)
					.eq('id', nodeId);
				if (error && error.message?.includes('icon') && 'icon' in updatePayload) {
					delete updatePayload.icon;
					const retry = await locals.supabase
						.from('nodes')
						.update(updatePayload)
						.eq('id', nodeId);
					if (retry.error) return fail(400, { message: retry.error.message });
				} else if (error) {
					return fail(400, { message: error.message });
				}
				return { success: true };
			} catch (e: any) {
				return fail(400, { message: e?.message ?? 'Falha ao atualizar item de identidade.' });
			}
		}

		try {
			updateNodeRecord(user, nodeId, {
				title,
				description,
				color,
				icon,
				start_year: startYearStr ? Number(startYearStr) : null,
				end_year: endYearStr ? Number(endYearStr) : null
			});
			return { success: true };
		} catch (e: any) {
			return fail(400, { message: e?.message ?? 'Falha ao atualizar item de identidade.' });
		}
	},

	archiveAndCreateEra: async ({ request, locals }) => {
		const { user } = await locals.safeGetSession();
		const formData = await request.formData();

		const archivePriorEndYear = Number(formData.get('archivePriorEndYear'));
		const newStartYear = Number(formData.get('newStartYear'));
		const newEndYearStr = formData.get('newEndYear') as string | null;
		const missionTitle = ((formData.get('missionTitle') as string) ?? '').trim();
		const missionDescription = ((formData.get('missionDescription') as string) || '').trim() || null;

		const valueTitles = formData.getAll('valueTitles').map(String);
		const valueDescriptions = formData.getAll('valueDescriptions').map(String);

		const values = valueTitles
			.map((title, i) => ({
				title: title.trim(),
				description: valueDescriptions[i]?.trim() || null
			}))
			.filter((v) => Boolean(v.title));

		if (locals.mode === 'supabase' && locals.supabase) {
			try {
				// 1. Archive prior active identity items
				await locals.supabase
					.from('nodes')
					.update({ end_year: archivePriorEndYear })
					.eq('tree', 'identity')
					.is('end_year', null);

				// 2. Insert new Mission
				const { data: newMission, error: missionErr } = await locals.supabase
					.from('nodes')
					.insert({
						parent_id: null,
						tree: 'identity',
						type: 'mission',
						title: missionTitle,
						description: missionDescription,
						start_year: newStartYear,
						end_year: newEndYearStr ? Number(newEndYearStr) : null,
						status: 'on_track',
						created_by: user?.id ?? null
					})
					.select()
					.single();

				if (missionErr) return fail(400, { message: missionErr.message });

				// 3. Insert values linked to new Mission
				if (values.length > 0 && newMission) {
					await locals.supabase.from('nodes').insert(
						values.map((v, i) => ({
							parent_id: newMission.id,
							tree: 'identity',
							type: 'value',
							title: v.title,
							description: v.description,
							start_year: newStartYear,
							end_year: newEndYearStr ? Number(newEndYearStr) : null,
							sort_order: i + 1,
							status: 'on_track',
							created_by: user?.id ?? null
						}))
					);
				}
				return { success: true };
			} catch (e: any) {
				return fail(400, { message: e?.message ?? 'Falha ao iniciar nova era estratégica.' });
			}
		}

		try {
			archiveAndCreateEraRecord(user, {
				archivePriorEndYear,
				newStartYear,
				newEndYear: newEndYearStr ? Number(newEndYearStr) : null,
				missionTitle,
				missionDescription,
				values
			});
			return { success: true };
		} catch (e: any) {
			return fail(400, { message: e?.message ?? 'Falha ao iniciar nova era estratégica.' });
		}
	},

	deleteIdentityNode: async ({ request, locals }) => {
		const { user } = await locals.safeGetSession();
		const formData = await request.formData();
		const nodeId = formData.get('nodeId') as string;

		if (locals.mode === 'supabase' && locals.supabase) {
			try {
				const { error } = await locals.supabase.from('nodes').delete().eq('id', nodeId);
				if (error) return fail(400, { message: error.message });
				return { success: true };
			} catch (e: any) {
				return fail(400, { message: e?.message ?? 'Falha ao excluir item de identidade.' });
			}
		}

		try {
			deleteNodeRecord(user, nodeId, false);
			return { success: true };
		} catch (e: any) {
			return fail(400, { message: e?.message ?? 'Falha ao excluir item de identidade.' });
		}
	}
};

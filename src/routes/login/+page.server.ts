import { fail, redirect } from '@sveltejs/kit';
import type { Actions, PageServerLoad } from './$types';
import { SESSION_COOKIE } from '../../hooks.server';

export const load: PageServerLoad = async ({ locals }) => {
	const { user } = await locals.safeGetSession();
	if (user) {
		throw redirect(303, '/strategy');
	}
	return {
		mode: locals.mode
	};
};

export const actions: Actions = {
	login: async ({ request, locals }) => {
		const formData = await request.formData();
		const email = (formData.get('email') as string | null)?.trim();
		const password = (formData.get('password') as string | null) ?? '';

		if (!email || !password) {
			return fail(400, { message: 'E-mail corporativo e senha de acesso são obrigatórios.' });
		}

		if (locals.mode === 'supabase' && locals.supabase) {
			const { error } = await locals.supabase.auth.signInWithPassword({
				email,
				password
			});
			if (error) {
				return fail(400, { message: error.message });
			}
			throw redirect(303, '/strategy');
		}

		return fail(500, { message: 'Supabase não configurado ou indisponível.' });
	},

	logout: async ({ cookies, locals }) => {
		if (locals.mode === 'supabase' && locals.supabase) {
			await locals.supabase.auth.signOut();
		}
		cookies.set(SESSION_COOKIE, 'logged_out', {
			path: '/',
			httpOnly: true,
			sameSite: 'lax'
		});
		throw redirect(303, '/login');
	}
};

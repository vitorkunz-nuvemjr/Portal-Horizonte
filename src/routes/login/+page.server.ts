import { fail, redirect } from '@sveltejs/kit';
import type { Actions, PageServerLoad } from './$types';
import { readDb } from '$lib/server/store';
import { SESSION_COOKIE } from '../../hooks.server';

export const load: PageServerLoad = async ({ locals }) => {
	const db = readDb();
	return {
		mode: locals.mode,
		profiles: db.profiles
	};
};

export const actions: Actions = {
	login: async ({ request, cookies, locals }) => {
		const formData = await request.formData();
		const email = (formData.get('email') as string | null)?.trim();
		const password = (formData.get('password') as string | null) ?? '';

		if (!email || !password) {
			return fail(400, { message: 'E-mail e senha são obrigatórios.' });
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

		// Local Store mode: match by email or fall back to first admin
		const db = readDb();
		const match =
			db.profiles.find((p) => p.email?.toLowerCase() === email.toLowerCase()) ??
			db.profiles[0];

		if (!match) {
			return fail(400, { message: 'Nenhum perfil de usuário local encontrado.' });
		}

		cookies.set(SESSION_COOKIE, match.id, {
			path: '/',
			httpOnly: true,
			sameSite: 'lax',
			maxAge: 60 * 60 * 24 * 30
		});

		throw redirect(303, '/strategy');
	},

	switchUser: async ({ request, cookies }) => {
		const formData = await request.formData();
		const userId = formData.get('userId') as string;
		const referer = request.headers.get('referer');

		if (userId) {
			cookies.set(SESSION_COOKIE, userId, {
				path: '/',
				httpOnly: true,
				sameSite: 'lax',
				maxAge: 60 * 60 * 24 * 30
			});
		}

		if (referer) {
			const url = new URL(referer);
			throw redirect(303, url.pathname + url.search);
		}
		throw redirect(303, '/strategy');
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

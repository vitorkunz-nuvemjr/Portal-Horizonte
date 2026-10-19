import { createServerClient } from '@supabase/ssr';
import { fail, redirect } from '@sveltejs/kit';
import type { Actions, PageServerLoad } from './$types';
import { SESSION_COOKIE, resolvedSupabaseUrl, resolvedSupabaseAnonKey } from '../../hooks.server';

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
	login: async ({ request, cookies, locals }) => {
		const formData = await request.formData();
		const email = (formData.get('email') as string | null)?.trim();
		const password = (formData.get('password') as string | null) ?? '';

		if (!email || !password) {
			return fail(400, { message: 'E-mail corporativo e senha de acesso são obrigatórios.' });
		}

		let supabase = locals.supabase;
		if (!supabase && resolvedSupabaseUrl && resolvedSupabaseAnonKey) {
			supabase = createServerClient(resolvedSupabaseUrl, resolvedSupabaseAnonKey, {
				cookies: {
					getAll() {
						return cookies.getAll();
					},
					setAll(cookiesToSet: Array<{ name: string; value: string; options: Record<string, any> }>) {
						cookiesToSet.forEach(({ name, value, options }) => {
							cookies.set(name, value, { ...options, path: '/' });
						});
					}
				}
			});
		}

		if (supabase) {
			const { error } = await supabase.auth.signInWithPassword({
				email,
				password
			});
			if (error) {
				const errorMsg =
					error.message === 'Invalid login credentials'
						? 'Credenciais inválidas. Verifique seu e-mail e senha corporativa.'
						: error.message;
				return fail(400, { message: errorMsg });
			}
			throw redirect(303, '/strategy');
		}

		return fail(500, { message: 'Supabase não configurado ou indisponível.' });
	},

	signup: async ({ request, cookies, locals }) => {
		const formData = await request.formData();
		const email = (formData.get('email') as string | null)?.trim();
		const password = (formData.get('password') as string | null) ?? '';
		const name = (formData.get('name') as string | null)?.trim() || email?.split('@')[0] || 'Usuário';

		if (!email || !password) {
			return fail(400, { message: 'E-mail corporativo e senha de acesso são obrigatórios.' });
		}

		let supabase = locals.supabase;
		if (!supabase && resolvedSupabaseUrl && resolvedSupabaseAnonKey) {
			supabase = createServerClient(resolvedSupabaseUrl, resolvedSupabaseAnonKey, {
				cookies: {
					getAll() {
						return cookies.getAll();
					},
					setAll(cookiesToSet: Array<{ name: string; value: string; options: Record<string, any> }>) {
						cookiesToSet.forEach(({ name, value, options }) => {
							cookies.set(name, value, { ...options, path: '/' });
						});
					}
				}
			});
		}

		if (supabase) {
			const { data, error } = await supabase.auth.signUp({
				email,
				password,
				options: {
					data: { name }
				}
			});
			if (error) {
				return fail(400, { message: error.message });
			}
			if (data.session) {
				throw redirect(303, '/strategy');
			}
			return {
				success: true,
				notice: 'Cadastro realizado com sucesso! Se a confirmação de e-mail estiver ativada, verifique sua caixa de entrada.'
			};
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

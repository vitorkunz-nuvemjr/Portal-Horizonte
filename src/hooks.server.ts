import { createServerClient } from '@supabase/ssr';
import type { Handle } from '@sveltejs/kit';
import { env as pubEnv } from '$env/dynamic/public';
import { readDb } from '$lib/server/store';

export const SESSION_COOKIE = 'je_session_user_id';

export const resolvedSupabaseUrl =
	pubEnv.PUBLIC_SUPABASE_URL ||
	(typeof process !== 'undefined' ? process.env?.PUBLIC_SUPABASE_URL : '') ||
	(typeof import.meta !== 'undefined' && (import.meta as any).env?.PUBLIC_SUPABASE_URL) ||
	'https://ptpcafftqlwxcdexofos.supabase.co';

export const resolvedSupabaseAnonKey =
	pubEnv.PUBLIC_SUPABASE_ANON_KEY ||
	(typeof process !== 'undefined' ? process.env?.PUBLIC_SUPABASE_ANON_KEY : '') ||
	(typeof import.meta !== 'undefined' && (import.meta as any).env?.PUBLIC_SUPABASE_ANON_KEY) ||
	'sb_publishable_7dvgutK2lSMz7tzbAc0-jg_T9TQimpb';

export const handle: Handle = async ({ event, resolve }) => {
	// Fast-path redirect for root URL to avoid unnecessary serverless compute and database round-trips
	if (event.url.pathname === '/') {
		return new Response(null, {
			status: 307,
			headers: { location: '/strategy' }
		});
	}

	const hasSupabase = Boolean(resolvedSupabaseUrl && resolvedSupabaseAnonKey);

	if (hasSupabase) {
		event.locals.mode = 'supabase';
		event.locals.supabase = createServerClient(
			resolvedSupabaseUrl,
			resolvedSupabaseAnonKey,
			{
				cookies: {
					getAll() {
						return event.cookies.getAll();
					},
					setAll(cookiesToSet: Array<{ name: string; value: string; options: Record<string, any> }>) {
						cookiesToSet.forEach(({ name, value, options }) => {
							event.cookies.set(name, value, { ...options, path: '/' });
						});
					}
				}
			}
		);

		let cachedSessionPromise: Promise<{ user: any | null }> | null = null;

		event.locals.safeGetSession = () => {
			if (cachedSessionPromise) return cachedSessionPromise;

			cachedSessionPromise = (async () => {
				try {
					// Check if any auth cookie exists before attempting network calls
					const cookies = event.cookies.getAll();
					const hasAuthCookie = cookies.some(
						(c) => c.name.includes('-auth-token') && Boolean(c.value)
					);
					if (!hasAuthCookie) {
						return { user: null };
					}

					// Fast check via getSession to obtain candidate user ID from cookie payload
					const {
						data: { session }
					} = await event.locals.supabase!.auth.getSession();
					const candidateUserId = session?.user?.id;

					if (candidateUserId) {
						// Parallelize verified getUser() check with profile fetch
						const [userRes, profileRes] = await Promise.all([
							event.locals.supabase!.auth.getUser(),
							event.locals.supabase!
								.from('profiles')
								.select('*')
								.eq('id', candidateUserId)
								.single()
						]);

						if (userRes.error || !userRes.data.user) {
							return { user: null };
						}
						const user = userRes.data.user;

						return {
							user: profileRes.data ?? {
								id: user.id,
								name: user.email?.split('@')[0] ?? 'User',
								email: user.email,
								role: 'member',
								color: '#2563eb',
								created_at: new Date().toISOString()
							}
						};
					}

					// Fallback: standard sequential getUser -> profile
					const {
						data: { user },
						error
					} = await event.locals.supabase!.auth.getUser();
					if (error || !user) return { user: null };

					const { data: profile } = await event.locals.supabase!
						.from('profiles')
						.select('*')
						.eq('id', user.id)
						.single();

					return {
						user: profile ?? {
							id: user.id,
							name: user.email?.split('@')[0] ?? 'User',
							email: user.email,
							role: 'member',
							color: '#2563eb',
							created_at: new Date().toISOString()
						}
					};
				} catch {
					return { user: null };
				}
			})();

			return cachedSessionPromise;
		};
	} else {
		event.locals.mode = 'local';
		event.locals.supabase = null;
		let cachedLocalSession: Promise<{ user: any | null }> | null = null;
		event.locals.safeGetSession = () => {
			if (cachedLocalSession) return cachedLocalSession;
			cachedLocalSession = (async () => {
				const db = readDb();
				const cookieUserId = event.cookies.get(SESSION_COOKIE);
				if (cookieUserId === 'logged_out') {
					return { user: null };
				}
				const profile =
					db.profiles.find((p) => p.id === cookieUserId) ?? db.profiles[0] ?? null;
				return { user: profile };
			})();
			return cachedLocalSession;
		};
	}

	return resolve(event, {
		filterSerializedResponseHeaders(name) {
			return name === 'content-range' || name === 'x-supabase-api-version';
		}
	});
};

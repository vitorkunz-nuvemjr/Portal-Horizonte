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

		event.locals.safeGetSession = async () => {
			try {
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
		};
	} else {
		event.locals.mode = 'local';
		event.locals.supabase = null;
		event.locals.safeGetSession = async () => {
			const db = readDb();
			const cookieUserId = event.cookies.get(SESSION_COOKIE);
			if (cookieUserId === 'logged_out') {
				return { user: null };
			}
			const profile =
				db.profiles.find((p) => p.id === cookieUserId) ?? db.profiles[0] ?? null;
			return { user: profile };
		};
	}

	return resolve(event, {
		filterSerializedResponseHeaders(name) {
			return name === 'content-range' || name === 'x-supabase-api-version';
		}
	});
};

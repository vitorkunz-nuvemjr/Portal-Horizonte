import { createClient } from '@supabase/supabase-js';
import { env } from '$env/dynamic/private';
import { resolvedSupabaseUrl } from '../../hooks.server';

export function getSupabaseAdmin() {
	if (!resolvedSupabaseUrl || !env.SUPABASE_SERVICE_ROLE_KEY) {
		return null;
	}
	return createClient(resolvedSupabaseUrl, env.SUPABASE_SERVICE_ROLE_KEY, {
		auth: {
			autoRefreshToken: false,
			persistSession: false
		}
	});
}

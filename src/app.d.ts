import type { Profile } from '$lib/types';
import type { SupabaseClient } from '@supabase/supabase-js';

declare global {
	namespace App {
		interface Locals {
			supabase: SupabaseClient | null;
			mode: 'local' | 'supabase';
			safeGetSession(): Promise<{ user: Profile | null }>;
		}
		interface PageData {
			user: Profile | null;
			mode?: 'local' | 'supabase';
		}
	}
}

export {};

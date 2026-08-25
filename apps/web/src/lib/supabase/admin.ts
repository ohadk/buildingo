import { createClient, type SupabaseClient } from "@supabase/supabase-js";
import { env } from "@/lib/env";

let client: SupabaseClient | undefined;

/**
 * Service-role Supabase client. BYPASSES RLS — only ever use it inside
 * server routes that have already verified the caller's Firebase session
 * and scope every query by building_id/role (see lib/auth/session.ts).
 */
export function supabaseAdmin(): SupabaseClient {
  if (!client) {
    client = createClient(env.supabaseUrl, env.supabaseSecretKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });
  }
  return client;
}

import { NextResponse } from "next/server";
import { env } from "@/lib/env";

const APP_HOSTING_ORIGIN =
  "https://buildingo-api--buildingo-6ff54.us-central1.hosted.app";

/**
 * GET /api/config — non-secret client bootstrap (Realtime publishable key,
 * public web origin for shareable join links).
 * Safe to expose: the publishable/anon key is designed for client apps; RLS
 * still protects rows. Secret keys are never returned.
 */
export async function GET() {
  const supabasePublishableKey =
    process.env.SUPABASE_PUBLISHABLE_KEY ||
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ||
    process.env.SUPABASE_ANON_KEY ||
    null;
  // Prefer env helper (rejects stale Netlify buildingo.com); fall back to App Hosting.
  const publicWebUrl = env.publicWebUrl || APP_HOSTING_ORIGIN;
  return NextResponse.json({
    supabaseUrl: process.env.SUPABASE_URL ?? null,
    supabasePublishableKey,
    realtimeEnabled: Boolean(supabasePublishableKey),
    publicWebUrl,
    /** Smart store link: /app detects iOS vs Android. */
    appDownloadUrl: `${publicWebUrl}/app`,
  });
}

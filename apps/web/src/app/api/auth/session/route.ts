import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { adminAuth } from "@/lib/firebase/admin";
import { supabaseAdmin } from "@/lib/supabase/admin";
import {
  ApiError,
  SESSION_COOKIE,
  SESSION_DURATION_MS,
  withErrorHandling,
} from "@/lib/auth/session";
import type { AppUser } from "@/lib/types";

const bodySchema = z.object({
  idToken: z.string().min(1),
  inviteCode: z.string().optional(),
});

/**
 * POST /api/auth/session — Firebase → Supabase token exchange.
 *
 * 1. Verifies the Firebase ID token (issued after phone OTP) with the
 *    Admin SDK.
 * 2. Fetches or creates the matching `users` row in Supabase Postgres:
 *      - phone in `super_admins`      → role super_admin
 *      - matching pending invitation  → role/building/apartment from invite
 *      - otherwise                    → bare profile awaiting an invite
 * 3. Mints a 14-day Firebase session cookie for the web console.
 *    (The Flutter app skips the cookie and sends Bearer ID tokens.)
 */
export const POST = withErrorHandling(async (req: NextRequest) => {
  const { idToken, inviteCode } = bodySchema.parse(await req.json());

  const decoded = await adminAuth().verifyIdToken(idToken, true);
  const phone = decoded.phone_number;
  if (!phone) throw new ApiError(400, "Token has no phone number; use phone OTP sign-in");

  const db = supabaseAdmin();

  const existing = await db
    .from("users")
    .select("*")
    .eq("firebase_uid", decoded.uid)
    .maybeSingle();
  if (existing.error) throw new ApiError(500, `User lookup failed: ${existing.error.message}`);
  let user = existing.data;

  if (!user) {
    // Role resolution for first-time sign-ins
    const { data: superAdmin, error: superAdminError } = await db
      .from("super_admins")
      .select("id")
      .eq("phone_number", phone)
      .maybeSingle();
    if (superAdminError) {
      throw new ApiError(500, `Role lookup failed: ${superAdminError.message}`);
    }

    let invite = null;
    if (!superAdmin) {
      const query = db
        .from("invitations")
        .select("*")
        .eq("status", "pending")
        .gt("expires_at", new Date().toISOString());
      const { data: invites } = inviteCode
        ? await query.eq("invite_code", inviteCode)
        : await query.eq("phone_number", phone);
      invite = invites?.[0] ?? null;
      if (invite && invite.phone_number !== phone) {
        throw new ApiError(403, "This invitation was issued for a different phone number");
      }
    }

    const { data: created, error } = await db
      .from("users")
      .insert({
        firebase_uid: decoded.uid,
        phone_number: phone,
        role: superAdmin ? "super_admin" : (invite?.role ?? "tenant"),
        building_id: invite?.building_id ?? null,
        apartment_id: invite?.apartment_id ?? null,
      })
      .select("*")
      .single();
    if (error) throw new ApiError(500, error.message);
    user = created;

    if (invite) {
      await db
        .from("invitations")
        .update({ status: "accepted", accepted_by: created.id })
        .eq("id", invite.id);
    }
  } else if (!user.building_id && user.role !== "super_admin") {
    // Returning user who signed up before being invited: claim any pending
    // invitation for their phone so assignment takes effect on next login.
    const { data: invites } = await db
      .from("invitations")
      .select("*")
      .eq("status", "pending")
      .eq("phone_number", phone)
      .gt("expires_at", new Date().toISOString());
    const invite = invites?.[0];
    if (invite) {
      const { data: updated, error } = await db
        .from("users")
        .update({
          role: invite.role,
          building_id: invite.building_id,
          apartment_id: invite.apartment_id,
        })
        .eq("id", user.id)
        .select("*")
        .single();
      if (error) throw new ApiError(500, error.message);
      user = updated;
      await db
        .from("invitations")
        .update({ status: "accepted", accepted_by: user.id })
        .eq("id", invite.id);
    }
  }

  const appUser = user as AppUser;
  const sessionCookie = await adminAuth().createSessionCookie(idToken, {
    expiresIn: SESSION_DURATION_MS,
  });

  const res = NextResponse.json({
    user: appUser,
    needsOnboarding: !appUser.onboarded_at && appUser.role !== "super_admin",
  });
  res.cookies.set(SESSION_COOKIE, sessionCookie, {
    httpOnly: true,
    secure: process.env.NODE_ENV === "production",
    sameSite: "lax",
    maxAge: SESSION_DURATION_MS / 1000,
    path: "/",
  });
  return res;
});

/** DELETE /api/auth/session — logout. */
export const DELETE = withErrorHandling(async () => {
  const res = NextResponse.json({ ok: true });
  res.cookies.set(SESSION_COOKIE, "", { maxAge: 0, path: "/" });
  return res;
});

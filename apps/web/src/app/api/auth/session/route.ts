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
import {
  decryptInvitationRow,
  decryptUserRow,
  findPendingInvitationByPhone,
  findSuperAdminByPhone,
  findUserByPhone,
  normalizePhone,
  userPiiStorageFields,
} from "@/lib/pii";
import { activateTenancy } from "@/lib/tenancy";
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
  const normalizedPhone = normalizePhone(phone);

  const existing = await db
    .from("users")
    .select("*")
    .eq("firebase_uid", decoded.uid)
    .neq("account_status", "deleted")
    .is("deleted_at", null)
    .maybeSingle();
  if (existing.error) throw new ApiError(500, `User lookup failed: ${existing.error.message}`);
  let user = existing.data ? decryptUserRow(existing.data) : null;

  if (user?.account_status === "deleted" || user?.deleted_at) {
    user = null;
  }

  if (!user) {
    // Never revive a soft-deleted profile. findUserByPhone already skips
    // account_status=deleted, so a re-signup always creates a new row
    // (no building) unless there is a *new* pending invitation.
    const byPhone = await findUserByPhone(db, phone);
    if (byPhone.error) {
      throw new ApiError(500, `User lookup failed: ${byPhone.error.message}`);
    }
    if (byPhone.data) {
      if (
        byPhone.data.account_status === "deleted" ||
        byPhone.data.deleted_at
      ) {
        // Defensive: treat as no user so we fall through to create.
      } else {
        const { data: relinked, error } = await db
          .from("users")
          .update({ firebase_uid: decoded.uid })
          .eq("id", byPhone.data.id)
          .neq("account_status", "deleted")
          .select("*")
          .single();
        if (error) throw new ApiError(500, error.message);
        user = decryptUserRow(relinked);
      }
    }
  }

  if (!user) {
    const { data: superAdmin, error: superAdminError } = await findSuperAdminByPhone(
      db,
      phone,
    );
    if (superAdminError) {
      throw new ApiError(500, `Role lookup failed: ${superAdminError.message}`);
    }

    let invite = null;
    if (!superAdmin) {
      const { data: inv, error: invErr } = await findPendingInvitationByPhone(db, phone, {
        inviteCode,
      });
      if (invErr) throw new ApiError(500, invErr.message);
      invite = inv ? decryptInvitationRow(inv) : null;
      if (invite && normalizePhone(invite.phone_number) !== normalizedPhone) {
        throw new ApiError(403, "This invitation was issued for a different phone number");
      }
    }

    // Fresh profile after delete: never copy building from a deleted twin.
    // building_id is only set from a current pending invite (or null).
    const { data: created, error } = await db
      .from("users")
      .insert({
        firebase_uid: decoded.uid,
        ...userPiiStorageFields({ phone: normalizedPhone }),
        role: superAdmin ? "super_admin" : (invite?.role ?? "tenant"),
        building_id: invite?.building_id ?? null,
        apartment_id: invite?.apartment_id ?? null,
        account_status: "active",
        is_active: true,
      })
      .select("*")
      .single();
    if (error) throw new ApiError(500, error.message);
    user = decryptUserRow(created);

    if (invite) {
      await db
        .from("invitations")
        .update({ status: "accepted", accepted_by: created.id })
        .eq("id", invite.id);
      if (invite.apartment_id) {
        await activateTenancy({
          id: created.id,
          building_id: invite.building_id,
          apartment_id: invite.apartment_id,
          full_name: user.full_name,
          phone_number: user.phone_number,
          num_occupants: user.num_occupants,
        });
      }
    }
  } else if (!user.building_id && user.role !== "super_admin") {
    const { data: inv, error: invErr } = await findPendingInvitationByPhone(db, phone);
    if (invErr) throw new ApiError(500, invErr.message);
    const invite = inv ? decryptInvitationRow(inv) : null;
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
      user = decryptUserRow(updated);
      await db
        .from("invitations")
        .update({ status: "accepted", accepted_by: user.id })
        .eq("id", invite.id);
      if (invite.apartment_id) {
        await activateTenancy({
          id: user.id,
          building_id: invite.building_id,
          apartment_id: invite.apartment_id,
          full_name: user.full_name,
          phone_number: user.phone_number,
          num_occupants: user.num_occupants,
        });
      }
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

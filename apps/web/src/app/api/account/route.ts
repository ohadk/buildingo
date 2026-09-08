import { NextRequest, NextResponse } from "next/server";
import {
  ApiError,
  SESSION_COOKIE,
  getCurrentUserWithAccess,
  withErrorHandling,
} from "@/lib/auth/session";
import { setAccountStatus } from "@/lib/account-status";
import { logAudit } from "@/lib/audit";
import { adminAuth } from "@/lib/firebase/admin";
import { revokeAllPendingInvitesForPhone } from "@/lib/pii";
import { supabaseAdmin } from "@/lib/supabase/admin";

/**
 * DELETE /api/account — user-initiated soft delete (App Store 5.1.1(v)).
 *
 * Soft-delete keeps the row for super-admin history (building_id stays so
 * the account still appears under that building as "deleted"). A later
 * sign-in with the same phone creates a brand-new users row with no
 * building — it does not revive this one. Pending invites for the phone
 * are revoked so nothing auto-rejoins them to the old building.
 */
export const DELETE = withErrorHandling(async (req: NextRequest) => {
  const { user, blockedReason } = await getCurrentUserWithAccess(req);
  if (blockedReason === "blocked" || blockedReason === "trial_expired") {
    throw new ApiError(403, "Building access is suspended");
  }
  if (user.role === "super_admin") {
    throw new ApiError(
      403,
      "Super-admin accounts cannot be deleted from the app. Contact support.",
    );
  }

  const db = supabaseAdmin();
  const deletedAt = new Date().toISOString();
  const firebaseUid = user.firebase_uid;
  const phone = user.phone_number;

  if (user.apartment_id) {
    await db
      .from("tenancies")
      .update({ status: "ended", ended_at: deletedAt.slice(0, 10) })
      .eq("user_id", user.id)
      .eq("status", "active");
  }

  await db
    .from("join_requests")
    .update({ status: "rejected", decided_at: deletedAt })
    .eq("user_id", user.id)
    .eq("status", "pending");

  // Prevent auto-rejoin via leftover personal invites after re-registration.
  if (phone) {
    await revokeAllPendingInvitesForPhone(db, phone);
  }

  // Keep building_id for admin history; clear live apartment attachment.
  // Scramble firebase_uid so a fresh Auth user can create a new profile.
  await db
    .from("users")
    .update({
      firebase_uid: `deleted:${user.id}:${firebaseUid}`,
      apartment_id: null,
      onboarded_at: null,
    })
    .eq("id", user.id);

  const { error } = await setAccountStatus(db, {
    userId: user.id,
    status: "deleted",
    reason: "Deleted by user from the app",
    changedBy: user.id,
  });
  if (error) throw new ApiError(500, error.message);

  void logAudit({
    buildingId: user.building_id,
    actorId: user.id,
    action: "account_deleted",
    entityType: "user",
    entityId: user.id,
    details: {
      role: user.role,
      full_name: user.full_name,
      deleted_at: deletedAt,
      former_building_id: user.building_id,
    },
  });

  try {
    await adminAuth().deleteUser(firebaseUid);
  } catch (err) {
    console.error("[account DELETE] Firebase Auth delete failed", firebaseUid, err);
  }

  const res = NextResponse.json({ deleted: true, deletedAt });
  res.cookies.set(SESSION_COOKIE, "", { maxAge: 0, path: "/" });
  return res;
});

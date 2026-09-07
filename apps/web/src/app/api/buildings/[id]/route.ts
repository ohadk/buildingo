import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { ApiError, requireRole, withErrorHandling } from "@/lib/auth/session";
import { logAudit } from "@/lib/audit";
import { feeChangeAnnouncementBody } from "@/lib/fees";
import { adminAuth } from "@/lib/firebase/admin";
import { notifyBuilding } from "@/lib/notify-building";
import { supabaseAdmin } from "@/lib/supabase/admin";

const patchSchema = z
  .object({
    isActive: z.boolean().optional(),
    planStatus: z.enum(["trial", "active", "blocked"]).optional(),
    extendTrialDays: z.number().int().min(1).max(365).optional(),
    requireJoinDocs: z.boolean().optional(),
    feeMethod: z.enum(["fixed", "per_sqm"]).optional(),
    fixedMonthlyFee: z.number().min(0).optional(),
    pricePerSqm: z.number().min(0).optional(),
    /** When true (default), residents get an announcement + WhatsApp ping. */
    notifyResidents: z.boolean().optional(),
  })
  .refine(
    (b) =>
      b.isActive != null ||
      b.planStatus != null ||
      b.extendTrialDays != null ||
      b.requireJoinDocs != null ||
      b.feeMethod != null ||
      b.fixedMonthlyFee != null ||
      b.pricePerSqm != null,
    { message: "Nothing to update" },
  );

/**
 * PATCH /api/buildings/[id] — super admin manages access/subscription;
 * a Vaad may update join policy and Vaad fee settings for their building.
 */
export const PATCH = withErrorHandling(
  async (req: NextRequest, ctx: { params: Promise<{ id: string }> }) => {
    const user = await requireRole(req, "vaad", "super_admin");
    const { id } = await ctx.params;
    const body = patchSchema.parse(await req.json());
    const db = supabaseAdmin();

    if (user.role === "vaad") {
      if (user.building_id !== id) {
        throw new ApiError(403, "This building belongs to another Vaad");
      }
      if (body.isActive != null || body.planStatus != null || body.extendTrialDays != null) {
        throw new ApiError(403, "Only building policy and fees can be changed by a Vaad");
      }
    }

    const { data: before } = await db
      .from("buildings")
      .select("name, fee_method, fixed_monthly_fee, price_per_sqm")
      .eq("id", id)
      .single();

    const patch: Record<string, unknown> = {};
    if (body.isActive != null) patch.is_active = body.isActive;
    if (body.planStatus != null) patch.plan_status = body.planStatus;
    if (body.requireJoinDocs != null) patch.require_join_docs = body.requireJoinDocs;

    if (body.feeMethod != null) {
      patch.fee_method = body.feeMethod;
      if (body.feeMethod === "fixed") {
        if (body.fixedMonthlyFee == null) {
          throw new ApiError(400, "fixedMonthlyFee is required when feeMethod is fixed");
        }
        patch.fixed_monthly_fee = body.fixedMonthlyFee;
        patch.price_per_sqm = null;
      } else {
        if (body.pricePerSqm == null) {
          throw new ApiError(400, "pricePerSqm is required when feeMethod is per_sqm");
        }
        patch.price_per_sqm = body.pricePerSqm;
        patch.fixed_monthly_fee = null;
      }
    } else {
      if (body.fixedMonthlyFee != null) patch.fixed_monthly_fee = body.fixedMonthlyFee;
      if (body.pricePerSqm != null) patch.price_per_sqm = body.pricePerSqm;
    }

    if (body.extendTrialDays != null) {
      const { data: current, error: curErr } = await db
        .from("buildings")
        .select("trial_ends_at")
        .eq("id", id)
        .single();
      if (curErr) throw new ApiError(500, curErr.message);
      const base = Math.max(Date.now(), new Date(current.trial_ends_at).getTime());
      patch.trial_ends_at = new Date(base + body.extendTrialDays * 24 * 60 * 60 * 1000).toISOString();
      if (body.planStatus == null) patch.plan_status = "trial";
    }

    const { data, error } = await db
      .from("buildings")
      .update(patch)
      .eq("id", id)
      .select(
        "id, name, is_active, plan_status, trial_ends_at, require_join_docs, fee_method, fixed_monthly_fee, price_per_sqm",
      )
      .single();
    if (error) throw new ApiError(500, error.message);

    const feeChanged =
      body.feeMethod != null ||
      body.fixedMonthlyFee != null ||
      body.pricePerSqm != null;
    if (feeChanged && body.notifyResidents !== false && before) {
      const { title, body: msg } = feeChangeAnnouncementBody(before.name, {
        fee_method: data.fee_method,
        fixed_monthly_fee: data.fixed_monthly_fee,
        price_per_sqm: data.price_per_sqm,
      });
      await notifyBuilding(id, user.id, title, msg);
      await logAudit({
        buildingId: id,
        actorId: user.id,
        action: "fee_updated",
        entityType: "building",
        entityId: id,
        details: {
          fee_method: data.fee_method,
          fixed_monthly_fee: data.fixed_monthly_fee,
          price_per_sqm: data.price_per_sqm,
        },
      });
    }

    return NextResponse.json({ building: data });
  },
);

/**
 * DELETE /api/buildings/[id] — super admin permanently removes a building
 * and every user assigned to it (Vaad + tenants). Building-scoped rows
 * cascade in Postgres; app user profiles + Firebase Auth accounts are
 * cleaned up explicitly.
 */
export const DELETE = withErrorHandling(
  async (_req: NextRequest, ctx: { params: Promise<{ id: string }> }) => {
    const actor = await requireRole(_req, "super_admin");
    const { id } = await ctx.params;
    const db = supabaseAdmin();

    const { data: building, error: bErr } = await db
      .from("buildings")
      .select("id, name, address, city")
      .eq("id", id)
      .maybeSingle();
    if (bErr) throw new ApiError(500, bErr.message);
    if (!building) throw new ApiError(404, "Building not found");

    const { data: members, error: uErr } = await db
      .from("users")
      .select("id, firebase_uid, role, full_name")
      .eq("building_id", id);
    if (uErr) throw new ApiError(500, uErr.message);

    const userIds = (members ?? []).map((u) => u.id as string);
    const firebaseUids = (members ?? [])
      .map((u) => u.firebase_uid as string)
      .filter(Boolean);

    // Break non-cascading FKs that would block user deletion after the
    // building (and its CASCADE children) are gone.
    if (userIds.length > 0) {
      await Promise.all([
        db.from("join_requests").update({ decided_by: null }).in("decided_by", userIds),
        db.from("schedule_events").update({ created_by: null }).in("created_by", userIds),
        db.from("announcements").update({ created_by: null }).in("created_by", userIds),
        db.from("documents").update({ uploaded_by: null }).in("uploaded_by", userIds),
        db.from("meetings").update({ created_by: null }).in("created_by", userIds),
        db.from("expenses").update({ created_by: null }).in("created_by", userIds),
      ]);
    }

    const { error: delBuildingErr } = await db.from("buildings").delete().eq("id", id);
    if (delBuildingErr) throw new ApiError(500, delBuildingErr.message);

    if (userIds.length > 0) {
      // Leftover rows that reference users without ON DELETE CASCADE
      // (should be rare after the building cascade, but block user delete).
      await Promise.all([
        db.from("invitations").delete().in("created_by", userIds),
        db.from("tickets").delete().in("reported_by", userIds),
        db.from("vote_ballots").delete().in("user_id", userIds),
        db.from("ticket_events").delete().in("actor", userIds),
      ]);

      const { error: delUsersErr } = await db.from("users").delete().in("id", userIds);
      if (delUsersErr) throw new ApiError(500, delUsersErr.message);
    }

    // Best-effort Firebase Auth cleanup so the phone can re-register cleanly.
    await Promise.all(
      firebaseUids.map((uid) =>
        adminAuth()
          .deleteUser(uid)
          .catch((err) =>
            console.error("[buildings DELETE] Firebase Auth delete failed", uid, err),
          ),
      ),
    );

    void logAudit({
      buildingId: null,
      actorId: actor.id,
      action: "building_deleted",
      entityType: "building",
      entityId: id,
      details: {
        name: building.name,
        address: building.address,
        city: building.city,
        usersRemoved: userIds.length,
        roles: (members ?? []).map((u) => u.role),
      },
    });

    return NextResponse.json({
      deleted: true,
      buildingId: id,
      usersRemoved: userIds.length,
    });
  },
);

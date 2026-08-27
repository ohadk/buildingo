import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { ApiError, requireRole, withErrorHandling } from "@/lib/auth/session";
import { supabaseAdmin } from "@/lib/supabase/admin";

const patchSchema = z
  .object({
    isActive: z.boolean().optional(),
    // Subscription controls: activate (paid), block, or put back on
    // trial. extendTrialDays pushes trial_ends_at forward from
    // max(now, current end).
    planStatus: z.enum(["trial", "active", "blocked"]).optional(),
    extendTrialDays: z.number().int().min(1).max(365).optional(),
    // Building policy the Vaad controls: must new residents attach
    // documents (Arnona bill + proof of residence) when joining?
    requireJoinDocs: z.boolean().optional(),
  })
  .refine(
    (b) =>
      b.isActive != null ||
      b.planStatus != null ||
      b.extendTrialDays != null ||
      b.requireJoinDocs != null,
    { message: "Nothing to update" },
  );

/**
 * PATCH /api/buildings/[id] — super admin manages access/subscription;
 * a Vaad may update their own building's join policy (requireJoinDocs).
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
      if (
        body.isActive != null ||
        body.planStatus != null ||
        body.extendTrialDays != null
      ) {
        throw new ApiError(403, "Only the requireJoinDocs policy can be changed by a Vaad");
      }
    }

    const patch: Record<string, unknown> = {};
    if (body.isActive != null) patch.is_active = body.isActive;
    if (body.planStatus != null) patch.plan_status = body.planStatus;
    if (body.requireJoinDocs != null) patch.require_join_docs = body.requireJoinDocs;

    if (body.extendTrialDays != null) {
      const { data: current, error: curErr } = await db
        .from("buildings")
        .select("trial_ends_at")
        .eq("id", id)
        .single();
      if (curErr) throw new ApiError(500, curErr.message);
      const base = Math.max(
        Date.now(),
        new Date(current.trial_ends_at).getTime(),
      );
      patch.trial_ends_at = new Date(
        base + body.extendTrialDays * 24 * 60 * 60 * 1000,
      ).toISOString();
      // Extending a blocked/expired building puts it back on trial.
      if (body.planStatus == null) patch.plan_status = "trial";
    }

    const { data, error } = await db
      .from("buildings")
      .update(patch)
      .eq("id", id)
      .select("id, name, is_active, plan_status, trial_ends_at, require_join_docs")
      .single();
    if (error) throw new ApiError(500, error.message);
    return NextResponse.json({ building: data });
  },
);

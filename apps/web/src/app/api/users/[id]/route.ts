import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { ApiError, requireRole, withErrorHandling } from "@/lib/auth/session";
import { setAccountStatus } from "@/lib/account-status";
import { supabaseAdmin } from "@/lib/supabase/admin";

const patchSchema = z.object({
  /** @deprecated prefer accountStatus */
  isActive: z.boolean().optional(),
  accountStatus: z.enum(["active", "suspended"]).optional(),
  reason: z.string().max(500).optional(),
}).refine((b) => b.accountStatus != null || b.isActive != null, {
  message: "accountStatus or isActive required",
});

/** PATCH /api/users/[id] — super admin suspends/restores a single user. */
export const PATCH = withErrorHandling(
  async (req: NextRequest, ctx: { params: Promise<{ id: string }> }) => {
    const admin = await requireRole(req, "super_admin");
    const { id } = await ctx.params;
    if (id === admin.id) throw new ApiError(400, "Cannot suspend yourself");
    const body = patchSchema.parse(await req.json());

    const status =
      body.accountStatus ?? (body.isActive ? "active" : "suspended");

    const { data: target, error: lookupError } = await supabaseAdmin()
      .from("users")
      .select("id, role, account_status")
      .eq("id", id)
      .maybeSingle();
    if (lookupError) throw new ApiError(500, lookupError.message);
    if (!target) throw new ApiError(404, "User not found");
    if (target.role === "super_admin") {
      throw new ApiError(400, "Cannot suspend a platform admin");
    }
    if (target.account_status === "deleted") {
      throw new ApiError(409, "Deleted accounts cannot be reactivated here");
    }

    const reason =
      body.reason?.trim() ||
      (status === "suspended"
        ? "Suspended by super admin"
        : "Reactivated by super admin");

    const { error } = await setAccountStatus(supabaseAdmin(), {
      userId: id,
      status,
      reason,
      changedBy: admin.id,
    });
    if (error) throw new ApiError(500, error.message);

    const { data, error: fetchErr } = await supabaseAdmin()
      .from("users")
      .select(
        "id, full_name, is_active, account_status, status_reason, status_changed_at, deleted_at",
      )
      .eq("id", id)
      .single();
    if (fetchErr) throw new ApiError(500, fetchErr.message);
    return NextResponse.json({ user: data });
  },
);

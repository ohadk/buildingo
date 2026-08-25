import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { ApiError, requireRole, withErrorHandling } from "@/lib/auth/session";
import { supabaseAdmin } from "@/lib/supabase/admin";

const patchSchema = z.object({
  isActive: z.boolean(),
});

/** PATCH /api/users/[id] — super admin suspends/restores a single user. */
export const PATCH = withErrorHandling(
  async (req: NextRequest, ctx: { params: Promise<{ id: string }> }) => {
    const admin = await requireRole(req, "super_admin");
    const { id } = await ctx.params;
    if (id === admin.id) throw new ApiError(400, "Cannot suspend yourself");
    const { isActive } = patchSchema.parse(await req.json());

    const { data: target, error: lookupError } = await supabaseAdmin()
      .from("users")
      .select("id, role")
      .eq("id", id)
      .maybeSingle();
    if (lookupError) throw new ApiError(500, lookupError.message);
    if (!target) throw new ApiError(404, "User not found");
    if (target.role === "super_admin") {
      throw new ApiError(400, "Cannot suspend a platform admin");
    }

    const { data, error } = await supabaseAdmin()
      .from("users")
      .update({ is_active: isActive })
      .eq("id", id)
      .select("id, full_name, is_active")
      .single();
    if (error) throw new ApiError(500, error.message);
    return NextResponse.json({ user: data });
  },
);

import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { ApiError, requireRole, withErrorHandling } from "@/lib/auth/session";
import { supabaseAdmin } from "@/lib/supabase/admin";

const patchSchema = z.object({
  isActive: z.boolean(),
});

/** PATCH /api/buildings/[id] — super admin suspends/restores a building. */
export const PATCH = withErrorHandling(
  async (req: NextRequest, ctx: { params: Promise<{ id: string }> }) => {
    await requireRole(req, "super_admin");
    const { id } = await ctx.params;
    const { isActive } = patchSchema.parse(await req.json());

    const { data, error } = await supabaseAdmin()
      .from("buildings")
      .update({ is_active: isActive })
      .eq("id", id)
      .select("id, name, is_active")
      .single();
    if (error) throw new ApiError(500, error.message);
    return NextResponse.json({ building: data });
  },
);

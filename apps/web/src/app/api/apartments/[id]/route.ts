import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { ApiError, requireRole, withErrorHandling } from "@/lib/auth/session";
import { supabaseAdmin } from "@/lib/supabase/admin";

const patchSchema = z
  .object({
    sizeSqm: z.number().min(1).max(10000).optional(),
    parkingSpot: z.string().max(50).nullable().optional(),
    monthlyFee: z.number().min(0).optional(),
  })
  .refine((b) => Object.keys(b).length > 0, { message: "Nothing to update" });

/**
 * PATCH /api/apartments/:id — Vaad updates unit details: size in sqm
 * (used for per-sqm dues), parking spot, or a manual fee override.
 */
export const PATCH = withErrorHandling(
  async (req: NextRequest, { params }: { params: Promise<{ id: string }> }) => {
    const user = await requireRole(req, "vaad", "super_admin");
    const { id } = await params;
    const body = patchSchema.parse(await req.json());

    const { data, error } = await supabaseAdmin()
      .from("apartments")
      .update({
        ...(body.sizeSqm !== undefined ? { size_sqm: body.sizeSqm } : {}),
        ...(body.parkingSpot !== undefined ? { parking_spot: body.parkingSpot } : {}),
        ...(body.monthlyFee !== undefined ? { monthly_fee: body.monthlyFee } : {}),
      })
      .eq("id", id)
      .eq("building_id", user.building_id!)
      .select("*")
      .single();
    if (error || !data) throw new ApiError(404, "Apartment not found in your building");
    return NextResponse.json({ apartment: data });
  },
);

import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { ApiError, getCurrentUser, withErrorHandling } from "@/lib/auth/session";
import { monthlyFeeAmount } from "@/lib/fees";
import { supabaseAdmin } from "@/lib/supabase/admin";

const querySchema = z.object({
  apartmentNumber: z.coerce.number().int().min(1),
});

/**
 * GET /api/buildings/:id/apartment-fee-preview?apartmentNumber=N
 * Used during tenant onboarding: show known sqm + calculated monthly fee.
 */
export const GET = withErrorHandling(
  async (req: NextRequest, ctx: { params: Promise<{ id: string }> }) => {
    await getCurrentUser(req);
    const { id } = await ctx.params;
    const { apartmentNumber } = querySchema.parse({
      apartmentNumber: req.nextUrl.searchParams.get("apartmentNumber"),
    });
    const db = supabaseAdmin();

    const { data: building } = await db
      .from("buildings")
      .select("fee_method, fixed_monthly_fee, price_per_sqm, require_join_docs")
      .eq("id", id)
      .maybeSingle();
    if (!building) throw new ApiError(404, "Building not found");

    const { data: apartment } = await db
      .from("apartments")
      .select("id, size_sqm, monthly_fee")
      .eq("building_id", id)
      .eq("apartment_number", apartmentNumber)
      .maybeSingle();

    const sizeSqm = apartment?.size_sqm != null ? Number(apartment.size_sqm) : null;
    const perSqm = building.fee_method === "per_sqm";
    const monthlyFee = apartment
      ? monthlyFeeAmount(building, {
          monthly_fee: Number(apartment.monthly_fee ?? 0),
          size_sqm: sizeSqm,
        })
      : perSqm
        ? null
        : monthlyFeeAmount(building, { monthly_fee: 0, size_sqm: null });

    return NextResponse.json({
      apartmentNumber,
      feeMethod: building.fee_method,
      pricePerSqm: building.price_per_sqm,
      fixedMonthlyFee: building.fixed_monthly_fee,
      sizeSqm,
      monthlyFee,
      requiresSqmInput: perSqm && sizeSqm == null,
      requireJoinDocs: building.require_join_docs,
    });
  },
);

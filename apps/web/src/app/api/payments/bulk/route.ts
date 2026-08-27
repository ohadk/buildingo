import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { ApiError, requireRole, withErrorHandling } from "@/lib/auth/session";
import { logAudit } from "@/lib/audit";
import { supabaseAdmin } from "@/lib/supabase/admin";

const bodySchema = z.object({
  apartmentIds: z.array(z.string().uuid()).min(1).max(500),
  months: z
    .array(
      z.object({
        month: z.number().int().min(1).max(12),
        year: z.number().int().min(2020),
      }),
    )
    .min(1)
    .max(24),
  status: z.enum(["paid", "pending"]),
});

/**
 * POST /api/payments/bulk — Vaad quick actions: mark a whole floor or a
 * whole month as paid in one call. Creates missing dues rows with the
 * building's fee rules; keeps existing amounts untouched.
 */
export const POST = withErrorHandling(async (req: NextRequest) => {
  const user = await requireRole(req, "vaad", "super_admin");
  const { apartmentIds, months, status } = bodySchema.parse(await req.json());
  const db = supabaseAdmin();

  const [{ data: building }, { data: apartments }] = await Promise.all([
    db
      .from("buildings")
      .select("fee_method, fixed_monthly_fee, price_per_sqm")
      .eq("id", user.building_id!)
      .single(),
    db
      .from("apartments")
      .select("id, monthly_fee, size_sqm")
      .eq("building_id", user.building_id!)
      .in("id", apartmentIds),
  ]);
  if (!apartments?.length) throw new ApiError(404, "Apartments not found in your building");

  const amountFor = (a: { monthly_fee: number; size_sqm: number | null }): number => {
    if (building?.fee_method === "per_sqm" && building.price_per_sqm != null && a.size_sqm != null) {
      return Math.round(a.size_sqm * building.price_per_sqm * 100) / 100;
    }
    if (building?.fee_method === "fixed" && building.fixed_monthly_fee != null) {
      return building.fixed_monthly_fee;
    }
    return a.monthly_fee;
  };

  // Existing rows keep their amount; missing ones get a computed one.
  const years = [...new Set(months.map((m) => m.year))];
  const { data: existing } = await db
    .from("payments")
    .select("apartment_id, month, year, amount")
    .eq("building_id", user.building_id!)
    .in("apartment_id", apartments.map((a) => a.id))
    .in("year", years);
  const amounts = new Map(
    (existing ?? []).map((p) => [`${p.apartment_id}|${p.year}-${p.month}`, p.amount]),
  );

  const paymentDate = status === "paid" ? new Date().toISOString().slice(0, 10) : null;
  const rows = apartments.flatMap((a) =>
    months.map(({ month, year }) => ({
      building_id: user.building_id,
      apartment_id: a.id,
      month,
      year,
      amount: amounts.get(`${a.id}|${year}-${month}`) ?? amountFor(a),
      status,
      payment_date: paymentDate,
    })),
  );

  const { data, error } = await db
    .from("payments")
    .upsert(rows, { onConflict: "apartment_id,month,year" })
    .select("id");
  if (error) throw new ApiError(500, error.message);

  await logAudit({
    buildingId: user.building_id,
    actorId: user.id,
    action: "payments_bulk_marked",
    entityType: "payment",
    details: {
      status,
      apartments: apartments.length,
      months: months.length,
      updated: data?.length ?? 0,
    },
  });

  return NextResponse.json({ updated: data?.length ?? 0 });
});

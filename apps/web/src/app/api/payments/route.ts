import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { ApiError, getCurrentUser, requireRole, withErrorHandling } from "@/lib/auth/session";
import { supabaseAdmin } from "@/lib/supabase/admin";

const generateSchema = z.object({
  month: z.number().int().min(1).max(12),
  year: z.number().int().min(2020),
});

const patchSchema = z.object({
  paymentId: z.string().uuid(),
  status: z.enum(["pending", "paid", "overdue"]),
  paymentDate: z.string().optional(),
  notes: z.string().optional(),
});

/**
 * GET /api/payments — Vaad: full matrix for the building.
 * Tenant: only their own apartment's ledger (receipt archive included).
 */
export const GET = withErrorHandling(async (req: NextRequest) => {
  const user = await getCurrentUser(req);
  if (!user.building_id) throw new ApiError(409, "Not mapped to a building");

  let query = supabaseAdmin()
    .from("payments")
    .select("*, apartments(apartment_number, floor)")
    .eq("building_id", user.building_id)
    .order("year", { ascending: false })
    .order("month", { ascending: false });

  if (user.role === "tenant") {
    if (!user.apartment_id) throw new ApiError(409, "Not mapped to an apartment");
    query = query.eq("apartment_id", user.apartment_id);
  }

  const { data, error } = await query;
  if (error) throw new ApiError(500, error.message);
  return NextResponse.json({ payments: data });
});

/**
 * POST /api/payments — Vaad generates the month's dues rows for every
 * apartment from its monthly_fee (skips rows that already exist).
 */
export const POST = withErrorHandling(async (req: NextRequest) => {
  const user = await requireRole(req, "vaad", "super_admin");
  const { month, year } = generateSchema.parse(await req.json());
  const db = supabaseAdmin();

  const [{ data: building }, { data: apartments, error: aptError }] = await Promise.all([
    db.from("buildings").select("fee_method, fixed_monthly_fee, price_per_sqm").eq("id", user.building_id!).single(),
    db.from("apartments").select("id, monthly_fee, size_sqm").eq("building_id", user.building_id!),
  ]);
  if (aptError) throw new ApiError(500, aptError.message);

  // fixed → the building-wide amount; per_sqm → size × price (falls back
  // to the apartment's own monthly_fee when data is missing)
  const amountFor = (a: { monthly_fee: number; size_sqm: number | null }): number => {
    if (building?.fee_method === "per_sqm" && building.price_per_sqm != null && a.size_sqm != null) {
      return Math.round(a.size_sqm * building.price_per_sqm * 100) / 100;
    }
    if (building?.fee_method === "fixed" && building.fixed_monthly_fee != null) {
      return building.fixed_monthly_fee;
    }
    return a.monthly_fee;
  };

  const { data, error } = await db
    .from("payments")
    .upsert(
      (apartments ?? []).map((a) => ({
        building_id: user.building_id,
        apartment_id: a.id,
        month,
        year,
        amount: amountFor(a),
      })),
      { onConflict: "apartment_id,month,year", ignoreDuplicates: true },
    )
    .select("*");
  if (error) throw new ApiError(500, error.message);

  return NextResponse.json({ created: data?.length ?? 0 }, { status: 201 });
});

/** PATCH /api/payments — Vaad marks a payment paid/overdue. */
export const PATCH = withErrorHandling(async (req: NextRequest) => {
  const user = await requireRole(req, "vaad", "super_admin");
  const { paymentId, status, paymentDate, notes } = patchSchema.parse(await req.json());

  const { data, error } = await supabaseAdmin()
    .from("payments")
    .update({
      status,
      payment_date: status === "paid" ? (paymentDate ?? new Date().toISOString().slice(0, 10)) : null,
      ...(notes !== undefined ? { notes } : {}),
    })
    .eq("id", paymentId)
    .eq("building_id", user.building_id!)
    .select("*")
    .single();
  if (error || !data) throw new ApiError(404, "Payment not found in your building");
  return NextResponse.json({ payment: data });
});

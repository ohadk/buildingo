import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { ApiError, getCurrentUser, requireRole, withErrorHandling } from "@/lib/auth/session";
import { logAudit } from "@/lib/audit";
import { supabaseAdmin } from "@/lib/supabase/admin";

const generateSchema = z.object({
  month: z.number().int().min(1).max(12),
  year: z.number().int().min(2020),
});

const patchSchema = z
  .object({
    // Either an existing row id, or a matrix cell address. The cell form
    // lets the Vaad mark months that have no dues row yet (residents who
    // pay several months or a year ahead).
    paymentId: z.string().uuid().optional(),
    apartmentId: z.string().uuid().optional(),
    month: z.number().int().min(1).max(12).optional(),
    year: z.number().int().min(2020).optional(),
    status: z.enum(["pending", "paid", "overdue"]),
    paymentDate: z.string().optional(),
    notes: z.string().optional(),
  })
  .refine(
    (b) => b.paymentId != null || (b.apartmentId != null && b.month != null && b.year != null),
    { message: "Provide paymentId or apartmentId+month+year" },
  );

type FeeRules = {
  fee_method: string | null;
  fixed_monthly_fee: number | null;
  price_per_sqm: number | null;
};

/** Monthly amount for one apartment under the building's fee rules. */
function amountFor(
  building: FeeRules | null,
  a: { monthly_fee: number; size_sqm: number | null },
): number {
  if (building?.fee_method === "per_sqm" && building.price_per_sqm != null && a.size_sqm != null) {
    return Math.round(a.size_sqm * building.price_per_sqm * 100) / 100;
  }
  if (building?.fee_method === "fixed" && building.fixed_monthly_fee != null) {
    return building.fixed_monthly_fee;
  }
  return a.monthly_fee;
}

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

  const { data, error } = await db
    .from("payments")
    .upsert(
      (apartments ?? []).map((a) => ({
        building_id: user.building_id,
        apartment_id: a.id,
        month,
        year,
        amount: amountFor(building, a),
      })),
      { onConflict: "apartment_id,month,year", ignoreDuplicates: true },
    )
    .select("*");
  if (error) throw new ApiError(500, error.message);

  return NextResponse.json({ created: data?.length ?? 0 }, { status: 201 });
});

/**
 * PATCH /api/payments — Vaad toggles a payment's status.
 * Accepts a row id, or an (apartmentId, month, year) matrix cell —
 * creating the dues row on the fly when a resident pays ahead of time.
 */
export const PATCH = withErrorHandling(async (req: NextRequest) => {
  const user = await requireRole(req, "vaad", "super_admin");
  const body = patchSchema.parse(await req.json());
  const db = supabaseAdmin();

  const statusPatch = {
    status: body.status,
    payment_date:
      body.status === "paid"
        ? (body.paymentDate ?? new Date().toISOString().slice(0, 10))
        : null,
    ...(body.notes !== undefined ? { notes: body.notes } : {}),
  };

  const logMark = (p: {
    id: string;
    month: number;
    year: number;
    apartments?: { apartment_number: number } | null;
  }) =>
    logAudit({
      buildingId: user.building_id,
      actorId: user.id,
      action: "payment_marked",
      entityType: "payment",
      entityId: p.id,
      details: {
        status: body.status,
        month: p.month,
        year: p.year,
        apartment: p.apartments?.apartment_number ?? null,
      },
    });

  if (body.paymentId) {
    const { data, error } = await db
      .from("payments")
      .update(statusPatch)
      .eq("id", body.paymentId)
      .eq("building_id", user.building_id!)
      .select("*, apartments(apartment_number, floor)")
      .single();
    if (error || !data) throw new ApiError(404, "Payment not found in your building");
    await logMark(data);
    return NextResponse.json({ payment: data });
  }

  // Cell form: update if the row exists, otherwise create it with the
  // amount derived from the building's fee rules.
  const { data: existing } = await db
    .from("payments")
    .select("id")
    .eq("apartment_id", body.apartmentId!)
    .eq("building_id", user.building_id!)
    .eq("month", body.month!)
    .eq("year", body.year!)
    .maybeSingle();

  if (existing) {
    const { data, error } = await db
      .from("payments")
      .update(statusPatch)
      .eq("id", existing.id)
      .select("*, apartments(apartment_number, floor)")
      .single();
    if (error) throw new ApiError(500, error.message);
    await logMark(data);
    return NextResponse.json({ payment: data });
  }

  const [{ data: building }, { data: apartment }] = await Promise.all([
    db
      .from("buildings")
      .select("fee_method, fixed_monthly_fee, price_per_sqm")
      .eq("id", user.building_id!)
      .single(),
    db
      .from("apartments")
      .select("id, monthly_fee, size_sqm")
      .eq("id", body.apartmentId!)
      .eq("building_id", user.building_id!)
      .maybeSingle(),
  ]);
  if (!apartment) throw new ApiError(404, "Apartment not found in your building");

  const { data, error } = await db
    .from("payments")
    .insert({
      building_id: user.building_id,
      apartment_id: apartment.id,
      month: body.month,
      year: body.year,
      amount: amountFor(building, apartment),
      ...statusPatch,
    })
    .select("*, apartments(apartment_number, floor)")
    .single();
  if (error) throw new ApiError(500, error.message);
  await logMark(data);
  return NextResponse.json({ payment: data }, { status: 201 });
});

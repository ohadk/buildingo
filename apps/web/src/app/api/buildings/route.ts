import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { ApiError, requireRole, withErrorHandling } from "@/lib/auth/session";
import { canonicalizeBuildingAddress } from "@/lib/building-address";
import { findActiveBuildingByAddress } from "@/lib/find-building-by-address";
import { supabaseAdmin } from "@/lib/supabase/admin";

const createSchema = z
  .object({
    address: z.string().min(2),
    city: z.string().min(2).max(100),
    country: z.string().min(2).max(100).default("ישראל"),
    postalCode: z.string().max(20).optional(),
    apartmentCount: z.number().int().min(1).max(500),
    apartmentsPerFloor: z.number().int().min(1).max(50),
    feeMethod: z.enum(["fixed", "per_sqm"]),
    fixedMonthlyFee: z.number().min(0).optional(),
    pricePerSqm: z.number().min(0).optional(),
    bankName: z.string().optional(),
    bankBranch: z.string().optional(),
    bankAccountNumber: z.string().optional(),
  })
  .refine((b) => (b.feeMethod === "fixed" ? b.fixedMonthlyFee != null : true), {
    message: "fixedMonthlyFee is required when feeMethod is 'fixed'",
  })
  .refine((b) => (b.feeMethod === "per_sqm" ? b.pricePerSqm != null : true), {
    message: "pricePerSqm is required when feeMethod is 'per_sqm'",
  });

/** GET /api/buildings — super admin: all buildings with unit counts. */
export const GET = withErrorHandling(async (req: NextRequest) => {
  await requireRole(req, "super_admin");
  const { data, error } = await supabaseAdmin()
    .from("buildings")
    .select("*, apartments(count), users!users_building_id_fkey(count)")
    .order("created_at", { ascending: false });
  if (error) throw new ApiError(500, error.message);
  return NextResponse.json({ buildings: data });
});

/**
 * POST /api/buildings — super admin creates a building.
 * The name is generated automatically as "<address>, <city>", and the
 * apartments are generated from apartmentCount / apartmentsPerFloor.
 * Fees: fixed → every unit gets fixedMonthlyFee; per_sqm → dues are
 * computed as size_sqm × pricePerSqm once the Vaad fills in unit sizes.
 */
export const POST = withErrorHandling(async (req: NextRequest) => {
  await requireRole(req, "super_admin");
  const body = createSchema.parse(await req.json());
  const db = supabaseAdmin();

  let canonical;
  try {
    canonical = canonicalizeBuildingAddress({
      city: body.city,
      address: body.address,
      country: body.country,
    });
  } catch {
    throw new ApiError(400, "Invalid city or address");
  }

  try {
    const { building: existing } = await findActiveBuildingByAddress({
      city: canonical.city,
      address: canonical.address,
      country: canonical.country,
    });
    if (existing) {
      throw new ApiError(409, "A building at this address already exists");
    }
  } catch (err) {
    if (err instanceof ApiError) throw err;
  }

  const { address, city, country, name } = canonical;

  const { data: building, error } = await db
    .from("buildings")
    .insert({
      name,
      address,
      city,
      country,
      postal_code: body.postalCode ?? null,
      fee_method: body.feeMethod,
      fixed_monthly_fee: body.feeMethod === "fixed" ? body.fixedMonthlyFee : null,
      price_per_sqm: body.feeMethod === "per_sqm" ? body.pricePerSqm : null,
      bank_name: body.bankName ?? null,
      bank_branch: body.bankBranch ?? null,
      bank_account_number: body.bankAccountNumber ?? null,
    })
    .select("*")
    .single();
  // 23505 = unique violation on uq_buildings_active_address_hash.
  if (error?.code === "23505") {
    throw new ApiError(409, "A building at this address already exists");
  }
  if (error) throw new ApiError(500, error.message);

  const apartments = Array.from({ length: body.apartmentCount }, (_, i) => ({
    building_id: building.id,
    apartment_number: i + 1,
    floor: Math.floor(i / body.apartmentsPerFloor) + 1,
    monthly_fee: body.feeMethod === "fixed" ? body.fixedMonthlyFee : 0,
  }));

  const { data: created, error: aptError } = await db
    .from("apartments")
    .insert(apartments)
    .select("*");
  if (aptError) throw new ApiError(500, aptError.message);

  return NextResponse.json({ building, apartments: created }, { status: 201 });
});

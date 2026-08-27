import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { ApiError, getCurrentUser, withErrorHandling } from "@/lib/auth/session";
import { logAudit } from "@/lib/audit";
import { supabaseAdmin } from "@/lib/supabase/admin";

const createSchema = z
  .object({
    address: z.string().min(2),
    city: z.string().min(2).max(100),
    country: z.string().min(2).max(100).default("ישראל"),
    postalCode: z.string().max(20).optional(),
    apartmentCount: z.number().int().min(1).max(500),
    apartmentsPerFloor: z.number().int().min(1).max(50),
    feeMethod: z.enum(["fixed", "per_sqm"]).default("fixed"),
    fixedMonthlyFee: z.number().min(0).optional(),
    pricePerSqm: z.number().min(0).optional(),
    // The Vaad's own unit, so they show up in the directory right away.
    myApartmentNumber: z.number().int().min(1).optional(),
    fullName: z.string().max(255).optional(),
    email: z.string().email().optional(),
  })
  .refine((b) => (b.feeMethod === "fixed" ? b.fixedMonthlyFee != null : true), {
    message: "fixedMonthlyFee is required when feeMethod is 'fixed'",
  })
  .refine((b) => (b.feeMethod === "per_sqm" ? b.pricePerSqm != null : true), {
    message: "pricePerSqm is required when feeMethod is 'per_sqm'",
  });

/**
 * POST /api/buildings/self-serve — an app user with no building creates
 * their own building and becomes its Vaad. Returns the building
 * including join_code, which powers the WhatsApp invite link.
 */
export const POST = withErrorHandling(async (req: NextRequest) => {
  const user = await getCurrentUser(req);
  if (user.role === "super_admin") {
    throw new ApiError(400, "Super admins create buildings from the admin console");
  }
  if (user.building_id) {
    throw new ApiError(409, "You already belong to a building");
  }

  const body = createSchema.parse(await req.json());
  const db = supabaseAdmin();

  // Guard against duplicates: same address+city already registered.
  const { data: existing } = await db
    .from("buildings")
    .select("id")
    .ilike("address", body.address.trim())
    .ilike("city", body.city.trim())
    .maybeSingle();
  if (existing) {
    throw new ApiError(409, "A building at this address already exists — ask to join it instead");
  }

  const name = `${body.address.trim()}, ${body.city.trim()}`;

  const { data: building, error } = await db
    .from("buildings")
    .insert({
      name,
      address: body.address.trim(),
      city: body.city.trim(),
      country: body.country,
      postal_code: body.postalCode ?? null,
      fee_method: body.feeMethod,
      fixed_monthly_fee: body.feeMethod === "fixed" ? body.fixedMonthlyFee : null,
      price_per_sqm: body.feeMethod === "per_sqm" ? body.pricePerSqm : null,
      created_by: user.id,
      // Self-created buildings start a 14-day free trial; the super
      // admin activates them (paid) or blocks them from the console.
      plan_status: "trial",
      trial_ends_at: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000).toISOString(),
    })
    .select("*")
    .single();
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
    .select("id, apartment_number");
  if (aptError) throw new ApiError(500, aptError.message);

  const myApartment = body.myApartmentNumber
    ? created?.find((a) => a.apartment_number === body.myApartmentNumber)
    : null;

  const { data: updatedUser, error: userError } = await db
    .from("users")
    .update({
      role: "vaad",
      building_id: building.id,
      apartment_id: myApartment?.id ?? null,
      ...(body.fullName ? { full_name: body.fullName } : {}),
      ...(body.email ? { email: body.email } : {}),
    })
    .eq("id", user.id)
    .select("*")
    .single();
  if (userError) throw new ApiError(500, userError.message);

  const joinLink = `${req.nextUrl.origin}/join/${building.join_code}`;
  await logAudit({
    buildingId: building.id,
    actorId: user.id,
    action: "building_created",
    entityType: "building",
    entityId: building.id,
    details: { name: building.name, apartments: body.apartmentCount },
  });

  return NextResponse.json(
    { building, user: updatedUser, joinLink },
    { status: 201 },
  );
});

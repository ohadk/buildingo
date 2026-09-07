import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { ApiError, getCurrentUser, withErrorHandling } from "@/lib/auth/session";
import { logAudit } from "@/lib/audit";
import { env } from "@/lib/env";
import { findActiveBuildingByAddress } from "@/lib/find-building-by-address";
import { canonicalizeBuildingAddress } from "@/lib/building-address";
import { normalizeParkingSpots } from "@/lib/parking";
import { supabaseAdmin } from "@/lib/supabase/admin";
import { activateTenancy } from "@/lib/tenancy";

const createSchema = z
  .object({
    address: z.string().min(2),
    city: z.string().min(2).max(100),
    country: z.string().min(2).max(100).default("ישראל"),
    postalCode: z.string().max(20).optional(),
    district: z.string().max(100).optional(),
    apartmentCount: z.number().int().min(1).max(500),
    /** Legacy even split; ignored when [floors] is provided. */
    apartmentsPerFloor: z.number().int().min(1).max(50).optional(),
    /** Explicit floor map from the Vaad onboarding planner. */
    floors: z
      .array(
        z.object({
          floor: z.number().int().min(0).max(100),
          apartments: z.number().int().min(1).max(80),
        }),
      )
      .min(1)
      .max(80)
      .optional(),
    elevatorCount: z.number().int().min(0).max(50).optional(),
    entrances: z
      .array(
        z.object({
          name: z.string().min(1).max(20),
          code: z.string().max(32).optional().default(""),
        }),
      )
      .max(20)
      .optional(),
    feeMethod: z.enum(["fixed", "per_sqm"]).default("fixed"),
    fixedMonthlyFee: z.number().min(0).optional(),
    pricePerSqm: z.number().min(0).optional(),
    typicalApartmentSqm: z.number().min(0).max(2000).optional(),
    billingDay: z.number().int().min(1).max(28).optional(),
    /** Starting bank/cash balance (₪). Optional; defaults to 0. */
    openingBalance: z.number().min(0).optional(),
    // The Vaad's own unit — required so they appear in the directory.
    myApartmentNumber: z.number().int().min(1),
    /** First apartment number in the sequential numbering (default 1). */
    firstApartmentNumber: z.number().int().min(1).max(9999).optional(),
    fullName: z.string().min(2).max(255),
    email: z.string().email().optional(),
    /** Vaad apartment profile (same fields tenants provide when joining). */
    numOccupants: z.number().int().min(1).max(20).default(1),
    parkingSpots: z.array(z.string().min(1).max(50)).max(10).optional(),
    /** @deprecated Prefer parkingSpots. */
    parkingSpot: z.string().max(50).optional(),
    mySizeSqm: z.number().min(1).max(10000).optional(),
    arnonaDocPath: z.string().max(500).optional(),
    residenceDocPath: z.string().max(500).optional(),
    /** Optional recurring building services → schedule_events rows. */
    recurringServices: z
      .array(
        z.object({
          eventType: z.enum([
            "garbage",
            "cleaning",
            "bulk_waste",
            "gardening",
            "pest",
            "water_tank",
            "other",
          ]),
          title: z.string().min(2).max(255),
          recurrence: z.enum([
            "weekly",
            "biweekly",
            "monthly",
            "quarterly",
            "yearly",
          ]),
          /** Weekdays 0=Sun … 6=Sat for weekly/biweekly (one event per day). */
          daysOfWeek: z.array(z.number().int().min(0).max(6)).max(7).optional(),
          dayOfMonth: z.number().int().min(1).max(31).optional(),
          monthlyCost: z.number().min(0).optional(),
          providerName: z.string().max(255).optional(),
        }),
      )
      .max(30)
      .optional(),
  })
  .refine((b) => (b.feeMethod === "fixed" ? b.fixedMonthlyFee != null : true), {
    message: "fixedMonthlyFee is required when feeMethod is 'fixed'",
  })
  .refine((b) => (b.feeMethod === "per_sqm" ? b.pricePerSqm != null : true), {
    message: "pricePerSqm is required when feeMethod is 'per_sqm'",
  })
  .refine((b) => b.floors != null || b.apartmentsPerFloor != null, {
    message: "Provide floors map or apartmentsPerFloor",
  })
  .refine(
    (b) => {
      if (!b.floors) return true;
      const sum = b.floors.reduce((s, f) => s + f.apartments, 0);
      return sum === b.apartmentCount;
    },
    { message: "Sum of floor apartments must equal apartmentCount" },
  );

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

  // Guard against duplicates via normalized address (single source of truth).
  try {
    const { building: existing } = await findActiveBuildingByAddress({
      city: canonical.city,
      address: canonical.address,
      country: canonical.country,
    });
    if (existing) {
      throw new ApiError(
        409,
        "A building at this address already exists — ask to join it instead",
      );
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
      district: body.district?.trim() || null,
      fee_method: body.feeMethod,
      fixed_monthly_fee: body.feeMethod === "fixed" ? body.fixedMonthlyFee : null,
      price_per_sqm: body.feeMethod === "per_sqm" ? body.pricePerSqm : null,
      typical_apartment_sqm: body.typicalApartmentSqm ?? null,
      billing_day: body.billingDay ?? 1,
      elevator_count: body.elevatorCount ?? 0,
      entrances: body.entrances ?? [],
      opening_balance: body.openingBalance ?? 0,
      created_by: user.id,
      // Self-created buildings start a 14-day free trial; the super
      // admin activates them (paid) or blocks them from the console.
      plan_status: "trial",
      trial_ends_at: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000).toISOString(),
    })
    .select("*")
    .single();
  // 23505 = unique violation on uq_buildings_active_address_hash
  if (error?.code === "23505") {
    throw new ApiError(409, "A building at this address already exists — ask to join it instead");
  }
  if (error) throw new ApiError(500, error.message);

  const firstApt = body.firstApartmentNumber ?? 1;
  const typicalSqm = body.typicalApartmentSqm ?? null;
  const apartments =
    body.floors != null
      ? body.floors
          .slice()
          .sort((a, b) => a.floor - b.floor)
          .flatMap((f) =>
            Array.from({ length: f.apartments }, () => ({
              building_id: building.id,
              // numbers assigned below
              floor: f.floor,
              monthly_fee: body.feeMethod === "fixed" ? body.fixedMonthlyFee : 0,
              size_sqm: typicalSqm,
            })),
          )
          .map((row, i) => ({ ...row, apartment_number: firstApt + i }))
      : Array.from({ length: body.apartmentCount }, (_, i) => ({
          building_id: building.id,
          apartment_number: firstApt + i,
          floor: Math.floor(i / (body.apartmentsPerFloor ?? 1)) + 1,
          monthly_fee: body.feeMethod === "fixed" ? body.fixedMonthlyFee : 0,
          size_sqm: typicalSqm,
        }));
  const { data: created, error: aptError } = await db
    .from("apartments")
    .insert(apartments)
    .select("id, apartment_number");
  if (aptError) throw new ApiError(500, aptError.message);

  const myApartment = created?.find(
    (a) => a.apartment_number === body.myApartmentNumber,
  );
  if (!myApartment) {
    // Roll back apartments + building so we don't leave an orphan shell.
    await db.from("apartments").delete().eq("building_id", building.id);
    await db.from("buildings").delete().eq("id", building.id);
    throw new ApiError(
      400,
      "Your apartment number was not found in the building plan",
    );
  }

  const aptPatch: Record<string, unknown> = {};
  if (body.mySizeSqm != null) aptPatch.size_sqm = body.mySizeSqm;
  const parkingSpots = normalizeParkingSpots(body);
  if (parkingSpots.length) aptPatch.parking_spots = parkingSpots;
  if (Object.keys(aptPatch).length) {
    const { error: aptPatchError } = await db
      .from("apartments")
      .update(aptPatch)
      .eq("id", myApartment.id);
    if (aptPatchError) throw new ApiError(500, aptPatchError.message);
  }

  const { data: updatedUser, error: userError } = await db
    .from("users")
    .update({
      role: "vaad",
      building_id: building.id,
      apartment_id: myApartment.id,
      full_name: body.fullName,
      num_occupants: body.numOccupants,
      onboarded_at: new Date().toISOString(),
      ...(body.email ? { email: body.email } : {}),
    })
    .eq("id", user.id)
    .select("*")
    .single();
  if (userError) throw new ApiError(500, userError.message);

  await activateTenancy({
    id: user.id,
    building_id: building.id,
    apartment_id: myApartment.id,
    full_name: body.fullName,
    phone_number: user.phone_number,
    num_occupants: body.numOccupants,
  });

  // Persist Vaad unit docs in the apartment vault (same bucket tenants use).
  const vaultDocs: { title: string; file_path: string; file_type: string }[] =
    [];
  if (body.arnonaDocPath) {
    vaultDocs.push({
      title: "Arnona",
      file_path: body.arnonaDocPath,
      file_type: "arnona",
    });
  }
  if (body.residenceDocPath) {
    vaultDocs.push({
      title: "Proof of residence",
      file_path: body.residenceDocPath,
      file_type: "residence",
    });
  }
  if (vaultDocs.length) {
    const { error: docsError } = await db.from("documents").insert(
      vaultDocs.map((d) => ({
        building_id: building.id,
        apartment_id: myApartment.id,
        title: d.title,
        file_path: d.file_path,
        file_type: d.file_type,
        uploaded_by: user.id,
      })),
    );
    if (
      docsError &&
      !/documents|schema cache|does not exist/i.test(docsError.message)
    ) {
      throw new ApiError(500, docsError.message);
    }
  }

  // Seed building calendar from onboarding recurring services.
  if (body.recurringServices?.length) {
    const today = new Date().toISOString().slice(0, 10);
    const rows: Record<string, unknown>[] = [];
    for (const svc of body.recurringServices) {
      const isWeekly =
        svc.recurrence === "weekly" || svc.recurrence === "biweekly";
      const days = isWeekly
        ? (svc.daysOfWeek?.length ? svc.daysOfWeek : [0])
        : [null];
      days.forEach((dow, idx) => {
        rows.push({
          building_id: building.id,
          event_type: svc.eventType,
          title: svc.title,
          notes: null,
          recurrence: svc.recurrence,
          day_of_week: isWeekly ? dow : null,
          day_of_month: isWeekly ? null : (svc.dayOfMonth ?? 1),
          specific_date:
            svc.recurrence === "biweekly" ||
            svc.recurrence === "quarterly" ||
            svc.recurrence === "yearly"
              ? today
              : null,
          // Attach monthly cost only once per service (first weekday).
          monthly_cost: idx === 0 ? (svc.monthlyCost ?? null) : null,
          provider_name: svc.providerName?.trim() || null,
          created_by: user.id,
        });
      });
    }
    if (rows.length) {
      const { error: schedError } = await db.from("schedule_events").insert(rows);
      // Soft-fail if migration 0018/0029 isn't applied yet — building still created.
      if (
        schedError &&
        !/schedule_events|schema cache|does not exist/i.test(schedError.message)
      ) {
        throw new ApiError(500, schedError.message);
      }
    }
  }

  const origin =
    env.publicWebUrl ||
    "https://buildingo-api--buildingo-6ff54.us-central1.hosted.app";
  const joinLink = `${origin}/join/${building.join_code}`;
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

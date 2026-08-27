import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { ApiError, getCurrentUser, withErrorHandling } from "@/lib/auth/session";
import { logAudit } from "@/lib/audit";
import { assertBuildingCapacity } from "@/lib/billing";
import { supabaseAdmin } from "@/lib/supabase/admin";
import { activateTenancy } from "@/lib/tenancy";

/**
 * GET /api/join?code= — resolve a code before joining so the app can
 * show which building it belongs to. Accepts both building join codes
 * (WhatsApp link) and personal invitation codes.
 */
export const GET = withErrorHandling(async (req: NextRequest) => {
  await getCurrentUser(req);
  const code = req.nextUrl.searchParams.get("code")?.trim();
  if (!code) throw new ApiError(400, "code is required");
  const db = supabaseAdmin();

  const { data: building } = await db
    .from("buildings")
    .select("id, name, address, city, is_active, require_join_docs, fee_method")
    .eq("join_code", code)
    .maybeSingle();
  if (building?.is_active) {
    return NextResponse.json({
      kind: "building",
      building: {
        id: building.id,
        name: building.name,
        address: building.address,
        city: building.city,
        require_join_docs: building.require_join_docs,
        fee_method: building.fee_method,
      },
    });
  }

  const { data: invite } = await db
    .from("invitations")
    .select("id, building_id, apartment_id, status, expires_at, buildings(name), apartments(apartment_number)")
    .eq("invite_code", code)
    .maybeSingle();
  if (invite && invite.status === "pending" && new Date(invite.expires_at) > new Date()) {
    return NextResponse.json({
      kind: "invitation",
      building: { id: invite.building_id, name: (invite.buildings as unknown as { name: string })?.name },
      apartmentNumber: (invite.apartments as unknown as { apartment_number: number })?.apartment_number,
    });
  }

  throw new ApiError(404, "Code not found or expired");
});

const joinSchema = z.object({
  code: z.string().min(4),
  apartmentNumber: z.number().int().min(1).optional(),
  fullName: z.string().max(255).optional(),
  email: z.string().email().optional(),
  numOccupants: z.number().int().min(1).max(20).optional(),
  floor: z.number().int().min(-5).max(200).optional(),
  parkingSpot: z.string().max(50).optional(),
  /** Proof of residence: rent/purchase agreement. */
  docPath: z.string().max(500).optional(),
  /** Arnona bill — shows the apartment's sqm (drives per-sqm fees). */
  arnonaDocPath: z.string().max(500).optional(),
});

/**
 * POST /api/join — a signed-in user with no building joins one by code.
 *  - Personal invitation code → accepts the invite immediately
 *    (role/unit come from it; it was issued to this exact phone).
 *  - Building join code (shared by the Vaad in WhatsApp) → the user
 *    submits their details as a join request; the Vaad must approve it
 *    before they get access.
 */
export const POST = withErrorHandling(async (req: NextRequest) => {
  const user = await getCurrentUser(req);
  if (user.building_id) throw new ApiError(409, "You already belong to a building");
  const body = joinSchema.parse(await req.json());
  const { code, apartmentNumber, fullName } = body;
  const db = supabaseAdmin();

  // 1. Personal invitation
  const { data: invite } = await db
    .from("invitations")
    .select("*")
    .eq("invite_code", code)
    .eq("status", "pending")
    .gt("expires_at", new Date().toISOString())
    .maybeSingle();
  if (invite) {
    if (invite.phone_number !== user.phone_number) {
      throw new ApiError(403, "This invitation was issued for a different phone number");
    }
    const { data: updated, error } = await db
      .from("users")
      .update({
        role: invite.role,
        building_id: invite.building_id,
        apartment_id: invite.apartment_id,
        ...(fullName ? { full_name: fullName } : {}),
      })
      .eq("id", user.id)
      .select("*")
      .single();
    if (error) throw new ApiError(500, error.message);
    await db
      .from("invitations")
      .update({ status: "accepted", accepted_by: user.id })
      .eq("id", invite.id);

    if (invite.apartment_id) {
      await activateTenancy({
        id: user.id,
        building_id: invite.building_id,
        apartment_id: invite.apartment_id,
        full_name: fullName ?? user.full_name,
        phone_number: user.phone_number,
        num_occupants: user.num_occupants,
      });
    }

    await logAudit({
      buildingId: invite.building_id,
      actorId: user.id,
      action: "tenant_joined",
      entityType: "user",
      entityId: user.id,
      details: {
        name: fullName ?? user.full_name ?? "",
        role: invite.role,
        via: "invitation",
      },
    });

    return NextResponse.json({ user: updated, joined: "invitation" });
  }

  // 2. Building join link → pending request awaiting Vaad approval
  const { data: building } = await db
    .from("buildings")
    .select("id, name, is_active, require_join_docs")
    .eq("join_code", code)
    .maybeSingle();
  if (!building) throw new ApiError(404, "Code not found or expired");
  if (!building.is_active) throw new ApiError(403, "This building is suspended");
  if (!apartmentNumber) throw new ApiError(400, "apartmentNumber is required for a building join link");
  if (!fullName || fullName.trim().length < 2) {
    throw new ApiError(400, "fullName is required so the Vaad knows who's asking");
  }
  if (building.require_join_docs && (!body.docPath || !body.arnonaDocPath)) {
    throw new ApiError(
      400,
      "ועד הבית דורש לצרף חשבון ארנונה ואישור מגורים כדי להצטרף",
    );
  }

  // The building's declared apartment count is a hard resident limit.
  await assertBuildingCapacity(building.id, apartmentNumber);

  // Replace any previous open request (unique index allows one pending).
  await db
    .from("join_requests")
    .update({ status: "rejected", decided_at: new Date().toISOString() })
    .eq("user_id", user.id)
    .eq("status", "pending");

  const { data: request, error } = await db
    .from("join_requests")
    .insert({
      building_id: building.id,
      user_id: user.id,
      apartment_number: apartmentNumber,
      full_name: fullName.trim(),
      email: body.email ?? null,
      num_occupants: body.numOccupants ?? null,
      floor: body.floor ?? null,
      parking_spot: body.parkingSpot ?? null,
      doc_path: body.docPath ?? null,
      arnona_doc_path: body.arnonaDocPath ?? null,
    })
    .select("*")
    .single();
  if (error) throw new ApiError(500, error.message);

  await db
    .from("users")
    .update({ full_name: fullName.trim(), email: body.email ?? null })
    .eq("id", user.id);

  await logAudit({
    buildingId: building.id,
    actorId: user.id,
    action: "join_requested",
    entityType: "join_request",
    entityId: request.id,
    details: { name: fullName.trim(), apartment: apartmentNumber },
  });

  return NextResponse.json({ joinRequest: request, joined: "pending" }, { status: 201 });
});

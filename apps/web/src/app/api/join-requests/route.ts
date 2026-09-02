import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { ApiError, getCurrentUser, requireRole, withErrorHandling } from "@/lib/auth/session";
import { logAudit } from "@/lib/audit";
import { assertBuildingCapacity } from "@/lib/billing";
import { validateJoinSubmission } from "@/lib/join-validation";
import { normalizeParkingSpots } from "@/lib/parking";
import {
  decryptJoinRequestRow,
  decryptUserRow,
  joinRequestPiiStorageFields,
  userPiiStorageFields,
} from "@/lib/pii";
import { supabaseAdmin } from "@/lib/supabase/admin";

/** GET /api/join-requests — Vaad lists pending requests for their building. */
export const GET = withErrorHandling(async (req: NextRequest) => {
  const user = await requireRole(req, "vaad", "super_admin");
  if (!user.building_id) throw new ApiError(409, "Not mapped to a building");
  const db = supabaseAdmin();
  const { data, error } = await db
    .from("join_requests")
    .select("*, users!join_requests_user_id_fkey(id, phone_number, full_name)")
    .eq("building_id", user.building_id)
    .eq("status", "pending")
    .order("created_at", { ascending: true });
  if (error) throw new ApiError(500, error.message);

  // Attach viewable links for uploaded documents (residence + Arnona).
  const sign = async (path: string | null) => {
    if (!path) return null;
    const { data: signed } = await db.storage
      .from("documents")
      .createSignedUrl(path, 60 * 60);
    return signed?.signedUrl ?? null;
  };
  const withDocs = await Promise.all(
    (data ?? []).map(async (r) => {
      const row = decryptJoinRequestRow(r);
      const nested = r.users as Record<string, unknown> | null;
      return {
        ...row,
        users: nested ? decryptUserRow(nested) : nested,
        doc_url: await sign(r.doc_path as string | null),
        arnona_doc_url: await sign(r.arnona_doc_path as string | null),
      };
    }),
  );
  return NextResponse.json({ joinRequests: withDocs });
});

const createSchema = z.object({
  buildingId: z.string().uuid(),
  apartmentNumber: z.number().int().min(1),
  fullName: z.string().min(2).max(255),
  email: z.string().email().optional(),
  numOccupants: z.number().int().min(1).max(20).optional(),
  floor: z.number().int().min(-5).max(200).optional(),
  parkingSpots: z.array(z.string().min(1).max(50)).max(10).optional(),
  /** @deprecated Prefer parkingSpots. */
  parkingSpot: z.string().max(50).optional(),
  /** Proof of residence: rent/purchase agreement. */
  docPath: z.string().max(500).optional(),
  /** Arnona bill — shows the apartment's sqm (drives per-sqm fees). */
  arnonaDocPath: z.string().max(500).optional(),
  sizeSqm: z.number().min(1).max(10000).optional(),
});

/**
 * POST /api/join-requests — a signed-in user with no building asks to
 * join one found by address search; the building's Vaad must approve.
 */
export const POST = withErrorHandling(async (req: NextRequest) => {
  const user = await getCurrentUser(req);
  if (user.building_id) throw new ApiError(409, "You already belong to a building");
  const body = createSchema.parse(await req.json());
  const db = supabaseAdmin();
  const parkingSpots = normalizeParkingSpots(body);

  const { data: building } = await db
    .from("buildings")
    .select("id, name, is_active")
    .eq("id", body.buildingId)
    .maybeSingle();
  if (!building || !building.is_active) throw new ApiError(404, "Building not found");

  const { sizeSqm } = await validateJoinSubmission(db, building.id, body.apartmentNumber, {
    docPath: body.docPath,
    arnonaDocPath: body.arnonaDocPath,
    sizeSqm: body.sizeSqm,
  });

  // The building's declared apartment count is a hard resident limit.
  await assertBuildingCapacity(building.id, body.apartmentNumber);

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
      apartment_number: body.apartmentNumber,
      ...joinRequestPiiStorageFields({
        fullName: body.fullName,
        email: body.email ?? null,
      }),
      num_occupants: body.numOccupants ?? null,
      floor: body.floor ?? null,
      parking_spots: parkingSpots,
      doc_path: body.docPath ?? null,
      arnona_doc_path: body.arnonaDocPath ?? null,
      size_sqm: sizeSqm,
    })
    .select("*")
    .single();
  if (error) throw new ApiError(500, error.message);

  await db
    .from("users")
    .update(userPiiStorageFields({ fullName: body.fullName, email: body.email ?? null }))
    .eq("id", user.id);

  await logAudit({
    buildingId: building.id,
    actorId: user.id,
    action: "join_requested",
    entityType: "join_request",
    entityId: request.id,
    details: { name: body.fullName, apartment: body.apartmentNumber },
  });

  return NextResponse.json({ joinRequest: decryptJoinRequestRow(request) }, { status: 201 });
});

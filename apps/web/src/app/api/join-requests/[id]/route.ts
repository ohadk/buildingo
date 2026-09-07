import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { ApiError, requireRole, withErrorHandling } from "@/lib/auth/session";
import { logAudit } from "@/lib/audit";
import { assertBuildingCapacity } from "@/lib/billing";
import { decryptJoinRequestRow, userPiiStorageFields } from "@/lib/pii";
import { supabaseAdmin } from "@/lib/supabase/admin";
import { activateTenancy } from "@/lib/tenancy";

const patchSchema = z.object({ action: z.enum(["approve", "reject"]) });

/**
 * PATCH /api/join-requests/[id] — the Vaad approves or rejects a
 * tenant's request to join their building. Approval attaches the user
 * to the requested apartment (created on the fly if missing).
 */
export const PATCH = withErrorHandling(
  async (req: NextRequest, { params }: { params: Promise<{ id: string }> }) => {
    const user = await requireRole(req, "vaad", "super_admin");
    const { id } = await params;
    const { action } = patchSchema.parse(await req.json());
    const db = supabaseAdmin();

    const { data: request, error } = await db
      .from("join_requests")
      .select("*")
      .eq("id", id)
      .maybeSingle();
    if (error) throw new ApiError(500, error.message);
    if (!request) throw new ApiError(404, "Join request not found");
    const decrypted = decryptJoinRequestRow(request);
    if (user.role !== "super_admin" && request.building_id !== user.building_id) {
      throw new ApiError(403, "This request belongs to another building");
    }
    if (request.status !== "pending") throw new ApiError(409, "Request already decided");

    const decidedAt = new Date().toISOString();

    if (action === "reject") {
      const { data: updated, error: e } = await db
        .from("join_requests")
        .update({ status: "rejected", decided_by: user.id, decided_at: decidedAt })
        .eq("id", id)
        .select("*")
        .single();
      if (e) throw new ApiError(500, e.message);

      void logAudit({
        buildingId: request.building_id,
        actorId: user.id,
        action: "join_rejected",
        entityType: "join_request",
        entityId: id,
        details: {
          name: decrypted.full_name ?? "",
          apartment: request.apartment_number,
        },
      });

      return NextResponse.json({ joinRequest: decryptJoinRequestRow(updated) });
    }

    await assertBuildingCapacity(request.building_id, request.apartment_number);

    let apartmentId: string | null = null;
    if (request.apartment_number) {
      const { data: apartment } = await db
        .from("apartments")
        .select("id, floor, parking_spots")
        .eq("building_id", request.building_id)
        .eq("apartment_number", request.apartment_number)
        .maybeSingle();
      if (!apartment) throw new ApiError(409, "Apartment not found in this building");
      apartmentId = apartment.id;

      const aptPatch: Record<string, unknown> = {};
      if (request.floor != null) aptPatch.floor = request.floor;
      const requestSpots = (request.parking_spots as string[] | null) ?? [];
      const existingSpots = (apartment.parking_spots as string[] | null) ?? [];
      if (requestSpots.length && existingSpots.length === 0) {
        aptPatch.parking_spots = requestSpots;
      }
      if (request.size_sqm != null) {
        aptPatch.size_sqm = request.size_sqm;
      }

      const userPatch = {
        role: "tenant" as const,
        building_id: request.building_id,
        apartment_id: apartmentId,
        ...userPiiStorageFields({
          fullName: decrypted.full_name ?? undefined,
          email: decrypted.email ?? undefined,
        }),
        ...(request.num_occupants != null
          ? { num_occupants: request.num_occupants }
          : {}),
      };

      // Parallelize the critical path so Approve feels instant.
      const [{ error: userError }, aptRes, jrRes] = await Promise.all([
        db.from("users").update(userPatch).eq("id", request.user_id),
        Object.keys(aptPatch).length > 0
          ? db.from("apartments").update(aptPatch).eq("id", apartment.id)
          : Promise.resolve({ error: null }),
        db
          .from("join_requests")
          .update({
            status: "approved",
            decided_by: user.id,
            decided_at: decidedAt,
          })
          .eq("id", id)
          .select("*")
          .single(),
      ]);

      if (userError) throw new ApiError(500, userError.message);
      if (aptRes.error) throw new ApiError(500, aptRes.error.message);
      if (jrRes.error) throw new ApiError(500, jrRes.error.message);

      await activateTenancy({
        id: request.user_id,
        building_id: request.building_id,
        apartment_id: apartment.id,
        full_name: decrypted.full_name,
        num_occupants: request.num_occupants,
      });

      void logAudit({
        buildingId: request.building_id,
        actorId: user.id,
        action: "tenant_joined",
        entityType: "user",
        entityId: request.user_id,
        details: {
          name: decrypted.full_name ?? "",
          apartment: request.apartment_number,
        },
      });

      return NextResponse.json({
        joinRequest: decryptJoinRequestRow(jrRes.data!),
      });
    }

    // No apartment number — still approve the request + attach to building.
    const [{ error: userError }, jrRes] = await Promise.all([
      db
        .from("users")
        .update({
          role: "tenant",
          building_id: request.building_id,
          apartment_id: null,
          ...userPiiStorageFields({
            fullName: decrypted.full_name ?? undefined,
            email: decrypted.email ?? undefined,
          }),
          ...(request.num_occupants != null
            ? { num_occupants: request.num_occupants }
            : {}),
        })
        .eq("id", request.user_id),
      db
        .from("join_requests")
        .update({
          status: "approved",
          decided_by: user.id,
          decided_at: decidedAt,
        })
        .eq("id", id)
        .select("*")
        .single(),
    ]);
    if (userError) throw new ApiError(500, userError.message);
    if (jrRes.error) throw new ApiError(500, jrRes.error.message);

    void logAudit({
      buildingId: request.building_id,
      actorId: user.id,
      action: "tenant_joined",
      entityType: "user",
      entityId: request.user_id,
      details: {
        name: decrypted.full_name ?? "",
        apartment: request.apartment_number,
      },
    });

    return NextResponse.json({
      joinRequest: decryptJoinRequestRow(jrRes.data!),
    });
  },
);

import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { ApiError, requireRole, withErrorHandling } from "@/lib/auth/session";
import { supabaseAdmin } from "@/lib/supabase/admin";

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
    if (user.role !== "super_admin" && request.building_id !== user.building_id) {
      throw new ApiError(403, "This request belongs to another building");
    }
    if (request.status !== "pending") throw new ApiError(409, "Request already decided");

    if (action === "reject") {
      const { data: updated, error: e } = await db
        .from("join_requests")
        .update({ status: "rejected", decided_by: user.id, decided_at: new Date().toISOString() })
        .eq("id", id)
        .select("*")
        .single();
      if (e) throw new ApiError(500, e.message);
      return NextResponse.json({ joinRequest: updated });
    }

    // Approve: resolve the apartment, then attach the requester.
    let apartmentId: string | null = null;
    if (request.apartment_number) {
      const { data: apartment } = await db
        .from("apartments")
        .select("id")
        .eq("building_id", request.building_id)
        .eq("apartment_number", request.apartment_number)
        .maybeSingle();
      if (apartment) {
        apartmentId = apartment.id;
      } else {
        const { data: createdApt, error: aptError } = await db
          .from("apartments")
          .insert({
            building_id: request.building_id,
            apartment_number: request.apartment_number,
            floor: 1,
          })
          .select("id")
          .single();
        if (aptError) throw new ApiError(500, aptError.message);
        apartmentId = createdApt.id;
      }
    }

    const { error: userError } = await db
      .from("users")
      .update({
        role: "tenant",
        building_id: request.building_id,
        apartment_id: apartmentId,
        ...(request.full_name ? { full_name: request.full_name } : {}),
      })
      .eq("id", request.user_id);
    if (userError) throw new ApiError(500, userError.message);

    const { data: updated, error: e } = await db
      .from("join_requests")
      .update({ status: "approved", decided_by: user.id, decided_at: new Date().toISOString() })
      .eq("id", id)
      .select("*")
      .single();
    if (e) throw new ApiError(500, e.message);
    return NextResponse.json({ joinRequest: updated });
  },
);

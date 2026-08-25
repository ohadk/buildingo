import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { ApiError, getCurrentUser, requireRole, withErrorHandling } from "@/lib/auth/session";
import { supabaseAdmin } from "@/lib/supabase/admin";

/** GET /api/join-requests — Vaad lists pending requests for their building. */
export const GET = withErrorHandling(async (req: NextRequest) => {
  const user = await requireRole(req, "vaad", "super_admin");
  if (!user.building_id) throw new ApiError(409, "Not mapped to a building");
  const { data, error } = await supabaseAdmin()
    .from("join_requests")
    .select("*, users!join_requests_user_id_fkey(id, phone_number, full_name)")
    .eq("building_id", user.building_id)
    .eq("status", "pending")
    .order("created_at", { ascending: true });
  if (error) throw new ApiError(500, error.message);
  return NextResponse.json({ joinRequests: data });
});

const createSchema = z.object({
  buildingId: z.string().uuid(),
  apartmentNumber: z.number().int().min(1),
  fullName: z.string().min(2).max(255),
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

  const { data: building } = await db
    .from("buildings")
    .select("id, name, is_active")
    .eq("id", body.buildingId)
    .maybeSingle();
  if (!building || !building.is_active) throw new ApiError(404, "Building not found");

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
      full_name: body.fullName,
    })
    .select("*")
    .single();
  if (error) throw new ApiError(500, error.message);

  // Remember the name so the Vaad sees who's asking.
  await db.from("users").update({ full_name: body.fullName }).eq("id", user.id);

  return NextResponse.json({ joinRequest: request }, { status: 201 });
});

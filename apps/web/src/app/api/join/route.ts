import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { ApiError, getCurrentUser, withErrorHandling } from "@/lib/auth/session";
import { supabaseAdmin } from "@/lib/supabase/admin";

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
    .select("id, name, address, city, is_active")
    .eq("join_code", code)
    .maybeSingle();
  if (building?.is_active) {
    return NextResponse.json({
      kind: "building",
      building: { id: building.id, name: building.name, address: building.address, city: building.city },
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
  const { code, apartmentNumber, fullName } = joinSchema.parse(await req.json());
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
    return NextResponse.json({ user: updated, joined: "invitation" });
  }

  // 2. Building join link → pending request awaiting Vaad approval
  const { data: building } = await db
    .from("buildings")
    .select("id, name, is_active")
    .eq("join_code", code)
    .maybeSingle();
  if (!building) throw new ApiError(404, "Code not found or expired");
  if (!building.is_active) throw new ApiError(403, "This building is suspended");
  if (!apartmentNumber) throw new ApiError(400, "apartmentNumber is required for a building join link");
  if (!fullName || fullName.trim().length < 2) {
    throw new ApiError(400, "fullName is required so the Vaad knows who's asking");
  }

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
    })
    .select("*")
    .single();
  if (error) throw new ApiError(500, error.message);

  await db.from("users").update({ full_name: fullName.trim() }).eq("id", user.id);

  return NextResponse.json({ joinRequest: request, joined: "pending" }, { status: 201 });
});

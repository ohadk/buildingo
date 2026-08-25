import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { ApiError, requireRole, withErrorHandling } from "@/lib/auth/session";
import { supabaseAdmin } from "@/lib/supabase/admin";
import { sendSms } from "@/lib/notify";

const createSchema = z.object({
  apartmentId: z.string().uuid(),
  phoneNumber: z.string().regex(/^\+[1-9]\d{6,14}$/, "Phone must be E.164, e.g. +9725..."),
  role: z.enum(["tenant", "vaad"]).default("tenant"),
  // Super admins (not tied to a building) must name the target building;
  // Vaad members always invite into their own.
  buildingId: z.string().uuid().optional(),
});

/** GET /api/invitations — Vaad lists invitations for their building. */
export const GET = withErrorHandling(async (req: NextRequest) => {
  const user = await requireRole(req, "vaad", "super_admin");
  const { data, error } = await supabaseAdmin()
    .from("invitations")
    .select("*, apartments(apartment_number, floor)")
    .eq("building_id", user.building_id!)
    .order("created_at", { ascending: false });
  if (error) throw new ApiError(500, error.message);
  return NextResponse.json({ invitations: data });
});

/**
 * POST /api/invitations — Vaad invites a phone number into a unit.
 * Sends the invite link by SMS when Twilio is configured.
 */
export const POST = withErrorHandling(async (req: NextRequest) => {
  const user = await requireRole(req, "vaad", "super_admin");
  const { apartmentId, phoneNumber, role, buildingId } = createSchema.parse(await req.json());
  const targetBuilding = user.role === "super_admin" ? buildingId : user.building_id;
  if (!targetBuilding) throw new ApiError(400, "buildingId is required");
  const db = supabaseAdmin();

  const { data: apartment } = await db
    .from("apartments")
    .select("id, apartment_number")
    .eq("id", apartmentId)
    .eq("building_id", targetBuilding)
    .maybeSingle();
  if (!apartment) throw new ApiError(404, "Apartment not found in your building");

  // If this phone already has an account, grant access right away —
  // no need to wait for their next sign-in.
  const { data: existingUser, error: lookupError } = await db
    .from("users")
    .select("id, role")
    .eq("phone_number", phoneNumber)
    .maybeSingle();
  if (lookupError) throw new ApiError(500, lookupError.message);
  if (existingUser?.role === "super_admin") {
    throw new ApiError(400, "This phone number belongs to a platform admin");
  }

  // Replace any previous pending invite for this phone in this building,
  // so re-assigning doesn't pile up duplicates.
  await db
    .from("invitations")
    .update({ status: "revoked" })
    .eq("building_id", targetBuilding)
    .eq("phone_number", phoneNumber)
    .eq("status", "pending");

  const { data: invite, error } = await db
    .from("invitations")
    .insert({
      building_id: targetBuilding,
      apartment_id: apartmentId,
      phone_number: phoneNumber,
      role,
      created_by: user.id,
      ...(existingUser ? { status: "accepted", accepted_by: existingUser.id } : {}),
    })
    .select("*")
    .single();
  if (error) throw new ApiError(500, error.message);

  if (existingUser) {
    const { error: assignError } = await db
      .from("users")
      .update({ role, building_id: targetBuilding, apartment_id: apartmentId })
      .eq("id", existingUser.id);
    if (assignError) throw new ApiError(500, assignError.message);
  }

  const sms = await sendSms(
    phoneNumber,
    existingUser
      ? `You've been added to your building on Dira (apartment ${apartment.apartment_number}) as ${role}. ` +
          `Open the app — your access is already active.`
      : `You've been invited to join your building on Dira (apartment ${apartment.apartment_number}). ` +
          `Sign in with this phone number to accept: https://dira.app — code ${invite.invite_code}`,
  );

  return NextResponse.json(
    { invitation: invite, smsDelivery: sms, assignedImmediately: Boolean(existingUser) },
    { status: 201 },
  );
});

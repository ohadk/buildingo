import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { ApiError, getCurrentUser, withErrorHandling } from "@/lib/auth/session";
import { supabaseAdmin } from "@/lib/supabase/admin";

const bodySchema = z.object({
  fullName: z.string().min(2).max(255),
  numOccupants: z.number().int().min(1).max(50),
});

/**
 * POST /api/onboarding — completes the tenant profile after the invite
 * was consumed during token exchange. Lease upload is a separate
 * multipart call (POST /api/onboarding/lease).
 */
export const POST = withErrorHandling(async (req: NextRequest) => {
  const user = await getCurrentUser(req);
  if (!user.building_id || !user.apartment_id) {
    throw new ApiError(409, "No apartment mapped yet — ask your Vaad for an invitation");
  }

  const { fullName, numOccupants } = bodySchema.parse(await req.json());

  const { data, error } = await supabaseAdmin()
    .from("users")
    .update({
      full_name: fullName,
      num_occupants: numOccupants,
      onboarded_at: new Date().toISOString(),
    })
    .eq("id", user.id)
    .select("*")
    .single();
  if (error) throw new ApiError(500, error.message);

  return NextResponse.json({ user: data });
});

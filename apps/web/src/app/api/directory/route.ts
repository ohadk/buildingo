import { NextRequest, NextResponse } from "next/server";
import { ApiError, getCurrentUser, withErrorHandling } from "@/lib/auth/session";
import { supabaseAdmin } from "@/lib/supabase/admin";

/**
 * GET /api/directory — floor/apartment resident listing with parking
 * space IDs, for everyone in the caller's building.
 */
export const GET = withErrorHandling(async (req: NextRequest) => {
  const user = await getCurrentUser(req);
  if (!user.building_id) throw new ApiError(409, "Not mapped to a building");

  const db = supabaseAdmin();
  const { data, error } = await db
    .from("apartments")
    .select("id, apartment_number, floor, parking_spot, users(id, full_name, phone_number, role, num_occupants)")
    .eq("building_id", user.building_id)
    .order("floor")
    .order("apartment_number");
  if (error) throw new ApiError(500, error.message);

  // Vaad also sees which apartments have an invite out that hasn't been
  // accepted yet ("invited, waiting to connect").
  let pendingInvitations: unknown[] = [];
  if (user.role === "vaad" || user.role === "super_admin") {
    const { data: invites, error: invErr } = await db
      .from("invitations")
      .select("id, apartment_id, phone_number, invite_code, created_at")
      .eq("building_id", user.building_id)
      .eq("status", "pending")
      .gt("expires_at", new Date().toISOString());
    if (invErr) throw new ApiError(500, invErr.message);
    pendingInvitations = invites ?? [];
  }

  return NextResponse.json({ directory: data, pendingInvitations });
});

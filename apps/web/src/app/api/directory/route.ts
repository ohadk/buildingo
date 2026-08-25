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

  const { data, error } = await supabaseAdmin()
    .from("apartments")
    .select("id, apartment_number, floor, parking_spot, users(id, full_name, phone_number, role, num_occupants)")
    .eq("building_id", user.building_id)
    .order("floor")
    .order("apartment_number");
  if (error) throw new ApiError(500, error.message);

  return NextResponse.json({ directory: data });
});

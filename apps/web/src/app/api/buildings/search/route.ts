import { NextRequest, NextResponse } from "next/server";
import { ApiError, getCurrentUser, withErrorHandling } from "@/lib/auth/session";
import { supabaseAdmin } from "@/lib/supabase/admin";

/**
 * GET /api/buildings/search?city=&address=&country= — a signed-in user
 * looks up a building by address before asking to join it. Only basic
 * identity fields are exposed.
 */
export const GET = withErrorHandling(async (req: NextRequest) => {
  await getCurrentUser(req);
  const city = req.nextUrl.searchParams.get("city")?.trim() ?? "";
  const address = req.nextUrl.searchParams.get("address")?.trim() ?? "";
  const country = req.nextUrl.searchParams.get("country")?.trim() ?? "";
  if (city.length < 2 && address.length < 2) {
    throw new ApiError(400, "Provide a city or address to search");
  }

  let query = supabaseAdmin()
    .from("buildings")
    .select("id, name, address, city, country")
    .eq("is_active", true)
    .limit(8);
  if (city) query = query.ilike("city", `%${city}%`);
  if (address) query = query.ilike("address", `%${address}%`);
  if (country) query = query.ilike("country", `%${country}%`);

  const { data, error } = await query;
  if (error) throw new ApiError(500, error.message);
  return NextResponse.json({ buildings: data });
});

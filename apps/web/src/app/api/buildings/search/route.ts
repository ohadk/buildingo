import { NextRequest, NextResponse } from "next/server";
import { ApiError, getCurrentUser, withErrorHandling } from "@/lib/auth/session";
import { supabaseAdmin } from "@/lib/supabase/admin";

/**
 * GET /api/buildings/search — a signed-in user looks up a building
 * before asking to join it. Only basic identity fields are exposed.
 *
 * Autocomplete modes (values come from OUR buildings, so a selection is
 * guaranteed to match exactly):
 *   ?suggest=city&q=תל        → distinct city names
 *   ?suggest=address&city=תל אביב&q=דיז → distinct addresses in that city
 *
 * Search mode:
 *   ?city=תל אביב&address=דיזנגוף 10   → matching buildings
 */
export const GET = withErrorHandling(async (req: NextRequest) => {
  await getCurrentUser(req);
  const p = req.nextUrl.searchParams;
  const db = supabaseAdmin();

  const suggest = p.get("suggest");
  if (suggest === "city" || suggest === "address") {
    const q = p.get("q")?.trim() ?? "";
    const column = suggest === "city" ? "city" : "address";
    let query = db
      .from("buildings")
      .select(column)
      .eq("is_active", true)
      .order(column)
      .limit(50);
    if (q) query = query.ilike(column, `%${q}%`);
    if (suggest === "address") {
      const city = p.get("city")?.trim() ?? "";
      if (!city) throw new ApiError(400, "city is required for address suggestions");
      query = query.eq("city", city);
    }
    const { data, error } = await query;
    if (error) throw new ApiError(500, error.message);
    const values = [
      ...new Set(
        (data as Record<string, string>[]).map((r) => r[column]).filter(Boolean),
      ),
    ].slice(0, 10);
    return NextResponse.json({ suggestions: values });
  }

  const city = p.get("city")?.trim() ?? "";
  const address = p.get("address")?.trim() ?? "";
  if (city.length < 2 && address.length < 2) {
    throw new ApiError(400, "Provide a city or address to search");
  }

  let query = db
    .from("buildings")
    .select("id, name, address, city, country, require_join_docs, fee_method")
    .eq("is_active", true)
    .limit(8);
  // City comes from our own autocomplete, so match it exactly; the
  // address may be partial while typing.
  if (city) query = query.eq("city", city);
  if (address) query = query.ilike("address", `%${address}%`);

  const { data, error } = await query;
  if (error) throw new ApiError(500, error.message);
  return NextResponse.json({ buildings: data });
});

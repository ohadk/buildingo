import { NextRequest, NextResponse } from "next/server";
import { ApiError, getCurrentUser, withErrorHandling } from "@/lib/auth/session";
import { findActiveBuildingByAddress } from "@/lib/find-building-by-address";
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
 *   ?exact=1&city=…&address=…[&country=…] → identity lookup (hash + soft match)
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
  const country = p.get("country")?.trim() || "ישראל";
  if (city.length < 2 && address.length < 2) {
    throw new ApiError(400, "Provide a city or address to search");
  }

  const exact = p.get("exact") === "1" || p.get("exact") === "true";

  if (exact) {
    if (city.length < 2 || address.length < 2) {
      throw new ApiError(400, "exact search requires city and address");
    }
    try {
      const { building, canonical } = await findActiveBuildingByAddress({
        city,
        address,
        country,
      });
      return NextResponse.json({
        buildings: building ? [building] : [],
        addressHash: canonical.addressHash,
        canonical: {
          city: canonical.city,
          address: canonical.address,
          country: canonical.country,
          name: canonical.name,
        },
      });
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err);
      throw new ApiError(500, message);
    }
  }

  let query = db
    .from("buildings")
    .select("id, name, address, city, country, require_join_docs, fee_method")
    .eq("is_active", true)
    .limit(8);
  if (city) query = query.eq("city", city);
  if (address) query = query.ilike("address", `%${address}%`);

  const { data, error } = await query;
  if (error) throw new ApiError(500, error.message);
  return NextResponse.json({ buildings: data });
});

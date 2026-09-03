import {
  canonicalizeBuildingAddress,
  isSameBuildingAddress,
  normalizeCity,
  normalizeStreetAddress,
} from "@/lib/building-address";
import { supabaseAdmin } from "@/lib/supabase/admin";

export type BuildingAddressHit = {
  id: string;
  name: string;
  address: string;
  city: string;
  country: string | null;
  require_join_docs?: boolean;
  fee_method?: string;
};

type AddressParts = {
  city: string;
  address?: string | null;
  street?: string | null;
  houseNumber?: string | null;
  country?: string | null;
};

/**
 * Find an active building at this physical address.
 * Always canonicalizes input first (single source of truth), then:
 * 1) address_hash equality
 * 2) city-scoped candidate scan with normalized compare
 */
export async function findActiveBuildingByAddress(
  parts: AddressParts,
): Promise<{
  building: BuildingAddressHit | null;
  canonical: ReturnType<typeof canonicalizeBuildingAddress>;
}> {
  const canonical = canonicalizeBuildingAddress(parts);
  const { city, address, country, addressHash } = canonical;
  const db = supabaseAdmin();
  const select =
    "id, name, address, city, country, require_join_docs, fee_method";

  // Fast path: normalized hash.
  {
    const { data, error } = await db
      .from("buildings")
      .select(select)
      .eq("is_active", true)
      .eq("address_hash", addressHash)
      .limit(1);
    if (!error && data?.[0]) {
      return { building: data[0] as BuildingAddressHit, canonical };
    }
  }

  // Soft path: same city (fuzzy), then normalized equality in app code.
  const cityNeedle = normalizeCity(city);
  const streetNeedle = normalizeStreetAddress(address);
  const houseMatch = streetNeedle.match(/(\d+[א-תa-z]?)$/i)?.[1];

  let query = db
    .from("buildings")
    .select(select)
    .eq("is_active", true)
    .limit(60);

  if (cityNeedle.length >= 2) {
    query = query.ilike("city", `%${cityNeedle}%`);
  } else if (houseMatch) {
    query = query.ilike("address", `%${houseMatch}%`);
  }

  const { data: candidates, error } = await query;
  if (error) {
    if (/address_hash|schema cache/i.test(error.message)) {
      const fallback = await db
        .from("buildings")
        .select(select)
        .eq("is_active", true)
        .ilike("city", `%${city}%`)
        .limit(60);
      const hit = (fallback.data ?? []).find((b) =>
        isSameBuildingAddress(
          { city: b.city, address: b.address, country: b.country },
          canonical,
        ),
      );
      return {
        building: (hit as BuildingAddressHit | undefined) ?? null,
        canonical,
      };
    }
    throw error;
  }

  const hit = (candidates ?? []).find((b) =>
    isSameBuildingAddress(
      { city: b.city, address: b.address, country: b.country },
      canonical,
    ),
  );

  if (hit) {
    return { building: hit as BuildingAddressHit, canonical };
  }

  const streetToken = streetNeedle.replace(/\s+\d+[א-תa-z]?$/i, "").trim();
  if (streetToken.length >= 2) {
    const { data: byStreet } = await db
      .from("buildings")
      .select(select)
      .eq("is_active", true)
      .ilike("address", `%${streetToken}%`)
      .limit(40);
    const soft = (byStreet ?? []).find((b) =>
      isSameBuildingAddress(
        { city: b.city, address: b.address, country: b.country },
        canonical,
      ),
    );
    if (soft) {
      return { building: soft as BuildingAddressHit, canonical };
    }
  }

  return { building: null, canonical };
}

/** Re-export for callers that only need canonicalize. */
export { canonicalizeBuildingAddress };

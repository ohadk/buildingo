import { createHash } from "crypto";

/**
 * SINGLE SOURCE OF TRUTH for building address identity.
 *
 * All create / search / duplicate checks must go through
 * `canonicalizeBuildingAddress` (or `buildingAddressHash` derived from it).
 *
 * SQL twin (must stay aligned):
 *   supabase/migrations/0031_building_address_hash.sql
 *   supabase/migrations/0032_address_normalize_strengthen.sql
 *
 * Dart twin (compose / strip prefix for the mobile client):
 *   apps/mobile/lib/core/building_address.dart
 */

/** Common city spellings → one canonical Hebrew form (storage + hash). */
const CITY_ALIASES: Record<string, string> = {
  "פתח תקוה": "פתח תקווה",
  "פתח-תקווה": "פתח תקווה",
  "פתח-תקוה": "פתח תקווה",
  "petah tikva": "פתח תקווה",
  "petah tiqwa": "פתח תקווה",
  "petach tikva": "פתח תקווה",
  "תל אביב": "תל אביב - יפו",
  "תל אביב יפו": "תל אביב - יפו",
  "תל-אביב": "תל אביב - יפו",
  "tel aviv": "תל אביב - יפו",
  "tel aviv-yafo": "תל אביב - יפו",
  "ראשלצ": "ראשון לציון",
};

/**
 * Street-type prefixes people type before the street name.
 * Keep in sync with Dart `BuildingAddress.streetPrefix` and SQL 0032.
 */
export const STREET_PREFIX =
  /^(רחוב|רח'|רח׳|רח|street|st\.?|שדרות|שד'|שד׳|שד|avenue|ave\.?|סמטת|סמטה|סמ'|סמ׳|סמ|alley)\s+/i;

export type BuildingAddressInput = {
  city: string;
  country?: string | null;
  /** Full "street + house" line, e.g. "רח מייזנר 17". */
  address?: string | null;
  street?: string | null;
  houseNumber?: string | null;
};

export type CanonicalBuildingAddress = {
  /** Canonical country label (ישראל folded). */
  country: string;
  /** Canonical city (aliases applied, trimmed). */
  city: string;
  /** Canonical street+number without type prefix ("מייזנר 17"). */
  address: string;
  /** Display / default building name. */
  name: string;
  /** MD5 of normalized country\\ncity\\naddress — unique among active buildings. */
  addressHash: string;
};

export function collapseSpaces(value: string): string {
  return value.trim().replace(/\s+/g, " ");
}

/** Lowercase + collapse spaces — used only for hashing / compare keys. */
export function normalizeAddressPart(value: string): string {
  return collapseSpaces(value).toLowerCase();
}

/** Strip רח/רחוב/… while preserving the rest of the original casing. */
export function stripStreetPrefix(value: string): string {
  let s = collapseSpaces(value);
  for (let i = 0; i < 2; i++) {
    const next = s.replace(STREET_PREFIX, "").trim();
    if (next === s) break;
    s = next;
  }
  return s.replace(/^["'\u05F3\u05F4]+|["'\u05F3\u05F4]+$/g, "").trim();
}

/** Fold city aliases → canonical Hebrew (or collapsed original). */
export function canonicalizeCity(value: string): string {
  const collapsed = collapseSpaces(value);
  const alias = CITY_ALIASES[normalizeAddressPart(collapsed)];
  return alias ?? collapsed;
}

/** Hash/compare form of city. */
export function normalizeCity(value: string): string {
  return normalizeAddressPart(canonicalizeCity(value));
}

/**
 * Compose street + house, then strip street-type prefixes.
 * "רח", "מייזנר", "17" → "מייזנר 17"
 */
export function composeStreetAddress(
  street: string,
  houseNumber?: string | null,
): string {
  const s = stripStreetPrefix(street);
  const n = (houseNumber ?? "").trim();
  if (!s) return n;
  if (!n) return s;
  // Avoid "מייזנר 17 17" when house is already in the street field.
  if (new RegExp(`(^|\\s)${escapeRegExp(n)}$`).test(s)) return s;
  return `${s} ${n}`;
}

/** Hash/compare form of street+number. */
export function normalizeStreetAddress(value: string): string {
  return normalizeAddressPart(stripStreetPrefix(value));
}

/** Fold common Israel country labels onto one storage token. */
export function canonicalizeCountry(value?: string | null): string {
  const raw = collapseSpaces(value || "ישראל");
  const n = normalizeAddressPart(raw);
  if (
    n === "israel" ||
    n === "il" ||
    n === "ישראל" ||
    n === "state of israel" ||
    n === ""
  ) {
    return "ישראל";
  }
  return raw;
}

/** Hash/compare form of country. */
export function normalizeCountry(value?: string | null): string {
  return normalizeAddressPart(canonicalizeCountry(value));
}

function escapeRegExp(s: string): string {
  return s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

/**
 * Resolve street/house/address inputs into one canonical triple + hash.
 * This is what every write path and exact-duplicate check must use.
 */
export function canonicalizeBuildingAddress(
  input: BuildingAddressInput,
): CanonicalBuildingAddress {
  const country = canonicalizeCountry(input.country);
  const city = canonicalizeCity(input.city);

  let address: string;
  if (input.street != null && collapseSpaces(input.street).length > 0) {
    address = composeStreetAddress(input.street, input.houseNumber);
  } else {
    address = stripStreetPrefix(input.address ?? "");
  }

  if (!city || !address) {
    throw new Error("canonicalizeBuildingAddress requires city and address");
  }

  const addressHash = buildingAddressHash({ city, address, country });
  return {
    country,
    city,
    address,
    name: `${address}, ${city}`,
    addressHash,
  };
}

export function buildingAddressKey(parts: {
  city: string;
  address: string;
  country?: string | null;
}): string {
  return [
    normalizeCountry(parts.country),
    normalizeCity(parts.city),
    normalizeStreetAddress(parts.address),
  ].join("\n");
}

/** Stable MD5 hex — same algorithm as Postgres `md5(...)`. */
export function buildingAddressHash(parts: {
  city: string;
  address: string;
  country?: string | null;
}): string {
  return createHash("md5")
    .update(buildingAddressKey(parts), "utf8")
    .digest("hex");
}

/** True when two address triples identify the same physical building. */
export function isSameBuildingAddress(
  a: { city: string; address: string; country?: string | null },
  b: { city: string; address: string; country?: string | null },
): boolean {
  return buildingAddressHash(a) === buildingAddressHash(b);
}

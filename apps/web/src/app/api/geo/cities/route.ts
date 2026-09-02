import { NextRequest, NextResponse } from "next/server";

// Official Israeli locality registry (data.gov.il, free & keyless).
const CITIES_RESOURCE = "5c78e9fa-c2e2-4771-93ff-7f400a12f7ba";
const MIN_QUERY = 3;
const CACHE_TTL_MS = 24 * 60 * 60 * 1000;

let citiesCache: string[] | null = null;
let citiesCacheAt = 0;

async function loadCities(): Promise<string[]> {
  if (citiesCache && Date.now() - citiesCacheAt < CACHE_TTL_MS) {
    return citiesCache;
  }
  const url = new URL("https://data.gov.il/api/3/action/datastore_search");
  url.searchParams.set("resource_id", CITIES_RESOURCE);
  url.searchParams.set("limit", "5000");
  url.searchParams.set("fields", "שם_ישוב");

  const res = await fetch(url.toString(), { next: { revalidate: 86400 } });
  const data = await res.json();
  const names = [
    ...new Set(
      ((data.result?.records ?? []) as Record<string, string>[])
        .map((r) => (r["שם_ישוב"] ?? "").trim())
        .filter(Boolean),
    ),
  ].sort((a, b) => a.localeCompare(b, "he"));
  citiesCache = names;
  citiesCacheAt = Date.now();
  return names;
}

function rankMatches(names: string[], q: string, limit = 10): string[] {
  const starts: string[] = [];
  const contains: string[] = [];
  for (const n of names) {
    if (n.startsWith(q)) starts.push(n);
    else if (n.includes(q)) contains.push(n);
    if (starts.length >= limit) break;
  }
  return [...starts, ...contains].slice(0, limit);
}

/** GET /api/geo/cities?q=פתח — city name autocomplete (prefix after 3 chars). */
export async function GET(req: NextRequest) {
  const q = req.nextUrl.searchParams.get("q")?.trim();
  if (!q || q.length < MIN_QUERY) return NextResponse.json({ cities: [] });

  try {
    const cities = rankMatches(await loadCities(), q);
    return NextResponse.json({ cities });
  } catch {
    return NextResponse.json({ cities: [] });
  }
}

import { NextRequest, NextResponse } from "next/server";

// Official Israeli street registry (data.gov.il, free & keyless).
const STREETS_RESOURCE = "9ad3862c-8391-4b2f-84a4-2d4c68625f4b";
const MIN_QUERY = 3;
const CACHE_TTL_MS = 24 * 60 * 60 * 1000;

const streetsByCity = new Map<string, { at: number; streets: string[] }>();

async function loadStreetsForCity(city: string): Promise<string[]> {
  const cached = streetsByCity.get(city);
  if (cached && Date.now() - cached.at < CACHE_TTL_MS) {
    return cached.streets;
  }

  const url = new URL("https://data.gov.il/api/3/action/datastore_search");
  url.searchParams.set("resource_id", STREETS_RESOURCE);
  url.searchParams.set("limit", "5000");
  url.searchParams.set("fields", "שם_רחוב");
  url.searchParams.set("filters", JSON.stringify({ שם_ישוב: city }));

  const res = await fetch(url.toString(), { next: { revalidate: 86400 } });
  const data = await res.json();
  const streets = [
    ...new Set(
      ((data.result?.records ?? []) as Record<string, string>[])
        .map((r) => (r["שם_רחוב"] ?? "").trim())
        .filter(Boolean),
    ),
  ].sort((a, b) => a.localeCompare(b, "he"));

  streetsByCity.set(city, { at: Date.now(), streets });
  return streets;
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

/** GET /api/geo/streets?q=מיי&city=פתח תקווה — street autocomplete (prefix after 3 chars). */
export async function GET(req: NextRequest) {
  const q = req.nextUrl.searchParams.get("q")?.trim();
  const city = req.nextUrl.searchParams.get("city")?.trim();
  if (!q || q.length < MIN_QUERY || !city) {
    return NextResponse.json({ streets: [] });
  }

  try {
    const streets = rankMatches(await loadStreetsForCity(city), q);
    return NextResponse.json({ streets });
  } catch {
    return NextResponse.json({ streets: [] });
  }
}

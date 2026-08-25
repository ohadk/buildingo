import { NextRequest, NextResponse } from "next/server";

// Official Israeli locality registry (data.gov.il, free & keyless).
const CITIES_RESOURCE = "5c78e9fa-c2e2-4771-93ff-7f400a12f7ba";

/** GET /api/geo/cities?q=תל — city name autocomplete. */
export async function GET(req: NextRequest) {
  const q = req.nextUrl.searchParams.get("q")?.trim();
  if (!q || q.length < 2) return NextResponse.json({ cities: [] });

  const url = new URL("https://data.gov.il/api/3/action/datastore_search");
  url.searchParams.set("resource_id", CITIES_RESOURCE);
  url.searchParams.set("q", q);
  url.searchParams.set("limit", "50");

  try {
    const res = await fetch(url, { next: { revalidate: 86400 } });
    const data = await res.json();
    const names: string[] = (data.result?.records ?? []).map(
      (r: Record<string, string>) => (r["שם_ישוב"] ?? "").trim(),
    );
    // Full-text search also matches district/municipality fields; keep only
    // localities whose own name contains the query.
    const cities = [...new Set(names.filter((n) => n && n.includes(q)))].slice(0, 10);
    return NextResponse.json({ cities });
  } catch {
    return NextResponse.json({ cities: [] });
  }
}

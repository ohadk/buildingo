import { NextRequest, NextResponse } from "next/server";

// Official Israeli street registry (data.gov.il, free & keyless).
const STREETS_RESOURCE = "9ad3862c-8391-4b2f-84a4-2d4c68625f4b";

/** GET /api/geo/streets?q=הרצ&city=תל אביב - יפו — street autocomplete. */
export async function GET(req: NextRequest) {
  const q = req.nextUrl.searchParams.get("q")?.trim();
  const city = req.nextUrl.searchParams.get("city")?.trim();
  if (!q || q.length < 2) return NextResponse.json({ streets: [] });

  const url = new URL("https://data.gov.il/api/3/action/datastore_search");
  url.searchParams.set("resource_id", STREETS_RESOURCE);
  url.searchParams.set("q", q);
  url.searchParams.set("limit", "100");

  try {
    const res = await fetch(url, { next: { revalidate: 86400 } });
    const data = await res.json();
    let records: Record<string, string>[] = data.result?.records ?? [];
    if (city) {
      records = records.filter((r) => (r["שם_ישוב"] ?? "").trim() === city);
    }
    const streets = [
      ...new Set(records.map((r) => (r["שם_רחוב"] ?? "").trim()).filter(Boolean)),
    ].slice(0, 10);
    return NextResponse.json({ streets });
  } catch {
    return NextResponse.json({ streets: [] });
  }
}

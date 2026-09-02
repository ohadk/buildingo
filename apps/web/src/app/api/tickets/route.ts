import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { ApiError, getCurrentUser, withErrorHandling } from "@/lib/auth/session";
import { logAudit } from "@/lib/audit";
import { supabaseAdmin } from "@/lib/supabase/admin";

const createSchema = z.object({
  title: z.string().min(3).max(255),
  description: z.string().max(4000).optional().default(""),
  location: z.string().max(100).optional(),
  imagePath: z.string().max(500).optional(),
  imagePaths: z.array(z.string().max(500)).max(8).optional(),
  category: z
    .enum(["leak", "elevator", "cleaning", "lights", "electric", "door", "other"])
    .optional()
    .default("other"),
});

function parseStoredImagePaths(imagePath: string | null | undefined): string[] {
  if (!imagePath) return [];
  if (imagePath.startsWith("[")) {
    try {
      const parsed = JSON.parse(imagePath) as unknown;
      if (Array.isArray(parsed)) {
        return parsed.filter((p): p is string => typeof p === "string" && p.length > 0);
      }
    } catch {
      /* fall through */
    }
  }
  return [imagePath];
}

function serializeImagePaths(paths: string[]): string | null {
  if (paths.length === 0) return null;
  if (paths.length === 1) return paths[0];
  return JSON.stringify(paths);
}

/** Serve ticket photos via the authenticated API proxy (not Supabase signed URLs). */
function ticketImageUrls(
  origin: string,
  imagePath: string | null | undefined
): { image_url: string | null; image_urls: string[] } {
  const paths = parseStoredImagePaths(imagePath);
  const urls = paths.map(
    (path) =>
      `${origin}/api/files/content?bucket=documents&path=${encodeURIComponent(path)}`
  );
  return { image_url: urls[0] ?? null, image_urls: urls };
}

/** GET /api/tickets — all tickets in the caller's building, with timeline. */
export const GET = withErrorHandling(async (req: NextRequest) => {
  const user = await getCurrentUser(req);
  if (!user.building_id) throw new ApiError(409, "Not mapped to a building");

  const db = supabaseAdmin();
  const { data, error } = await db
    .from("tickets")
    .select("*, ticket_events(*), vendor_agents(vendor_name, service_type), reporter:users!tickets_reported_by_fkey(full_name)")
    .eq("building_id", user.building_id)
    .order("created_at", { ascending: false })
    .order("created_at", { referencedTable: "ticket_events", ascending: true });
  if (error) throw new ApiError(500, error.message);

  const origin = req.nextUrl.origin;
  const tickets = (data ?? []).map((t) => {
    const images = ticketImageUrls(origin, t.image_path);
    const receipt_url = t.receipt_path
      ? `${origin}/api/files/content?bucket=receipts&path=${encodeURIComponent(t.receipt_path)}`
      : null;
    return {
      ...t,
      ...images,
      cost_amount: t.cost_amount ?? null,
      progress_note: t.progress_note ?? null,
      fix_date: t.fix_date ?? null,
      receipt_url,
    };
  });

  return NextResponse.json({ tickets });
});

/** POST /api/tickets — tenant (or vaad) reports a fault. */
export const POST = withErrorHandling(async (req: NextRequest) => {
  const user = await getCurrentUser(req);
  if (!user.building_id) throw new ApiError(409, "Not mapped to a building");

  const { title, description, location, imagePath, imagePaths, category } =
    createSchema.parse(await req.json());
  const db = supabaseAdmin();
  const paths = [
    ...new Set([...(imagePaths ?? []), ...(imagePath ? [imagePath] : [])]),
  ];

  const baseRow = {
    building_id: user.building_id,
    apartment_id: user.apartment_id,
    reported_by: user.id,
    title,
    description: description ?? "",
    location: location ?? null,
    image_path: serializeImagePaths(paths),
  };

  let { data: ticket, error } = await db
    .from("tickets")
    .insert({ ...baseRow, category })
    .select("*")
    .single();

  // Migration 0024 not applied yet — fall back so reports still work.
  if (
    error &&
    /category/i.test(error.message) &&
    /schema cache|column/i.test(error.message)
  ) {
    ({ data: ticket, error } = await db
      .from("tickets")
      .insert(baseRow)
      .select("*")
      .single());
  }
  if (error) throw new ApiError(500, error.message);
  if (!ticket) throw new ApiError(500, "Failed to create ticket");

  await db.from("ticket_events").insert({
    ticket_id: ticket.id,
    building_id: user.building_id,
    label: "Reported",
    detail: `Reported by ${user.full_name || user.phone_number}`,
    actor: user.id,
  });

  await logAudit({
    buildingId: user.building_id,
    actorId: user.id,
    action: "ticket_created",
    entityType: "ticket",
    entityId: ticket.id,
    details: { title, category, ...(location ? { location } : {}) },
  });

  return NextResponse.json({ ticket }, { status: 201 });
});

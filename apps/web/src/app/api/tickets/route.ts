import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { ApiError, getCurrentUser, withErrorHandling } from "@/lib/auth/session";
import { logAudit } from "@/lib/audit";
import { supabaseAdmin } from "@/lib/supabase/admin";

const createSchema = z.object({
  title: z.string().min(3).max(255),
  description: z.string().min(3),
  location: z.string().max(100).optional(),
  imagePath: z.string().max(500).optional(),
});

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

  const tickets = await Promise.all(
    (data ?? []).map(async (t) => {
      let image_url: string | null = null;
      if (t.image_path) {
        const { data: signed } = await db.storage
          .from("documents")
          .createSignedUrl(t.image_path, 60 * 60);
        image_url = signed?.signedUrl ?? null;
      }
      return { ...t, image_url };
    })
  );

  return NextResponse.json({ tickets });
});

/** POST /api/tickets — tenant (or vaad) reports a fault. */
export const POST = withErrorHandling(async (req: NextRequest) => {
  const user = await getCurrentUser(req);
  if (!user.building_id) throw new ApiError(409, "Not mapped to a building");

  const { title, description, location, imagePath } = createSchema.parse(await req.json());
  const db = supabaseAdmin();

  const { data: ticket, error } = await db
    .from("tickets")
    .insert({
      building_id: user.building_id,
      apartment_id: user.apartment_id,
      reported_by: user.id,
      title,
      description,
      location: location ?? null,
      image_path: imagePath ?? null,
    })
    .select("*")
    .single();
  if (error) throw new ApiError(500, error.message);

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
    details: { title, ...(location ? { location } : {}) },
  });

  return NextResponse.json({ ticket }, { status: 201 });
});

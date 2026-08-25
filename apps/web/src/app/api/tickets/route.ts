import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { ApiError, getCurrentUser, withErrorHandling } from "@/lib/auth/session";
import { supabaseAdmin } from "@/lib/supabase/admin";

const createSchema = z.object({
  title: z.string().min(3).max(255),
  description: z.string().min(3),
  imagePath: z.string().optional(),
});

/** GET /api/tickets — all tickets in the caller's building, with timeline. */
export const GET = withErrorHandling(async (req: NextRequest) => {
  const user = await getCurrentUser(req);
  if (!user.building_id) throw new ApiError(409, "Not mapped to a building");

  const { data, error } = await supabaseAdmin()
    .from("tickets")
    .select("*, ticket_events(*), vendor_agents(vendor_name, service_type), reporter:users!tickets_reported_by_fkey(full_name)")
    .eq("building_id", user.building_id)
    .order("created_at", { ascending: false })
    .order("created_at", { referencedTable: "ticket_events", ascending: true });
  if (error) throw new ApiError(500, error.message);

  return NextResponse.json({ tickets: data });
});

/** POST /api/tickets — tenant (or vaad) reports a fault. */
export const POST = withErrorHandling(async (req: NextRequest) => {
  const user = await getCurrentUser(req);
  if (!user.building_id) throw new ApiError(409, "Not mapped to a building");

  const { title, description, imagePath } = createSchema.parse(await req.json());
  const db = supabaseAdmin();

  const { data: ticket, error } = await db
    .from("tickets")
    .insert({
      building_id: user.building_id,
      apartment_id: user.apartment_id,
      reported_by: user.id,
      title,
      description,
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

  return NextResponse.json({ ticket }, { status: 201 });
});

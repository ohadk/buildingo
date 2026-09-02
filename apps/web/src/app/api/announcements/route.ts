import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { ApiError, getCurrentUser, requireRole, withErrorHandling } from "@/lib/auth/session";
import { logAudit } from "@/lib/audit";
import { supabaseAdmin } from "@/lib/supabase/admin";
import { isWahaConfigured, sendText } from "@/lib/waha/client";

const createSchema = z.object({
  title: z.string().min(2).max(255),
  body: z.string().min(1),
  eventDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional().nullable(),
});

/** GET /api/announcements — the building's community board. */
export const GET = withErrorHandling(async (req: NextRequest) => {
  const user = await getCurrentUser(req);
  if (!user.building_id) throw new ApiError(409, "Not mapped to a building");

  const { data, error } = await supabaseAdmin()
    .from("announcements")
    .select("*")
    .eq("building_id", user.building_id)
    .order("created_at", { ascending: false })
    .limit(50);
  if (error) throw new ApiError(500, error.message);
  return NextResponse.json({ announcements: data });
});

/** POST /api/announcements — Vaad posts to the board. */
export const POST = withErrorHandling(async (req: NextRequest) => {
  const user = await requireRole(req, "vaad", "super_admin");
  const body = createSchema.parse(await req.json());

  const { data, error } = await supabaseAdmin()
    .from("announcements")
    .insert({
      building_id: user.building_id,
      title: body.title,
      body: body.body,
      event_date: body.eventDate ?? null,
      created_by: user.id,
    })
    .select("*")
    .single();
  if (error) {
    const msg = error.message.toLowerCase();
    if (msg.includes("event_date") && (msg.includes("schema cache") || msg.includes("column"))) {
      throw new ApiError(
        503,
        "Announcement dates are not enabled yet. Run migration 0020_announcement_event_date.sql in the Supabase SQL editor, then try again.",
      );
    }
    throw new ApiError(500, error.message);
  }

  await logAudit({
    buildingId: user.building_id,
    actorId: user.id,
    action: "announcement_published",
    entityType: "announcement",
    entityId: data.id,
    details: { title: body.title },
  });

  // Optional: ping the linked WhatsApp group so residents see it outside the app.
  if (user.building_id && isWahaConfigured()) {
    const { data: building } = await supabaseAdmin()
      .from("buildings")
      .select("waha_session, whatsapp_group_id, name")
      .eq("id", user.building_id)
      .maybeSingle();
    if (building?.waha_session && building.whatsapp_group_id) {
      const text = `📢 ${body.title}\n\n${body.body}\n\n— ${building.name || "Buildingo"}`;
      void sendText(building.waha_session, building.whatsapp_group_id, text).catch((err) =>
        console.error("announcement WhatsApp notify failed", err),
      );
    }
  }

  return NextResponse.json({ announcement: data }, { status: 201 });
});

import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { ApiError, requireRole, withErrorHandling } from "@/lib/auth/session";
import { logAudit } from "@/lib/audit";
import { supabaseAdmin } from "@/lib/supabase/admin";
import { isWahaConfigured, listChats, sessionNameForBuilding } from "@/lib/waha/client";

const linkSchema = z.object({
  groupId: z.string().min(5).max(128),
});

async function sessionFor(buildingId: string) {
  const { data } = await supabaseAdmin()
    .from("buildings")
    .select("waha_session")
    .eq("id", buildingId)
    .single();
  return data?.waha_session || sessionNameForBuilding(buildingId);
}

/** GET /api/whatsapp/groups — list WhatsApp groups on the connected session. */
export const GET = withErrorHandling(async (req: NextRequest) => {
  const user = await requireRole(req, "vaad", "super_admin");
  if (!user.building_id) throw new ApiError(409, "Not mapped to a building");
  if (!isWahaConfigured()) throw new ApiError(503, "WAHA is not configured");

  const session = await sessionFor(user.building_id);
  const chats = await listChats(session);
  const groups = chats
    .filter((c) => c.isGroup || c.id?.endsWith("@g.us"))
    .map((c) => ({ id: c.id, name: c.name || c.id }));

  return NextResponse.json({ groups });
});

/** POST /api/whatsapp/groups — link the building's WhatsApp group for listening. */
export const POST = withErrorHandling(async (req: NextRequest) => {
  const user = await requireRole(req, "vaad", "super_admin");
  if (!user.building_id) throw new ApiError(409, "Not mapped to a building");

  const { groupId } = linkSchema.parse(await req.json());
  const db = supabaseAdmin();
  const { data, error } = await db
    .from("buildings")
    .update({
      whatsapp_group_id: groupId,
      whatsapp_linked_by: user.id,
      whatsapp_linked_at: new Date().toISOString(),
    })
    .eq("id", user.building_id)
    .select("id, whatsapp_group_id, whatsapp_linked_at")
    .single();
  if (error) throw new ApiError(500, error.message);

  await logAudit({
    buildingId: user.building_id,
    actorId: user.id,
    action: "whatsapp_group_linked",
    entityType: "building",
    entityId: user.building_id,
    details: { whatsapp_group_id: groupId },
  });

  return NextResponse.json({ building: data });
});

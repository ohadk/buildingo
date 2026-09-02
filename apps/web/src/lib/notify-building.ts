import { supabaseAdmin } from "@/lib/supabase/admin";
import { isWahaConfigured, sendText } from "@/lib/waha/client";

/** Post an in-app announcement and optionally ping the building WhatsApp group. */
export async function notifyBuilding(
  buildingId: string,
  actorId: string,
  title: string,
  body: string,
): Promise<void> {
  const db = supabaseAdmin();
  await db.from("announcements").insert({
    building_id: buildingId,
    title,
    body,
    created_by: actorId,
  });

  if (!isWahaConfigured()) return;
  const { data: building } = await db
    .from("buildings")
    .select("waha_session, whatsapp_group_id, name")
    .eq("id", buildingId)
    .maybeSingle();
  if (building?.waha_session && building?.whatsapp_group_id) {
    const text = `📢 ${title}\n\n${body}\n\n— ${building.name || "Buildingo"}`;
    void sendText(building.waha_session, building.whatsapp_group_id, text).catch((err) =>
      console.error("building notify WhatsApp failed", err),
    );
  }
}

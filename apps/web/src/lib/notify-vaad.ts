import { decryptUserRow } from "@/lib/pii";
import { sendWhatsApp } from "@/lib/notify";
import { supabaseAdmin } from "@/lib/supabase/admin";

/**
 * Notify every Vaad member of a new join request (WhatsApp to their phone).
 * Fire-and-forget — never block the join API on delivery.
 */
export async function notifyVaadOfJoinRequest(input: {
  buildingId: string;
  requesterName: string;
  apartmentNumber: number | null;
}): Promise<void> {
  try {
    const db = supabaseAdmin();
    const [{ data: building }, { data: vaadRows }] = await Promise.all([
      db.from("buildings").select("name").eq("id", input.buildingId).maybeSingle(),
      db
        .from("users")
        .select(
          "id, phone_number, phone_number_enc, phone_number_hash, full_name",
        )
        .eq("building_id", input.buildingId)
        .eq("role", "vaad"),
    ]);

    const apt =
      input.apartmentNumber != null ? `דירה ${input.apartmentNumber}` : "דירה";
    const name = input.requesterName.trim() || "דייר";
    const buildingName = building?.name?.trim() || "הבניין";
    const text =
      `בקשת הצטרפות חדשה ל־${buildingName}\n` +
      `${name} · ${apt}\n` +
      `פתחו את Buildingo כדי לאשר או לדחות.`;

    const phones = new Set<string>();
    for (const row of vaadRows ?? []) {
      const phone = decryptUserRow(row).phone_number;
      if (phone && typeof phone === "string" && phone.startsWith("+")) {
        phones.add(phone);
      }
    }

    await Promise.all(
      [...phones].map((phone) =>
        sendWhatsApp(phone, text).catch((err) =>
          console.error("[notifyVaadOfJoinRequest] WhatsApp failed", phone, err),
        ),
      ),
    );
  } catch (err) {
    console.error("[notifyVaadOfJoinRequest]", err);
  }
}

import { supabaseAdmin } from "@/lib/supabase/admin";

/**
 * Called whenever a user becomes attached to an apartment (invite
 * accepted, join request approved...). If the Vaad prepared a pending
 * tenancy during a holder transfer, claim it; otherwise open a fresh
 * active tenancy so the apartment's occupancy history stays complete.
 */
export async function activateTenancy(u: {
  id: string;
  building_id: string;
  apartment_id: string;
  full_name?: string | null;
  phone_number?: string | null;
  num_occupants?: number | null;
}): Promise<void> {
  try {
    const db = supabaseAdmin();

    // Already holds an open tenancy on this apartment? Nothing to do.
    const { data: mine } = await db
      .from("tenancies")
      .select("id")
      .eq("apartment_id", u.apartment_id)
      .eq("user_id", u.id)
      .eq("status", "active")
      .limit(1);
    if (mine && mine.length > 0) return;

    const { data: pending } = await db
      .from("tenancies")
      .select("*")
      .eq("apartment_id", u.apartment_id)
      .eq("status", "pending")
      .order("created_at", { ascending: false })
      .limit(1);
    const t = pending?.[0];

    if (t) {
      await db
        .from("tenancies")
        .update({
          user_id: u.id,
          full_name: u.full_name ?? t.full_name,
          phone_number: u.phone_number ?? t.phone_number,
          num_occupants: u.num_occupants ?? t.num_occupants,
          status: "active",
        })
        .eq("id", t.id);
      return;
    }

    await db.from("tenancies").insert({
      building_id: u.building_id,
      apartment_id: u.apartment_id,
      user_id: u.id,
      full_name: u.full_name ?? null,
      phone_number: u.phone_number ?? null,
      num_occupants: u.num_occupants ?? null,
      status: "active",
    });
  } catch (err) {
    // Occupancy history must never block a login or a join.
    console.error("tenancy activation failed", err);
  }
}

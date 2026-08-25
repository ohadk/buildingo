// One-off diagnostic: dump users + invitations for the test building.
import { readFileSync } from "node:fs";
import { createClient } from "@supabase/supabase-js";

const env = Object.fromEntries(
  readFileSync(new URL("../.env.local", import.meta.url), "utf8")
    .split("\n")
    .filter((l) => l.includes("="))
    .map((l) => [l.slice(0, l.indexOf("=")).trim(), l.slice(l.indexOf("=") + 1).trim()]),
);

const db = createClient(env.SUPABASE_URL, env.SUPABASE_SECRET_KEY ?? env.SUPABASE_SERVICE_ROLE_KEY);

const buildingId = "3f61059a-b9a9-4b8d-b452-224f04d05dc6";

const { data: users, error: e1 } = await db
  .from("users")
  .select("id, phone_number, firebase_uid, role, building_id, apartment_id, full_name, onboarded_at, is_active, created_at")
  .order("created_at");
if (e1) console.error("users error:", e1.message);
console.log("=== ALL USERS ===");
console.table(
  (users ?? []).map((u) => ({
    phone: u.phone_number,
    role: u.role,
    building: u.building_id?.slice(0, 8) ?? null,
    apt: u.apartment_id?.slice(0, 8) ?? null,
    name: u.full_name,
    onboarded: !!u.onboarded_at,
    active: u.is_active,
    uid: u.firebase_uid?.slice(0, 10),
  })),
);

const { data: invites, error: e2 } = await db
  .from("invitations")
  .select("id, phone_number, role, status, building_id, apartment_id, invite_code, expires_at, created_at")
  .order("created_at");
if (e2) console.error("invitations error:", e2.message);
console.log("=== ALL INVITATIONS ===");
console.table(
  (invites ?? []).map((i) => ({
    phone: i.phone_number,
    role: i.role,
    status: i.status,
    building: i.building_id?.slice(0, 8),
    apt: i.apartment_id?.slice(0, 8) ?? null,
    code: i.invite_code?.slice(0, 8),
    expires: i.expires_at,
  })),
);

const { data: building } = await db
  .from("buildings")
  .select("id, name, is_active")
  .eq("id", buildingId)
  .maybeSingle();
console.log("=== BUILDING ===", building);

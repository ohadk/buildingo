import type { SupabaseClient } from "@supabase/supabase-js";
import { normalizePhone, phoneHash } from "./crypto";
import { decryptUserRow, migrateRowPiiFields } from "./fields";

type Db = SupabaseClient;

async function lookupByPhoneHash(
  db: Db,
  table: "users" | "super_admins" | "invitations",
  phone: string,
  extra?: { status?: string; expiresAfter?: string },
) {
  const normalized = normalizePhone(phone);
  const hash = phoneHash(normalized);

  let query = db.from(table).select("*").eq("phone_number_hash", hash);
  if (extra?.status) query = query.eq("status", extra.status);
  if (extra?.expiresAfter) query = query.gt("expires_at", extra.expiresAfter);

  const byHash = await query.maybeSingle();
  if (byHash.data) return byHash;

  // Legacy plaintext fallback (pre-migration rows).
  let legacy = db.from(table).select("*").eq("phone_number", normalized);
  if (extra?.status) legacy = legacy.eq("status", extra.status);
  if (extra?.expiresAfter) legacy = legacy.gt("expires_at", extra.expiresAfter);
  return legacy.maybeSingle();
}

export async function findUserByPhone(db: Db, phone: string) {
  const { data, error } = await lookupByPhoneHash(db, "users", phone);
  if (error) return { data: null, error };
  if (!data) return { data: null, error: null };

  const patch = migrateRowPiiFields(data, "user");
  if (Object.keys(patch).length > 0) {
    await db.from("users").update(patch).eq("id", data.id);
    Object.assign(data, patch);
  }
  return { data: decryptUserRow(data), error: null };
}

export async function findSuperAdminByPhone(db: Db, phone: string) {
  return lookupByPhoneHash(db, "super_admins", phone);
}

export async function findPendingInvitationByPhone(
  db: Db,
  phone: string,
  opts?: { inviteCode?: string },
) {
  if (opts?.inviteCode) {
    const { data, error } = await db
      .from("invitations")
      .select("*")
      .eq("invite_code", opts.inviteCode)
      .eq("status", "pending")
      .gt("expires_at", new Date().toISOString())
      .maybeSingle();
    return { data, error };
  }
  return lookupByPhoneHash(db, "invitations", phone, {
    status: "pending",
    expiresAfter: new Date().toISOString(),
  });
}

/** Match a WhatsApp sender against building users (hash + legacy). */
export function phoneMatchesStored(storedPhone: string, variants: string[]): boolean {
  return variants.some((v) => normalizePhone(v) === normalizePhone(storedPhone));
}

export async function findBuildingUserByPhoneVariants(
  db: Db,
  buildingId: string,
  variants: string[],
) {
  const hashes = [...new Set(variants.map((v) => phoneHash(normalizePhone(v))))];
  const { data: byHash } = await db
    .from("users")
    .select("id, apartment_id, phone_number, phone_number_enc, phone_number_hash")
    .eq("building_id", buildingId)
    .in("phone_number_hash", hashes);

  if (byHash && byHash.length > 0) {
    return decryptUserRow(byHash[0]);
  }

  const { data: all } = await db
    .from("users")
    .select("id, apartment_id, phone_number, phone_number_enc")
    .eq("building_id", buildingId);

  const match = (all ?? []).find((u) => {
    const phone = decryptUserRow(u).phone_number;
    return phoneMatchesStored(phone, variants);
  });
  return match ? decryptUserRow(match) : null;
}

export async function revokePendingInvitesForPhone(
  db: Db,
  buildingId: string,
  phone: string,
) {
  const hash = phoneHash(normalizePhone(phone));
  await db
    .from("invitations")
    .update({ status: "revoked" })
    .eq("building_id", buildingId)
    .eq("phone_number_hash", hash)
    .eq("status", "pending");

  await db
    .from("invitations")
    .update({ status: "revoked" })
    .eq("building_id", buildingId)
    .eq("phone_number", normalizePhone(phone))
    .eq("status", "pending");
}

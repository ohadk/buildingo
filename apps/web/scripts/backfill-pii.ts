/**
 * Backfill encrypted PII + hash indexes for existing plaintext rows.
 * Requires PII_SECRET_KEY in the environment.
 *
 * Usage: npm run backfill:pii
 */
import { supabaseAdmin } from "../src/lib/supabase/admin";
import {
  isPiiProtectionEnabled,
  migrateRowPiiFields,
  phoneStorageFields,
} from "../src/lib/pii";

async function backfillTable(
  table: string,
  kind: "user" | "invitation" | "tenancy" | "join_request",
  batchSize = 200,
) {
  const db = supabaseAdmin();
  let offset = 0;
  let total = 0;

  for (;;) {
    const { data, error } = await db.from(table).select("*").range(offset, offset + batchSize - 1);
    if (error) throw error;
    if (!data?.length) break;

    for (const row of data) {
      const patch = migrateRowPiiFields(row, kind);
      if (Object.keys(patch).length === 0) continue;
      const { error: upErr } = await db.from(table).update(patch).eq("id", row.id);
      if (upErr) throw upErr;
      total += 1;
    }

    if (data.length < batchSize) break;
    offset += batchSize;
  }

  console.log(`  ${table}: ${total} rows migrated`);
}

async function main() {
  if (!isPiiProtectionEnabled()) {
    console.error("Set PII_SECRET_KEY (32+ random bytes, base64) before running backfill.");
    process.exit(1);
  }

  console.log("Backfilling PII encryption…");
  await backfillTable("users", "user");
  await backfillTable("super_admins", "user");
  await backfillTable("invitations", "invitation");
  await backfillTable("tenancies", "tenancy");
  await backfillTable("join_requests", "join_request");

  // contact_requests: name + phone + email
  const db = supabaseAdmin();
  const { data: contacts } = await db.from("contact_requests").select("*");
  let contactCount = 0;
  for (const row of contacts ?? []) {
    const patch: Record<string, unknown> = {};
    if (row.phone && !row.phone_hash) Object.assign(patch, phoneStorageFields(row.phone));
    if (row.name && !row.name_enc) {
      const { fullNameStorageFields } = await import("../src/lib/pii/fields");
      Object.assign(patch, fullNameStorageFields(row.name));
    }
    if (row.email && !row.email_hash) {
      const { emailStorageFields } = await import("../src/lib/pii/fields");
      Object.assign(patch, emailStorageFields(row.email));
    }
    if (Object.keys(patch).length === 0) continue;
    await db.from("contact_requests").update(patch).eq("id", row.id);
    contactCount += 1;
  }
  console.log(`  contact_requests: ${contactCount} rows migrated`);

  console.log("Done.");
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});

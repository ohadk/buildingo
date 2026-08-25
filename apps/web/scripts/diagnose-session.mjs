// Diagnoses the /api/auth/session flow outside Next.js:
// 1. Firebase Admin connectivity + latency (the 22s suspect)
// 2. Lists Firebase users (who actually signed in with OTP)
// 3. Supabase users insert/delete round-trip (the empty-table suspect)
import { readFileSync } from "fs";
import { cert, initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { createClient } from "@supabase/supabase-js";

const envFile = readFileSync(".env.local", "utf8");
const env = Object.fromEntries(
  envFile.split("\n").filter((l) => l.includes("=") && !l.startsWith("#"))
    .map((l) => [l.slice(0, l.indexOf("=")).trim(), l.slice(l.indexOf("=") + 1).trim()]),
);

const t0 = Date.now();
const app = initializeApp({
  credential: cert(JSON.parse(readFileSync("../../firebase-service-account.json", "utf8"))),
});
const auth = getAuth(app);

const t1 = Date.now();
const list = await auth.listUsers(10);
console.log(`firebase listUsers: ${Date.now() - t1}ms`);
for (const u of list.users) {
  console.log(`  firebase user: uid=${u.uid} phone=${u.phoneNumber} created=${u.metadata.creationTime}`);
}

const db = createClient(env.SUPABASE_URL, env.SUPABASE_SECRET_KEY, {
  auth: { persistSession: false },
});
console.log(`supabase url in env: ${env.SUPABASE_URL}`);

const t2 = Date.now();
const sel = await db.from("users").select("*");
console.log(`supabase select users: ${Date.now() - t2}ms rows=${sel.data?.length} error=${JSON.stringify(sel.error)}`);

const t3 = Date.now();
const ins = await db
  .from("users")
  .insert({ firebase_uid: "diag-test-uid", phone_number: "+10000000001" })
  .select("*")
  .single();
console.log(`supabase insert user: ${Date.now() - t3}ms error=${JSON.stringify(ins.error)} id=${ins.data?.id}`);

if (ins.data) {
  const del = await db.from("users").delete().eq("id", ins.data.id);
  console.log(`cleanup delete: error=${JSON.stringify(del.error)}`);
}
console.log(`total: ${Date.now() - t0}ms`);

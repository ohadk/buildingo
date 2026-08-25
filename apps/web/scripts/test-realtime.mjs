// Verifies the DB -> Realtime broadcast path added in migration 0007:
// subscribes to the first building's `building:<id>` topic, then touches a
// row and waits for the `changed` broadcast to arrive.
//   node scripts/test-realtime.mjs
import { readFileSync } from "node:fs";
import { createClient } from "@supabase/supabase-js";

const env = Object.fromEntries(
  readFileSync(".env.local", "utf8")
    .split("\n")
    .filter((l) => l.includes("="))
    .map((l) => [l.slice(0, l.indexOf("=")), l.slice(l.indexOf("=") + 1)]),
);

const supabase = createClient(env.SUPABASE_URL, env.SUPABASE_SECRET_KEY, {
  realtime: { params: { log_level: "info" } },
});

const { data: building, error } = await supabase
  .from("buildings")
  .select("id, name")
  .limit(1)
  .single();
if (error) throw error;
console.log(`Listening on building:${building.id} (${building.name})`);

const timeout = setTimeout(() => {
  console.error("TIMED OUT: no broadcast received within 20s");
  process.exit(1);
}, 20_000);

const channel = supabase.channel(`building:${building.id}`);
channel
  .on("broadcast", { event: "changed" }, (msg) => {
    console.log("RECEIVED BROADCAST:", JSON.stringify(msg.payload));
    clearTimeout(timeout);
    process.exit(0);
  })
  .subscribe(async (status, err) => {
    console.log("channel status:", status, err ?? "");
    if (status === "SUBSCRIBED") {
      // Touch a building-scoped row to fire the trigger.
      const { data, error: updErr } = await supabase
        .from("users")
        .update({ updated_at: new Date().toISOString() })
        .eq("building_id", building.id)
        .select("id");
      if (updErr) console.error("update failed:", updErr.message);
      else console.log(`touched ${data.length} users rows, waiting for broadcast...`);
    }
  });

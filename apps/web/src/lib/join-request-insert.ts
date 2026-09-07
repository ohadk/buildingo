import type { SupabaseClient } from "@supabase/supabase-js";

type Db = SupabaseClient;

/** Insert a join_request; omit size_sqm when null (and retry without it if the column is missing). */
export async function insertJoinRequest(
  db: Db,
  row: Record<string, unknown> & { size_sqm?: number | null },
) {
  const payload: Record<string, unknown> = { ...row };
  if (payload.size_sqm == null) delete payload.size_sqm;

  let { data, error } = await db
    .from("join_requests")
    .insert(payload)
    .select("*")
    .single();

  if (
    error &&
    typeof error.message === "string" &&
    error.message.includes("size_sqm")
  ) {
    const { size_sqm: _drop, ...withoutSqm } = payload;
    ({ data, error } = await db
      .from("join_requests")
      .insert(withoutSqm)
      .select("*")
      .single());
  }

  return { data, error };
}

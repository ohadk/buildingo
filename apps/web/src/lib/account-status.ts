import type { SupabaseClient } from "@supabase/supabase-js";
import type { AccountStatus } from "@/lib/types";

export interface SetAccountStatusInput {
  userId: string;
  status: AccountStatus;
  reason?: string | null;
  /** Acting user id, or null for system / self-delete. */
  changedBy?: string | null;
}

/**
 * Updates users.account_status (+ mirrors is_active / deleted_at) and
 * appends a user_status_events row for the admin timeline.
 * Refuses to change an already-deleted account.
 */
export async function setAccountStatus(
  db: SupabaseClient,
  input: SetAccountStatusInput,
): Promise<{ error: { message: string } | null }> {
  const now = new Date().toISOString();
  const reason = input.reason?.trim() || null;

  const patch: Record<string, unknown> = {
    account_status: input.status,
    status_reason: reason,
    status_changed_at: now,
    is_active: input.status === "active",
    deleted_at: input.status === "deleted" ? now : null,
  };

  const { data, error: updErr } = await db
    .from("users")
    .update(patch)
    .eq("id", input.userId)
    .neq("account_status", "deleted")
    .select("id")
    .maybeSingle();

  if (updErr) return { error: updErr };
  if (!data) {
    return { error: { message: "Account not found or already deleted" } };
  }

  const { error: evErr } = await db.from("user_status_events").insert({
    user_id: input.userId,
    status: input.status,
    reason,
    changed_by: input.changedBy ?? null,
  });
  if (evErr) {
    console.error("[setAccountStatus] event insert failed", evErr);
  }

  return { error: null };
}

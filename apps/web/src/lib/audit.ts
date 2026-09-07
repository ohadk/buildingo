import { supabaseAdmin } from "@/lib/supabase/admin";

export type AuditAction =
  | "tenant_joined"
  | "join_requested"
  | "join_rejected"
  | "ticket_created"
  | "ticket_dispatched"
  | "ticket_status_changed"
  | "ticket_cost_recorded"
  | "ticket_deleted"
  | "meeting_created"
  | "meeting_updated"
  | "meeting_deleted"
  | "meeting_closed"
  | "vote_cast"
  | "payment_marked"
  | "payments_bulk_marked"
  | "expense_added"
  | "announcement_published"
  | "announcement_updated"
  | "announcement_deleted"
  | "schedule_event_created"
  | "schedule_event_updated"
  | "schedule_event_deleted"
  | "vendor_added"
  | "vendor_updated"
  | "vendor_deleted"
  | "building_created"
  | "vaad_invited"
  | "tenant_transferred"
  | "fee_updated"
  | "whatsapp_group_linked"
  | "whatsapp_session_started";

export interface AuditEntry {
  buildingId: string | null;
  actorId?: string | null;
  action: AuditAction;
  entityType?: string;
  entityId?: string | null;
  /** Small, display-oriented context (title, apartment number, option...). */
  details?: Record<string, unknown>;
}

/**
 * Append a row to the building activity trail. Fire-and-forget by
 * design: a logging hiccup must never fail the action it describes.
 */
export async function logAudit(entry: AuditEntry): Promise<void> {
  try {
    await supabaseAdmin().from("audit_logs").insert({
      building_id: entry.buildingId,
      actor_id: entry.actorId ?? null,
      action: entry.action,
      entity_type: entry.entityType ?? null,
      entity_id: entry.entityId ?? null,
      details: entry.details ?? {},
    });
  } catch (err) {
    console.error("audit log write failed", err);
  }
}

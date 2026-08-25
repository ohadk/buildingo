import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { ApiError, requireRole, withErrorHandling } from "@/lib/auth/session";
import { supabaseAdmin } from "@/lib/supabase/admin";
import { runVendorDispatchAgent } from "@/lib/agent/dispatch";
import type { Apartment, Building, Ticket, VendorAgent } from "@/lib/types";

const bodySchema = z.object({ vendorAgentId: z.string().uuid() });

/**
 * POST /api/tickets/:id/dispatch — "Approve & Dispatch Agent".
 *
 * Vaad-only. Marks the ticket approved, then runs the Claude agent which
 * composes and sends the vendor notifications (email / SMS / WhatsApp)
 * and appends "Agent Contacted Vendor" timeline events.
 */
export const POST = withErrorHandling(
  async (req: NextRequest, { params }: { params: Promise<{ id: string }> }) => {
    const user = await requireRole(req, "vaad", "super_admin");
    const { id } = await params;
    const { vendorAgentId } = bodySchema.parse(await req.json());
    const db = supabaseAdmin();

    const [{ data: ticket }, { data: vendor }] = await Promise.all([
      db.from("tickets").select("*").eq("id", id).eq("building_id", user.building_id!).maybeSingle(),
      db.from("vendor_agents").select("*").eq("id", vendorAgentId).eq("building_id", user.building_id!).eq("is_active", true).maybeSingle(),
    ]);
    if (!ticket) throw new ApiError(404, "Ticket not found in your building");
    if (!vendor) throw new ApiError(404, "Vendor agent not found or inactive");
    if (ticket.agent_status === "communicating") {
      throw new ApiError(409, "Agent is already dispatching this ticket");
    }

    const [{ data: building }, { data: apartment }] = await Promise.all([
      db.from("buildings").select("*").eq("id", ticket.building_id).single(),
      ticket.apartment_id
        ? db.from("apartments").select("*").eq("id", ticket.apartment_id).single()
        : Promise.resolve({ data: null }),
    ]);

    // 1. Approve + mark agent triggered
    await db
      .from("tickets")
      .update({ status: "approved", assigned_vendor_agent_id: vendor.id, agent_status: "triggered" })
      .eq("id", ticket.id);
    await db.from("ticket_events").insert({
      ticket_id: ticket.id,
      building_id: ticket.building_id,
      label: "Approved by Vaad",
      detail: `Dispatching AI agent to ${vendor.vendor_name}`,
      actor: user.id,
    });

    // 2. Run the Claude agent
    await db.from("tickets").update({ agent_status: "communicating" }).eq("id", ticket.id);
    try {
      const outcome = await runVendorDispatchAgent({
        ticket: ticket as Ticket,
        building: building as Building,
        apartment: apartment as Apartment | null,
        vendor: vendor as VendorAgent,
      });

      const delivered = outcome.channelsUsed.length > 0;
      const { data: updated, error } = await db
        .from("tickets")
        .update({
          status: "in_progress",
          agent_status: delivered ? "resolved" : "failed",
          agent_log: outcome.agentLog,
        })
        .eq("id", ticket.id)
        .select("*, ticket_events(*)")
        .single();
      if (error) throw new ApiError(500, error.message);

      return NextResponse.json({
        ticket: updated,
        agentSummary: outcome.summary,
        channelsUsed: outcome.channelsUsed,
      });
    } catch (err) {
      await db.from("tickets").update({ agent_status: "failed" }).eq("id", ticket.id);
      await db.from("ticket_events").insert({
        ticket_id: ticket.id,
        building_id: ticket.building_id,
        label: "Agent Dispatch Failed",
        detail: err instanceof Error ? err.message : "Unknown error",
      });
      throw err;
    }
  },
);

import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { ApiError, requireRole, withErrorHandling } from "@/lib/auth/session";
import { supabaseAdmin } from "@/lib/supabase/admin";

const patchSchema = z.object({
  status: z.enum(["open", "approved", "in_progress", "resolved", "rejected"]),
});

const STATUS_LABELS: Record<string, string> = {
  approved: "Approved by Vaad",
  in_progress: "In Progress",
  resolved: "Resolved",
  rejected: "Rejected",
  open: "Reopened",
};

/** PATCH /api/tickets/:id — Vaad updates ticket status. */
export const PATCH = withErrorHandling(
  async (req: NextRequest, { params }: { params: Promise<{ id: string }> }) => {
    const user = await requireRole(req, "vaad", "super_admin");
    const { id } = await params;
    const { status } = patchSchema.parse(await req.json());
    const db = supabaseAdmin();

    const { data: ticket, error } = await db
      .from("tickets")
      .update({ status })
      .eq("id", id)
      .eq("building_id", user.building_id!)
      .select("*")
      .single();
    if (error || !ticket) throw new ApiError(404, "Ticket not found in your building");

    await db.from("ticket_events").insert({
      ticket_id: ticket.id,
      building_id: ticket.building_id,
      label: STATUS_LABELS[status],
      actor: user.id,
    });

    return NextResponse.json({ ticket });
  },
);

import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import {
  ApiError,
  getCurrentUser,
  withErrorHandling,
} from "@/lib/auth/session";
import { logAudit } from "@/lib/audit";
import { supabaseAdmin } from "@/lib/supabase/admin";

const categoryEnum = z.enum([
  "leak",
  "elevator",
  "cleaning",
  "lights",
  "electric",
  "door",
  "other",
]);

const patchSchema = z.object({
  // Primary statuses: open | in_progress | resolved.
  // "approved" kept for older clients / AI dispatch; UI maps it to in_progress.
  status: z
    .enum(["open", "approved", "in_progress", "resolved", "rejected"])
    .optional(),
  costAmount: z.number().nonnegative().optional(),
  receiptPath: z.string().max(500).optional(),
  progressNote: z.string().max(1000).optional().nullable(),
  fixDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional().nullable(),
  title: z.string().min(3).max(255).optional(),
  description: z.string().max(4000).optional(),
  location: z.string().max(100).optional().nullable(),
  category: categoryEnum.optional(),
  imagePath: z.string().max(500).optional().nullable(),
  imagePaths: z.array(z.string().max(500)).max(8).optional(),
});

const STATUS_LABELS: Record<string, string> = {
  approved: "In Progress",
  in_progress: "In Progress",
  resolved: "Done",
  rejected: "Rejected",
  open: "New",
};

function missingOptionalColumns(message: string): boolean {
  return (
    /cost_amount|receipt_path|progress_note|fix_date/i.test(message) &&
    /schema cache|column/i.test(message)
  );
}

function serializeImagePaths(paths: string[]): string | null {
  if (paths.length === 0) return null;
  if (paths.length === 1) return paths[0];
  return JSON.stringify(paths);
}

/** PATCH /api/tickets/:id — Vaad (status/cost/progress) or reporter (content). */
export const PATCH = withErrorHandling(
  async (req: NextRequest, { params }: { params: Promise<{ id: string }> }) => {
    const user = await getCurrentUser(req);
    if (!user.building_id) throw new ApiError(409, "Not mapped to a building");
    const { id } = await params;
    const body = patchSchema.parse(await req.json());

    const db = supabaseAdmin();
    const { data: existing, error: loadError } = await db
      .from("tickets")
      .select("*")
      .eq("id", id)
      .eq("building_id", user.building_id)
      .maybeSingle();
    if (loadError || !existing) {
      throw new ApiError(404, "Ticket not found in your building");
    }

    const isVaad = user.role === "vaad" || user.role === "super_admin";
    const isReporter = existing.reported_by === user.id;
    if (!isVaad && !isReporter) throw new ApiError(403, "Not allowed to edit this ticket");

    const hasContent =
      body.title !== undefined ||
      body.description !== undefined ||
      body.location !== undefined ||
      body.category !== undefined ||
      body.imagePath !== undefined ||
      body.imagePaths !== undefined;
    const hasVaadFields =
      body.status !== undefined ||
      body.costAmount !== undefined ||
      body.receiptPath !== undefined ||
      body.progressNote !== undefined ||
      body.fixDate !== undefined;

    if (!hasContent && !hasVaadFields) throw new ApiError(400, "Nothing to update");
    if (hasVaadFields && !isVaad) {
      throw new ApiError(403, "Only the Vaad can update status or cost");
    }

    const patch: Record<string, unknown> = {};
    if (isVaad) {
      if (body.status) {
        // Collapse legacy "approved" into in_progress for the 3-stage model.
        patch.status = body.status === "approved" ? "in_progress" : body.status;
      }
      if (body.costAmount !== undefined) patch.cost_amount = body.costAmount;
      if (body.receiptPath) patch.receipt_path = body.receiptPath;
      if (body.progressNote !== undefined) patch.progress_note = body.progressNote;
      if (body.fixDate !== undefined) patch.fix_date = body.fixDate;
    }
    if (hasContent && (isVaad || isReporter)) {
      if (body.title !== undefined) patch.title = body.title;
      if (body.description !== undefined) patch.description = body.description;
      if (body.location !== undefined) patch.location = body.location;
      if (body.category !== undefined) patch.category = body.category;
      if (body.imagePaths !== undefined) {
        patch.image_path = serializeImagePaths(body.imagePaths);
      } else if (body.imagePath !== undefined) {
        patch.image_path = body.imagePath;
      }
    }

    let ticket = existing;
    if (Object.keys(patch).length > 0) {
      let { data, error } = await db
        .from("tickets")
        .update(patch)
        .eq("id", id)
        .eq("building_id", user.building_id)
        .select("*")
        .single();

      if (error && missingOptionalColumns(error.message)) {
        const fallback = { ...patch };
        delete fallback.cost_amount;
        delete fallback.receipt_path;
        delete fallback.progress_note;
        delete fallback.fix_date;
        if (Object.keys(fallback).length === 0) {
          throw new ApiError(
            500,
            "Ticket columns missing. Run migrations 0025_ticket_cost.sql and 0026_ticket_progress.sql.",
          );
        }
        ({ data, error } = await db
          .from("tickets")
          .update(fallback)
          .eq("id", id)
          .eq("building_id", user.building_id)
          .select("*")
          .single());
      }
      if (error || !data) throw new ApiError(404, "Ticket not found in your building");
      ticket = data;
    }

    const nextStatus = (patch.status as string | undefined) ?? existing.status;
    if (body.status && nextStatus !== existing.status) {
      await db.from("ticket_events").insert({
        ticket_id: ticket.id,
        building_id: ticket.building_id,
        label: STATUS_LABELS[nextStatus] ?? nextStatus,
        actor: user.id,
      });
    }

    if (
      body.progressNote !== undefined ||
      body.fixDate !== undefined
    ) {
      const bits = [
        body.progressNote?.trim() || null,
        body.fixDate ? `Fix date: ${body.fixDate}` : null,
      ].filter(Boolean);
      if (bits.length > 0) {
        await db.from("ticket_events").insert({
          ticket_id: ticket.id,
          building_id: ticket.building_id,
          label: "Progress update",
          detail: bits.join(" · "),
          actor: user.id,
        });
      }
    }

    if (body.costAmount !== undefined && body.costAmount > 0) {
      await upsertTicketExpense(db, {
        ticket,
        amount: body.costAmount,
        receiptPath: body.receiptPath ?? ticket.receipt_path ?? null,
        actorId: user.id,
      });
      await db.from("ticket_events").insert({
        ticket_id: ticket.id,
        building_id: ticket.building_id,
        label: "Repair cost recorded",
        detail: `₪${body.costAmount}`,
        actor: user.id,
      });
    }

    if (hasContent) {
      await logAudit({
        buildingId: ticket.building_id,
        actorId: user.id,
        action: "ticket_status_changed",
        entityType: "ticket",
        entityId: ticket.id,
        details: { title: ticket.title, edited: true },
      });
    } else {
      await logAudit({
        buildingId: ticket.building_id,
        actorId: user.id,
        action: body.status ? "ticket_status_changed" : "ticket_cost_recorded",
        entityType: "ticket",
        entityId: ticket.id,
        details: {
          title: ticket.title,
          ...(body.status ? { status: nextStatus } : {}),
          ...(body.costAmount !== undefined ? { costAmount: body.costAmount } : {}),
          ...(body.progressNote ? { progressNote: body.progressNote } : {}),
        },
      });
    }

    return NextResponse.json({ ticket });
  },
);

async function upsertTicketExpense(
  db: ReturnType<typeof supabaseAdmin>,
  args: {
    ticket: { id: string; building_id: string; title: string };
    amount: number;
    receiptPath: string | null;
    actorId: string;
  },
) {
  const today = new Date().toISOString().slice(0, 10);
  const row = {
    building_id: args.ticket.building_id,
    title: args.ticket.title,
    category: "maintenance",
    amount: args.amount,
    expense_date: today,
    receipt_path: args.receiptPath,
    description: `Repair for ticket: ${args.ticket.title}`,
    created_by: args.actorId,
    ticket_id: args.ticket.id,
  };

  const { data: existing } = await db
    .from("expenses")
    .select("id")
    .eq("ticket_id", args.ticket.id)
    .maybeSingle();

  if (existing) {
    const { error } = await db
      .from("expenses")
      .update({
        amount: args.amount,
        receipt_path: args.receiptPath,
        title: args.ticket.title,
      })
      .eq("id", existing.id);
    if (!error) return;
  }

  const { error } = await db.from("expenses").insert(row);
  if (
    error &&
    /ticket_id/i.test(error.message) &&
    /schema cache|column/i.test(error.message)
  ) {
    const { ticket_id: _, ...withoutTicketId } = row;
    await db.from("expenses").insert(withoutTicketId);
  }
}

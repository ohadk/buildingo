import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { ApiError, requireRole, withErrorHandling } from "@/lib/auth/session";
import { logAudit } from "@/lib/audit";
import { supabaseAdmin } from "@/lib/supabase/admin";

const updateSchema = z.object({
  title: z.string().min(2).max(255).optional(),
  notes: z.string().max(2000).nullable().optional(),
  timeOfDay: z.string().regex(/^\d{2}:\d{2}(:\d{2})?$/).nullable().optional(),
  isActive: z.boolean().optional(),
  eventType: z
    .enum([
      "garbage",
      "cleaning",
      "bulk_waste",
      "gardening",
      "pest",
      "water_tank",
      "other",
    ])
    .optional(),
  recurrence: z
    .enum([
      "once",
      "daily",
      "weekly",
      "biweekly",
      "monthly",
      "quarterly",
      "yearly",
    ])
    .optional(),
  dayOfWeek: z.number().int().min(0).max(6).nullable().optional(),
  dayOfMonth: z.number().int().min(1).max(31).nullable().optional(),
  specificDate: z
    .string()
    .regex(/^\d{4}-\d{2}-\d{2}$/)
    .nullable()
    .optional(),
});

async function findScoped(id: string, buildingId: string | null, isSuperAdmin: boolean) {
  const { data, error } = await supabaseAdmin()
    .from("schedule_events")
    .select("id, building_id, title")
    .eq("id", id)
    .maybeSingle();
  if (error) throw new ApiError(500, error.message);
  if (!data) throw new ApiError(404, "Schedule event not found");
  if (!isSuperAdmin && data.building_id !== buildingId) {
    throw new ApiError(403, "This schedule event belongs to another building");
  }
  return data;
}

/** PATCH /api/schedule-events/[id] — Vaad updates a schedule rule. */
export const PATCH = withErrorHandling(
  async (req: NextRequest, ctx: { params: Promise<{ id: string }> }) => {
    const user = await requireRole(req, "vaad", "super_admin");
    const { id } = await ctx.params;
    const scoped = await findScoped(id, user.building_id, user.role === "super_admin");
    const body = updateSchema.parse(await req.json());

    const patch: Record<string, unknown> = { updated_at: new Date().toISOString() };
    if (body.title != null) patch.title = body.title;
    if (body.notes !== undefined) patch.notes = body.notes;
    if (body.timeOfDay !== undefined) {
      patch.time_of_day = body.timeOfDay
        ? body.timeOfDay.length === 5
          ? body.timeOfDay
          : body.timeOfDay.slice(0, 5)
        : null;
    }
    if (body.isActive != null) patch.is_active = body.isActive;
    if (body.eventType != null) patch.event_type = body.eventType;
    if (body.recurrence != null) patch.recurrence = body.recurrence;
    if (body.dayOfWeek !== undefined) patch.day_of_week = body.dayOfWeek;
    if (body.dayOfMonth !== undefined) patch.day_of_month = body.dayOfMonth;
    if (body.specificDate !== undefined) patch.specific_date = body.specificDate;

    const { data, error } = await supabaseAdmin()
      .from("schedule_events")
      .update(patch)
      .eq("id", id)
      .select("*")
      .single();
    if (error) throw new ApiError(500, error.message);

    await logAudit({
      buildingId: scoped.building_id,
      actorId: user.id,
      action: "schedule_event_updated",
      entityType: "schedule_event",
      entityId: id,
      details: { title: body.title ?? scoped.title },
    });

    return NextResponse.json({ event: data });
  },
);

/** DELETE /api/schedule-events/[id] — Vaad removes a schedule rule. */
export const DELETE = withErrorHandling(
  async (req: NextRequest, ctx: { params: Promise<{ id: string }> }) => {
    const user = await requireRole(req, "vaad", "super_admin");
    const { id } = await ctx.params;
    const scoped = await findScoped(id, user.building_id, user.role === "super_admin");

    const { error } = await supabaseAdmin()
      .from("schedule_events")
      .delete()
      .eq("id", id);
    if (error) throw new ApiError(500, error.message);

    await logAudit({
      buildingId: scoped.building_id,
      actorId: user.id,
      action: "schedule_event_deleted",
      entityType: "schedule_event",
      entityId: id,
      details: { title: scoped.title },
    });

    return NextResponse.json({ ok: true });
  },
);

import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { ApiError, getCurrentUser, requireRole, withErrorHandling } from "@/lib/auth/session";
import { logAudit } from "@/lib/audit";
import { expandScheduleEvents } from "@/lib/schedule";
import { supabaseAdmin } from "@/lib/supabase/admin";

const createSchema = z
  .object({
    eventType: z.enum(["garbage", "cleaning", "bulk_waste", "other"]),
    title: z.string().min(2).max(255),
    notes: z.string().max(2000).optional(),
    recurrence: z.enum(["weekly", "once"]),
    dayOfWeek: z.number().int().min(0).max(6).optional(),
    specificDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional(),
    timeOfDay: z.string().regex(/^\d{2}:\d{2}(:\d{2})?$/).optional(),
  })
  .superRefine((body, ctx) => {
    if (body.recurrence === "weekly" && body.dayOfWeek == null) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: "dayOfWeek is required for weekly events",
        path: ["dayOfWeek"],
      });
    }
    if (body.recurrence === "once" && !body.specificDate) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: "specificDate is required for one-time events",
        path: ["specificDate"],
      });
    }
  });

function defaultRange() {
  const today = new Date();
  const from = today.toISOString().slice(0, 10);
  const end = new Date(today);
  end.setDate(end.getDate() + 42);
  return { from, to: end.toISOString().slice(0, 10) };
}

/** GET /api/schedule-events — expanded occurrences for a date window. */
export const GET = withErrorHandling(async (req: NextRequest) => {
  const user = await getCurrentUser(req);
  if (!user.building_id) throw new ApiError(409, "Not mapped to a building");

  const { searchParams } = new URL(req.url);
  const fallback = defaultRange();
  const from = searchParams.get("from") ?? fallback.from;
  const to = searchParams.get("to") ?? fallback.to;

  const { data, error } = await supabaseAdmin()
    .from("schedule_events")
    .select("*")
    .eq("building_id", user.building_id)
    .eq("is_active", true)
    .order("created_at", { ascending: true });
  if (error) throw new ApiError(500, error.message);

  const occurrences = expandScheduleEvents(data ?? [], from, to);
  return NextResponse.json({ occurrences, rules: data });
});

/** POST /api/schedule-events — Vaad adds a schedule rule. */
export const POST = withErrorHandling(async (req: NextRequest) => {
  const user = await requireRole(req, "vaad", "super_admin");
  const body = createSchema.parse(await req.json());

  const { data, error } = await supabaseAdmin()
    .from("schedule_events")
    .insert({
      building_id: user.building_id,
      event_type: body.eventType,
      title: body.title,
      notes: body.notes ?? null,
      recurrence: body.recurrence,
      day_of_week: body.recurrence === "weekly" ? body.dayOfWeek : null,
      specific_date: body.recurrence === "once" ? body.specificDate : null,
      time_of_day: body.timeOfDay ?? null,
      created_by: user.id,
    })
    .select("*")
    .single();
  if (error) throw new ApiError(500, error.message);

  await logAudit({
    buildingId: user.building_id,
    actorId: user.id,
    action: "schedule_event_created",
    entityType: "schedule_event",
    entityId: data.id,
    details: { title: body.title, eventType: body.eventType },
  });

  return NextResponse.json({ event: data }, { status: 201 });
});

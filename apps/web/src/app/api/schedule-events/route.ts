import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { ApiError, getCurrentUser, requireRole, withErrorHandling } from "@/lib/auth/session";
import { logAudit } from "@/lib/audit";
import { expandScheduleEvents, isScheduleTableMissing, meetingsToOccurrences, announcementsToOccurrences, mergeScheduleOccurrences } from "@/lib/schedule";
import { supabaseAdmin } from "@/lib/supabase/admin";

const recurrenceEnum = z.enum([
  "once",
  "daily",
  "weekly",
  "biweekly",
  "monthly",
  "quarterly",
  "yearly",
]);

const createSchema = z
  .object({
    eventType: z.enum([
      "garbage",
      "cleaning",
      "bulk_waste",
      "gardening",
      "pest",
      "water_tank",
      "other",
    ]),
    title: z.string().min(2).max(255),
    notes: z.string().max(2000).optional(),
    recurrence: recurrenceEnum,
    dayOfWeek: z.number().int().min(0).max(6).optional(),
    dayOfMonth: z.number().int().min(1).max(31).optional(),
    specificDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional(),
    timeOfDay: z.string().regex(/^\d{1,2}:\d{2}(:\d{2})?$/).optional(),
    monthlyCost: z.number().min(0).optional(),
    providerName: z.string().max(255).optional(),
  })
  .superRefine((body, ctx) => {
    if (body.recurrence === "once" && !body.specificDate) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: "specificDate is required for one-time events",
        path: ["specificDate"],
      });
    }
    if (
      (body.recurrence === "weekly" || body.recurrence === "biweekly") &&
      body.dayOfWeek == null
    ) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: "dayOfWeek is required for weekly events",
        path: ["dayOfWeek"],
      });
    }
    if (
      (body.recurrence === "monthly" ||
        body.recurrence === "quarterly" ||
        body.recurrence === "yearly") &&
      body.dayOfMonth == null
    ) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: "dayOfMonth is required for monthly/quarterly/yearly events",
        path: ["dayOfMonth"],
      });
    }
  });

function normalizeTime(t?: string): string | null {
  if (!t) return null;
  const [h, m] = t.split(":");
  return `${h.padStart(2, "0")}:${m.padStart(2, "0")}`;
}

function scheduleSetupError(message: string): never {
  if (isScheduleTableMissing(message)) {
    throw new ApiError(
      503,
      "Building schedule is not set up yet. Run migration 0018_schedule_events.sql in Supabase.",
    );
  }
  throw new ApiError(500, message);
}

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

  let rules: typeof data = [];
  if (error) {
    if (!isScheduleTableMissing(error.message)) scheduleSetupError(error.message);
  } else {
    rules = data ?? [];
  }

  const { data: meetings, error: meetingsError } = await supabaseAdmin()
    .from("meetings")
    .select("id, building_id, title, agenda, meeting_date, location, is_closed")
    .eq("building_id", user.building_id)
    .gte("meeting_date", `${from}T00:00:00`)
    .lte("meeting_date", `${to}T23:59:59.999`)
    .order("meeting_date", { ascending: true });
  if (meetingsError) throw new ApiError(500, meetingsError.message);

  const { data: datedAnnouncements } = await supabaseAdmin()
    .from("announcements")
    .select("id, building_id, title, body, event_date")
    .eq("building_id", user.building_id)
    .not("event_date", "is", null)
    .gte("event_date", from)
    .lte("event_date", to);

  const scheduleOccurrences = expandScheduleEvents(rules ?? [], from, to);
  const meetingOccurrences = meetingsToOccurrences(meetings ?? [], from, to);
  const announcementOccurrences = announcementsToOccurrences(
    datedAnnouncements ?? [],
    from,
    to,
  );
  const occurrences = mergeScheduleOccurrences(
    scheduleOccurrences,
    meetingOccurrences,
    announcementOccurrences,
  );
  return NextResponse.json({ occurrences, rules: rules ?? [] });
});

/** POST /api/schedule-events — Vaad adds a schedule rule. */
export const POST = withErrorHandling(async (req: NextRequest) => {
  const user = await requireRole(req, "vaad", "super_admin");
  const parsed = createSchema.safeParse(await req.json());
  if (!parsed.success) {
    throw new ApiError(400, parsed.error.issues[0]?.message ?? "Invalid schedule event");
  }
  const body = parsed.data;

  const { data, error } = await supabaseAdmin()
    .from("schedule_events")
    .insert({
      building_id: user.building_id,
      event_type: body.eventType,
      title: body.title,
      notes: body.notes ?? null,
      recurrence: body.recurrence,
      day_of_week:
        body.recurrence === "weekly" || body.recurrence === "biweekly"
          ? body.dayOfWeek
          : null,
      day_of_month:
        body.recurrence === "monthly" ||
        body.recurrence === "quarterly" ||
        body.recurrence === "yearly"
          ? body.dayOfMonth
          : null,
      specific_date:
        body.recurrence === "once"
          ? body.specificDate
          : body.recurrence === "biweekly" ||
              body.recurrence === "quarterly" ||
              body.recurrence === "yearly"
            ? (body.specificDate ?? new Date().toISOString().slice(0, 10))
            : null,
      time_of_day: normalizeTime(body.timeOfDay),
      monthly_cost: body.monthlyCost ?? null,
      provider_name: body.providerName?.trim() || null,
      created_by: user.id,
    })
    .select("*")
    .single();
  if (error) scheduleSetupError(error.message);

  await logAudit({
    buildingId: user.building_id,
    actorId: user.id,
    action: "schedule_event_created",
    entityType: "schedule_event",
    entityId: data.id,
    details: { title: body.title, eventType: body.eventType, recurrence: body.recurrence },
  });

  return NextResponse.json({ event: data }, { status: 201 });
});

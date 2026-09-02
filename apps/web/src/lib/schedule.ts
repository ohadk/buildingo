export type ScheduleRecurrence =
  | "once"
  | "daily"
  | "weekly"
  | "biweekly"
  | "monthly"
  | "quarterly"
  | "yearly";

export type ScheduleEventRow = {
  id: string;
  building_id: string;
  event_type: string;
  title: string;
  notes: string | null;
  recurrence: ScheduleRecurrence;
  day_of_week: number | null;
  day_of_month: number | null;
  specific_date: string | null;
  time_of_day: string | null;
  is_active: boolean;
  monthly_cost?: number | null;
  provider_name?: string | null;
  created_at?: string;
};

export type ScheduleOccurrence = ScheduleEventRow & {
  occurrence_date: string;
  /** Full timestamp for one-off events (e.g. resident assemblies). */
  starts_at?: string;
};

export type MeetingRow = {
  id: string;
  building_id: string;
  title: string;
  agenda: string;
  meeting_date: string;
  location: string | null;
  is_closed: boolean;
};

export type AnnouncementRow = {
  id: string;
  building_id: string;
  title: string;
  body: string;
  event_date: string | null;
};

function parseDate(s: string): Date {
  const [y, m, d] = s.split("-").map(Number);
  return new Date(y, m - 1, d);
}

function formatDate(d: Date): string {
  const y = d.getFullYear();
  const m = `${d.getMonth() + 1}`.padStart(2, "0");
  const day = `${d.getDate()}`.padStart(2, "0");
  return `${y}-${m}-${day}`;
}

function daysBetween(a: Date, b: Date): number {
  const ms = parseDate(formatDate(b)).getTime() - parseDate(formatDate(a)).getTime();
  return Math.round(ms / 86_400_000);
}

/** Expand schedule rules into concrete dates inside [from, to]. */
export function expandScheduleEvents(
  events: ScheduleEventRow[],
  from: string,
  to: string,
): ScheduleOccurrence[] {
  const fromD = parseDate(from);
  const toD = parseDate(to);
  const out: ScheduleOccurrence[] = [];

  for (const event of events) {
    if (!event.is_active) continue;

    if (event.recurrence === "once" && event.specific_date) {
      if (event.specific_date >= from && event.specific_date <= to) {
        out.push({ ...event, occurrence_date: event.specific_date });
      }
      continue;
    }

    if (event.recurrence === "daily") {
      const cur = new Date(fromD);
      while (cur <= toD) {
        out.push({ ...event, occurrence_date: formatDate(cur) });
        cur.setDate(cur.getDate() + 1);
      }
      continue;
    }

    if (
      (event.recurrence === "weekly" || event.recurrence === "biweekly") &&
      event.day_of_week != null
    ) {
      const anchor =
        event.specific_date ??
        (event.created_at ? event.created_at.slice(0, 10) : from);
      const step = event.recurrence === "biweekly" ? 14 : 7;
      const cur = new Date(fromD);
      while (cur <= toD) {
        if (cur.getDay() === event.day_of_week) {
          const delta = daysBetween(parseDate(anchor), cur);
          if (delta >= 0 && delta % step === 0) {
            out.push({ ...event, occurrence_date: formatDate(cur) });
          }
        }
        cur.setDate(cur.getDate() + 1);
      }
      continue;
    }

    if (event.recurrence === "monthly" && event.day_of_month != null) {
      let y = fromD.getFullYear();
      let m = fromD.getMonth();
      const endY = toD.getFullYear();
      const endM = toD.getMonth();
      while (y < endY || (y === endY && m <= endM)) {
        const lastDay = new Date(y, m + 1, 0).getDate();
        const dom = Math.min(event.day_of_month, lastDay);
        const d = new Date(y, m, dom);
        if (d >= fromD && d <= toD) {
          out.push({ ...event, occurrence_date: formatDate(d) });
        }
        m += 1;
        if (m > 11) {
          m = 0;
          y += 1;
        }
      }
      continue;
    }

    if (
      (event.recurrence === "quarterly" || event.recurrence === "yearly") &&
      event.day_of_month != null
    ) {
      const anchor = parseDate(
        event.specific_date ??
          (event.created_at ? event.created_at.slice(0, 10) : from),
      );
      const stepMonths = event.recurrence === "quarterly" ? 3 : 12;
      let y = anchor.getFullYear();
      let m = anchor.getMonth();
      // Walk forward from anchor until past [to].
      while (new Date(y, m, 1) <= toD) {
        const lastDay = new Date(y, m + 1, 0).getDate();
        const dom = Math.min(event.day_of_month, lastDay);
        const d = new Date(y, m, dom);
        if (d >= fromD && d <= toD && d >= anchor) {
          out.push({ ...event, occurrence_date: formatDate(d) });
        }
        m += stepMonths;
        while (m > 11) {
          m -= 12;
          y += 1;
        }
      }
    }
  }

  return out.sort(compareOccurrences);
}

/** Map resident assemblies into schedule occurrences for a date window. */
export function meetingsToOccurrences(
  meetings: MeetingRow[],
  from: string,
  to: string,
): ScheduleOccurrence[] {
  const fromD = parseDate(from);
  const toD = parseDate(to);
  const out: ScheduleOccurrence[] = [];

  for (const meeting of meetings) {
    const dt = new Date(meeting.meeting_date);
    const dateStr = formatDate(dt);
    const dateOnly = parseDate(dateStr);
    if (dateOnly < fromD || dateOnly > toD) continue;

    const h = `${dt.getHours()}`.padStart(2, "0");
    const m = `${dt.getMinutes()}`.padStart(2, "0");

    out.push({
      id: meeting.id,
      building_id: meeting.building_id,
      event_type: "meeting",
      title: meeting.title,
      notes: meeting.location,
      recurrence: "once",
      day_of_week: null,
      day_of_month: null,
      specific_date: dateStr,
      time_of_day: `${h}:${m}`,
      is_active: !meeting.is_closed,
      occurrence_date: dateStr,
      starts_at: meeting.meeting_date,
    });
  }

  return out;
}

/** Dated community announcements as one-off calendar items. */
export function announcementsToOccurrences(
  announcements: AnnouncementRow[],
  from: string,
  to: string,
): ScheduleOccurrence[] {
  const out: ScheduleOccurrence[] = [];
  for (const a of announcements) {
    if (!a.event_date) continue;
    if (a.event_date < from || a.event_date > to) continue;
    out.push({
      id: a.id,
      building_id: a.building_id,
      event_type: "announcement",
      title: a.title,
      notes: a.body,
      recurrence: "once",
      day_of_week: null,
      day_of_month: null,
      specific_date: a.event_date,
      time_of_day: null,
      is_active: true,
      occurrence_date: a.event_date,
    });
  }
  return out;
}

function compareOccurrences(a: ScheduleOccurrence, b: ScheduleOccurrence): number {
  const left = a.starts_at ?? `${a.occurrence_date}T${a.time_of_day ?? "23:59"}`;
  const right = b.starts_at ?? `${b.occurrence_date}T${b.time_of_day ?? "23:59"}`;
  return left.localeCompare(right);
}

/** Merge any schedule sources into one sorted timeline. */
export function mergeScheduleOccurrences(
  ...groups: ScheduleOccurrence[][]
): ScheduleOccurrence[] {
  return groups.flat().sort(compareOccurrences);
}

export function isScheduleTableMissing(message: string): boolean {
  const m = message.toLowerCase();
  return (
    m.includes("schedule_events") &&
    (m.includes("schema cache") ||
      m.includes("pgrst205") ||
      m.includes("does not exist") ||
      m.includes("could not find the table"))
  );
}

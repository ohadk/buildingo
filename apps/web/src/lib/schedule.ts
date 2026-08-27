export type ScheduleEventRow = {
  id: string;
  building_id: string;
  event_type: string;
  title: string;
  notes: string | null;
  recurrence: "weekly" | "once";
  day_of_week: number | null;
  specific_date: string | null;
  time_of_day: string | null;
  is_active: boolean;
};

export type ScheduleOccurrence = ScheduleEventRow & {
  occurrence_date: string;
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

/** Expand weekly/one-off rules into concrete dates inside [from, to]. */
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

    if (event.recurrence === "weekly" && event.day_of_week != null) {
      const cur = new Date(fromD);
      while (cur <= toD) {
        if (cur.getDay() === event.day_of_week) {
          out.push({ ...event, occurrence_date: formatDate(cur) });
        }
        cur.setDate(cur.getDate() + 1);
      }
    }
  }

  return out.sort((a, b) => {
    const left = `${a.occurrence_date}T${a.time_of_day ?? "23:59"}`;
    const right = `${b.occurrence_date}T${b.time_of_day ?? "23:59"}`;
    return left.localeCompare(right);
  });
}

import { supabaseAdmin } from "@/lib/supabase/admin";
import { Card } from "@/components/ui/card";
import { formatPhoneDisplay } from "@/lib/format";
import { BuildingFilter } from "./building-filter";

export const dynamic = "force-dynamic";

/** Hebrew labels + tones for the machine action keys. */
const ACTIONS: Record<string, { label: string; cls: string }> = {
  tenant_joined: { label: "דייר הצטרף", cls: "bg-sage-100 text-sage-700" },
  join_requested: { label: "בקשת הצטרפות", cls: "bg-gold-300 text-gold-700" },
  join_rejected: { label: "בקשה נדחתה", cls: "bg-terracotta-100 text-brick-600" },
  ticket_created: { label: "קריאה נפתחה", cls: "bg-gold-300 text-gold-700" },
  ticket_dispatched: { label: "קריאה שוגרה לספק", cls: "bg-sage-100 text-sage-700" },
  ticket_status_changed: { label: "עדכון סטטוס קריאה", cls: "bg-cream-200 text-ink-600" },
  meeting_created: { label: "אסיפה נקבעה", cls: "bg-sage-100 text-sage-700" },
  meeting_closed: { label: "אסיפה נסגרה", cls: "bg-cream-200 text-ink-600" },
  vote_cast: { label: "הצבעה", cls: "bg-gold-300 text-gold-700" },
  payment_marked: { label: "סימון תשלום", cls: "bg-sage-100 text-sage-700" },
  payments_bulk_marked: { label: "סימון תשלומים מרוכז", cls: "bg-sage-100 text-sage-700" },
  expense_added: { label: "הוצאה נרשמה", cls: "bg-cream-200 text-ink-600" },
  announcement_published: { label: "הודעה פורסמה", cls: "bg-gold-300 text-gold-700" },
  vendor_added: { label: "סוכן ספק נוסף", cls: "bg-sage-100 text-sage-700" },
  vendor_updated: { label: "סוכן ספק עודכן", cls: "bg-cream-200 text-ink-600" },
  vendor_deleted: { label: "סוכן ספק נמחק", cls: "bg-terracotta-100 text-brick-600" },
  building_created: { label: "בניין נוצר", cls: "bg-sage-100 text-sage-700" },
  vaad_invited: { label: "הזמנה נשלחה", cls: "bg-gold-300 text-gold-700" },
  tenant_transferred: { label: "החלפת מחזיק", cls: "bg-sage-100 text-sage-700" },
};

interface LogRow {
  id: string;
  action: string;
  details: Record<string, unknown>;
  created_at: string;
  actor: { full_name: string | null; phone_number: string } | null;
  buildings: { name: string } | null;
}

/** One-line human summary from the details blob. */
function summarize(log: LogRow): string {
  const d = log.details ?? {};
  const parts: string[] = [];
  if (typeof d.title === "string" && d.title) parts.push(d.title);
  if (typeof d.name === "string" && d.name) parts.push(d.name);
  if (d.apartment != null) parts.push(`דירה ${d.apartment}`);
  if (typeof d.option === "string") parts.push(`בחר: ${d.option}`);
  if (typeof d.vendor === "string") parts.push(`ספק: ${d.vendor}`);
  if (typeof d.service === "string") parts.push(d.service);
  if (d.amount != null) parts.push(`₪${d.amount}`);
  if (d.month != null && d.year != null) parts.push(`${d.month}/${d.year}`);
  if (typeof d.status === "string") {
    parts.push(d.status === "paid" ? "שולם" : d.status);
  }
  if (d.apartments != null && d.months != null) {
    parts.push(`${d.apartments} דירות × ${d.months} חודשים`);
  }
  if (typeof d.location === "string") parts.push(d.location);
  return parts.join(" · ");
}

export default async function AuditPage({
  searchParams,
}: {
  searchParams: Promise<{ building?: string }>;
}) {
  const { building } = await searchParams;
  const db = supabaseAdmin();

  let query = db
    .from("audit_logs")
    .select(
      "id, action, details, created_at, actor:users!audit_logs_actor_id_fkey(full_name, phone_number), buildings(name)",
    )
    .order("created_at", { ascending: false })
    .limit(200);
  if (building) query = query.eq("building_id", building);

  const [{ data: logsData }, { data: buildingsData }] = await Promise.all([
    query,
    db.from("buildings").select("id, name, address, city").order("name"),
  ]);
  const logs = (logsData ?? []) as unknown as LogRow[];
  const buildings = buildingsData ?? [];

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-end justify-between gap-5">
        <div>
          <h1 className="text-3xl text-ink-900">לוג פעולות</h1>
          <p className="mt-1.5 text-sm text-ink-600">
            כל הפעולות בפלטפורמה — הצטרפויות, קריאות, אסיפות, הצבעות ותשלומים.
          </p>
        </div>
        <BuildingFilter
          buildings={buildings.map((b) => ({
            id: b.id,
            label: `${b.address}, ${b.city}`,
          }))}
          selected={building ?? ""}
        />
      </div>

      <Card className="overflow-hidden p-0">
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-cream-200 text-right text-[11px] uppercase tracking-wider text-ink-600">
                <th className="px-6 py-2.5 font-medium">מתי</th>
                {!building && <th className="px-3 py-2.5 font-medium">בניין</th>}
                <th className="px-3 py-2.5 font-medium">פעולה</th>
                <th className="px-3 py-2.5 font-medium">פרטים</th>
                <th className="px-3 py-2.5 font-medium">בוצע ע&quot;י</th>
              </tr>
            </thead>
            <tbody>
              {logs.map((log) => {
                const action = ACTIONS[log.action] ?? {
                  label: log.action,
                  cls: "bg-cream-200 text-ink-600",
                };
                return (
                  <tr
                    key={log.id}
                    className="border-b border-cream-200 last:border-0 hover:bg-cream-100/70"
                  >
                    <td className="whitespace-nowrap px-6 py-3 text-ink-600">
                      {new Date(log.created_at).toLocaleString("he-IL", {
                        day: "2-digit",
                        month: "2-digit",
                        year: "2-digit",
                        hour: "2-digit",
                        minute: "2-digit",
                      })}
                    </td>
                    {!building && (
                      <td className="whitespace-nowrap px-3 py-3 text-ink-900">
                        {log.buildings?.name ?? "—"}
                      </td>
                    )}
                    <td className="whitespace-nowrap px-3 py-3">
                      <span
                        className={`rounded-full px-2.5 py-0.5 text-xs font-semibold ${action.cls}`}
                      >
                        {action.label}
                      </span>
                    </td>
                    <td className="max-w-[360px] px-3 py-3 text-ink-900">
                      {summarize(log) || "—"}
                    </td>
                    <td className="whitespace-nowrap px-3 py-3 text-ink-600">
                      {log.actor
                        ? log.actor.full_name ||
                          formatPhoneDisplay(log.actor.phone_number)
                        : "מערכת"}
                    </td>
                  </tr>
                );
              })}
              {logs.length === 0 && (
                <tr>
                  <td colSpan={building ? 4 : 5} className="px-6 py-10 text-center text-ink-400">
                    אין פעולות מתועדות עדיין.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </Card>
    </div>
  );
}

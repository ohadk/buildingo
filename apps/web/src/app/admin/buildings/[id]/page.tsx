import Link from "next/link";
import { notFound } from "next/navigation";
import { supabaseAdmin } from "@/lib/supabase/admin";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { PRICE_PER_APARTMENT_ILS } from "@/lib/billing";
import { formatDateHe, formatPhoneDisplay } from "@/lib/format";
import { AssignVaadButton } from "../../actions";
import {
  SubscriptionControls,
  ToggleBuildingAccessButton,
  ToggleUserAccessButton,
} from "./actions";

export const dynamic = "force-dynamic";

interface BuildingDetail {
  id: string;
  name: string;
  address: string;
  city: string;
  country: string;
  postal_code: string | null;
  fee_method: "fixed" | "per_sqm";
  fixed_monthly_fee: number | null;
  price_per_sqm: number | null;
  is_active: boolean;
  plan_status: "trial" | "active" | "blocked";
  trial_ends_at: string;
  created_at: string;
  apartments: { id: string; apartment_number: number; floor: number }[];
  users: {
    id: string;
    full_name: string;
    phone_number: string;
    email: string | null;
    role: string;
    apartment_id: string | null;
    onboarded_at: string | null;
    is_active: boolean;
    created_at: string;
  }[];
  invitations: {
    id: string;
    status: string;
    role: string;
    phone_number: string;
    apartment_id: string;
  }[];
  tickets: {
    id: string;
    title: string;
    status: string;
    agent_status: string;
    agent_log: unknown[];
    created_at: string;
  }[];
}

const ticketStatusHe: Record<string, string> = {
  open: "פתוחה",
  approved: "אושרה",
  in_progress: "בטיפול",
  resolved: "טופלה",
  rejected: "נדחתה",
};

export default async function BuildingDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const { data, error } = await supabaseAdmin()
    .from("buildings")
    .select(
      `id, name, address, city, country, postal_code, fee_method, fixed_monthly_fee,
       price_per_sqm, is_active, plan_status, trial_ends_at, created_at,
       apartments(id, apartment_number, floor),
       users!users_building_id_fkey(id, full_name, phone_number, email, role, apartment_id, onboarded_at, is_active, created_at),
       invitations(id, status, role, phone_number, apartment_id),
       tickets(id, title, status, agent_status, agent_log, created_at)`,
    )
    .eq("id", id)
    .maybeSingle();
  if (error) throw new Error(`Building query failed: ${error.message}`);
  if (!data) notFound();
  const b = data as unknown as BuildingDetail;

  const connectedTenants = b.users.filter((u) => u.is_active && u.onboarded_at);
  const occupiedApartments = new Set(
    b.users.filter((u) => u.apartment_id).map((u) => u.apartment_id),
  );
  const openTickets = b.tickets.filter((t) =>
    ["open", "approved", "in_progress"].includes(t.status),
  );
  const agentDispatches = b.tickets.filter((t) => t.agent_status !== "idle");
  const agentMessages = b.tickets.reduce(
    (n, t) => n + (Array.isArray(t.agent_log) ? t.agent_log.length : 0),
    0,
  );
  // Pending invitees who haven't signed in yet (no users row for their phone)
  const registeredPhones = new Set(b.users.map((u) => u.phone_number));
  const pendingInvites = b.invitations.filter((i) => i.status === "pending");
  const awaitingInvitees = [
    ...new Map(
      pendingInvites
        .filter((i) => !registeredPhones.has(i.phone_number))
        .map((i) => [i.phone_number, i]),
    ).values(),
  ];

  const apartmentNumber = (apartmentId: string | null) =>
    b.apartments.find((a) => a.id === apartmentId)?.apartment_number;

  const vaadMembers = b.users.filter((u) => u.role === "vaad");
  const pendingVaadInvites = awaitingInvitees.filter((i) => i.role === "vaad");
  const trialDaysLeft = Math.ceil(
    (new Date(b.trial_ends_at).getTime() - Date.now()) / 86_400_000,
  );

  const stats = [
    {
      label: "דיירים מחוברים (לחיוב)",
      value: connectedTenants.length,
      sub: `מתוך ${b.users.length} רשומים`,
    },
    {
      label: "דירות מאוכלסות",
      value: `${occupiedApartments.size}/${b.apartments.length}`,
      sub: pendingInvites.length > 0 ? `${pendingInvites.length} הזמנות ממתינות` : undefined,
    },
    {
      label: "קריאות שירות פתוחות",
      value: openTickets.length,
      sub: `${b.tickets.length} סה״כ`,
    },
    {
      label: "שימוש בסוכן AI",
      value: agentDispatches.length,
      sub: `${agentMessages} הודעות סוכן`,
    },
  ];

  return (
    <div className="space-y-8">
      <div className="flex flex-wrap items-start justify-between gap-4">
        <div>
          <Link href="/admin" className="text-sm text-sage-700 hover:underline">
            → כל הבניינים
          </Link>
          <h1 className="mt-1 flex items-center gap-3 text-2xl font-bold text-ink-900">
            {b.name}
            {!b.is_active && (
              <span className="rounded-full bg-terracotta-100 px-3 py-1 text-xs font-semibold text-brick-600">
                הבניין מושבת
              </span>
            )}
          </h1>
          <p className="mt-1 text-sm text-ink-600">
            {b.address}, {b.city}, {b.country}
            {b.postal_code ? ` · מיקוד ${b.postal_code}` : ""} · נוצר{" "}
            {formatDateHe(b.created_at)} ·{" "}
            {b.fee_method === "fixed"
              ? `דמי ועד ₪${b.fixed_monthly_fee ?? 0} לדירה`
              : `דמי ועד ₪${b.price_per_sqm ?? 0} למ״ר`}
          </p>
        </div>
        <div className="flex gap-2">
          <AssignVaadButton
            building={{ id: b.id, name: b.name, apartments: b.apartments }}
          />
          <ToggleBuildingAccessButton
            buildingId={b.id}
            buildingName={b.name}
            isActive={b.is_active}
          />
        </div>
      </div>

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {stats.map((s) => (
          <Card key={s.label}>
            <CardHeader>
              <CardTitle className="text-3xl">{s.value}</CardTitle>
            </CardHeader>
            <CardContent className="text-sm text-ink-600">
              {s.label}
              {s.sub && <div className="mt-0.5 text-xs text-ink-400">{s.sub}</div>}
            </CardContent>
          </Card>
        ))}
      </div>

      <section>
        <h2 className="mb-3 text-xl font-bold text-ink-900">מנוי וגישה</h2>
        <Card className="flex flex-wrap items-center justify-between gap-4 p-6">
          <div>
            <div className="flex items-center gap-2">
              {b.plan_status === "active" ? (
                <span className="rounded-full bg-sage-100 px-3 py-1 text-sm font-semibold text-sage-700">
                  מנוי פעיל (שולם)
                </span>
              ) : b.plan_status === "blocked" ? (
                <span className="rounded-full bg-terracotta-100 px-3 py-1 text-sm font-semibold text-brick-600">
                  חסום
                </span>
              ) : trialDaysLeft > 0 ? (
                <span className="rounded-full bg-gold-300 px-3 py-1 text-sm font-semibold text-gold-700">
                  תקופת ניסיון — נותרו {trialDaysLeft} ימים
                </span>
              ) : (
                <span className="rounded-full bg-terracotta-100 px-3 py-1 text-sm font-semibold text-brick-600">
                  תקופת הניסיון הסתיימה — הגישה חסומה
                </span>
              )}
            </div>
            <p className="mt-2 text-xs text-ink-600">
              {b.plan_status === "trial"
                ? `הניסיון מסתיים ב־${formatDateHe(b.trial_ends_at)}. בסיום, הדיירים והוועד יאבדו גישה עד הפעלת מנוי.`
                : b.plan_status === "active"
                  ? "לבניין מנוי פעיל ללא הגבלת זמן."
                  : "הבניין חסום — אף משתמש לא יכול לגשת לנתונים."}
            </p>
            <p className="mt-1 text-xs font-semibold text-ink-900">
              מחיר מנוי: {b.apartments.length} דירות × ₪{PRICE_PER_APARTMENT_ILS} = ₪
              {(b.apartments.length * PRICE_PER_APARTMENT_ILS).toFixed(2)} לחודש
            </p>
          </div>
          <SubscriptionControls
            buildingId={b.id}
            planStatus={b.plan_status}
            trialEndsAt={b.trial_ends_at}
          />
        </Card>
      </section>

      <section>
        <h2 className="mb-3 text-xl font-bold text-ink-900">
          ועד הבית ({vaadMembers.length + pendingVaadInvites.length})
        </h2>
        {vaadMembers.length === 0 && pendingVaadInvites.length === 0 ? (
          <Card className="p-6 text-sm text-ink-600">
            טרם שויך ועד בית לבניין — השתמשו בכפתור ״שיוך ועד״ למעלה.
          </Card>
        ) : (
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {vaadMembers.map((v) => (
              <Card key={v.id} className="p-5">
                <div className="flex items-start gap-3">
                  <span className="grid h-11 w-11 flex-none place-items-center rounded-full bg-sage-100 font-heading text-lg text-sage-700">
                    {(v.full_name || "?").slice(0, 1)}
                  </span>
                  <div className="min-w-0">
                    <div className="flex flex-wrap items-center gap-2">
                      <span className="font-semibold text-ink-900">
                        {v.full_name || "ממתין להשלמת פרופיל"}
                      </span>
                      {!v.is_active ? (
                        <span className="rounded-full bg-terracotta-100 px-2.5 py-0.5 text-xs font-semibold text-brick-600">
                          מושבת
                        </span>
                      ) : v.onboarded_at ? (
                        <span className="rounded-full bg-sage-100 px-2.5 py-0.5 text-xs font-semibold text-sage-700">
                          מחובר
                        </span>
                      ) : (
                        <span className="rounded-full bg-gold-300/40 px-2.5 py-0.5 text-xs font-semibold text-gold-700">
                          טרם השלים פרופיל
                        </span>
                      )}
                    </div>
                    <div dir="ltr" className="mt-1 text-right text-sm text-ink-600">
                      {formatPhoneDisplay(v.phone_number)}
                    </div>
                    <div className="mt-1.5 text-xs text-ink-600">
                      {apartmentNumber(v.apartment_id) != null
                        ? `דירה ${apartmentNumber(v.apartment_id)}`
                        : "ללא דירה משויכת"}
                      {" · "}שויך {formatDateHe(v.created_at)}
                    </div>
                  </div>
                </div>
              </Card>
            ))}
            {pendingVaadInvites.map((i) => (
              <Card key={i.id} className="border border-dashed border-gold-500/50 bg-cream-100/60 p-5">
                <div className="flex items-start gap-3">
                  <span className="grid h-11 w-11 flex-none place-items-center rounded-full bg-gold-300/50 font-heading text-lg text-gold-700">
                    ?
                  </span>
                  <div className="min-w-0">
                    <div className="flex flex-wrap items-center gap-2">
                      <span className="font-semibold text-ink-900">הוזמן לוועד</span>
                      <span className="rounded-full bg-gold-300/40 px-2.5 py-0.5 text-xs font-semibold text-gold-700">
                        ממתין לחיבור ראשון
                      </span>
                    </div>
                    <div dir="ltr" className="mt-1 text-right text-sm text-ink-600">
                      {formatPhoneDisplay(i.phone_number)}
                    </div>
                    <div className="mt-1.5 text-xs text-ink-600">
                      {apartmentNumber(i.apartment_id) != null
                        ? `דירה ${apartmentNumber(i.apartment_id)}`
                        : "ללא דירה משויכת"}
                    </div>
                  </div>
                </div>
              </Card>
            ))}
          </div>
        )}
      </section>

      <section>
        <h2 className="mb-3 text-xl font-bold text-ink-900">
          דיירים ({b.users.length + awaitingInvitees.length})
        </h2>
        <Card>
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-cream-200 text-right text-ink-600">
                  <th className="px-5 py-3 font-semibold">שם</th>
                  <th className="px-5 py-3 font-semibold">טלפון</th>
                  <th className="px-5 py-3 font-semibold">דירה</th>
                  <th className="px-5 py-3 font-semibold">תפקיד</th>
                  <th className="px-5 py-3 font-semibold">סטטוס</th>
                  <th className="px-5 py-3 font-semibold">גישה</th>
                </tr>
              </thead>
              <tbody>
                {b.users
                  .slice()
                  .sort((a, z) => (apartmentNumber(a.apartment_id) ?? 999) - (apartmentNumber(z.apartment_id) ?? 999))
                  .map((u) => (
                    <tr key={u.id} className="border-b border-cream-200 last:border-0">
                      <td className="px-5 py-3 font-semibold text-ink-900">
                        {u.full_name || "ממתין להשלמת פרופיל"}
                      </td>
                      <td dir="ltr" className="px-5 py-3 text-right text-ink-600">
                        {formatPhoneDisplay(u.phone_number)}
                        {u.email && (
                          <div className="text-xs text-ink-400">{u.email}</div>
                        )}
                      </td>
                      <td className="px-5 py-3">{apartmentNumber(u.apartment_id) ?? "—"}</td>
                      <td className="px-5 py-3">
                        {u.role === "vaad" ? (
                          <span className="rounded-full bg-sage-100 px-3 py-1 text-xs font-semibold text-sage-700">
                            ועד
                          </span>
                        ) : (
                          <span className="text-ink-600">דייר</span>
                        )}
                      </td>
                      <td className="px-5 py-3">
                        {!u.is_active ? (
                          <span className="rounded-full bg-terracotta-100 px-3 py-1 text-xs font-semibold text-brick-600">
                            מושבת
                          </span>
                        ) : u.onboarded_at ? (
                          <span className="rounded-full bg-sage-100 px-3 py-1 text-xs font-semibold text-sage-700">
                            מחובר
                          </span>
                        ) : (
                          <span className="rounded-full bg-gold-300/40 px-3 py-1 text-xs font-semibold text-gold-700">
                            טרם השלים פרופיל
                          </span>
                        )}
                      </td>
                      <td className="px-5 py-3">
                        <ToggleUserAccessButton
                          userId={u.id}
                          userName={u.full_name || formatPhoneDisplay(u.phone_number)}
                          isActive={u.is_active}
                        />
                      </td>
                    </tr>
                  ))}
                {awaitingInvitees.map((i) => (
                  <tr key={i.id} className="border-b border-cream-200 last:border-0 bg-cream-100/60">
                    <td className="px-5 py-3 text-ink-600">הוזמן — טרם התחבר</td>
                    <td dir="ltr" className="px-5 py-3 text-right text-ink-600">
                      {formatPhoneDisplay(i.phone_number)}
                    </td>
                    <td className="px-5 py-3">{apartmentNumber(i.apartment_id) ?? "—"}</td>
                    <td className="px-5 py-3">
                      {i.role === "vaad" ? (
                        <span className="rounded-full bg-sage-100 px-3 py-1 text-xs font-semibold text-sage-700">
                          ועד
                        </span>
                      ) : (
                        <span className="text-ink-600">דייר</span>
                      )}
                    </td>
                    <td className="px-5 py-3">
                      <span className="rounded-full bg-gold-300/40 px-3 py-1 text-xs font-semibold text-gold-700">
                        ממתין לחיבור ראשון
                      </span>
                    </td>
                    <td className="px-5 py-3 text-ink-400">—</td>
                  </tr>
                ))}
                {b.users.length === 0 && awaitingInvitees.length === 0 && (
                  <tr>
                    <td colSpan={6} className="px-5 py-8 text-center text-ink-400">
                      אין דיירים רשומים עדיין — שייכו חבר ועד כדי להתחיל.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </Card>
      </section>

      <section>
        <h2 className="mb-3 text-xl font-bold text-ink-900">
          קריאות שירות אחרונות ({b.tickets.length})
        </h2>
        <Card>
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-cream-200 text-right text-ink-600">
                  <th className="px-5 py-3 font-semibold">קריאה</th>
                  <th className="px-5 py-3 font-semibold">סטטוס</th>
                  <th className="px-5 py-3 font-semibold">סוכן AI</th>
                  <th className="px-5 py-3 font-semibold">נפתחה</th>
                </tr>
              </thead>
              <tbody>
                {b.tickets
                  .slice()
                  .sort((a, z) => z.created_at.localeCompare(a.created_at))
                  .slice(0, 10)
                  .map((t) => (
                    <tr key={t.id} className="border-b border-cream-200 last:border-0">
                      <td className="px-5 py-3 font-semibold text-ink-900">{t.title}</td>
                      <td className="px-5 py-3 text-ink-600">
                        {ticketStatusHe[t.status] ?? t.status}
                      </td>
                      <td className="px-5 py-3">
                        {t.agent_status !== "idle" ? (
                          <span className="rounded-full bg-sage-100 px-3 py-1 text-xs font-semibold text-sage-700">
                            הופעל ({Array.isArray(t.agent_log) ? t.agent_log.length : 0} הודעות)
                          </span>
                        ) : (
                          <span className="text-ink-400">—</span>
                        )}
                      </td>
                      <td className="px-5 py-3 text-ink-600">{formatDateHe(t.created_at)}</td>
                    </tr>
                  ))}
                {b.tickets.length === 0 && (
                  <tr>
                    <td colSpan={4} className="px-5 py-8 text-center text-ink-400">
                      אין קריאות שירות עדיין.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </Card>
      </section>
    </div>
  );
}

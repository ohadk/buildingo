import Link from "next/link";
import { supabaseAdmin } from "@/lib/supabase/admin";
import { Card } from "@/components/ui/card";
import { AddBuildingButton, AssignVaadButton, DeleteBuildingButton } from "./actions";
import { formatPhoneDisplay } from "@/lib/format";

export const dynamic = "force-dynamic";

export interface AdminBuilding {
  id: string;
  name: string;
  address: string;
  city: string;
  country: string;
  fee_method: "fixed" | "per_sqm";
  fixed_monthly_fee: number | null;
  price_per_sqm: number | null;
  is_active: boolean;
  plan_status: "trial" | "active" | "blocked";
  trial_ends_at: string;
  created_at: string;
  apartments: { id: string; apartment_number: number; floor: number }[];
  users: { id: string; role: string; full_name: string; phone_number: string }[];
  invitations: { id: string; status: string; role: string; phone_number: string }[];
}

export default async function AdminPage() {
  const { data } = await supabaseAdmin()
    .from("buildings")
    .select(
      "id, name, address, city, country, fee_method, fixed_monthly_fee, price_per_sqm, is_active, plan_status, trial_ends_at, created_at, apartments(id, apartment_number, floor), users!users_building_id_fkey(id, role, full_name, phone_number), invitations(id, status, role, phone_number)",
    )
    .order("created_at", { ascending: false });
  const buildings = (data ?? []) as unknown as AdminBuilding[];

  const hasVaad = (b: AdminBuilding) =>
    b.users.some((u) => u.role === "vaad") ||
    b.invitations.some((i) => i.status === "pending" && i.role === "vaad");
  const withoutVaad = buildings.filter((b) => !hasVaad(b));

  const planBadge = (b: AdminBuilding) => {
    if (b.plan_status === "blocked" || !b.is_active) {
      return { label: "חסום", cls: "bg-terracotta-100 text-brick-600" };
    }
    if (b.plan_status === "active") {
      return { label: "מנוי פעיל", cls: "bg-sage-100 text-sage-700" };
    }
    const daysLeft = Math.ceil(
      (new Date(b.trial_ends_at).getTime() - Date.now()) / 86_400_000,
    );
    return daysLeft > 0
      ? { label: `ניסיון · ${daysLeft} ימים`, cls: "bg-gold-300 text-gold-700" }
      : { label: "ניסיון הסתיים", cls: "bg-terracotta-100 text-brick-600" };
  };

  const stats = [
    { label: "בניינים", value: buildings.length },
    { label: "דירות", value: buildings.reduce((n, b) => n + b.apartments.length, 0) },
    { label: "דיירים רשומים", value: buildings.reduce((n, b) => n + b.users.length, 0) },
    {
      label: "הזמנות ממתינות",
      value: buildings.reduce(
        (n, b) => n + b.invitations.filter((i) => i.status === "pending").length,
        0,
      ),
    },
  ];

  const today = new Date().toLocaleDateString("he-IL", { month: "long", year: "numeric" });

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-end justify-between gap-5">
        <div>
          <h1 className="text-3xl text-ink-900">סקירת פלטפורמה</h1>
          <p className="mt-1.5 text-sm text-ink-600">נתונים לחודש {today}</p>
        </div>
        <AddBuildingButton />
      </div>

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {stats.map((s) => (
          <Card key={s.label} className="p-5 px-6">
            <div className="mb-2 text-[13px] text-ink-600">{s.label}</div>
            <div className="font-heading text-3xl leading-none text-ink-900">{s.value}</div>
          </Card>
        ))}
      </div>

      <div className="grid items-start gap-5 lg:grid-cols-[1.65fr_1fr]">
        <Card className="overflow-hidden p-0">
          <div className="flex items-center justify-between px-6 pb-3 pt-5">
            <h3 className="text-xl text-ink-900">בניינים</h3>
          </div>
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-cream-200 text-right text-[11px] uppercase tracking-wider text-ink-600">
                  <th className="px-6 py-2.5 font-medium">כתובת</th>
                  <th className="px-3 py-2.5 font-medium">יח&apos;</th>
                  <th className="px-3 py-2.5 font-medium">ועד בית</th>
                  <th className="px-3 py-2.5 font-medium">דמי ועד</th>
                  <th className="px-3 py-2.5 font-medium">מנוי</th>
                  <th className="px-3 py-2.5 font-medium"></th>
                </tr>
              </thead>
              <tbody>
                {buildings.map((b) => {
                  const vaadMembers = b.users.filter((u) => u.role === "vaad");
                  const pendingVaad = [
                    ...new Set(
                      b.invitations
                        .filter((i) => i.status === "pending" && i.role === "vaad")
                        .map((i) => i.phone_number),
                    ),
                  ];
                  return (
                    <tr key={b.id} className="border-b border-cream-200 last:border-0 hover:bg-cream-100/70">
                      <td className="px-6 py-3">
                        <Link href={`/admin/buildings/${b.id}`} className="group block">
                          <div className="font-semibold text-ink-900 group-hover:text-brick-700">
                            {b.address}
                            {!b.is_active && (
                              <span className="ms-2 rounded-full bg-terracotta-100 px-2 py-0.5 text-xs font-semibold text-brick-600">
                                מושבת
                              </span>
                            )}
                          </div>
                          <div className="text-[11.5px] text-ink-600">{b.city}</div>
                        </Link>
                      </td>
                      <td className="px-3 py-3">{b.apartments.length}</td>
                      <td className="px-3 py-3">
                        <div className="flex flex-wrap gap-1">
                          {vaadMembers.map((v) => (
                            <span
                              key={v.id}
                              className="rounded-full bg-sage-100 px-2.5 py-0.5 text-xs font-semibold text-sage-700"
                              title={formatPhoneDisplay(v.phone_number)}
                            >
                              {v.full_name || formatPhoneDisplay(v.phone_number)}
                            </span>
                          ))}
                          {pendingVaad.map((phone) => (
                            <span
                              key={phone}
                              className="rounded-full bg-gold-300 px-2.5 py-0.5 text-xs font-semibold text-gold-700"
                              title="הוזמן — ממתין לחיבור ראשון"
                            >
                              <bdi dir="ltr">{formatPhoneDisplay(phone)}</bdi> · ממתין
                            </span>
                          ))}
                          {vaadMembers.length === 0 && pendingVaad.length === 0 && (
                            <span className="rounded-full bg-terracotta-100 px-2.5 py-0.5 text-xs font-semibold text-brick-600">
                              אין ועד
                            </span>
                          )}
                        </div>
                      </td>
                      <td className="whitespace-nowrap px-3 py-3 text-ink-600">
                        {b.fee_method === "fixed"
                          ? `₪${b.fixed_monthly_fee ?? 0} לדירה`
                          : `₪${b.price_per_sqm ?? 0} למ״ר`}
                      </td>
                      <td className="whitespace-nowrap px-3 py-3">
                        {(() => {
                          const badge = planBadge(b);
                          return (
                            <span
                              className={`rounded-full px-2.5 py-0.5 text-xs font-semibold ${badge.cls}`}
                            >
                              {badge.label}
                            </span>
                          );
                        })()}
                      </td>
                      <td className="px-3 py-3 text-left">
                        <div className="flex items-center justify-end gap-1.5">
                          <AssignVaadButton
                            building={{ id: b.id, name: b.name, apartments: b.apartments }}
                          />
                          <Link
                            href={`/admin/buildings/${b.id}`}
                            className="rounded-full px-3 py-1.5 text-xs font-semibold text-brick-700 hover:bg-terracotta-100"
                          >
                            כניסה
                          </Link>
                          <DeleteBuildingButton
                            building={{ id: b.id, name: b.name, address: b.address }}
                            userCount={b.users.length}
                          />
                        </div>
                      </td>
                    </tr>
                  );
                })}
                {buildings.length === 0 && (
                  <tr>
                    <td colSpan={6} className="px-6 py-10 text-center text-ink-400">
                      אין בניינים עדיין — הוסיפו את הבניין הראשון בכפתור למעלה.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </Card>

        <div className="flex flex-col gap-5">
          {withoutVaad.length > 0 && (
            <section className="rounded-2xl bg-sage-100 p-6">
              <h3 className="mb-2 text-lg text-ink-900">בניינים ללא ועד</h3>
              <p className="mb-4 text-[13px] leading-relaxed text-sage-900">
                {withoutVaad.length === 1
                  ? "בניין אחד מחכה לשיוך ועד בית לפני שהתושבים יוזמנו."
                  : `${withoutVaad.length} בניינים מחכים לשיוך ועד בית לפני שהתושבים יוזמנו.`}
              </p>
              <ul className="space-y-1.5 text-sm text-ink-900">
                {withoutVaad.slice(0, 4).map((b) => (
                  <li key={b.id} className="flex items-center justify-between gap-2">
                    <span>
                      {b.address}, {b.city}
                    </span>
                    <AssignVaadButton
                      building={{ id: b.id, name: b.name, apartments: b.apartments }}
                    />
                  </li>
                ))}
              </ul>
            </section>
          )}
          <section className="rounded-2xl bg-ink-950 p-6 text-cream-50/80">
            <h3 className="mb-2 text-lg text-white">מודל החיוב</h3>
            <p className="text-[13px] leading-relaxed">
              החיוב הוא לפי דיירים מחוברים. היכנסו לבניין כדי לראות כמה דיירים
              השלימו פרופיל, את קריאות השירות ואת השימוש בסוכן ה-AI.
            </p>
          </section>
        </div>
      </div>
    </div>
  );
}

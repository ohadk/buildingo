"use client";

import { useRouter } from "next/navigation";

/** Dropdown that scopes the audit table to one building via ?building=. */
export function BuildingFilter({
  buildings,
  selected,
}: {
  buildings: { id: string; label: string }[];
  selected: string;
}) {
  const router = useRouter();
  return (
    <select
      value={selected}
      onChange={(e) => {
        const v = e.target.value;
        router.push(v ? `/admin/audit?building=${v}` : "/admin/audit");
      }}
      className="rounded-2xl border border-cream-200 bg-white px-4 py-2.5 text-sm text-ink-900 shadow-sm focus:border-brick-500 focus:outline-none"
    >
      <option value="">כל הבניינים</option>
      {buildings.map((b) => (
        <option key={b.id} value={b.id}>
          {b.label}
        </option>
      ))}
    </select>
  );
}

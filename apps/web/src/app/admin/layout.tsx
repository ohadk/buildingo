import { redirect } from "next/navigation";
import Link from "next/link";
import { getSessionUser } from "@/lib/auth/session";
import { LogoutButton } from "./logout-button";

export default async function AdminLayout({ children }: { children: React.ReactNode }) {
  const user = await getSessionUser();
  if (!user) redirect("/login");
  if (user.role !== "super_admin") redirect("/");

  return (
    <div className="flex min-h-screen flex-col">
      <header className="sticky top-0 z-40 flex items-center gap-4 bg-ink-950 px-6 py-3 text-cream-50">
        <Link href="/admin" className="flex items-center gap-2.5">
          <span className="grid h-7 w-7 place-items-center rounded-full bg-brick-500 font-heading text-sm text-white">
            ב
          </span>
          <span className="font-heading text-lg">
            Buildingo<span className="text-terracotta-500">.</span>
          </span>
        </Link>
        <span className="text-xs text-cream-50/50">ניהול פלטפורמה</span>
        <div className="ms-auto flex items-center gap-3 text-sm text-cream-50/70">
          <span dir="ltr">{user.full_name || user.phone_number}</span>
          <LogoutButton />
        </div>
      </header>

      <div className="flex flex-1 items-stretch">
        <aside className="hidden w-60 flex-none flex-col gap-1 bg-ink-950 px-4 py-6 text-cream-50/70 md:flex">
          <div className="px-3 pb-2 text-[11px] tracking-widest text-cream-50/40">פלטפורמה</div>
          <Link
            href="/admin"
            className="rounded-2xl bg-white/10 px-4 py-2.5 text-sm font-medium text-white"
          >
            סקירת פלטפורמה
          </Link>
          <div className="mt-auto rounded-2xl bg-white/5 p-4 text-xs leading-relaxed">
            <div className="mb-1 text-white">מנהל־על · {user.full_name || "מנהל"}</div>
            גישה מלאה לכל הבניינים במערכת
          </div>
        </aside>
        <main className="min-w-0 flex-1 px-6 py-8 lg:px-9">{children}</main>
      </div>
    </div>
  );
}

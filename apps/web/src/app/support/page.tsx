import type { Metadata } from "next";
import Link from "next/link";
import { SupportForm } from "./support-form";

export const metadata: Metadata = {
  title: "תמיכה וצור קשר — Buildingo",
  description: "צרו קשר עם צוות Buildingo לתמיכה באפליקציה, שאלות על החשבון או עזרה בוועד הבית.",
};

const SUPPORT_EMAIL = process.env.NEXT_PUBLIC_SUPPORT_EMAIL || "support@buildingo.com";

export default function SupportPage() {
  return (
    <main className="min-h-screen">
      <header className="border-b border-cream-300 bg-cream-50/80">
        <div className="mx-auto flex max-w-3xl items-center justify-between px-6 py-4">
          <Link href="/" className="font-heading text-xl text-brick-700">
            Buildingo
          </Link>
          <Link href="/" className="text-sm text-ink-600 hover:text-ink-900">
            לדף הבית
          </Link>
        </div>
      </header>

      <section className="mx-auto max-w-3xl px-6 py-14">
        <p className="text-sm font-semibold tracking-wide text-brick-700">Support</p>
        <h1 className="mt-2 text-4xl text-ink-900">תמיכה וצור קשר</h1>
        <p className="mt-4 max-w-2xl text-lg leading-relaxed text-ink-600">
          צריכים עזרה עם האפליקציה, החשבון או ניהול הבניין? שלחו פנייה ונחזור אליכם בהקדם.
        </p>

        <div className="mt-8 rounded-2xl border border-cream-300 bg-cream-50 px-5 py-4 text-sm text-ink-600">
          אפשר גם לכתוב ישירות ל־{" "}
          <a
            href={`mailto:${SUPPORT_EMAIL}`}
            className="font-medium text-brick-700 underline underline-offset-2"
            dir="ltr"
          >
            {SUPPORT_EMAIL}
          </a>
        </div>

        <div className="mt-10">
          <SupportForm />
        </div>

        <div className="mt-14 space-y-3 border-t border-cream-300 pt-8 text-sm text-ink-600">
          <p className="font-semibold text-ink-900">שאלות נפוצות</p>
          <p>
            <span className="font-medium text-ink-900">איך נכנסים?</span> התחברות עם מספר הטלפון
            שהוזמן לבניין, ואז קוד SMS.
          </p>
          <p>
            <span className="font-medium text-ink-900">שכחתי את הקוד / לא מגיע SMS?</span> בדקו את
            המספר, המתינו דקה ונסו שוב. אם זה נמשך — כתבו לנו עם מספר הטלפון שלכם.
          </p>
          <p>
            <span className="font-medium text-ink-900">מדיניות פרטיות</span> —{" "}
            <Link href="/privacy" className="text-brick-700 underline underline-offset-2">
              buildingo.com/privacy
            </Link>
          </p>
        </div>
      </section>

      <footer className="mx-auto max-w-3xl px-6 pb-12 text-center text-sm text-ink-400">
        © {new Date().getFullYear()} Buildingo
      </footer>
    </main>
  );
}

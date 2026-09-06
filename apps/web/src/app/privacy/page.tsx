import type { Metadata } from "next";
import Link from "next/link";

export const metadata: Metadata = {
  title: "מדיניות פרטיות — Buildingo",
  description: "מדיניות הפרטיות של אפליקציית Buildingo לניהול בניינים משותפים.",
};

export default function PrivacyPage() {
  return (
    <main className="min-h-screen">
      <header className="border-b border-cream-300 bg-cream-50/80">
        <div className="mx-auto flex max-w-3xl items-center justify-between px-6 py-4">
          <Link href="/" className="font-heading text-xl text-brick-700">
            Buildingo
          </Link>
          <Link href="/support" className="text-sm text-ink-600 hover:text-ink-900">
            צור קשר
          </Link>
        </div>
      </header>

      <article className="mx-auto max-w-3xl px-6 py-14 prose-headings:font-heading">
        <p className="text-sm font-semibold tracking-wide text-brick-700">Privacy</p>
        <h1 className="mt-2 text-4xl text-ink-900">מדיניות פרטיות</h1>
        <p className="mt-2 text-sm text-ink-400">עודכן לאחרונה: ספטמבר 2026</p>

        <div className="mt-8 space-y-6 text-base leading-relaxed text-ink-600">
          <p>
            Buildingo („השירות“) היא אפליקציה לניהול בניין משותף עבור דיירים וועד בית. מדיניות זו
            מסבירה אילו מידע אנחנו אוספים, למה, וכיצד ניתן לפנות אלינו.
          </p>

          <section className="space-y-2">
            <h2 className="text-xl text-ink-900">מידע שאנחנו אוספים</h2>
            <ul className="list-disc space-y-1 pr-5">
              <li>מספר טלפון לצורך התחברות (OTP / SMS).</li>
              <li>שם, דירה, ופרטי קשר שמוזנים בפרופיל או בהזמנה לבניין.</li>
              <li>
                תוכן שאתם יוצרים בשירות: הודעות, תקלות, תשלומים, מסמכים והצבעות — במסגרת הבניין
                שלכם.
              </li>
              <li>נתונים טכניים בסיסיים לשיפור השירות ואבטחה (למשל מזהה התקן להתראות).</li>
            </ul>
          </section>

          <section className="space-y-2">
            <h2 className="text-xl text-ink-900">למה אנחנו משתמשים במידע</h2>
            <ul className="list-disc space-y-1 pr-5">
              <li>להפעלת האפליקציה ולשיוך משתמשים לדירה ולבניין.</li>
              <li>לשלוח התראות וקודים להתחברות.</li>
              <li>לאפשר לוועד ולדיירים לנהל תשלומים, תקלות ומסמכים.</li>
              <li>לתמוך בכם כשפונים אלינו, ולשמור על אבטחת השירות.</li>
            </ul>
          </section>

          <section className="space-y-2">
            <h2 className="text-xl text-ink-900">שיתוף עם צדדים שלישיים</h2>
            <p>
              אנחנו לא מוכרים את המידע שלכם. ספקי תשתית (למשל אימות, אחסון, שליחת SMS/מייל) מקבלים
              גישה רק למה שנדרש להפעלת השירות, תחת התחייבויות סודיות. בתוך הבניין, דיירים וועד רואים
              מידע בהתאם להרשאות התפקיד שלהם.
            </p>
          </section>

          <section className="space-y-2">
            <h2 className="text-xl text-ink-900">שמירה ואבטחה</h2>
            <p>
              המידע נשמר כל עוד החשבון או הבניין פעילים, או כנדרש על פי דין. אנחנו נוקטים באמצעי אבטחה
              סבירים, כולל הצפנת שדות רגישים בסביבת ייצור כשהוגדר לכך.
            </p>
          </section>

          <section className="space-y-2">
            <h2 className="text-xl text-ink-900">הזכויות שלכם</h2>
            <p>
              אפשר לבקש עיון, תיקון או מחיקה של מידע אישי דרך{" "}
              <Link href="/support" className="text-brick-700 underline underline-offset-2">
                דף התמיכה
              </Link>
              . חלק מהמידע נשמר לצרכי תיעוד בניין (למשל היסטוריית תשלומים) לפי צורך תפעולי וחוקי.
            </p>
          </section>

          <section className="space-y-2">
            <h2 className="text-xl text-ink-900">יצירת קשר</h2>
            <p>
              לשאלות על פרטיות או תמיכה:{" "}
              <Link href="/support" className="text-brick-700 underline underline-offset-2">
                buildingo.com/support
              </Link>
              .
            </p>
          </section>

          <section className="space-y-2 border-t border-cream-300 pt-6" dir="ltr">
            <h2 className="text-xl text-ink-900 text-left">English summary</h2>
            <p className="text-left">
              Buildingo collects account and building data (phone sign-in, profile, apartment
              activity) to run the service for residents and the Vaad. We do not sell personal data.
              Contact us at{" "}
              <Link href="/support" className="text-brick-700 underline underline-offset-2">
                /support
              </Link>{" "}
              for access, correction, or deletion requests.
            </p>
          </section>
        </div>
      </article>

      <footer className="mx-auto max-w-3xl px-6 pb-12 text-center text-sm text-ink-400">
        © {new Date().getFullYear()} Buildingo
      </footer>
    </main>
  );
}

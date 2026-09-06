import type { Metadata } from "next";
import Image from "next/image";
import Link from "next/link";
import { Button } from "@/components/ui/button";

export const metadata: Metadata = {
  title: "Buildingo — הבניין שלכם, מסודר",
  description:
    "אפליקציה לוועד דיירים: דמי ועד, תקלות עם שיגור סוכן AI לספקים, הודעות, דיירים, מסמכים ואסיפות — הכל במקום אחד.",
};

const APP_STORE_URL =
  process.env.APP_STORE_URL ||
  "https://apps.apple.com/search?term=Buildingo&entity=software";

const FEATURES = [
  {
    eyebrow: "סוכן AI",
    title: "תקלה נכנסת. הספק מקבל פנייה.",
    body: "דייר מדווח מהטלפון, הוועד מאשר בלחיצה — וסוכן Buildingo מנסח פנייה רשמית לחברת המעליות, לאינסטלטור או לחשמלאי עם כתובת הבניין, פרטי התקלה ותנאי החוזה. במייל, SMS או וואטסאפ.",
    image: "/marketing/web/05-maintenance.png",
    imageAlt: "מסך תקלות ושיגור סוכן באפליקציית Buildingo",
    points: ["אישור ועד בלחיצה אחת", "פנייה אוטומטית לספק", "מעקב סטטוס עד לסגירה"],
  },
  {
    eyebrow: "כסף שקוף",
    title: "דמי ועד שכולם רואים.",
    body: "מטריצת תשלומים חיה לכל דירה, סימון שולם, קבלות ומאזן בניין. הוועד גובה בלי אקסל — והדיירים יודעים בדיוק מה מגיע.",
    image: "/marketing/web/03-payments.png",
    imageAlt: "מסך תשלומים ודמי ועד ב-Buildingo",
    points: ["מעקב לפי דירה וחודש", "קבלות והוצאות", "שקיפות לדיירים"],
  },
  {
    eyebrow: "קהילה",
    title: "דיירים, דירות והודעות במקום אחד.",
    body: "ספר דיירים לפי קומה, הזמנות אישיות להצטרפות, ולוח הודעות שמגיע לכולם. בלי קבוצות וואטסאפ ששוקעות.",
    image: "/marketing/web/04-directory.png",
    imageAlt: "ספר דיירים באפליקציית Buildingo",
    points: ["הזמנה לפי דירה", "לוח הודעות לבניין", "עדכון אוטומטי של הרשימה"],
  },
  {
    eyebrow: "בית",
    title: "הכל שקורה בבניין — במסך אחד.",
    body: "דף הבית מרכז תשלומים קרובים, תקלות פתוחות, הודעות ואירועים. דייר והוועד רואים בדיוק את מה שרלוונטי להם.",
    image: "/marketing/web/02-home.png",
    imageAlt: "מסך הבית של Buildingo",
    points: ["תמונת מצב יומית", "התראות על מה שחשוב", "עברית מלאה ו-RTL"],
  },
];

const MORE = [
  {
    title: "מסמכים לכל דירה",
    body: "חוזים, קבלות ופרוטוקולים — עם בידוד גישה. דייר רואה את שלו, הוועד רואה את כל הבניין.",
  },
  {
    title: "אסיפות והצבעות",
    body: "סדר יום, הצבעה אחת לדירה, וסיכום שמופץ ללוח המודעות בלי לרדוף אחרי חתימות.",
  },
  {
    title: "כניסה בטלפון בלבד",
    body: "בלי סיסמאות. OTP ב-SMS, וכל מספר משויך מראש לדירה הנכונה.",
  },
  {
    title: "לוח אירועים",
    body: "אסיפות, ביקורי ספקים ותזכורות — כדי שאף אחד לא יגיד „לא ידעתי“.",
  },
];

export default function LandingPage() {
  return (
    <main className="overflow-x-hidden">
      {/* ── Nav ── */}
      <header className="absolute inset-x-0 top-0 z-20">
        <div className="mx-auto flex max-w-6xl items-center justify-between px-6 py-5">
          <Link href="/" className="font-heading text-2xl tracking-tight text-ink-900">
            Buildingo
          </Link>
          <div className="flex items-center gap-3">
            <Link
              href="/support"
              className="hidden text-sm text-ink-600 hover:text-ink-900 sm:inline"
            >
              צור קשר
            </Link>
            <Link href="/login">
              <Button size="sm" variant="outline">
                כניסת מנהלים
              </Button>
            </Link>
          </div>
        </div>
      </header>

      {/* ── Hero: one composition ── */}
      <section className="landing-hero min-h-[100svh]">
        <div className="relative mx-auto grid min-h-[100svh] max-w-6xl items-center gap-10 px-6 pb-16 pt-28 lg:grid-cols-[1.05fr_0.95fr] lg:gap-6 lg:pb-20 lg:pt-24">
          <div className="relative z-10 text-center lg:text-start">
            <p className="landing-rise font-heading text-4xl text-brick-700 sm:text-5xl md:text-6xl">
              Buildingo
            </p>
            <h1 className="landing-rise landing-rise-delay-1 mt-4 text-3xl leading-tight text-ink-900 sm:text-4xl md:text-5xl">
              הבניין סוף־סוף מסתדר לבד.
            </h1>
            <p className="landing-rise landing-rise-delay-2 mx-auto mt-5 max-w-xl text-lg leading-relaxed text-ink-600 lg:mx-0">
              דמי ועד, תקלות, דיירים ומסמכים — ואפילו סוכן AI שפונה לספקים במקומכם.
            </p>
            <div className="landing-rise landing-rise-delay-3 mt-9 flex flex-wrap items-center justify-center gap-3 lg:justify-start">
              <a href={APP_STORE_URL} target="_blank" rel="noopener noreferrer">
                <Button size="lg">הורידו את האפליקציה</Button>
              </a>
              <a href="#agent">
                <Button size="lg" variant="outline">
                  תראו את הסוכן
                </Button>
              </a>
            </div>
          </div>

          <div className="landing-rise landing-rise-delay-4 relative mx-auto w-full max-w-[340px] lg:max-w-none">
            <div
              className="landing-glow absolute inset-[12%] -z-10 rounded-full bg-terracotta-300/50 blur-3xl"
              aria-hidden
            />
            <div className="landing-phone-float relative">
              <Image
                src="/marketing/web/01-welcome.png"
                alt="מסך הפתיחה של אפליקציית Buildingo"
                width={915}
                height={1724}
                priority
                className="mx-auto h-auto w-full max-w-[280px] sm:max-w-[320px] lg:max-w-[360px]"
              />
            </div>
          </div>
        </div>
      </section>

      {/* ── Promise strip ── */}
      <section className="border-y border-cream-300 bg-cream-50/80">
        <div className="mx-auto grid max-w-6xl gap-8 px-6 py-12 sm:grid-cols-3">
          {[
            { k: "לוועד", v: "פחות רדיפה אחרי דיירים וספקים" },
            { k: "לדיירים", v: "שקיפות מלאה על מה שקורה בבניין" },
            { k: "לכולם", v: "עברית, טלפון בלבד, בלי סיסמאות" },
          ].map((item) => (
            <div key={item.k} className="text-center sm:text-start">
              <p className="text-sm font-semibold tracking-wide text-brick-700">{item.k}</p>
              <p className="mt-2 text-lg text-ink-900">{item.v}</p>
            </div>
          ))}
        </div>
      </section>

      {/* ── Feature chapters with product shots ── */}
      {FEATURES.map((feature, index) => {
        const reverse = index % 2 === 1;
        const isAgent = index === 0;
        return (
          <section
            key={feature.title}
            id={isAgent ? "agent" : undefined}
            className={isAgent ? "landing-section-band" : undefined}
          >
            <div
              className={`mx-auto grid max-w-6xl items-center gap-12 px-6 py-20 lg:grid-cols-2 lg:gap-16 lg:py-28`}
            >
              <div className={reverse ? "lg:order-2" : undefined}>
                <p className="text-sm font-semibold tracking-wide text-brick-700">
                  {feature.eyebrow}
                </p>
                <h2 className="mt-3 text-3xl leading-snug text-ink-900 md:text-4xl">
                  {feature.title}
                </h2>
                <p className="mt-5 text-lg leading-relaxed text-ink-600">{feature.body}</p>
                <ul className="mt-8 space-y-3">
                  {feature.points.map((point) => (
                    <li key={point} className="flex items-start gap-3 text-ink-900">
                      <span
                        className="mt-2 h-2 w-2 shrink-0 rounded-full bg-sage-500"
                        aria-hidden
                      />
                      <span>{point}</span>
                    </li>
                  ))}
                </ul>
              </div>
              <div className={`relative mx-auto w-full max-w-[320px] ${reverse ? "lg:order-1" : ""}`}>
                <div
                  className="absolute inset-[18%] -z-10 rounded-full bg-sage-200/60 blur-3xl"
                  aria-hidden
                />
                <Image
                  src={feature.image}
                  alt={feature.imageAlt}
                  width={920}
                  height={1724}
                  className="mx-auto h-auto w-full max-w-[300px] lg:max-w-[340px]"
                />
              </div>
            </div>
          </section>
        );
      })}

      {/* ── Agent story ── */}
      <section className="bg-ink-950 text-cream-50">
        <div className="mx-auto max-w-3xl px-6 py-20 text-center md:py-28">
          <p className="text-sm font-semibold tracking-wide text-gold-500">איך הסוכן עובד</p>
          <h2 className="mt-3 text-3xl text-cream-50 md:text-4xl">מדיווח ועד ספק — בארבעה צעדים</h2>
          <ol className="mt-12 space-y-8 text-start">
            {[
              "דייר מדווח מהאפליקציה: „המעלית תקועה בין קומות 2–3“.",
              "הוועד בוחן ולוחץ „אשר ושגר סוכן“.",
              "הסוכן מנסח פנייה רשמית עם כתובת, פרטי תקלה ותנאי החוזה.",
              "הספק מקבל מייל / SMS / וואטסאפ — והסטטוס מתעדכן אצל כולם.",
            ].map((step, i) => (
              <li key={step} className="flex gap-5">
                <span className="font-heading text-3xl text-gold-500 tabular-nums">
                  {String(i + 1).padStart(2, "0")}
                </span>
                <p className="pt-2 text-lg leading-relaxed text-cream-200">{step}</p>
              </li>
            ))}
          </ol>
        </div>
      </section>

      {/* ── More capabilities ── */}
      <section className="mx-auto max-w-6xl px-6 py-20 md:py-28">
        <div className="max-w-2xl">
          <p className="text-sm font-semibold tracking-wide text-brick-700">עוד בפנים</p>
          <h2 className="mt-3 text-3xl text-ink-900 md:text-4xl">כל מה שוועד ובניין צריכים</h2>
        </div>
        <div className="mt-14 grid gap-x-12 gap-y-12 sm:grid-cols-2">
          {MORE.map((item) => (
            <div key={item.title} className="border-t border-cream-300 pt-6">
              <h3 className="text-xl text-ink-900">{item.title}</h3>
              <p className="mt-3 leading-relaxed text-ink-600">{item.body}</p>
            </div>
          ))}
        </div>
      </section>

      {/* ── Audiences ── */}
      <section className="border-y border-cream-300 bg-sage-100/70">
        <div className="mx-auto grid max-w-6xl gap-16 px-6 py-20 md:grid-cols-2 md:py-28">
          <div>
            <p className="text-sm font-semibold tracking-wide text-sage-700">לוועד הבית</p>
            <h2 className="mt-3 text-3xl text-ink-900">תנהלו בניין, לא כאוס</h2>
            <ul className="mt-8 space-y-4 text-ink-600">
              {[
                "גביית דמי ועד ומעקב תשלומים",
                "שיגור סוכני ספקים לתקלות",
                "הזמנת דיירים לפי דירה",
                "פרסום הודעות וניהול אסיפות",
                "ארכיון מסמכים לכל הבניין",
              ].map((line) => (
                <li key={line} className="flex gap-3">
                  <span className="text-sage-700" aria-hidden>
                    —
                  </span>
                  <span>{line}</span>
                </li>
              ))}
            </ul>
          </div>
          <div>
            <p className="text-sm font-semibold tracking-wide text-brick-700">לדיירים</p>
            <h2 className="mt-3 text-3xl text-ink-900">תדעו מה קורה בבית</h2>
            <ul className="mt-8 space-y-4 text-ink-600">
              {[
                "יתרות ותשלומים קרובים",
                "דיווח תקלה ומעקב סטטוס",
                "הודעות ועד ואירועים",
                "מסמכים של הדירה",
                "הצטרפות בהזמנה אישית",
              ].map((line) => (
                <li key={line} className="flex gap-3">
                  <span className="text-brick-700" aria-hidden>
                    —
                  </span>
                  <span>{line}</span>
                </li>
              ))}
            </ul>
          </div>
        </div>
      </section>

      {/* ── Closing CTA ── */}
      <section className="landing-hero">
        <div className="relative mx-auto max-w-3xl px-6 py-24 text-center md:py-32">
          <p className="font-heading text-4xl text-brick-700 sm:text-5xl">Buildingo</p>
          <h2 className="mt-4 text-3xl text-ink-900 md:text-4xl">
            זה בדיוק מה שהבניין שלכם חיכה לו.
          </h2>
          <p className="mx-auto mt-5 max-w-xl text-lg text-ink-600">
            התחילו עם האפליקציה לדיירים ולוועד — והפסיקו לרדוף אחרי כולם בוואטסאפ.
          </p>
          <div className="mt-10 flex flex-wrap items-center justify-center gap-3">
            <a href={APP_STORE_URL} target="_blank" rel="noopener noreferrer">
              <Button size="lg">הורידו עכשיו</Button>
            </a>
            <Link href="/support">
              <Button size="lg" variant="outline">
                דברו איתנו
              </Button>
            </Link>
          </div>
        </div>
      </section>

      <footer className="border-t border-cream-300 bg-cream-50">
        <div className="mx-auto flex max-w-6xl flex-col items-center justify-between gap-4 px-6 py-10 text-sm text-ink-400 sm:flex-row">
          <p>© {new Date().getFullYear()} Buildingo</p>
          <div className="flex flex-wrap items-center justify-center gap-x-5 gap-y-2">
            <Link className="hover:text-ink-600" href="/support">
              תמיכה
            </Link>
            <Link className="hover:text-ink-600" href="/privacy">
              פרטיות
            </Link>
            <Link className="hover:text-ink-600" href="/login">
              כניסת מנהלים
            </Link>
          </div>
        </div>
      </footer>
    </main>
  );
}

import Link from "next/link";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";

const FEATURES = [
  {
    title: "שיגור ספקים חכם",
    body: "דייר מדווח על תקלה, הוועד מאשר בלחיצה אחת — וסוכן AI מבוסס Claude פונה לחברת המעליות, לאינסטלטור או לחשמלאי במייל, ב-SMS או בוואטסאפ, עם כל פרטי החוזה.",
  },
  {
    title: "דמי ועד והנהלת חשבונות",
    body: "מטריצת תשלומים חיה לכל דירה, מעקב הוצאות עם קבלות, ומאזן בניין שקוף שכל דייר יכול לראות.",
  },
  {
    title: "אסיפות והצבעות",
    body: "פרסום סדר יום, הצבעה מאובטחת אחת לכל דירה, והפקת מסמך סיכום אוטומטי שמופץ בלוח המודעות של הבניין.",
  },
  {
    title: "ספר דיירים וחניות",
    body: "רשימת דיירים לפי קומה ודירה כולל שיוך חניות, שמתעדכנת אוטומטית דרך הצטרפות בהזמנה אישית.",
  },
  {
    title: "ארכיון מסמכים",
    body: "חוזי שכירות, קבלות ופרוטוקולים שמורים לכל דירה בנפרד עם בידוד גישה מלא — דיירים רואים את שלהם, הוועד רואה את כל הבניין.",
  },
  {
    title: "כניסה בטלפון בלבד",
    body: "בלי סיסמאות. דיירים נכנסים עם קוד SMS, וכל מספר טלפון משויך מראש לדירה המדויקת שלו.",
  },
];

export default function LandingPage() {
  return (
    <main>
      {/* Hero */}
      <section className="hero-wash">
        <div className="mx-auto max-w-5xl px-6 py-24 text-center">
          <p className="text-sm font-semibold tracking-widest text-brick-700">דירה</p>
          <h1 className="mt-4 text-5xl font-bold text-ink-900 leading-tight">
            הבניין שלכם, מנהל את עצמו.
          </h1>
          <p className="mx-auto mt-6 max-w-2xl text-lg text-ink-600">
            בית אחד לדמי ועד, תחזוקה, אסיפות ומסמכים — עם סוכן AI שרודף אחרי הספקים
            כדי שהוועד לא יצטרך.
          </p>
          <div className="mt-10 flex items-center justify-center gap-4">
            <Link href="/login">
              <Button size="lg">כניסה עם מספר טלפון</Button>
            </Link>
            <a href="#features">
              <Button size="lg" variant="outline">
                מה יש בפנים
              </Button>
            </a>
          </div>
        </div>
      </section>

      {/* Features */}
      <section id="features" className="mx-auto max-w-5xl px-6 py-20">
        <h2 className="text-center text-3xl font-bold text-ink-900">
          כל מה שוועד בית צריך
        </h2>
        <div className="mt-12 grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
          {FEATURES.map((f) => (
            <Card key={f.title}>
              <CardHeader>
                <CardTitle>{f.title}</CardTitle>
              </CardHeader>
              <CardContent>
                <p className="text-sm leading-relaxed text-ink-600">{f.body}</p>
              </CardContent>
            </Card>
          ))}
        </div>
      </section>

      {/* How it works */}
      <section className="bg-sage-100">
        <div className="mx-auto max-w-5xl px-6 py-20">
          <h2 className="text-center text-3xl font-bold text-ink-900">איך עובד השיגור?</h2>
          <ol className="mx-auto mt-10 max-w-2xl space-y-4 text-ink-600">
            {[
              "דייר מדווח מהאפליקציה: „המעלית תקועה בין קומות 2–3“.",
              "הוועד בוחן את הפנייה ולוחץ „אשר ושגר סוכן“.",
              "Claude מנסח פנייה רשמית לספק עם כתובת הבניין, פרטי התקלה ותנאי החוזה.",
              "הספק מקבל הודעה במייל, ב-SMS או בוואטסאפ — וציר הזמן של הפנייה מתעדכן: „הסוכן יצר קשר עם הספק“.",
            ].map((step, i) => (
              <li key={i} className="flex gap-4">
                <span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-brick-500 text-cream-50 font-bold">
                  {i + 1}
                </span>
                <span className="pt-1">{step}</span>
              </li>
            ))}
          </ol>
        </div>
      </section>

      <footer className="mx-auto max-w-5xl px-6 py-10 text-center text-sm text-ink-400">
        דירה — ניהול בניינים משותפים. דיירים משתמשים באפליקציה;{" "}
        מנהלי המערכת <Link className="underline" href="/login">נכנסים כאן</Link>.
      </footer>
    </main>
  );
}

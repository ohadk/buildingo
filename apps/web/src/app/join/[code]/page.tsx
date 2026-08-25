import { supabaseAdmin } from "@/lib/supabase/admin";

export const dynamic = "force-dynamic";

/**
 * Public landing page for the WhatsApp join link the Vaad shares.
 * Shows which building the code belongs to and how to join from the app.
 */
export default async function JoinPage({ params }: { params: Promise<{ code: string }> }) {
  const { code } = await params;
  const { data: building } = await supabaseAdmin()
    .from("buildings")
    .select("name, address, city")
    .eq("join_code", code)
    .eq("is_active", true)
    .maybeSingle();

  return (
    <main className="mx-auto flex min-h-screen max-w-md flex-col items-center justify-center gap-6 px-6 text-center">
      <span className="grid h-14 w-14 place-items-center rounded-full bg-brick-500 font-heading text-2xl text-white">
        ב
      </span>
      {building ? (
        <>
          <h1 className="text-3xl text-ink-900">הוזמנתם להצטרף לבניין</h1>
          <div className="rounded-2xl bg-cream-50 px-8 py-6 shadow-[0_3px_10px_rgba(46,43,37,0.10)]">
            <div className="font-heading text-xl text-ink-900">{building.name}</div>
            <div className="mt-1 text-sm text-ink-600">
              {building.address}, {building.city}
            </div>
          </div>
          <ol className="space-y-2 text-start text-sm leading-relaxed text-ink-600">
            <li>1. מורידים את אפליקציית Buildingo לנייד.</li>
            <li>2. מתחברים עם מספר הטלפון שלכם (קוד ב-SMS).</li>
            <li>
              3. בוחרים ״יש לי קוד הצטרפות״ ומזינים את הקוד:
              <div
                dir="ltr"
                className="mt-2 rounded-xl bg-cream-200 px-4 py-2 text-center font-mono text-lg tracking-widest text-ink-900"
              >
                {code}
              </div>
            </li>
            <li>4. ממלאים שם ומספר דירה ושולחים בקשה — ועד הבית מאשר ואתם בפנים.</li>
          </ol>
        </>
      ) : (
        <>
          <h1 className="text-3xl text-ink-900">הקישור לא בתוקף</h1>
          <p className="text-sm text-ink-600">
            קוד ההצטרפות לא נמצא או שהבניין אינו פעיל. בקשו מוועד הבית קישור חדש.
          </p>
        </>
      )}
    </main>
  );
}

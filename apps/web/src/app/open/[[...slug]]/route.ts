import { NextRequest, NextResponse } from "next/server";
import { storeLinks } from "@/lib/store-links";

/**
 * GET /open and /open/payments — Universal / App Link landing + fallback.
 * Native apps claim these paths via Associated Domains / App Links.
 * WhatsApp in-app browsers may still load this page; we try buildingo://
 * and offer store buttons.
 */
export function GET(
  _req: NextRequest,
  ctx: { params: Promise<{ slug?: string[] }> },
) {
  return ctx.params.then(({ slug }) => {
    const path = (slug ?? []).join("/");
    const target = path ? `buildingo://open/${path}` : "buildingo://open";
    const { appStore, playStore, site } = storeLinks();

    const title =
      path === "payments"
        ? "פתיחת תשלומים ב־Buildingo"
        : "פתיחת Buildingo";
    const body =
      "אם האפליקציה מותקנת — לחצו לפתיחה. אחרת הורידו מחנות האפליקציות.";

    const html = `<!DOCTYPE html>
<html lang="he" dir="rtl">
<head>
  <meta charset="utf-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1"/>
  <title>${escapeHtml(title)}</title>
  <style>
    :root { color-scheme: light; }
    body {
      margin: 0; min-height: 100vh; display: grid; place-items: center;
      font-family: system-ui, -apple-system, "Segoe UI", sans-serif;
      background: #FAF3E0; color: #241C18; padding: 24px;
    }
    .card {
      width: min(420px, 100%); background: #FFFBF2; border-radius: 20px;
      padding: 28px 24px; box-shadow: 0 12px 40px rgba(36,28,24,.08);
      text-align: center;
    }
    .mark {
      width: 56px; height: 56px; border-radius: 999px; margin: 0 auto 16px;
      background: #A34A3A; color: #FFFBF2; display: grid; place-items: center;
      font-size: 1.6rem; font-weight: 700;
    }
    h1 { margin: 0 0 8px; font-size: 1.45rem; }
    p { margin: 0 0 22px; color: #7F7360; line-height: 1.45; font-size: .95rem; }
    a.btn {
      display: block; text-decoration: none; border-radius: 14px;
      padding: 14px 16px; margin: 0 0 10px; font-weight: 700;
    }
    a.open { background: #A34A3A; color: #FFFBF2; }
    a.ios { background: #241C18; color: #FFFBF2; }
    a.android { background: #4F6D4F; color: #FFFBF2; }
    a.site { color: #4F6D4F; font-size: .9rem; }
  </style>
</head>
<body>
  <div class="card">
    <div class="mark">ב</div>
    <h1>${escapeHtml(title)}</h1>
    <p>${escapeHtml(body)}</p>
    <a class="btn open" href="${escapeHtml(target)}">פתחו באפליקציה</a>
    <a class="btn ios" href="${escapeHtml(appStore)}">הורדה ל־iPhone</a>
    <a class="btn android" href="${escapeHtml(playStore)}">הורדה ל־Android</a>
    <a class="site" href="${escapeHtml(site)}">לאתר Buildingo</a>
  </div>
  <script>
    (function () {
      var target = ${JSON.stringify(target)};
      try { window.location.href = target; } catch (e) {}
    })();
  </script>
</body>
</html>`;

    return new NextResponse(html, {
      status: 200,
      headers: {
        "content-type": "text/html; charset=utf-8",
        "cache-control": "public, max-age=300",
      },
    });
  });
}

function escapeHtml(s: string): string {
  return s
    .replaceAll("&", "&amp;")
    .replaceAll('"', "&quot;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;");
}

import { NextRequest, NextResponse } from "next/server";

/**
 * GET /app — single download link for WhatsApp / marketing.
 * Detects iOS vs Android and redirects to the matching store.
 * Desktop gets a tiny chooser page with both store buttons.
 *
 * Configure (optional):
 *   APP_STORE_URL  — e.g. https://apps.apple.com/app/idXXXXXXXX
 *   PLAY_STORE_URL — e.g. https://play.google.com/store/apps/details?id=com.buildingo.buildingoMobile
 */
export function GET(req: NextRequest) {
  const ua = req.headers.get("user-agent") ?? "";
  const appStore =
    process.env.APP_STORE_URL?.trim() ||
    "https://apps.apple.com/search?term=Buildingo&entity=software";
  const playStore =
    process.env.PLAY_STORE_URL?.trim() ||
    "https://play.google.com/store/search?q=Buildingo&c=apps";
  const site =
    process.env.PUBLIC_WEB_URL?.replace(/\/$/, "") ||
    "https://buildingo-api--buildingo-6ff54.us-central1.hosted.app";

  const isIos = /iPhone|iPad|iPod/i.test(ua);
  const isAndroid = /Android/i.test(ua);

  if (isIos) {
    return NextResponse.redirect(appStore, 302);
  }
  if (isAndroid) {
    return NextResponse.redirect(playStore, 302);
  }

  const html = `<!DOCTYPE html>
<html lang="he" dir="rtl">
<head>
  <meta charset="utf-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1"/>
  <title>Buildingo — הורדה</title>
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
    h1 { margin: 0 0 8px; font-size: 1.5rem; }
    p { margin: 0 0 22px; color: #7F7360; line-height: 1.45; font-size: .95rem; }
    a.btn {
      display: block; text-decoration: none; border-radius: 14px;
      padding: 14px 16px; margin: 0 0 10px; font-weight: 700;
    }
    a.ios { background: #241C18; color: #FFFBF2; }
    a.android { background: #A34A3A; color: #FFFBF2; }
    a.site { color: #4F6D4F; font-size: .9rem; }
  </style>
</head>
<body>
  <div class="card">
    <h1>Buildingo</h1>
    <p>הורידו את האפליקציה לניהול הבניין — לוועד ולדיירים.</p>
    <a class="btn ios" href="${escapeHtml(appStore)}">הורדה ל־iPhone</a>
    <a class="btn android" href="${escapeHtml(playStore)}">הורדה ל־Android</a>
    <a class="site" href="${escapeHtml(site)}">לאתר Buildingo</a>
  </div>
</body>
</html>`;

  return new NextResponse(html, {
    status: 200,
    headers: {
      "content-type": "text/html; charset=utf-8",
      "cache-control": "public, max-age=300",
    },
  });
}

function escapeHtml(s: string): string {
  return s
    .replaceAll("&", "&amp;")
    .replaceAll('"', "&quot;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;");
}

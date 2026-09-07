import { NextResponse } from "next/server";

/**
 * iOS Universal Links association file.
 * Must be served at /.well-known/apple-app-site-association (no .json)
 * with Content-Type application/json and no auth/redirects.
 *
 * Team ID GVU7RNHQS7 · bundle com.buildingo.buildingoMobile
 */
export function GET() {
  const body = {
    applinks: {
      apps: [],
      details: [
        {
          appIDs: ["GVU7RNHQS7.com.buildingo.buildingoMobile"],
          components: [
            { "/": "/open", comment: "Open app home" },
            { "/": "/open/*", comment: "Deep links (e.g. /open/payments)" },
            { "/": "/app", comment: "Store / open shortcut" },
          ],
          // Legacy path format (older iOS).
          paths: ["/open", "/open/*", "/app"],
        },
      ],
    },
  };

  return NextResponse.json(body, {
    headers: {
      "content-type": "application/json",
      "cache-control": "public, max-age=3600",
    },
  });
}

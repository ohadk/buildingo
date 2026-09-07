import { NextResponse } from "next/server";

/**
 * Android App Links Digital Asset Links.
 * Package: com.dira.dira_mobile
 *
 * Set ANDROID_APP_LINK_SHA256S to comma-separated cert fingerprints
 * (Play App Signing + any upload/debug keys you verify with), e.g.:
 *   ANDROID_APP_LINK_SHA256S=AB:CD:...,12:34:...
 */
export function GET() {
  const raw = process.env.ANDROID_APP_LINK_SHA256S?.trim() || "";
  const fingerprints = raw
    .split(",")
    .map((s) => s.trim())
    .filter(Boolean);

  const body =
    fingerprints.length === 0
      ? []
      : [
          {
            relation: ["delegate_permission/common.handle_all_urls"],
            target: {
              namespace: "android_app",
              package_name: "com.dira.dira_mobile",
              sha256_cert_fingerprints: fingerprints,
            },
          },
        ];

  return NextResponse.json(body, {
    headers: {
      "content-type": "application/json",
      "cache-control": "public, max-age=3600",
    },
  });
}

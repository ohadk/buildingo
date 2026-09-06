import { readFileSync } from "fs";
import { resolve } from "path";
import { cert, getApps, initializeApp, type App } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { env } from "@/lib/env";

let app: App | undefined;

function loadServiceAccount(): object {
  // Production (e.g. Firebase App Hosting): inline JSON or base64 env var.
  const inline = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (inline) {
    const raw = inline.trim().startsWith("{")
      ? inline
      : Buffer.from(inline, "base64").toString("utf8");
    return JSON.parse(raw);
  }
  // Local development: key file referenced from .env.local.
  const keyPath = resolve(
    /*turbopackIgnore: true*/ process.cwd(),
    env.firebaseServiceAccountPath,
  );
  return JSON.parse(readFileSync(keyPath, "utf8"));
}

function getAdminApp(): App {
  if (!app) {
    const existing = getApps();
    if (existing.length > 0) {
      app = existing[0];
    } else {
      app = initializeApp({ credential: cert(loadServiceAccount()) });
    }
  }
  return app;
}

export function adminAuth() {
  return getAuth(getAdminApp());
}

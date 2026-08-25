// One-time setup helper: reads the local service account and fetches the
// Firebase Web App client config (apiKey, appId, etc.) needed for
// NEXT_PUBLIC_FIREBASE_* env vars. Prints the config as JSON.
import { GoogleAuth } from "google-auth-library";

const projectId = "buildingo-6ff54";
const auth = new GoogleAuth({
  keyFile: "../../firebase-service-account.json",
  scopes: ["https://www.googleapis.com/auth/firebase.readonly"],
});
const client = await auth.getClient();

const list = await client.request({
  url: `https://firebase.googleapis.com/v1beta1/projects/${projectId}/webApps`,
});
const apps = list.data.apps ?? [];
if (apps.length === 0) {
  console.log(JSON.stringify({ error: "NO_WEB_APP" }));
  process.exit(0);
}
const cfg = await client.request({
  url: `https://firebase.googleapis.com/v1beta1/${apps[0].name}/config`,
});
console.log(JSON.stringify(cfg.data, null, 2));

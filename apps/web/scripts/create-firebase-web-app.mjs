// One-time setup: registers a Web App on the Firebase project so the
// client SDK (phone OTP) has an apiKey/appId, then prints its config.
import { GoogleAuth } from "google-auth-library";

const projectId = "buildingo-6ff54";
const auth = new GoogleAuth({
  keyFile: "../../firebase-service-account.json",
  scopes: ["https://www.googleapis.com/auth/cloud-platform"],
});
const client = await auth.getClient();
const base = "https://firebase.googleapis.com/v1beta1";

const op = await client.request({
  url: `${base}/projects/${projectId}/webApps`,
  method: "POST",
  data: { displayName: "Dira Web" },
});

// Poll the long-running operation until the app exists
let appName;
for (let i = 0; i < 30; i++) {
  const status = await client.request({ url: `${base}/${op.data.name}` });
  if (status.data.done) {
    appName = status.data.response?.name;
    break;
  }
  await new Promise((r) => setTimeout(r, 2000));
}
if (!appName) throw new Error("Timed out waiting for web app creation");

const cfg = await client.request({ url: `${base}/${appName}/config` });
console.log(JSON.stringify(cfg.data, null, 2));

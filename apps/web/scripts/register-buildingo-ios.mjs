// One-time: registers the rebranded iOS app (com.buildingo.buildingoMobile)
// on the Firebase project and prints its config for GoogleService-Info.plist.
import { GoogleAuth } from "google-auth-library";

const projectId = "buildingo-6ff54";
const IOS_BUNDLE = "com.buildingo.buildingoMobile";

const auth = new GoogleAuth({
  keyFile: "../../firebase-service-account.json",
  scopes: ["https://www.googleapis.com/auth/cloud-platform"],
});
const client = await auth.getClient();
const base = "https://firebase.googleapis.com/v1beta1";

async function waitOp(opName) {
  for (let i = 0; i < 30; i++) {
    const s = await client.request({ url: `${base}/${opName}` });
    if (s.data.done) return s.data.response;
    await new Promise((r) => setTimeout(r, 2000));
  }
  throw new Error(`Timed out on ${opName}`);
}

const list = await client.request({ url: `${base}/projects/${projectId}/iosApps` });
let app = (list.data.apps ?? []).find((a) => a.bundleId === IOS_BUNDLE);
if (!app) {
  const op = await client.request({
    url: `${base}/projects/${projectId}/iosApps`,
    method: "POST",
    data: { displayName: "Buildingo iOS", bundleId: IOS_BUNDLE },
  });
  app = await waitOp(op.data.name);
}

const cfg = await client.request({ url: `${base}/${app.name}/config` });
console.log(JSON.stringify({ appId: app.appId, bundleId: IOS_BUNDLE }, null, 2));
console.log("---PLIST---");
console.log(Buffer.from(cfg.data.configFileContents, "base64").toString("utf8"));

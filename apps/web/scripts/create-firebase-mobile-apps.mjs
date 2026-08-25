// One-time setup: registers the Android + iOS apps on the Firebase
// project (matching the Flutter bundle ids) and prints both configs,
// used to generate lib/firebase_options.dart.
import { GoogleAuth } from "google-auth-library";

const projectId = "buildingo-6ff54";
const ANDROID_PACKAGE = "com.dira.dira_mobile";
const IOS_BUNDLE = "com.dira.diraMobile";

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

async function ensureApp(kind, listKey, createBody, matchFn) {
  const list = await client.request({ url: `${base}/projects/${projectId}/${kind}` });
  const existing = (list.data.apps ?? []).find(matchFn);
  if (existing) return existing;
  const op = await client.request({
    url: `${base}/projects/${projectId}/${kind}`,
    method: "POST",
    data: createBody,
  });
  return waitOp(op.data.name);
}

const androidApp = await ensureApp(
  "androidApps",
  "apps",
  { displayName: "Dira Android", packageName: ANDROID_PACKAGE },
  (a) => a.packageName === ANDROID_PACKAGE,
);
const iosApp = await ensureApp(
  "iosApps",
  "apps",
  { displayName: "Dira iOS", bundleId: IOS_BUNDLE },
  (a) => a.bundleId === IOS_BUNDLE,
);

// The per-app config files (google-services.json / GoogleService-Info.plist)
const androidCfg = await client.request({ url: `${base}/${androidApp.name}/config` });
const iosCfg = await client.request({ url: `${base}/${iosApp.name}/config` });

console.log(
  JSON.stringify(
    {
      android: {
        appId: androidApp.appId,
        packageName: ANDROID_PACKAGE,
        configFileBase64: androidCfg.data.configFileContents,
      },
      ios: {
        appId: iosApp.appId,
        bundleId: IOS_BUNDLE,
        configFileBase64: iosCfg.data.configFileContents,
      },
    },
    null,
    2,
  ),
);

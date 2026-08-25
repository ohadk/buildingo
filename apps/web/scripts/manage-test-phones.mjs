// Dev utility: list/update the Firebase Auth test phone numbers so the
// simulator can sign in without real SMS. Usage:
//   node scripts/manage-test-phones.mjs                 # list
//   node scripts/manage-test-phones.mjs +9725... 123456 # add/update
import { GoogleAuth } from "google-auth-library";

const projectId = "buildingo-6ff54";
const auth = new GoogleAuth({
  keyFile: "../../firebase-service-account.json",
  scopes: ["https://www.googleapis.com/auth/cloud-platform"],
});
const client = await auth.getClient();
const url = `https://identitytoolkit.googleapis.com/admin/v2/projects/${projectId}/config`;

const { data: cfg } = await client.request({ url });
const current = cfg.signIn?.phoneNumber?.testPhoneNumbers ?? {};
console.log("Current test phone numbers:", current);

const [phone, code] = process.argv.slice(2);
if (phone && code) {
  const updated = { ...current, [phone]: code };
  await client.request({
    url: `${url}?updateMask=signIn.phoneNumber.testPhoneNumbers`,
    method: "PATCH",
    data: { signIn: { phoneNumber: { enabled: true, testPhoneNumbers: updated } } },
  });
  console.log("Updated test phone numbers:", updated);
}

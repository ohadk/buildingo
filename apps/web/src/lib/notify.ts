import { env } from "@/lib/env";
import { isWahaConfigured, phoneToChatId, sendText } from "@/lib/waha/client";

export interface SendResult {
  sent: boolean;
  provider: string;
  detail: string;
}

/** Sends an email through SendGrid. No-ops (with log) when unconfigured. */
export async function sendEmail(to: string, subject: string, body: string): Promise<SendResult> {
  if (!env.sendgrid.apiKey) {
    return { sent: false, provider: "sendgrid", detail: "SENDGRID_API_KEY not configured — payload logged only" };
  }
  const res = await fetch("https://api.sendgrid.com/v3/mail/send", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${env.sendgrid.apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      personalizations: [{ to: [{ email: to }] }],
      from: { email: env.sendgrid.fromEmail, name: "Dira Building Management" },
      subject,
      content: [{ type: "text/plain", value: body }],
    }),
  });
  if (!res.ok) {
    return { sent: false, provider: "sendgrid", detail: `SendGrid error ${res.status}: ${await res.text()}` };
  }
  return { sent: true, provider: "sendgrid", detail: `Email sent to ${to}` };
}

async function sendTwilioMessage(to: string, body: string, whatsapp: boolean): Promise<SendResult> {
  const provider = whatsapp ? "twilio-whatsapp" : "twilio-sms";
  const from = whatsapp ? env.twilio.whatsappFrom : env.twilio.fromNumber;
  if (!env.twilio.accountSid || !env.twilio.authToken || !from) {
    return { sent: false, provider, detail: "Twilio not configured — payload logged only" };
  }
  const res = await fetch(
    `https://api.twilio.com/2010-04-01/Accounts/${env.twilio.accountSid}/Messages.json`,
    {
      method: "POST",
      headers: {
        Authorization:
          "Basic " + Buffer.from(`${env.twilio.accountSid}:${env.twilio.authToken}`).toString("base64"),
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: new URLSearchParams({
        To: whatsapp ? `whatsapp:${to}` : to,
        From: whatsapp ? `whatsapp:${from}` : from,
        Body: body,
      }),
    },
  );
  if (!res.ok) {
    return { sent: false, provider, detail: `Twilio error ${res.status}: ${await res.text()}` };
  }
  return { sent: true, provider, detail: `${whatsapp ? "WhatsApp" : "SMS"} sent to ${to}` };
}

export const sendSms = (to: string, body: string) => sendTwilioMessage(to, body, false);

/**
 * Prefer WAHA (WhatsApp via QR session). Falls back to Twilio if needed.
 * `session` defaults to WAHA_SESSION / "buildingo".
 */
export async function sendWhatsApp(
  to: string,
  body: string,
  opts?: { session?: string },
): Promise<SendResult> {
  if (isWahaConfigured()) {
    const session = opts?.session || env.waha.defaultSession;
    const chatId = to.includes("@") ? to : phoneToChatId(to);
    const result = await sendText(session, chatId, body);
    if (result.ok) {
      return { sent: true, provider: "waha", detail: result.detail };
    }
    const twilio = await sendTwilioMessage(to, body, true);
    if (twilio.sent) return twilio;
    return { sent: false, provider: "waha", detail: result.detail };
  }
  return sendTwilioMessage(to, body, true);
}

import { env } from "@/lib/env";

export type WahaSessionStatus =
  | "STOPPED"
  | "STARTING"
  | "SCAN_QR_CODE"
  | "WORKING"
  | "FAILED"
  | string;

export type WahaSession = {
  name: string;
  status: WahaSessionStatus;
  me?: { id?: string; pushName?: string } | null;
};

export type WahaChat = {
  id: string;
  name?: string | null;
  isGroup?: boolean;
};

function configured(): boolean {
  return Boolean(env.waha.url && env.waha.apiKey);
}

async function wahaFetch(path: string, init: RequestInit = {}): Promise<Response> {
  if (!configured()) {
    throw new Error("WAHA is not configured (WAHA_URL / WAHA_API_KEY)");
  }
  const headers = new Headers(init.headers);
  headers.set("X-Api-Key", env.waha.apiKey!);
  headers.set("Accept", "application/json");
  if (init.body && !headers.has("Content-Type")) {
    headers.set("Content-Type", "application/json");
  }
  return fetch(`${env.waha.url}${path}`, { ...init, headers });
}

/** E.164 / local phone → WAHA chat id (`972...@c.us`). */
export function phoneToChatId(phone: string): string {
  let digits = phone.replace(/\D/g, "");
  if (digits.startsWith("0") && digits.length >= 9) {
    digits = `972${digits.slice(1)}`;
  }
  return `${digits}@c.us`;
}

export function chatIdToPhone(chatId: string): string | null {
  const bare = chatId.split("@")[0]?.replace(/\D/g, "");
  if (!bare) return null;
  return bare.startsWith("972") ? `+${bare}` : `+${bare}`;
}

export function isWahaConfigured(): boolean {
  return configured();
}

export async function getSession(name: string): Promise<WahaSession | null> {
  const res = await wahaFetch(`/api/sessions/${encodeURIComponent(name)}`);
  if (res.status === 404) return null;
  if (!res.ok) throw new Error(`WAHA getSession ${res.status}: ${await res.text()}`);
  return (await res.json()) as WahaSession;
}

export async function createOrStartSession(
  name: string,
  webhookUrl?: string | null,
): Promise<WahaSession> {
  const existing = await getSession(name);
  const webhooks =
    webhookUrl && env.waha.webhookSecret
      ? [
          {
            url: webhookUrl,
            events: ["message", "session.status"],
            customHeaders: [{ name: "X-Webhook-Secret", value: env.waha.webhookSecret }],
          },
        ]
      : webhookUrl
        ? [{ url: webhookUrl, events: ["message", "session.status"] }]
        : [];

  if (!existing) {
    const res = await wahaFetch("/api/sessions", {
      method: "POST",
      body: JSON.stringify({
        name,
        start: true,
        config: { webhooks },
      }),
    });
    if (!res.ok) throw new Error(`WAHA createSession ${res.status}: ${await res.text()}`);
    return (await res.json()) as WahaSession;
  }

  if (webhooks.length) {
    await wahaFetch(`/api/sessions/${encodeURIComponent(name)}`, {
      method: "POST",
      body: JSON.stringify({ config: { webhooks } }),
    }).catch(() => null);
  }

  if (existing.status === "STOPPED" || existing.status === "FAILED") {
    const res = await wahaFetch(`/api/sessions/${encodeURIComponent(name)}/start`, {
      method: "POST",
    });
    if (!res.ok) throw new Error(`WAHA startSession ${res.status}: ${await res.text()}`);
    return (await res.json()) as WahaSession;
  }

  return existing;
}

/** Raw QR payload (data URL or wa.me link depending on engine). */
export async function getQr(session: string): Promise<{ value?: string } | null> {
  const res = await wahaFetch(`/api/${encodeURIComponent(session)}/auth/qr?format=raw`);
  if (!res.ok) return null;
  return (await res.json()) as { value?: string };
}

/** PNG bytes for the QR / pairing screen. */
export async function getQrImage(session: string): Promise<Buffer | null> {
  const res = await wahaFetch(`/api/${encodeURIComponent(session)}/auth/qr?format=image`);
  if (!res.ok) return null;
  return Buffer.from(await res.arrayBuffer());
}

export async function listChats(session: string): Promise<WahaChat[]> {
  const res = await wahaFetch(`/api/${encodeURIComponent(session)}/chats`);
  if (!res.ok) throw new Error(`WAHA listChats ${res.status}: ${await res.text()}`);
  const data = (await res.json()) as WahaChat[];
  return Array.isArray(data) ? data : [];
}

export async function sendText(
  session: string,
  chatId: string,
  text: string,
): Promise<{ ok: boolean; detail: string }> {
  const res = await wahaFetch("/api/sendText", {
    method: "POST",
    body: JSON.stringify({ session, chatId, text }),
  });
  if (!res.ok) {
    return { ok: false, detail: `WAHA sendText ${res.status}: ${await res.text()}` };
  }
  return { ok: true, detail: `WhatsApp sent via WAHA to ${chatId}` };
}

export function sessionNameForBuilding(buildingId: string): string {
  return `buildingo_${buildingId}`;
}

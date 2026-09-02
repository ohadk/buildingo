import { NextRequest, NextResponse } from "next/server";
import { env } from "@/lib/env";
import { supabaseAdmin } from "@/lib/supabase/admin";
import { createTicketFromWhatsApp } from "@/lib/waha/ticket-from-message";

type WahaMessagePayload = {
  id?: string;
  timestamp?: number;
  from?: string;
  fromMe?: boolean;
  body?: string | null;
  hasMedia?: boolean;
  chatId?: string;
  participant?: string;
};

type WahaWebhookBody = {
  event?: string;
  session?: string;
  payload?: WahaMessagePayload;
};

/**
 * POST /api/webhooks/waha — inbound WAHA events.
 * Listens for group messages on a linked building WhatsApp group and
 * opens a maintenance ticket when the text looks like a fault report.
 */
export async function POST(req: NextRequest) {
  const secret = env.waha.webhookSecret;
  if (secret) {
    const got = req.headers.get("x-webhook-secret") || req.headers.get("x-api-key");
    if (got !== secret) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }
  }

  let body: WahaWebhookBody;
  try {
    body = (await req.json()) as WahaWebhookBody;
  } catch {
    return NextResponse.json({ error: "Invalid JSON" }, { status: 400 });
  }

  if (body.event !== "message") {
    return NextResponse.json({ ok: true, ignored: body.event ?? "unknown" });
  }

  const payload = body.payload ?? {};
  if (payload.fromMe) {
    return NextResponse.json({ ok: true, ignored: "fromMe" });
  }

  const text = (payload.body ?? "").trim();
  if (!text) {
    return NextResponse.json({ ok: true, ignored: "empty" });
  }

  const chatId = payload.chatId || payload.from || "";
  if (!chatId.endsWith("@g.us")) {
    return NextResponse.json({ ok: true, ignored: "not_group" });
  }

  const session = body.session;
  if (!session) {
    return NextResponse.json({ ok: true, ignored: "no_session" });
  }

  const db = supabaseAdmin();
  const { data: matched } = await db
    .from("buildings")
    .select("id, whatsapp_group_id, waha_session")
    .eq("waha_session", session)
    .maybeSingle();

  if (!matched?.whatsapp_group_id) {
    return NextResponse.json({ ok: true, ignored: "building_not_linked" });
  }
  if (matched.whatsapp_group_id !== chatId) {
    return NextResponse.json({ ok: true, ignored: "other_group" });
  }

  const messageId =
    payload.id || `${session}:${chatId}:${payload.timestamp ?? Date.now()}:${text.slice(0, 40)}`;
  const from = payload.participant || payload.from || "";

  const result = await createTicketFromWhatsApp({
    buildingId: matched.id,
    messageId,
    chatId,
    from,
    body: text,
  });

  return NextResponse.json({ ok: true, ...result });
}

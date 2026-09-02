import Anthropic from "@anthropic-ai/sdk";
import { env } from "@/lib/env";
import { logAudit } from "@/lib/audit";
import { findBuildingUserByPhoneVariants } from "@/lib/pii";
import { chatIdToPhone } from "@/lib/waha/client";
import { supabaseAdmin } from "@/lib/supabase/admin";

const TICKET_HINTS =
  /תקלה|מקולקל|לא עובד|נזילה|דליפה|סתימה|מעלית|חשמל|מים|ריח|רעש|דלת|גג|מנעול|שבור|תיקון|fault|leak|broken|elevator|clog|repair|ticket|issue|water|power|door/i;

export type TicketGuess = {
  isTicket: boolean;
  title: string;
  description: string;
};

function heuristicGuess(body: string): TicketGuess {
  const text = body.trim();
  if (text.length < 4) return { isTicket: false, title: "", description: text };
  const isTicket = TICKET_HINTS.test(text);
  const title = text.length <= 60 ? text : `${text.slice(0, 57)}…`;
  return { isTicket, title, description: text };
}

async function classifyWithClaude(body: string): Promise<TicketGuess | null> {
  try {
    if (!process.env.ANTHROPIC_API_KEY || process.env.ANTHROPIC_API_KEY.startsWith("REPLACE")) {
      return null;
    }
    const client = new Anthropic({ apiKey: env.anthropicApiKey });
    const res = await client.messages.create({
      model: "claude-sonnet-4-5",
      max_tokens: 300,
      messages: [
        {
          role: "user",
          content: [
            "You classify WhatsApp messages from a residential building group.",
            "Decide if the message is reporting a maintenance fault / ticket.",
            "Reply with ONLY JSON: {\"isTicket\":boolean,\"title\":string,\"description\":string}",
            "Title max 80 chars, Hebrew OK. Ignore greetings, jokes, payments, voting, chat.",
            `Message:\n${body}`,
          ].join("\n"),
        },
      ],
    });
    const text = res.content.find((c) => c.type === "text")?.text ?? "";
    const match = text.match(/\{[\s\S]*\}/);
    if (!match) return null;
    const parsed = JSON.parse(match[0]) as TicketGuess;
    if (typeof parsed.isTicket !== "boolean") return null;
    return {
      isTicket: parsed.isTicket,
      title: String(parsed.title || body).slice(0, 255),
      description: String(parsed.description || body),
    };
  } catch (err) {
    console.error("whatsapp ticket classify failed", err);
    return null;
  }
}

export async function detectTicketIntent(body: string): Promise<TicketGuess> {
  const ai = await classifyWithClaude(body);
  if (ai) return ai;
  return heuristicGuess(body);
}

export async function createTicketFromWhatsApp(input: {
  buildingId: string;
  messageId: string;
  chatId: string;
  from: string;
  body: string;
}): Promise<{ ticketId: string | null; skippedReason: string | null }> {
  const db = supabaseAdmin();

  const { data: existing } = await db
    .from("whatsapp_inbound")
    .select("id, created_ticket_id")
    .eq("waha_message_id", input.messageId)
    .maybeSingle();
  if (existing) {
    return { ticketId: existing.created_ticket_id, skippedReason: "duplicate" };
  }

  const guess = await detectTicketIntent(input.body);
  if (!guess.isTicket) {
    await db.from("whatsapp_inbound").insert({
      building_id: input.buildingId,
      waha_message_id: input.messageId,
      chat_id: input.chatId,
      from_phone: chatIdToPhone(input.from),
      body: input.body,
      skipped_reason: "not_a_ticket",
    });
    return { ticketId: null, skippedReason: "not_a_ticket" };
  }

  const fromPhone = chatIdToPhone(input.from);
  let reporterId: string | null = null;
  let apartmentId: string | null = null;

  if (fromPhone) {
    const variants = [fromPhone, fromPhone.replace(/^\+/, ""), `+${fromPhone.replace(/^\+/, "")}`];
    const match = await findBuildingUserByPhoneVariants(db, input.buildingId, variants);
    if (match) {
      reporterId = match.id;
      apartmentId = match.apartment_id;
    }
  }

  if (!reporterId) {
    const { data: vaad } = await db
      .from("users")
      .select("id")
      .eq("building_id", input.buildingId)
      .eq("role", "vaad")
      .eq("is_active", true)
      .limit(1)
      .maybeSingle();
    reporterId = vaad?.id ?? null;
  }

  if (!reporterId) {
    await db.from("whatsapp_inbound").insert({
      building_id: input.buildingId,
      waha_message_id: input.messageId,
      chat_id: input.chatId,
      from_phone: fromPhone,
      body: input.body,
      skipped_reason: "no_reporter",
    });
    return { ticketId: null, skippedReason: "no_reporter" };
  }

  const { data: ticket, error } = await db
    .from("tickets")
    .insert({
      building_id: input.buildingId,
      apartment_id: apartmentId,
      reported_by: reporterId,
      title: guess.title.slice(0, 255),
      description: `${guess.description}\n\n— via WhatsApp group${fromPhone ? ` (${fromPhone})` : ""}`,
      location: "WhatsApp",
      category: "other",
    })
    .select("id")
    .single();
  if (error || !ticket) {
    await db.from("whatsapp_inbound").insert({
      building_id: input.buildingId,
      waha_message_id: input.messageId,
      chat_id: input.chatId,
      from_phone: fromPhone,
      body: input.body,
      skipped_reason: error?.message ?? "insert_failed",
    });
    return { ticketId: null, skippedReason: error?.message ?? "insert_failed" };
  }

  await db.from("ticket_events").insert({
    ticket_id: ticket.id,
    building_id: input.buildingId,
    label: "Reported",
    detail: `Detected from WhatsApp group message${fromPhone ? ` by ${fromPhone}` : ""}`,
    actor: reporterId,
  });

  await db.from("whatsapp_inbound").insert({
    building_id: input.buildingId,
    waha_message_id: input.messageId,
    chat_id: input.chatId,
    from_phone: fromPhone,
    body: input.body,
    created_ticket_id: ticket.id,
  });

  await logAudit({
    buildingId: input.buildingId,
    actorId: reporterId,
    action: "ticket_created",
    entityType: "ticket",
    entityId: ticket.id,
    details: { title: guess.title, source: "whatsapp_group" },
  });

  return { ticketId: ticket.id, skippedReason: null };
}

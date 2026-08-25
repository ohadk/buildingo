import Anthropic from "@anthropic-ai/sdk";
import { env } from "@/lib/env";
import { sendEmail, sendSms, sendWhatsApp } from "@/lib/notify";
import { supabaseAdmin } from "@/lib/supabase/admin";
import type { Apartment, Building, Ticket, VendorAgent } from "@/lib/types";

const MODEL = "claude-sonnet-4-5";
const MAX_AGENT_TURNS = 6;

const TOOLS: Anthropic.Tool[] = [
  {
    name: "send_email",
    description:
      "Send an official dispatch email to the vendor. Use a clear subject including the building address and fault type, and a professional body with all details the technician needs.",
    input_schema: {
      type: "object",
      properties: {
        to: { type: "string", description: "Vendor email address" },
        subject: { type: "string" },
        body: { type: "string", description: "Plain-text email body" },
      },
      required: ["to", "subject", "body"],
    },
  },
  {
    name: "send_sms",
    description: "Send a short SMS notification to the vendor phone (max ~300 chars).",
    input_schema: {
      type: "object",
      properties: {
        to: { type: "string", description: "Vendor phone in E.164 format" },
        message: { type: "string" },
      },
      required: ["to", "message"],
    },
  },
  {
    name: "send_whatsapp",
    description: "Send a WhatsApp message to the vendor phone.",
    input_schema: {
      type: "object",
      properties: {
        to: { type: "string", description: "Vendor phone in E.164 format" },
        message: { type: "string" },
      },
      required: ["to", "message"],
    },
  },
];

interface DispatchContext {
  ticket: Ticket;
  building: Building;
  apartment: Apartment | null;
  vendor: VendorAgent;
}

function buildSystemPrompt(ctx: DispatchContext): string {
  return [
    "You are the automated maintenance dispatcher for a residential building management company.",
    "Your job: notify the service vendor about an approved maintenance ticket, through the channels available to you, so a technician is scheduled as soon as possible.",
    "Rules:",
    "- Write in a professional, courteous tone. Identify yourself as the automated dispatch service acting for the building committee (Vaad).",
    `- Use ONLY these channels (the vendor's preference): ${ctx.vendor.preferred_channels.join(", ")}.`,
    "- Include: building address, fault description, location within the building, reference number, and a request to confirm a service visit time by replying.",
    "- If contract details mention SLAs or contract numbers, reference them.",
    ctx.vendor.ai_instructions ? `- Vendor-specific instructions from the Vaad: ${ctx.vendor.ai_instructions}` : "",
    "After using the messaging tools, reply with a one-paragraph summary of what was dispatched.",
  ]
    .filter(Boolean)
    .join("\n");
}

function buildUserMessage(ctx: DispatchContext): string {
  const { ticket, building, apartment, vendor } = ctx;
  return JSON.stringify(
    {
      ticket: {
        reference: ticket.id,
        title: ticket.title,
        description: ticket.description,
        reported_at: ticket.created_at,
        location: apartment
          ? `Apartment ${apartment.apartment_number}, floor ${apartment.floor}`
          : "Common area",
      },
      building: {
        name: building.name,
        address: `${building.address}, ${building.city}`,
      },
      vendor: {
        name: vendor.vendor_name,
        service_type: vendor.service_type,
        email: vendor.vendor_email,
        phone: vendor.vendor_phone,
        contract: vendor.contract_details,
      },
    },
    null,
    2,
  );
}

async function executeTool(
  name: string,
  input: Record<string, string>,
): Promise<{ ok: boolean; detail: string; channel: string }> {
  switch (name) {
    case "send_email": {
      const r = await sendEmail(input.to, input.subject, input.body);
      return { ok: r.sent, detail: r.detail, channel: "email" };
    }
    case "send_sms": {
      const r = await sendSms(input.to, input.message);
      return { ok: r.sent, detail: r.detail, channel: "sms" };
    }
    case "send_whatsapp": {
      const r = await sendWhatsApp(input.to, input.message);
      return { ok: r.sent, detail: r.detail, channel: "whatsapp" };
    }
    default:
      return { ok: false, detail: `Unknown tool ${name}`, channel: "unknown" };
  }
}

export interface DispatchOutcome {
  summary: string;
  channelsUsed: string[];
  agentLog: unknown[];
}

/**
 * Runs the Claude dispatch agent for an approved ticket:
 * tool-use loop → vendor notifications → returns transcript + summary.
 * The caller persists ticket status; this function persists timeline
 * events for each vendor contact as they happen.
 */
export async function runVendorDispatchAgent(ctx: DispatchContext): Promise<DispatchOutcome> {
  const anthropic = new Anthropic({ apiKey: env.anthropicApiKey });
  const db = supabaseAdmin();

  const agentLog: unknown[] = [];
  const channelsUsed: string[] = [];
  const messages: Anthropic.MessageParam[] = [
    { role: "user", content: `Dispatch this approved maintenance ticket to the vendor:\n${buildUserMessage(ctx)}` },
  ];

  let summary = "";

  for (let turn = 0; turn < MAX_AGENT_TURNS; turn++) {
    const response = await anthropic.messages.create({
      model: MODEL,
      max_tokens: 2048,
      system: buildSystemPrompt(ctx),
      tools: TOOLS,
      messages,
    });

    agentLog.push({ at: new Date().toISOString(), role: "assistant", content: response.content });

    const textParts = response.content.filter((b) => b.type === "text");
    if (textParts.length > 0) {
      summary = textParts.map((b) => b.text).join("\n");
    }

    if (response.stop_reason !== "tool_use") break;

    const toolResults: Anthropic.ToolResultBlockParam[] = [];
    for (const block of response.content) {
      if (block.type !== "tool_use") continue;
      const result = await executeTool(block.name, block.input as Record<string, string>);
      channelsUsed.push(result.channel);
      agentLog.push({ at: new Date().toISOString(), role: "tool", tool: block.name, result });

      // "Agent Contacted Vendor [timestamp]" timeline entry, per contact
      await db.from("ticket_events").insert({
        ticket_id: ctx.ticket.id,
        building_id: ctx.ticket.building_id,
        label: "Agent Contacted Vendor",
        detail: `${ctx.vendor.vendor_name} via ${result.channel} — ${result.detail}`,
      });

      toolResults.push({
        type: "tool_result",
        tool_use_id: block.id,
        content: result.ok ? `Delivered: ${result.detail}` : `Not delivered: ${result.detail}`,
        is_error: !result.ok,
      });
    }

    messages.push({ role: "assistant", content: response.content });
    messages.push({ role: "user", content: toolResults });
  }

  return { summary, channelsUsed, agentLog };
}

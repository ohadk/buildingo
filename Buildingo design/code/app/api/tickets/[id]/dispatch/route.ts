// POST /api/tickets/[id]/dispatch
// Runs after the Vaad approves a ticket (status = 'approved').
// Claude drafts the vendor dispatch, SendGrid/Twilio delivers it, Supabase records the state
// that the tenant timeline subscribes to (agent_status = 'communicating').

import { NextResponse } from 'next/server';
import Anthropic from '@anthropic-ai/sdk';
import { createClient } from '@supabase/supabase-js';
import sgMail from '@sendgrid/mail';
import twilio from 'twilio';

const anthropic = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY! });
const supabase = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY! // server-only: bypasses RLS for the agent write
);
sgMail.setApiKey(process.env.SENDGRID_API_KEY!);
const sms = twilio(process.env.TWILIO_ACCOUNT_SID!, process.env.TWILIO_AUTH_TOKEN!);

const DISPATCH_TOOL = {
  name: 'dispatch_vendor',
  description: 'Send an official maintenance dispatch to the building vendor.',
  input_schema: {
    type: 'object' as const,
    properties: {
      channel: { type: 'string', enum: ['email', 'sms'], description: 'Use sms only for urgent, safety-related faults.' },
      subject: { type: 'string', description: 'Email subject line. Omit for sms.' },
      body: { type: 'string', description: 'Message body in the vendor contract language, signed by the building committee.' },
      urgency: { type: 'string', enum: ['routine', 'urgent', 'emergency'] },
      requires_quote: { type: 'boolean', description: 'True when the contract does not already cover this work.' },
    },
    required: ['channel', 'body', 'urgency', 'requires_quote'],
  },
};

export async function POST(_req: Request, { params }: { params: { id: string } }) {
  // 1 — load the ticket with its building and contracted vendor
  const { data: ticket, error } = await supabase
    .from('tickets')
    .select(
      `id, title, description, category, status, agent_status, apartment,
       building:buildings ( id, name, address, committee_name, committee_phone ),
       vendor:vendors ( id, name, company, email, phone, contract_scope, sla_hours, language )`
    )
    .eq('id', params.id)
    .single();

  if (error || !ticket) return NextResponse.json({ error: 'ticket_not_found' }, { status: 404 });
  if (ticket.status !== 'approved')
    return NextResponse.json({ error: 'ticket_not_approved' }, { status: 409 });
  if (ticket.agent_status === 'communicating')
    return NextResponse.json({ ok: true, note: 'already_dispatched' }); // idempotent retry

  const { building, vendor } = ticket as any;
  if (!vendor) return NextResponse.json({ error: 'no_vendor_on_contract' }, { status: 422 });

  // 2 — Claude analyses the fault and drafts the dispatch as a tool call
  const message = await anthropic.messages.create({
    model: 'claude-sonnet-4-5',
    max_tokens: 1200,
    system:
      `You are the maintenance dispatch agent for the building committee (Vaad HaBayit) of ` +
      `${building.name}, ${building.address}. You write to contracted vendors on the committee's behalf. ` +
      `Be brief, factual and polite. Reference the contract scope; never agree to costs or dates yourself — ` +
      `ask the vendor to propose them. Write in ${vendor.language ?? 'Hebrew'}. ` +
      `Sign as "${building.committee_name}". Always call the dispatch_vendor tool exactly once.`,
    tools: [DISPATCH_TOOL],
    tool_choice: { type: 'tool', name: 'dispatch_vendor' },
    messages: [
      {
        role: 'user',
        content:
          `Fault report\n` +
          `Category: ${ticket.category}\n` +
          `Apartment: ${ticket.apartment ?? 'common area'}\n` +
          `Title: ${ticket.title}\n` +
          `Description: ${ticket.description}\n\n` +
          `Vendor: ${vendor.company} (${vendor.name})\n` +
          `Contract scope: ${vendor.contract_scope}\n` +
          `Response SLA: ${vendor.sla_hours}h\n` +
          `Committee contact for scheduling: ${building.committee_phone}`,
      },
    ],
  });

  const call = message.content.find((c) => c.type === 'tool_use');
  if (!call) return NextResponse.json({ error: 'agent_no_dispatch' }, { status: 502 });
  const dispatch = call.input as {
    channel: 'email' | 'sms';
    subject?: string;
    body: string;
    urgency: string;
    requires_quote: boolean;
  };

  // 3 — deliver it
  try {
    if (dispatch.channel === 'sms') {
      await sms.messages.create({
        from: process.env.TWILIO_FROM!,
        to: vendor.phone,
        body: dispatch.body,
      });
    } else {
      await sgMail.send({
        to: vendor.email,
        from: { email: process.env.DISPATCH_FROM_EMAIL!, name: building.committee_name },
        replyTo: process.env.DISPATCH_REPLY_TO!,
        subject: dispatch.subject ?? `${building.name} — ${ticket.title}`,
        text: dispatch.body,
      });
    }
  } catch (e) {
    await supabase.from('tickets').update({ agent_status: 'dispatch_failed' }).eq('id', ticket.id);
    await supabase.from('platform_errors').insert({
      building_id: building.id,
      source: 'vendor_dispatch',
      message: e instanceof Error ? e.message : 'unknown delivery failure',
    });
    return NextResponse.json({ error: 'delivery_failed' }, { status: 502 });
  }

  // 4 — record it; the tenant timeline is subscribed to this row
  await supabase
    .from('tickets')
    .update({
      agent_status: 'communicating',
      vendor_name: vendor.company,
      dispatched_at: new Date().toISOString(),
      requires_quote: dispatch.requires_quote,
      urgency: dispatch.urgency,
    })
    .eq('id', ticket.id);

  await supabase.from('ticket_events').insert({
    ticket_id: ticket.id,
    actor: 'claude_agent',
    label: `Claude AI contacted ${vendor.company}`,
    payload: dispatch,
  });

  return NextResponse.json({ ok: true, channel: dispatch.channel, urgency: dispatch.urgency });
}

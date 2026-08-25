// Habait Connect — Tenant Home (mobile-first)
// Warm Home theme: terracotta #A34A3A · sage #4F6D4F · gold #D9B382 · linen #FAF3E0
// Live ticket timeline via Supabase realtime on `tickets`.

'use client';

import { useEffect, useState } from 'react';
import { Bell, Wrench, CreditCard, Megaphone, Home, Users, Folder, Plus, Check } from 'lucide-react';
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
);

type AgentStatus = 'open' | 'approved' | 'communicating' | 'scheduled' | 'resolved';

type Ticket = {
  id: string;
  title: string;
  vendor_name: string | null;
  status: 'open' | 'approved' | 'resolved';
  agent_status: AgentStatus;
};

type Post = { id: string; kind: string; title: string; published_at: string };

const STEPS: { key: AgentStatus; label: string }[] = [
  { key: 'open', label: 'Reported' },
  { key: 'approved', label: 'Approved by Vaad' },
  { key: 'communicating', label: 'Claude AI Dispatching' },
  { key: 'resolved', label: 'Resolved' },
];

const stepIndex = (s: AgentStatus) =>
  s === 'resolved' ? 3 : s === 'communicating' || s === 'scheduled' ? 2 : s === 'approved' ? 1 : 0;

export default function TenantHome({
  resident,
  ticket: initialTicket,
  posts,
  balance,
}: {
  resident: { name: string; apartment: string; floor: number };
  ticket: Ticket | null;
  posts: Post[];
  balance: number;
}) {
  const [ticket, setTicket] = useState(initialTicket);
  const [tab, setTab] = useState('home');

  // Step 5 of the dispatch flow surfaces here: the backend writes agent_status,
  // this subscription moves the timeline without a refresh.
  useEffect(() => {
    if (!ticket) return;
    const channel = supabase
      .channel(`ticket:${ticket.id}`)
      .on(
        'postgres_changes',
        { event: 'UPDATE', schema: 'public', table: 'tickets', filter: `id=eq.${ticket.id}` },
        ({ new: row }) => setTicket(row as Ticket)
      )
      .subscribe();
    return () => void supabase.removeChannel(channel);
  }, [ticket?.id]);

  const active = ticket ? stepIndex(ticket.agent_status) : 0;

  return (
    <div className="relative mx-auto flex min-h-screen w-full max-w-[430px] flex-col bg-[#FAF3E0] font-sans text-[#241C18]">
      {/* Header */}
      <header className="bg-gradient-to-b from-[#E8B9AC] to-[#F3D9D1] px-5 pb-6 pt-14">
        <div className="flex items-start justify-between gap-3">
          <div>
            <h1 className="text-2xl font-bold leading-tight text-[#431C15]">Hello, {resident.name}!</h1>
            <p className="mt-1 text-sm text-[#5F281E]">
              Apt {resident.apartment}, Floor {resident.floor}
            </p>
          </div>
          <button
            aria-label="Notifications"
            className="relative grid h-11 w-11 place-items-center rounded-full bg-[#FFFBF2]/60 transition active:scale-95"
          >
            <Bell strokeWidth={2.75} className="h-5 w-5 text-[#7A3427]" />
            <span className="absolute right-2.5 top-2 h-2.5 w-2.5 rounded-full border-2 border-[#F3D9D1] bg-[#A34A3A]" />
          </button>
        </div>

        {/* Quick actions */}
        <h2 className="mb-3 mt-6 text-base font-semibold text-[#431C15]">Quick Actions</h2>
        <div className="flex gap-2.5">
          {[
            { icon: Wrench, label: 'Report Fault', go: () => setTab('maintenance') },
            { icon: CreditCard, label: 'Pay Dues', go: () => setTab('payments') },
            { icon: Megaphone, label: 'Announcements', go: () => setTab('home') },
          ].map(({ icon: Icon, label, go }) => (
            <button
              key={label}
              onClick={go}
              className="flex flex-1 flex-col items-center gap-2 rounded-2xl bg-[#FFFBF2] px-2 py-4 shadow-sm transition active:scale-95"
            >
              <Icon strokeWidth={2.75} className="h-6 w-6 text-[#D9B382]" />
              <span className="text-xs font-semibold text-[#354A35]">{label}</span>
            </button>
          ))}
        </div>
      </header>

      <main className="flex-1 space-y-6 px-4 pb-32 pt-5">
        {/* My Tickets */}
        {ticket && (
          <section>
            <h2 className="mb-2.5 text-base font-semibold">My Tickets</h2>
            <article className="rounded-2xl bg-[#4F6D4F] p-4 text-white">
              <div className="mb-4 flex items-center gap-2.5">
                <span className="h-2 w-2 rounded-full bg-[#D9B382]" />
                <h3 className="flex-1 font-semibold">{ticket.title}</h3>
                <span className="text-[11px] text-white/60">#{ticket.id.slice(0, 4)}</span>
              </div>

              <ol className="flex items-start">
                {STEPS.map((step, i) => {
                  const done = i < active;
                  const current = i === active;
                  return (
                    <li key={step.key} className="flex min-w-0 flex-1 items-start">
                      <div className="flex w-12 flex-none flex-col items-center gap-1.5">
                        <span
                          className={[
                            'grid h-7 w-7 place-items-center rounded-full transition-colors',
                            done ? 'bg-[#6B8A6B]' : current ? 'bg-[#A34A3A] animate-pulse' : 'bg-white/25',
                          ].join(' ')}
                        >
                          {done && <Check strokeWidth={3} className="h-3.5 w-3.5" />}
                        </span>
                        <span
                          className={`text-center text-[10px] leading-tight ${
                            done || current ? 'text-white' : 'text-white/50'
                          }`}
                        >
                          {step.label}
                        </span>
                      </div>
                      {i < STEPS.length - 1 && (
                        <span className={`mt-3.5 h-0.5 flex-1 rounded-full ${done ? 'bg-[#8FA98D]' : 'bg-white/20'}`} />
                      )}
                    </li>
                  );
                })}
              </ol>

              {ticket.agent_status === 'communicating' && ticket.vendor_name && (
                <p className="mt-4 border-t border-white/15 pt-3 text-xs text-white/80">
                  Claude AI is contacting {ticket.vendor_name}
                </p>
              )}
            </article>
          </section>
        )}

        {/* Balance */}
        <button
          onClick={() => setTab('payments')}
          className="flex w-full items-center gap-4 rounded-2xl bg-[#FFFBF2] p-4 text-right shadow-sm transition active:scale-[0.99]"
        >
          <span className="flex-1 text-left">
            <span className="block text-[11px] text-[#7F7360]">Balance due</span>
            <span className="block text-2xl font-bold text-[#7A3427]">₪{balance}</span>
          </span>
          <span className="rounded-full bg-[#A34A3A] px-5 py-2.5 text-sm font-semibold text-white">Pay</span>
        </button>

        {/* Community board */}
        <section>
          <h2 className="mb-2.5 text-base font-semibold">Community Board</h2>
          <ul className="space-y-2.5">
            {posts.slice(0, 2).map((p) => (
              <li key={p.id} className="rounded-2xl bg-[#FFFBF2] p-4 shadow-sm">
                <span className="rounded-full bg-[#F2E2C6] px-2.5 py-1 text-[10px] font-semibold text-[#6E5433]">
                  {p.kind}
                </span>
                <p className="mt-2 font-semibold leading-snug">{p.title}</p>
              </li>
            ))}
          </ul>
        </section>
      </main>

      {/* FAB */}
      <button className="fixed bottom-[86px] left-1/2 z-50 flex -translate-x-1/2 items-center gap-2 rounded-full bg-[#A34A3A] px-6 py-3.5 font-semibold text-white shadow-lg transition active:scale-95">
        <Plus strokeWidth={3} className="h-4 w-4" /> New Report
      </button>

      {/* Bottom nav */}
      <nav className="fixed bottom-0 left-1/2 z-40 flex w-full max-w-[430px] -translate-x-1/2 border-t border-white/10 bg-[#354A35] px-1.5 pb-6 pt-2.5">
        {[
          { key: 'home', label: 'Home', icon: Home },
          { key: 'payments', label: 'Payments', icon: CreditCard },
          { key: 'maintenance', label: 'Maintenance', icon: Wrench },
          { key: 'directory', label: 'Directory', icon: Users },
          { key: 'docs', label: 'Docs', icon: Folder },
        ].map(({ key, label, icon: Icon }) => (
          <button
            key={key}
            onClick={() => setTab(key)}
            className={`flex flex-1 flex-col items-center gap-1.5 py-1 ${
              tab === key ? 'text-white' : 'text-white/55'
            }`}
          >
            <Icon strokeWidth={2.75} className="h-5 w-5" />
            <span className="text-[10px]">{label}</span>
          </button>
        ))}
      </nav>
    </div>
  );
}

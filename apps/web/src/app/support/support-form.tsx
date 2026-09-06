"use client";

import { FormEvent, useState } from "react";
import { Button } from "@/components/ui/button";
import { Input, Label } from "@/components/ui/input";

export function SupportForm() {
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [phone, setPhone] = useState("");
  const [message, setMessage] = useState("");
  const [status, setStatus] = useState<"idle" | "sending" | "ok" | "error">("idle");
  const [error, setError] = useState<string | null>(null);

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    setStatus("sending");
    setError(null);
    try {
      const res = await fetch("/api/support", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          name,
          email,
          phone: phone.trim() || undefined,
          message,
        }),
      });
      if (!res.ok) {
        const data = (await res.json().catch(() => null)) as { error?: string } | null;
        throw new Error(data?.error || "שליחה נכשלה. נסו שוב.");
      }
      setStatus("ok");
      setName("");
      setEmail("");
      setPhone("");
      setMessage("");
    } catch (err) {
      setStatus("error");
      setError(err instanceof Error ? err.message : "שליחה נכשלה.");
    }
  }

  if (status === "ok") {
    return (
      <div className="rounded-2xl border border-sage-300 bg-sage-100 px-6 py-8 text-center">
        <p className="text-lg font-semibold text-ink-900">תודה, קיבלנו את הפנייה</p>
        <p className="mt-2 text-sm text-ink-600">נחזור אליכם בהקדם האפשרי.</p>
        <Button className="mt-6" variant="outline" onClick={() => setStatus("idle")}>
          שליחת פנייה נוספת
        </Button>
      </div>
    );
  }

  return (
    <form onSubmit={onSubmit} className="space-y-5">
      <div className="space-y-2">
        <Label htmlFor="support-name">שם מלא</Label>
        <Input
          id="support-name"
          name="name"
          autoComplete="name"
          required
          value={name}
          onChange={(e) => setName(e.target.value)}
          placeholder="ישראל ישראלי"
        />
      </div>
      <div className="space-y-2">
        <Label htmlFor="support-email">אימייל</Label>
        <Input
          id="support-email"
          name="email"
          type="email"
          autoComplete="email"
          required
          dir="ltr"
          className="text-left"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          placeholder="you@example.com"
        />
      </div>
      <div className="space-y-2">
        <Label htmlFor="support-phone">טלפון (אופציונלי)</Label>
        <Input
          id="support-phone"
          name="phone"
          type="tel"
          autoComplete="tel"
          dir="ltr"
          className="text-left"
          value={phone}
          onChange={(e) => setPhone(e.target.value)}
          placeholder="+972…"
        />
      </div>
      <div className="space-y-2">
        <Label htmlFor="support-message">איך אפשר לעזור?</Label>
        <textarea
          id="support-message"
          name="message"
          required
          minLength={5}
          rows={5}
          value={message}
          onChange={(e) => setMessage(e.target.value)}
          placeholder="תארו את הבעיה או את השאלה…"
          className="w-full rounded-2xl border border-cream-300 bg-cream-200 px-4 py-3 text-sm text-ink-900 placeholder:text-ink-400 hover:border-ink-400 focus-visible:border-brick-500 focus-visible:outline-2 focus-visible:outline-brick-500"
        />
      </div>
      {error ? <p className="text-sm text-brick-700">{error}</p> : null}
      <Button type="submit" size="lg" disabled={status === "sending"} className="w-full sm:w-auto">
        {status === "sending" ? "שולח…" : "שליחת פנייה"}
      </Button>
    </form>
  );
}

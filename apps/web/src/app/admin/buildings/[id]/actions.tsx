"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { Button } from "@/components/ui/button";
import { Modal } from "@/components/ui/dialog";

export function ToggleBuildingAccessButton({
  buildingId,
  buildingName,
  isActive,
}: {
  buildingId: string;
  buildingName: string;
  isActive: boolean;
}) {
  const router = useRouter();
  const [open, setOpen] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function toggle() {
    setBusy(true);
    setError(null);
    const res = await fetch(`/api/buildings/${buildingId}`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ isActive: !isActive }),
    });
    setBusy(false);
    if (!res.ok) {
      const data = await res.json();
      setError(data.error ?? "הפעולה נכשלה");
      return;
    }
    setOpen(false);
    router.refresh();
  }

  return (
    <>
      <Button
        variant={isActive ? "secondary" : "default"}
        size="sm"
        className={isActive ? "border-brick-600 text-brick-600" : ""}
        onClick={() => setOpen(true)}
      >
        {isActive ? "השבתת גישה לבניין" : "הפעלת הבניין מחדש"}
      </Button>
      <Modal
        open={open}
        onClose={() => setOpen(false)}
        title={isActive ? "השבתת גישה לבניין" : "הפעלת הבניין מחדש"}
      >
        <div className="space-y-4">
          <p className="text-sm leading-relaxed text-ink-600">
            {isActive ? (
              <>
                כל הדיירים וחברי הוועד של <b>{buildingName}</b> יאבדו גישה לאפליקציה עד
                שהבניין יופעל מחדש. משתמשים מחוברים ינותקו בבקשה הבאה שלהם.
              </>
            ) : (
              <>
                הגישה של כל הדיירים וחברי הוועד של <b>{buildingName}</b> תשוחזר באופן מיידי.
              </>
            )}
          </p>
          <div className="flex gap-2">
            <Button onClick={toggle} disabled={busy} className="flex-1">
              {busy ? "מבצע…" : isActive ? "אישור השבתה" : "אישור הפעלה"}
            </Button>
            <Button variant="secondary" onClick={() => setOpen(false)} className="flex-1">
              ביטול
            </Button>
          </div>
          {error && <p className="text-sm text-brick-600">{error}</p>}
        </div>
      </Modal>
    </>
  );
}

/**
 * Subscription controls: activate (paid), block, or extend the trial by
 * 14 days. Self-created buildings start on a 14-day trial and lose data
 * access when it expires.
 */
export function SubscriptionControls({
  buildingId,
  planStatus,
  trialEndsAt,
}: {
  buildingId: string;
  planStatus: "trial" | "active" | "blocked";
  trialEndsAt: string;
}) {
  const router = useRouter();
  const [busy, setBusy] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  async function update(body: Record<string, unknown>, key: string) {
    setBusy(key);
    setError(null);
    const res = await fetch(`/api/buildings/${buildingId}`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
    });
    setBusy(null);
    if (!res.ok) {
      const data = await res.json();
      setError(data.error ?? "הפעולה נכשלה");
      return;
    }
    router.refresh();
  }

  const daysLeft = Math.ceil(
    (new Date(trialEndsAt).getTime() - Date.now()) / 86_400_000,
  );

  return (
    <div className="flex flex-wrap items-center gap-2">
      {planStatus !== "active" && (
        <Button
          size="sm"
          disabled={busy != null}
          onClick={() => update({ planStatus: "active" }, "activate")}
        >
          {busy === "activate" ? "מבצע…" : "הפעלת מנוי (שולם)"}
        </Button>
      )}
      {planStatus !== "blocked" && (
        <Button
          size="sm"
          variant="secondary"
          className="border-brick-600 text-brick-600"
          disabled={busy != null}
          onClick={() => {
            if (window.confirm("לחסום את הבניין? כל המשתמשים יאבדו גישה מיידית.")) {
              update({ planStatus: "blocked" }, "block");
            }
          }}
        >
          {busy === "block" ? "מבצע…" : "חסימת גישה"}
        </Button>
      )}
      {planStatus !== "active" && (
        <Button
          size="sm"
          variant="secondary"
          disabled={busy != null}
          onClick={() => update({ extendTrialDays: 14 }, "extend")}
        >
          {busy === "extend"
            ? "מבצע…"
            : daysLeft > 0
              ? "הארכת ניסיון ב־14 יום"
              : "חידוש ניסיון ל־14 יום"}
        </Button>
      )}
      {error && <p className="w-full text-sm text-brick-600">{error}</p>}
    </div>
  );
}

export function ToggleUserAccessButton({
  userId,
  userName,
  accountStatus,
}: {
  userId: string;
  userName: string;
  accountStatus: "active" | "suspended" | "deleted";
}) {
  const router = useRouter();
  const [busy, setBusy] = useState(false);
  const isActive = accountStatus === "active";

  async function toggle() {
    if (accountStatus === "deleted") return;
    if (isActive) {
      const reason = window.prompt(
        `להשעות את ${userName}?\nהמשתמש יוכל להתחבר אבל יראה מסך חסימה.\nסיבה (תוצג למשתמש):`,
        "החשבון הושעה על ידי מנהל המערכת",
      );
      if (reason == null) return;
      setBusy(true);
      const res = await fetch(`/api/users/${userId}`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          accountStatus: "suspended",
          reason: reason.trim() || "החשבון הושעה על ידי מנהל המערכת",
        }),
      });
      setBusy(false);
      if (!res.ok) {
        const data = await res.json();
        window.alert(data.error ?? "הפעולה נכשלה");
        return;
      }
      router.refresh();
      return;
    }

    if (!window.confirm(`להפעיל מחדש את ${userName}?`)) return;
    setBusy(true);
    const res = await fetch(`/api/users/${userId}`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        accountStatus: "active",
        reason: "Reactivated by super admin",
      }),
    });
    setBusy(false);
    if (!res.ok) {
      const data = await res.json();
      window.alert(data.error ?? "הפעולה נכשלה");
      return;
    }
    router.refresh();
  }

  if (accountStatus === "deleted") {
    return <span className="text-xs text-ink-400">—</span>;
  }

  return (
    <button
      onClick={toggle}
      disabled={busy}
      className={
        isActive
          ? "rounded-lg border border-brick-600 px-3 py-1 text-xs font-medium text-brick-600 hover:bg-terracotta-100"
          : "rounded-lg border border-sage-500 px-3 py-1 text-xs font-medium text-sage-700 hover:bg-sage-100"
      }
    >
      {busy ? "…" : isActive ? "השעיה" : "הפעלה"}
    </button>
  );
}

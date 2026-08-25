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

export function ToggleUserAccessButton({
  userId,
  userName,
  isActive,
}: {
  userId: string;
  userName: string;
  isActive: boolean;
}) {
  const router = useRouter();
  const [busy, setBusy] = useState(false);

  async function toggle() {
    if (
      isActive &&
      !window.confirm(`להשבית את הגישה של ${userName}? הם לא יוכלו להתחבר עד להפעלה מחדש.`)
    ) {
      return;
    }
    setBusy(true);
    const res = await fetch(`/api/users/${userId}`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ isActive: !isActive }),
    });
    setBusy(false);
    if (!res.ok) {
      const data = await res.json();
      window.alert(data.error ?? "הפעולה נכשלה");
      return;
    }
    router.refresh();
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
      {busy ? "…" : isActive ? "השבתה" : "הפעלה"}
    </button>
  );
}

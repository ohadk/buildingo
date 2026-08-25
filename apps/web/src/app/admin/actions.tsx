"use client";

import { useRef, useState } from "react";
import { useRouter } from "next/navigation";
import { Button } from "@/components/ui/button";
import { Input, Label } from "@/components/ui/input";
import { Modal } from "@/components/ui/dialog";
import { Select } from "@/components/ui/select";
import { PhoneInput } from "@/components/ui/phone-input";
import { SuccessModal } from "@/components/ui/success-modal";
import { formatPhoneDisplay } from "@/lib/format";

export function AddBuildingButton() {
  const router = useRouter();
  const [open, setOpen] = useState(false);
  const [form, setForm] = useState({
    address: "",
    city: "",
    country: "ישראל",
    postalCode: "",
    apartmentCount: 8,
    apartmentsPerFloor: 2,
    feeMethod: "fixed" as "fixed" | "per_sqm",
    fixedMonthlyFee: 250,
    pricePerSqm: 4,
  });
  const [busy, setBusy] = useState(false);
  const [message, setMessage] = useState<string | null>(null);
  const [cityOptions, setCityOptions] = useState<string[]>([]);
  const [streetOptions, setStreetOptions] = useState<string[]>([]);
  const cityTimer = useRef<ReturnType<typeof setTimeout> | undefined>(undefined);
  const streetTimer = useRef<ReturnType<typeof setTimeout> | undefined>(undefined);

  function onCityChange(value: string) {
    setForm((f) => ({ ...f, city: value }));
    clearTimeout(cityTimer.current);
    if (value.trim().length < 2) {
      setCityOptions([]);
      return;
    }
    cityTimer.current = setTimeout(async () => {
      try {
        const res = await fetch(`/api/geo/cities?q=${encodeURIComponent(value.trim())}`);
        const data = await res.json();
        setCityOptions(data.cities ?? []);
      } catch {
        /* suggestions are best-effort */
      }
    }, 300);
  }

  function onAddressChange(value: string) {
    setForm((f) => ({ ...f, address: value }));
    clearTimeout(streetTimer.current);
    // Autocomplete on the street part only (strip a trailing house number).
    const streetPart = value.replace(/\s*\d+\s*$/, "").trim();
    if (streetPart.length < 2) {
      setStreetOptions([]);
      return;
    }
    streetTimer.current = setTimeout(async () => {
      try {
        const params = new URLSearchParams({ q: streetPart });
        if (form.city.trim()) params.set("city", form.city.trim());
        const res = await fetch(`/api/geo/streets?${params}`);
        const data = await res.json();
        setStreetOptions(data.streets ?? []);
      } catch {
        /* suggestions are best-effort */
      }
    }, 300);
  }

  const autoName =
    form.address.trim() && form.city.trim() ? `${form.address.trim()}, ${form.city.trim()}` : null;

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setBusy(true);
    setMessage(null);
    const res = await fetch("/api/buildings", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        address: form.address.trim(),
        city: form.city.trim(),
        country: form.country.trim(),
        postalCode: form.postalCode.trim() || undefined,
        apartmentCount: form.apartmentCount,
        apartmentsPerFloor: form.apartmentsPerFloor,
        feeMethod: form.feeMethod,
        fixedMonthlyFee: form.feeMethod === "fixed" ? form.fixedMonthlyFee : undefined,
        pricePerSqm: form.feeMethod === "per_sqm" ? form.pricePerSqm : undefined,
      }),
    });
    const data = await res.json();
    setBusy(false);
    if (!res.ok) {
      setMessage(data.error ?? "יצירת הבניין נכשלה");
      return;
    }
    setOpen(false);
    setForm({
      address: "",
      city: "",
      country: "ישראל",
      postalCode: "",
      apartmentCount: 8,
      apartmentsPerFloor: 2,
      feeMethod: "fixed",
      fixedMonthlyFee: 250,
      pricePerSqm: 4,
    });
    router.refresh();
  }

  return (
    <>
      <Button onClick={() => setOpen(true)}>+ הוספת בניין</Button>
      <Modal open={open} onClose={() => setOpen(false)} title="הוספת בניין חדש">
        <form onSubmit={submit} className="space-y-3">
          <div className="grid grid-cols-2 gap-3">
            <div className="space-y-1">
              <Label>עיר</Label>
              <Input
                required
                placeholder="תל אביב"
                list="city-suggestions"
                value={form.city}
                onChange={(e) => onCityChange(e.target.value)}
              />
              <datalist id="city-suggestions">
                {cityOptions.map((c) => (
                  <option key={c} value={c} />
                ))}
              </datalist>
            </div>
            <div className="space-y-1">
              <Label>כתובת (רחוב ומספר)</Label>
              <Input
                required
                placeholder="הרצל 12"
                list="street-suggestions"
                value={form.address}
                onChange={(e) => onAddressChange(e.target.value)}
              />
              <datalist id="street-suggestions">
                {streetOptions.map((s) => (
                  <option key={s} value={s} />
                ))}
              </datalist>
            </div>
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div className="space-y-1">
              <Label>מדינה</Label>
              <Input
                required
                value={form.country}
                onChange={(e) => setForm({ ...form, country: e.target.value })}
              />
            </div>
            <div className="space-y-1">
              <Label>מיקוד</Label>
              <Input
                dir="ltr"
                value={form.postalCode}
                onChange={(e) => setForm({ ...form, postalCode: e.target.value })}
              />
            </div>
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div className="space-y-1">
              <Label>מספר דירות</Label>
              <Input
                type="number"
                min={1}
                value={form.apartmentCount}
                onChange={(e) => setForm({ ...form, apartmentCount: Number(e.target.value) })}
              />
            </div>
            <div className="space-y-1">
              <Label>דירות בקומה</Label>
              <Input
                type="number"
                min={1}
                value={form.apartmentsPerFloor}
                onChange={(e) => setForm({ ...form, apartmentsPerFloor: Number(e.target.value) })}
              />
            </div>
          </div>

          <div className="space-y-2 rounded-lg bg-sage-100 p-3">
            <Label>שיטת חיוב דמי ועד</Label>
            <div className="flex gap-4">
              <label className="flex items-center gap-2 text-sm">
                <input
                  type="radio"
                  name="feeMethod"
                  checked={form.feeMethod === "fixed"}
                  onChange={() => setForm({ ...form, feeMethod: "fixed" })}
                />
                סכום קבוע לדירה
              </label>
              <label className="flex items-center gap-2 text-sm">
                <input
                  type="radio"
                  name="feeMethod"
                  checked={form.feeMethod === "per_sqm"}
                  onChange={() => setForm({ ...form, feeMethod: "per_sqm" })}
                />
                לפי גודל הדירה (למ״ר)
              </label>
            </div>
            {form.feeMethod === "fixed" ? (
              <div className="space-y-1">
                <Label>סכום חודשי לדירה (₪)</Label>
                <Input
                  type="number"
                  min={0}
                  required
                  value={form.fixedMonthlyFee}
                  onChange={(e) => setForm({ ...form, fixedMonthlyFee: Number(e.target.value) })}
                />
              </div>
            ) : (
              <div className="space-y-1">
                <Label>מחיר למ״ר (₪)</Label>
                <Input
                  type="number"
                  min={0}
                  step="0.1"
                  required
                  value={form.pricePerSqm}
                  onChange={(e) => setForm({ ...form, pricePerSqm: Number(e.target.value) })}
                />
                <p className="text-xs text-ink-400">
                  החיוב לכל דירה יחושב לפי שטח הדירה × המחיר למ״ר. שטחי הדירות
                  מוזנים על ידי הוועד באפליקציה.
                </p>
              </div>
            )}
          </div>

          {autoName && (
            <p className="text-sm text-ink-600">
              שם הבניין ייקבע אוטומטית: <span className="font-bold">{autoName}</span>
            </p>
          )}

          <Button type="submit" disabled={busy} className="w-full">
            {busy ? "יוצר…" : "יצירת הבניין"}
          </Button>
          {message && <p className="text-sm text-brick-600">{message}</p>}
        </form>
      </Modal>
    </>
  );
}

interface BuildingOption {
  id: string;
  name: string;
  apartments: { id: string; apartment_number: number; floor: number }[];
}

function PhoneText({ e164 }: { e164: string }) {
  return (
    <bdi dir="ltr" className="font-semibold text-ink-900">
      {formatPhoneDisplay(e164)}
    </bdi>
  );
}

export function AssignVaadButton({ building }: { building: BuildingOption }) {
  const router = useRouter();
  const [open, setOpen] = useState(false);
  const [apartmentId, setApartmentId] = useState("");
  const [phone, setPhone] = useState("");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<{
    message: React.ReactNode;
    code?: string;
    whatsappUrl?: string;
  } | null>(null);

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setBusy(true);
    setError(null);
    const res = await fetch("/api/invitations", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        buildingId: building.id,
        apartmentId,
        phoneNumber: phone,
        role: "vaad",
      }),
    });
    const data = await res.json();
    setBusy(false);
    if (!res.ok) {
      setError(data.error ?? "שליחת ההזמנה נכשלה");
      return;
    }
    setOpen(false);
    setApartmentId("");

    const code: string = data.invitation.invite_code;
    const waText =
      `הוזמנת להצטרף כחבר ועד בבניין ${building.name} באפליקציית Dira.\n` +
      `היכנסו לאפליקציה עם מספר הטלפון שלכם והגישה תוענק אוטומטית: https://dira.app\n` +
      `קוד הצטרפות ידני: ${code}`;
    const whatsappUrl = `https://wa.me/${phone.replace(/\D/g, "")}?text=${encodeURIComponent(waText)}`;

    setSuccess(
      data.assignedImmediately
        ? {
            message: (
              <>
                <PhoneText e164={phone} /> כבר רשום במערכת — הוא שויך כוועד וקיבל גישה לבניין
                באופן מיידי.
              </>
            ),
          }
        : data.smsDelivery?.sent
          ? {
              message: (
                <>
                  הזמנה נשלחה ב-SMS אל <PhoneText e164={phone} />. בכניסה הראשונה עם המספר הזה —
                  הגישה לבניין תוענק אוטומטית.
                </>
              ),
              whatsappUrl,
            }
          : {
              message: (
                <>
                  ההזמנה נוצרה. בכניסה הראשונה של <PhoneText e164={phone} /> לאפליקציה — הגישה
                  תוענק אוטומטית.
                </>
              ),
              code,
              whatsappUrl,
            },
    );
    router.refresh();
  }

  return (
    <>
      <Button variant="secondary" size="sm" onClick={() => setOpen(true)}>
        שיוך ועד
      </Button>
      <Modal
        open={open}
        onClose={() => setOpen(false)}
        title={`שיוך חבר ועד — ${building.name}`}
      >
        <form onSubmit={submit} className="space-y-3">
          <div className="space-y-1">
            <Label>הדירה של חבר הוועד</Label>
            <Select
              required
              placeholder="בחירת דירה…"
              value={apartmentId}
              onChange={setApartmentId}
              options={building.apartments
                .slice()
                .sort((a, b) => a.apartment_number - b.apartment_number)
                .map((a) => ({
                  value: a.id,
                  label: `דירה ${a.apartment_number} (קומה ${a.floor})`,
                }))}
            />
          </div>
          <div className="space-y-1">
            <Label>מספר טלפון</Label>
            <PhoneInput required onChange={setPhone} />
          </div>
          <Button type="submit" variant="secondary" disabled={busy} className="w-full">
            {busy ? (
              <span className="flex items-center justify-center gap-2">
                <svg className="h-4 w-4 animate-spin" viewBox="0 0 24 24" fill="none">
                  <circle
                    cx="12"
                    cy="12"
                    r="10"
                    stroke="currentColor"
                    strokeWidth="3"
                    strokeOpacity="0.25"
                  />
                  <path
                    d="M22 12a10 10 0 0 0-10-10"
                    stroke="currentColor"
                    strokeWidth="3"
                    strokeLinecap="round"
                  />
                </svg>
                שולח…
              </span>
            ) : (
              "שליחת הזמנת ועד"
            )}
          </Button>
          {error && <p className="text-sm text-brick-600">{error}</p>}
        </form>
      </Modal>
      <SuccessModal
        open={Boolean(success)}
        onClose={() => setSuccess(null)}
        title="ההזמנה נשלחה!"
        message={success?.message}
        code={success?.code}
        whatsappUrl={success?.whatsappUrl}
      />
    </>
  );
}

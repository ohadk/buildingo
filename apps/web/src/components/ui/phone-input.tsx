"use client";

import * as React from "react";
import { Input } from "@/components/ui/input";
import { Select } from "@/components/ui/select";

interface Country {
  iso: string;
  dial: string;
  name: string;
}

const COUNTRIES: Country[] = [
  { iso: "IL", dial: "972", name: "ישראל" },
  { iso: "US", dial: "1", name: "ארה״ב / קנדה" },
  { iso: "GB", dial: "44", name: "בריטניה" },
  { iso: "FR", dial: "33", name: "צרפת" },
  { iso: "DE", dial: "49", name: "גרמניה" },
  { iso: "NL", dial: "31", name: "הולנד" },
  { iso: "ES", dial: "34", name: "ספרד" },
  { iso: "IT", dial: "39", name: "איטליה" },
  { iso: "GR", dial: "30", name: "יוון" },
  { iso: "CY", dial: "357", name: "קפריסין" },
  { iso: "RU", dial: "7", name: "רוסיה" },
  { iso: "UA", dial: "380", name: "אוקראינה" },
  { iso: "GE", dial: "995", name: "גאורגיה" },
  { iso: "AU", dial: "61", name: "אוסטרליה" },
  { iso: "BR", dial: "55", name: "ברזיל" },
  { iso: "AR", dial: "54", name: "ארגנטינה" },
  { iso: "ZA", dial: "27", name: "דרום אפריקה" },
  { iso: "TH", dial: "66", name: "תאילנד" },
];

function flagEmoji(iso: string) {
  return String.fromCodePoint(...[...iso].map((c) => 0x1f1e6 + c.charCodeAt(0) - 65));
}

/** Builds an E.164 number: strips the local leading 0 and non-digits. */
export function composeE164(dial: string, local: string) {
  const digits = local.replace(/\D/g, "").replace(/^0+/, "");
  return digits ? `+${dial}${digits}` : "";
}

interface PhoneInputProps {
  /** E.164 result, e.g. +972541234567 (empty until a number is typed). */
  onChange: (e164: string) => void;
  required?: boolean;
}

export function PhoneInput({ onChange, required }: PhoneInputProps) {
  const [iso, setIso] = React.useState("IL");
  const [local, setLocal] = React.useState("");

  const country = COUNTRIES.find((c) => c.iso === iso)!;

  function update(nextIso: string, nextLocal: string) {
    setIso(nextIso);
    setLocal(nextLocal);
    const dial = COUNTRIES.find((c) => c.iso === nextIso)!.dial;
    onChange(composeE164(dial, nextLocal));
  }

  return (
    <div dir="ltr" className="flex gap-2">
      <Select
        className="w-28 shrink-0"
        value={iso}
        onChange={(v) => update(v, local)}
        options={COUNTRIES.map((c) => ({
          value: c.iso,
          label: (
            <span className="flex items-center gap-2" title={c.name}>
              <span className="text-base leading-none">{flagEmoji(c.iso)}</span>
              <span dir="ltr" className="text-ink-600">
                +{c.dial}
              </span>
            </span>
          ),
        }))}
      />
      <Input
        type="tel"
        dir="ltr"
        required={required}
        inputMode="numeric"
        placeholder={iso === "IL" ? "054-7760683" : ""}
        value={local}
        onChange={(e) => update(iso, e.target.value)}
      />
      <span className="sr-only">{country.name}</span>
    </div>
  );
}

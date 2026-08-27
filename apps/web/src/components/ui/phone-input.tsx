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

/**
 * Shared validity rule for phone numbers across the app.
 * Israeli numbers must be +972 followed by 8–9 digits; other countries
 * get the generic E.164 envelope (8–15 digits total).
 */
export function isValidPhone(e164: string): boolean {
  if (!/^\+\d{8,15}$/.test(e164)) return false;
  if (e164.startsWith("+972")) return /^\+972[2-9]\d{7,8}$/.test(e164);
  return true;
}

/** Groups local digits for display while typing (e.g. 054-776-0683). */
function formatLocal(iso: string, raw: string): string {
  const digits = raw.replace(/\D/g, "").slice(0, 15);
  if (!digits) return "";
  if (iso === "IL") {
    // 054-776-0683 (leading 0) or 54-776-0683.
    const head = digits.startsWith("0") ? 3 : 2;
    const parts = [
      digits.slice(0, head),
      digits.slice(head, head + 3),
      digits.slice(head + 3, head + 7),
    ].filter(Boolean);
    return parts.join("-");
  }
  return digits.replace(/(\d{3})(?=\d)/g, "$1 ").trim();
}

interface PhoneInputProps {
  /** E.164 result, e.g. +972541234567 (empty until a number is typed). */
  onChange: (e164: string) => void;
  /** Pre-fills from an existing E.164 number (edit flows). */
  initialValue?: string;
  required?: boolean;
  autoFocus?: boolean;
}

/**
 * The one phone input for the whole web app: flag + dial-code picker,
 * as-you-type grouping, and inline validation. Always reports E.164.
 */
export function PhoneInput({ onChange, initialValue, required, autoFocus }: PhoneInputProps) {
  const [iso, setIso] = React.useState(() => {
    if (initialValue?.startsWith("+")) {
      const digits = initialValue.slice(1);
      const match = [...COUNTRIES]
        .sort((a, b) => b.dial.length - a.dial.length)
        .find((c) => digits.startsWith(c.dial));
      if (match) return match.iso;
    }
    return "IL";
  });
  const [local, setLocal] = React.useState(() => {
    if (initialValue?.startsWith("+")) {
      const digits = initialValue.slice(1);
      const match = [...COUNTRIES]
        .sort((a, b) => b.dial.length - a.dial.length)
        .find((c) => digits.startsWith(c.dial));
      if (match) return formatLocal(match.iso, digits.slice(match.dial.length));
    }
    return "";
  });
  const [touched, setTouched] = React.useState(false);

  const country = COUNTRIES.find((c) => c.iso === iso)!;
  const e164 = composeE164(country.dial, local);
  const invalid = touched && local.trim() !== "" && !isValidPhone(e164);

  function update(nextIso: string, nextLocal: string) {
    const formatted = formatLocal(nextIso, nextLocal);
    setIso(nextIso);
    setLocal(formatted);
    const dial = COUNTRIES.find((c) => c.iso === nextIso)!.dial;
    onChange(composeE164(dial, formatted));
  }

  return (
    <div>
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
          autoFocus={autoFocus}
          inputMode="numeric"
          placeholder={iso === "IL" ? "054-776-0683" : ""}
          value={local}
          onChange={(e) => update(iso, e.target.value)}
          onBlur={() => setTouched(true)}
          aria-invalid={invalid}
          className={invalid ? "border-brick-600" : undefined}
        />
        <span className="sr-only">{country.name}</span>
      </div>
      {invalid && <p className="mt-1 text-xs text-brick-600">מספר הטלפון אינו תקין</p>}
    </div>
  );
}

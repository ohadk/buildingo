import Anthropic from "@anthropic-ai/sdk";
import { composeStreetAddress } from "@/lib/building-address";
import { env } from "@/lib/env";

const ZIP_JSON = /\{[\s\S]*"zip"[\s\S]*\}/;
const BARE_ZIP = /\b(\d{5,7})\b/;
const MODEL = "claude-haiku-4-5";

export type ZipLookupInput = {
  street: string;
  houseNumber?: string | null;
  city: string;
  country?: string | null;
  district?: string | null;
};

export type ZipLookupResult = {
  zip: string | null;
  /** Present when the LLM call could not complete. */
  error?: "missing_api_key" | "llm_failed" | "parse_failed";
  /** Raw model text (debug / logs). */
  raw?: string;
};

function buildAddressLine(input: ZipLookupInput): string {
  const street = composeStreetAddress(
    input.street,
    input.houseNumber,
  );
  return [
    street,
    input.city.trim(),
    input.district?.trim(),
    (input.country?.trim() || "ישראל"),
  ]
    .filter(Boolean)
    .join(", ");
}

/** Parse model output: `{"zip":"1234567"}` or a bare postal number. */
export function parseZipResponse(text: string): string | null {
  const match = text.match(ZIP_JSON);
  if (match) {
    try {
      const parsed = JSON.parse(match[0]) as { zip?: string | number | null };
      const raw = parsed.zip;
      if (raw == null) return null;
      const digits = String(raw).replace(/\D/g, "");
      if (digits.length >= 5 && digits.length <= 7) return digits;
    } catch {
      /* fall through */
    }
  }
  const bare = text.trim().match(BARE_ZIP);
  return bare ? bare[1] : null;
}

function keyFingerprint(): string {
  const k = process.env.ANTHROPIC_API_KEY ?? "";
  if (!k || k.startsWith("REPLACE")) return "(missing)";
  if (k.length < 12) return `(short len=${k.length})`;
  return `${k.slice(0, 7)}…${k.slice(-4)} (len=${k.length})`;
}

/**
 * Ask Claude for the Israeli מיקוד (postal code) for a street address.
 * Returns null zip when unsure; sets `error` when the LLM call fails.
 */
export async function lookupZipCode(
  input: ZipLookupInput,
): Promise<ZipLookupResult> {
  const address = buildAddressLine(input);
  const system =
    "You look up Israeli postal codes (מיקוד / ZIP). " +
    "Given a street address in Israel, return ONLY valid JSON with no markdown " +
    'and no other text: {"zip":"#######"} using 5–7 digits. ' +
    'If you are not reasonably sure, return {"zip":null}.';
  const userMessage = `Address:\n${address}`;

  console.log("[zip-lookup] request", {
    address,
    model: MODEL,
    apiKey: keyFingerprint(),
    system,
    userMessage,
  });

  if (address.replace(/,/g, "").trim().length < 4) {
    console.log("[zip-lookup] skipped — address too short");
    return { zip: null };
  }

  if (
    !process.env.ANTHROPIC_API_KEY ||
    process.env.ANTHROPIC_API_KEY.startsWith("REPLACE")
  ) {
    console.error("[zip-lookup] missing ANTHROPIC_API_KEY");
    return { zip: null, error: "missing_api_key" };
  }

  try {
    const client = new Anthropic({ apiKey: env.anthropicApiKey });
    const res = await client.messages.create({
      model: MODEL,
      max_tokens: 80,
      system,
      messages: [{ role: "user", content: userMessage }],
    });

    const text = res.content.find((c) => c.type === "text")?.text ?? "";
    const zip = parseZipResponse(text);

    console.log("[zip-lookup] response", {
      address,
      model: res.model,
      id: res.id,
      stopReason: res.stop_reason,
      usage: res.usage,
      rawText: text,
      parsedZip: zip,
    });

    if (!zip && text.trim()) {
      return { zip: null, error: "parse_failed", raw: text };
    }
    return { zip, raw: text };
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    console.error("[zip-lookup] LLM error", {
      address,
      model: MODEL,
      apiKey: keyFingerprint(),
      message,
      err,
    });
    return { zip: null, error: "llm_failed", raw: message };
  }
}

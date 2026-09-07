import { createHash, randomInt } from "crypto";
import { supabaseAdmin } from "@/lib/supabase/admin";
import { normalizePhone } from "@/lib/pii";

/** Matches WhatsApp OTP Content Template copy ("expires in 15 minutes"). */
export const OTP_TTL_MINUTES = 15;
export const OTP_TTL_SECONDS = OTP_TTL_MINUTES * 60;
const MAX_ATTEMPTS = 5;

function hashCode(phone: string, code: string): string {
  return createHash("sha256")
    .update(`${normalizePhone(phone)}:${code}`)
    .digest("hex");
}

export function generateOtpCode(): string {
  return String(randomInt(100000, 999999));
}

/**
 * Shared OTP persistence via Supabase RPCs (upsert_auth_otp / consume_auth_otp).
 * All apps should go through the Next.js /api/auth/otp/* routes — not call these
 * RPCs from the client — so Twilio + Firebase stay server-side.
 */
export async function storeOtp(
  phone: string,
  code: string,
  channel: "whatsapp" | "email",
): Promise<void> {
  const phoneE164 = normalizePhone(phone);
  const db = supabaseAdmin();
  const { error } = await db.rpc("upsert_auth_otp", {
    p_phone: phoneE164,
    p_code_hash: hashCode(phoneE164, code),
    p_channel: channel,
    p_ttl_minutes: OTP_TTL_MINUTES,
  });
  if (error) throw new Error(`Failed to store OTP: ${error.message}`);
}

export type VerifyOtpResult =
  | { ok: true }
  | { ok: false; reason: "not_found" | "expired" | "invalid" | "too_many" };

export async function verifyAndConsumeOtp(
  phone: string,
  code: string,
): Promise<VerifyOtpResult> {
  const phoneE164 = normalizePhone(phone);
  const db = supabaseAdmin();
  const { data, error } = await db.rpc("consume_auth_otp", {
    p_phone: phoneE164,
    p_code_hash: hashCode(phoneE164, code.trim()),
    p_max_attempts: MAX_ATTEMPTS,
  });
  if (error) throw new Error(`OTP verify failed: ${error.message}`);

  const reason = String(data ?? "not_found");
  if (reason === "ok") return { ok: true };
  if (
    reason === "not_found" ||
    reason === "expired" ||
    reason === "invalid" ||
    reason === "too_many"
  ) {
    return { ok: false, reason };
  }
  return { ok: false, reason: "not_found" };
}

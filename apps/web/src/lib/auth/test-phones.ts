import { normalizePhone } from "@/lib/pii";

/**
 * Firebase / App Review test phones — no real SMS or WhatsApp is sent.
 * Codes match README (§ Test users) and ASC_LISTING App Review notes.
 * OTP for all README numbers is 111111; Apple review number uses 123456.
 */
const TEST_PHONE_CODES: Record<string, string> = {
  "+972547788999": "111111", // super admin
  "+972547760683": "111111", // Vaad
  "+972548899656": "111111", // tenant
  "+972548899653": "111111", // free
  "+972547777777": "111111", // free
  "+972501234567": "123456", // App Store review
};

export function testOtpCodeFor(phone: string): string | null {
  const e164 = normalizePhone(phone);
  return TEST_PHONE_CODES[e164] ?? null;
}

export function isTestPhone(phone: string): boolean {
  return testOtpCodeFor(phone) != null;
}

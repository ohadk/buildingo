import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { ApiError, withErrorHandling } from "@/lib/auth/session";
import { adminAuth } from "@/lib/firebase/admin";
import { verifyAndConsumeOtp } from "@/lib/otp";
import { normalizePhone } from "@/lib/pii";

const bodySchema = z.object({
  phone: z.string().min(8).max(20),
  code: z.string().regex(/^\d{6}$/),
});

/**
 * POST /api/auth/otp/verify — verify WhatsApp/email OTP and mint a Firebase
 * custom token. Client signs in with signInWithCustomToken, then continues
 * through the existing POST /api/auth/session exchange.
 */
export const POST = withErrorHandling(async (req: NextRequest) => {
  const { phone: rawPhone, code } = bodySchema.parse(await req.json());
  const phone = normalizePhone(rawPhone);

  const result = await verifyAndConsumeOtp(phone, code);
  if (!result.ok) {
    const messages: Record<typeof result.reason, string> = {
      not_found: "No code found. Request a new one.",
      expired: "This code expired. Request a new one.",
      invalid: "Invalid code. Please try again.",
      too_many: "Too many attempts. Request a new code.",
    };
    const status =
      result.reason === "invalid" || result.reason === "too_many" ? 401 : 400;
    throw new ApiError(status, messages[result.reason]);
  }

  const auth = adminAuth();
  let uid: string;
  try {
    const existing = await auth.getUserByPhoneNumber(phone);
    uid = existing.uid;
  } catch (err: unknown) {
    const codeName =
      err && typeof err === "object" && "code" in err
        ? String((err as { code: string }).code)
        : "";
    if (codeName !== "auth/user-not-found") throw err;
    const created = await auth.createUser({ phoneNumber: phone });
    uid = created.uid;
  }

  const customToken = await auth.createCustomToken(uid);
  return NextResponse.json({ customToken });
});

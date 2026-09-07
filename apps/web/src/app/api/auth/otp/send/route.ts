import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { isTestPhone, testOtpCodeFor } from "@/lib/auth/test-phones";
import { ApiError, withErrorHandling } from "@/lib/auth/session";
import { env } from "@/lib/env";
import { sendEmail, sendWhatsAppOtp } from "@/lib/notify";
import { generateOtpCode, OTP_TTL_SECONDS, storeOtp } from "@/lib/otp";
import { normalizePhone } from "@/lib/pii";
import { supabaseAdmin } from "@/lib/supabase/admin";

const bodySchema = z.object({
  phone: z.string().min(8).max(20),
  channel: z.enum(["whatsapp", "email"]).default("whatsapp"),
  email: z.string().email().optional(),
});

const RESEND_COOLDOWN_MS = 45_000;

/**
 * POST /api/auth/otp/send — send a login OTP via WhatsApp (default) or email.
 * SMS login stays on Firebase Phone Auth in the mobile app.
 *
 * Firebase / App Review test phones (see lib/auth/test-phones.ts) never
 * trigger Twilio or SendGrid — a fixed code is stored for verify.
 */
export const POST = withErrorHandling(async (req: NextRequest) => {
  const body = bodySchema.parse(await req.json());
  const phone = normalizePhone(body.phone);
  const channel = body.channel;
  const bypassSend = isTestPhone(phone);

  if (!bypassSend) {
    if (channel === "whatsapp") {
      if (!env.twilio.accountSid || !env.twilio.authToken || !env.twilio.whatsappFrom) {
        throw new ApiError(503, "WhatsApp OTP is not configured");
      }
    } else {
      if (!env.sendgrid.apiKey) {
        throw new ApiError(503, "Email OTP is not configured");
      }
      if (!body.email) {
        throw new ApiError(400, "email is required for email OTP");
      }
    }
  } else if (channel === "email" && !body.email) {
    // Email channel still needs an address on the request shape; test
    // phones normally use WhatsApp. Allow empty by ignoring send.
  }

  const db = supabaseAdmin();
  const { data: existing } = await db
    .from("auth_otps")
    .select("created_at")
    .eq("phone_e164", phone)
    .maybeSingle();
  if (existing?.created_at) {
    const age = Date.now() - new Date(existing.created_at).getTime();
    if (age < RESEND_COOLDOWN_MS) {
      throw new ApiError(429, "Please wait before requesting another code");
    }
  }

  const code = bypassSend ? testOtpCodeFor(phone)! : generateOtpCode();
  await storeOtp(phone, code, channel);

  if (!bypassSend) {
    if (channel === "whatsapp") {
      const result = await sendWhatsAppOtp(phone, code);
      if (!result.sent) {
        console.error("[otp/send] WhatsApp failed:", result.detail);
        throw new ApiError(502, "Failed to send WhatsApp code");
      }
    } else {
      const result = await sendEmail(
        body.email!,
        "Your Buildingo sign-in code",
        `${code} is your verification code. For your security, do not share this code. This code expires in 15 minutes.`,
      );
      if (!result.sent) {
        console.error("[otp/send] Email failed:", result.detail);
        throw new ApiError(502, "Failed to send email code");
      }
    }
  } else {
    console.log(`[otp/send] test phone ${phone} — skipping Twilio/SendGrid`);
  }

  return NextResponse.json({
    ok: true,
    channel,
    // Hint for UI; never return the code.
    expiresInSeconds: OTP_TTL_SECONDS,
  });
});

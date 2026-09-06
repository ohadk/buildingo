import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { ApiError, withErrorHandling } from "@/lib/auth/session";
import { env } from "@/lib/env";
import { sendEmail } from "@/lib/notify";
import { supabaseAdmin } from "@/lib/supabase/admin";

const bodySchema = z.object({
  name: z.string().min(2).max(255),
  email: z.string().email(),
  phone: z.string().min(5).max(30).optional(),
  message: z.string().min(5).max(4000),
});

/**
 * POST /api/support — public App Store / marketing contact form.
 * No auth required. Stored in contact_requests; emailed when CONTACT_EMAIL is set.
 */
export const POST = withErrorHandling(async (req: NextRequest) => {
  const body = bodySchema.parse(await req.json());
  const db = supabaseAdmin();
  const phone = body.phone?.trim() || "-";

  const { error } = await db.from("contact_requests").insert({
    building_id: null,
    user_id: null,
    name: body.name.trim(),
    phone,
    email: body.email.trim(),
    message: body.message.trim(),
    topic: "support",
  });
  if (error) throw new ApiError(500, error.message);

  if (env.contactEmail) {
    await sendEmail(
      env.contactEmail,
      `Buildingo support: ${body.name.trim()}`,
      [
        `Name: ${body.name.trim()}`,
        `Email: ${body.email.trim()}`,
        `Phone: ${phone}`,
        "",
        body.message.trim(),
      ].join("\n"),
    );
  } else {
    console.log("CONTACT_EMAIL not set — support request stored in DB only");
  }

  return NextResponse.json({ ok: true }, { status: 201 });
});

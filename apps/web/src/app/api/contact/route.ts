import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { ApiError, getCurrentUserWithAccess, withErrorHandling } from "@/lib/auth/session";
import { PRICE_PER_APARTMENT_ILS } from "@/lib/billing";
import { env } from "@/lib/env";
import { sendEmail } from "@/lib/notify";
import { supabaseAdmin } from "@/lib/supabase/admin";

const bodySchema = z.object({
  name: z.string().min(2).max(255),
  phone: z.string().min(5).max(30),
  email: z.string().email().optional(),
  message: z.string().min(2).max(2000),
  topic: z.string().max(50).default("subscription"),
});

/**
 * POST /api/contact — "I want to subscribe / talk to you" form.
 * Deliberately uses getCurrentUserWithAccess: a Vaad whose trial just
 * expired is exactly the person who needs to reach us, so a blocked
 * building must not lock this endpoint.
 * Always stored in contact_requests; also emailed when configured.
 */
export const POST = withErrorHandling(async (req: NextRequest) => {
  const { user } = await getCurrentUserWithAccess(req);
  const body = bodySchema.parse(await req.json());
  const db = supabaseAdmin();

  const { error } = await db.from("contact_requests").insert({
    building_id: user.building_id,
    user_id: user.id,
    name: body.name,
    phone: body.phone,
    email: body.email ?? null,
    message: body.message,
    topic: body.topic,
  });
  if (error) throw new ApiError(500, error.message);

  // Enrich the email with the building context so the owner can act
  // on it directly (size → monthly price quote).
  let buildingLine = "Building: none";
  if (user.building_id) {
    const { data: b } = await db
      .from("buildings")
      .select("name, city, plan_status, trial_ends_at, apartments(count)")
      .eq("id", user.building_id)
      .single();
    if (b) {
      const aptCount =
        (b.apartments as unknown as { count: number }[])?.[0]?.count ?? 0;
      const monthly = (aptCount * PRICE_PER_APARTMENT_ILS).toFixed(2);
      buildingLine =
        `Building: ${b.name} (${b.city})\n` +
        `Plan: ${b.plan_status}, trial ends ${b.trial_ends_at}\n` +
        `Apartments: ${aptCount} → ₪${monthly}/month at ₪${PRICE_PER_APARTMENT_ILS} per apartment`;
    }
  }

  if (env.contactEmail) {
    await sendEmail(
      env.contactEmail,
      `Buildingo contact (${body.topic}): ${body.name}`,
      [
        `Name: ${body.name}`,
        `Phone: ${body.phone}`,
        `Email: ${body.email ?? "-"}`,
        `Role: ${user.role}`,
        buildingLine,
        "",
        body.message,
      ].join("\n"),
    );
  } else {
    console.log("CONTACT_EMAIL not set — contact request stored in DB only");
  }

  return NextResponse.json({ ok: true }, { status: 201 });
});

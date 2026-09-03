import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { getCurrentUser, withErrorHandling } from "@/lib/auth/session";
import { lookupZipCode } from "@/lib/zip-lookup";

const bodySchema = z.object({
  street: z.string().min(1).max(200),
  houseNumber: z.string().max(20).optional(),
  city: z.string().min(1).max(100),
  country: z.string().max(100).optional(),
  district: z.string().max(100).optional(),
});

/**
 * POST /api/geo/zip — LLM lookup of Israeli מיקוד for a street address.
 * Body: { street, houseNumber?, city, country?, district? }
 * Response: { zip: "1234567" | null, error?: string, raw?: string }
 */
export const POST = withErrorHandling(async (req: NextRequest) => {
  await getCurrentUser(req);
  const body = bodySchema.parse(await req.json());
  console.log("[api/geo/zip] incoming body", body);
  const result = await lookupZipCode(body);
  console.log("[api/geo/zip] outgoing", result);
  return NextResponse.json(result);
});

import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { ApiError, getCurrentUser, withErrorHandling } from "@/lib/auth/session";
import { canonicalizeBuildingAddress } from "@/lib/building-address";

const bodySchema = z
  .object({
    city: z.string().min(1).max(100),
    country: z.string().max(100).optional(),
    address: z.string().max(300).optional(),
    street: z.string().max(200).optional(),
    houseNumber: z.string().max(20).optional(),
  })
  .refine((b) => Boolean(b.address?.trim() || b.street?.trim()), {
    message: "address or street is required",
  });

/**
 * POST /api/geo/address/canonicalize
 * Single source of truth for building address identity.
 * Returns canonical city/address/country + addressHash used for duplicates.
 */
export const POST = withErrorHandling(async (req: NextRequest) => {
  await getCurrentUser(req);
  const body = bodySchema.parse(await req.json());
  try {
    const canonical = canonicalizeBuildingAddress(body);
    return NextResponse.json({ canonical });
  } catch (err) {
    throw new ApiError(
      400,
      err instanceof Error ? err.message : "Invalid address",
    );
  }
});

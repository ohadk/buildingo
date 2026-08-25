import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { ApiError, getCurrentUser, withErrorHandling } from "@/lib/auth/session";
import { supabaseAdmin } from "@/lib/supabase/admin";

const bodySchema = z.object({
  bucket: z.enum(["leases", "receipts", "documents"]),
  path: z.string().min(1),
});

/**
 * POST /api/files/signed-url — returns a 10-minute signed download URL.
 * Access rules mirror the storage RLS: path prefix must be the caller's
 * building, and tenants may only open building-wide files or files under
 * their own apartment folder.
 */
export const POST = withErrorHandling(async (req: NextRequest) => {
  const user = await getCurrentUser(req);
  const { bucket, path } = bodySchema.parse(await req.json());

  const [buildingFolder, secondFolder] = path.split("/");
  if (user.role !== "super_admin") {
    if (buildingFolder !== user.building_id) throw new ApiError(403, "File outside your building");
    if (
      user.role === "tenant" &&
      secondFolder !== "building" &&
      secondFolder !== user.apartment_id
    ) {
      throw new ApiError(403, "File outside your apartment vault");
    }
  }

  const { data, error } = await supabaseAdmin()
    .storage.from(bucket)
    .createSignedUrl(path, 600);
  if (error || !data) throw new ApiError(404, "File not found");
  return NextResponse.json({ url: data.signedUrl });
});

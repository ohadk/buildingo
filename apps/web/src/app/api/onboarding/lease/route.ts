import { NextRequest, NextResponse } from "next/server";
import { ApiError, getCurrentUser, withErrorHandling } from "@/lib/auth/session";
import { supabaseAdmin } from "@/lib/supabase/admin";

const MAX_LEASE_BYTES = 15 * 1024 * 1024;
const ALLOWED_TYPES = new Set(["application/pdf", "image/jpeg", "image/png"]);

/**
 * POST /api/onboarding/lease — optional lease upload (multipart form,
 * field "file"). Stored at leases/{building_id}/{apartment_id}/... in
 * Supabase Storage; the object path is saved on the user profile.
 */
export const POST = withErrorHandling(async (req: NextRequest) => {
  const user = await getCurrentUser(req);
  if (!user.building_id || !user.apartment_id) {
    throw new ApiError(409, "No apartment mapped yet");
  }

  const form = await req.formData();
  const file = form.get("file");
  if (!(file instanceof File)) throw new ApiError(400, "Missing multipart field 'file'");
  if (file.size > MAX_LEASE_BYTES) throw new ApiError(413, "Lease file exceeds 15 MB");
  if (!ALLOWED_TYPES.has(file.type)) throw new ApiError(415, "Only PDF/JPEG/PNG allowed");

  const ext = file.type === "application/pdf" ? "pdf" : file.type === "image/png" ? "png" : "jpg";
  const path = `${user.building_id}/${user.apartment_id}/lease-${Date.now()}.${ext}`;

  const db = supabaseAdmin();
  const { error: uploadError } = await db.storage
    .from("leases")
    .upload(path, Buffer.from(await file.arrayBuffer()), { contentType: file.type });
  if (uploadError) throw new ApiError(500, uploadError.message);

  const { error } = await db
    .from("users")
    .update({ lease_contract_path: path })
    .eq("id", user.id);
  if (error) throw new ApiError(500, error.message);

  return NextResponse.json({ leasePath: path });
});

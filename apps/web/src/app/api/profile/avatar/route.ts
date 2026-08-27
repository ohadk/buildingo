import { NextRequest, NextResponse } from "next/server";
import { ApiError, getCurrentUser, withErrorHandling } from "@/lib/auth/session";
import { supabaseAdmin } from "@/lib/supabase/admin";

/**
 * POST /api/profile/avatar — the signed-in user uploads a profile
 * picture. Stores it in the private `avatars` bucket, points
 * users.avatar_path at it (removing the previous file) and returns a
 * signed URL for immediate display.
 */
export const POST = withErrorHandling(async (req: NextRequest) => {
  const user = await getCurrentUser(req);

  const form = await req.formData();
  const file = form.get("file");
  if (!(file instanceof File)) throw new ApiError(400, "file is required");
  if (!file.type.startsWith("image/")) {
    throw new ApiError(400, "Only images are allowed");
  }
  if (file.size > 5 * 1024 * 1024) throw new ApiError(400, "File too large (max 5MB)");

  const db = supabaseAdmin();
  const safeName = file.name.replace(/[^a-zA-Z0-9._-]/g, "_");
  const path = `${user.id}/${Date.now()}-${safeName}`;

  const { error: uploadError } = await db.storage
    .from("avatars")
    .upload(path, Buffer.from(await file.arrayBuffer()), {
      contentType: file.type,
    });
  if (uploadError) throw new ApiError(500, uploadError.message);

  const { error: userError } = await db
    .from("users")
    .update({ avatar_path: path })
    .eq("id", user.id);
  if (userError) throw new ApiError(500, userError.message);

  // Best-effort cleanup of the replaced picture.
  if (user.avatar_path) {
    await db.storage.from("avatars").remove([user.avatar_path]);
  }

  const { data: signed } = await db.storage
    .from("avatars")
    .createSignedUrl(path, 60 * 60);

  return NextResponse.json(
    { avatarPath: path, avatarUrl: signed?.signedUrl ?? null },
    { status: 201 },
  );
});

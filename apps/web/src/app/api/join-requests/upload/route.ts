import { NextRequest, NextResponse } from "next/server";
import { ApiError, getCurrentUser, withErrorHandling } from "@/lib/auth/session";
import { supabaseAdmin } from "@/lib/supabase/admin";

/**
 * POST /api/join-requests/upload — a user preparing a join request
 * uploads a supporting document (e.g. rental contract) BEFORE they
 * belong to a building. Returns the storage path to send with the
 * join request; the Vaad gets a signed URL to view it.
 */
export const POST = withErrorHandling(async (req: NextRequest) => {
  const user = await getCurrentUser(req);
  if (user.building_id) throw new ApiError(409, "You already belong to a building");

  const form = await req.formData();
  const file = form.get("file");
  if (!(file instanceof File)) throw new ApiError(400, "file is required");
  if (file.size > 10 * 1024 * 1024) throw new ApiError(400, "File too large (max 10MB)");

  const safeName = file.name.replace(/[^a-zA-Z0-9._-]/g, "_");
  const path = `join-requests/${user.id}/${Date.now()}-${safeName}`;

  const { error } = await supabaseAdmin()
    .storage.from("documents")
    .upload(path, Buffer.from(await file.arrayBuffer()), { contentType: file.type });
  if (error) throw new ApiError(500, error.message);

  return NextResponse.json({ docPath: path }, { status: 201 });
});

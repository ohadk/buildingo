import { NextRequest, NextResponse } from "next/server";
import { ApiError, requireRole, withErrorHandling } from "@/lib/auth/session";
import { supabaseAdmin } from "@/lib/supabase/admin";

/**
 * POST /api/expenses/upload — the Vaad uploads a receipt/invoice for an
 * expense. Returns the storage path to send with the expense record;
 * residents get a signed URL to view it from GET /api/expenses.
 */
export const POST = withErrorHandling(async (req: NextRequest) => {
  const user = await requireRole(req, "vaad", "super_admin");
  if (!user.building_id) throw new ApiError(409, "Not mapped to a building");

  const form = await req.formData();
  const file = form.get("file");
  if (!(file instanceof File)) throw new ApiError(400, "file is required");
  if (file.size > 10 * 1024 * 1024) throw new ApiError(400, "File too large (max 10MB)");

  const safeName = file.name.replace(/[^a-zA-Z0-9._-]/g, "_");
  // First path segment = building id, matching the storage RLS layout.
  const path = `${user.building_id}/expenses/${Date.now()}-${safeName}`;

  const { error } = await supabaseAdmin()
    .storage.from("receipts")
    .upload(path, Buffer.from(await file.arrayBuffer()), { contentType: file.type });
  if (error) throw new ApiError(500, error.message);

  return NextResponse.json({ receiptPath: path }, { status: 201 });
});

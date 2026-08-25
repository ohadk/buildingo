import { NextRequest, NextResponse } from "next/server";
import { ApiError, getCurrentUser, requireRole, withErrorHandling } from "@/lib/auth/session";
import { supabaseAdmin } from "@/lib/supabase/admin";

/**
 * GET /api/documents — the caller's document vault:
 * building-wide docs + docs tied to their own apartment (Vaad sees all).
 */
export const GET = withErrorHandling(async (req: NextRequest) => {
  const user = await getCurrentUser(req);
  if (!user.building_id) throw new ApiError(409, "Not mapped to a building");

  let query = supabaseAdmin()
    .from("documents")
    .select("*, apartments(apartment_number)")
    .eq("building_id", user.building_id)
    .order("created_at", { ascending: false });

  if (user.role === "tenant") {
    query = user.apartment_id
      ? query.or(`apartment_id.is.null,apartment_id.eq.${user.apartment_id}`)
      : query.is("apartment_id", null);
  }

  const { data, error } = await query;
  if (error) throw new ApiError(500, error.message);
  return NextResponse.json({ documents: data });
});

/**
 * POST /api/documents — Vaad uploads a document (multipart: file, title,
 * optional apartmentId to scope it to one unit's vault).
 */
export const POST = withErrorHandling(async (req: NextRequest) => {
  const user = await requireRole(req, "vaad", "super_admin");
  const form = await req.formData();
  const file = form.get("file");
  const title = String(form.get("title") ?? "");
  const apartmentId = form.get("apartmentId") ? String(form.get("apartmentId")) : null;
  if (!(file instanceof File) || !title) throw new ApiError(400, "file and title are required");

  const db = supabaseAdmin();
  const folder = apartmentId ?? "building";
  const safeName = file.name.replace(/[^a-zA-Z0-9._-]/g, "_");
  const path = `${user.building_id}/${folder}/${Date.now()}-${safeName}`;

  const { error: uploadError } = await db.storage
    .from("documents")
    .upload(path, Buffer.from(await file.arrayBuffer()), { contentType: file.type });
  if (uploadError) throw new ApiError(500, uploadError.message);

  const { data, error } = await db
    .from("documents")
    .insert({
      building_id: user.building_id,
      apartment_id: apartmentId,
      title,
      file_path: path,
      file_type: file.type,
      uploaded_by: user.id,
    })
    .select("*")
    .single();
  if (error) throw new ApiError(500, error.message);
  return NextResponse.json({ document: data }, { status: 201 });
});

import { NextRequest, NextResponse } from "next/server";
import { ApiError, getCurrentUser, withErrorHandling } from "@/lib/auth/session";
import { supabaseAdmin } from "@/lib/supabase/admin";

function guessFileType(path: string): string {
  const lower = path.toLowerCase();
  if (lower.endsWith(".pdf")) return "application/pdf";
  if (lower.endsWith(".png")) return "image/png";
  if (lower.endsWith(".jpg") || lower.endsWith(".jpeg")) return "image/jpeg";
  if (lower.endsWith(".webp")) return "image/webp";
  if (lower.endsWith(".heic") || lower.endsWith(".heif")) return "image/heic";
  if (lower.endsWith(".gif")) return "image/gif";
  return "application/octet-stream";
}

/**
 * GET /api/documents — the caller's document vault:
 * building-wide docs + docs tied to their own apartment (Vaad sees all),
 * plus payment receipts for the caller's apartment (Vaad: all apartments).
 */
export const GET = withErrorHandling(async (req: NextRequest) => {
  const user = await getCurrentUser(req);
  if (!user.building_id) throw new ApiError(409, "Not mapped to a building");

  const db = supabaseAdmin();
  let docsQuery = db
    .from("documents")
    .select("*, apartments(apartment_number)")
    .eq("building_id", user.building_id)
    .order("created_at", { ascending: false });

  if (user.role === "tenant") {
    docsQuery = user.apartment_id
      ? docsQuery.or(`apartment_id.is.null,apartment_id.eq.${user.apartment_id}`)
      : docsQuery.is("apartment_id", null);
  }

  let paymentsQuery = db
    .from("payments")
    .select(
      "id, apartment_id, month, year, receipt_path, payment_date, updated_at, created_at, apartments(apartment_number)",
    )
    .eq("building_id", user.building_id)
    .not("receipt_path", "is", null)
    .order("year", { ascending: false })
    .order("month", { ascending: false });

  const skipPaymentReceipts =
    user.role === "tenant" && !user.apartment_id;
  if (user.role === "tenant" && user.apartment_id) {
    paymentsQuery = paymentsQuery.eq("apartment_id", user.apartment_id);
  }

  const [{ data: docs, error: docsErr }, paymentsResult] = await Promise.all([
    docsQuery,
    skipPaymentReceipts
      ? Promise.resolve({ data: [] as unknown[], error: null })
      : paymentsQuery,
  ]);
  if (docsErr) throw new ApiError(500, docsErr.message);
  if (paymentsResult.error) throw new ApiError(500, paymentsResult.error.message);
  const payments = paymentsResult.data;

  const vaultDocs = (docs ?? []).map((d) => ({
    ...d,
    bucket: "documents",
    source: "document",
  }));

  const receiptDocs = (payments ?? []).map((p) => {
    const path = p.receipt_path as string;
    const when =
      p.payment_date ??
      p.updated_at ??
      p.created_at ??
      new Date().toISOString();
    return {
      id: `payment-receipt-${p.id}`,
      title: null,
      file_path: path,
      file_type: guessFileType(path),
      bucket: "receipts",
      source: "payment_receipt",
      month: p.month,
      year: p.year,
      apartment_id: p.apartment_id,
      apartments: p.apartments,
      created_at: when,
      payment_id: p.id,
    };
  });

  const documents = [...receiptDocs, ...vaultDocs].sort((a, b) => {
    const ta = new Date(a.created_at as string).getTime();
    const tb = new Date(b.created_at as string).getTime();
    return tb - ta;
  });

  return NextResponse.json({ documents });
});

/**
 * POST /api/documents — upload a document (multipart: file, title,
 * optional apartmentId to scope it to one unit's vault).
 * Vaad may upload building-wide or for any apartment; tenants may
 * only upload to their own apartment.
 */
export const POST = withErrorHandling(async (req: NextRequest) => {
  const user = await getCurrentUser(req);
  if (!user.building_id) throw new ApiError(409, "Not mapped to a building");

  const form = await req.formData();
  const file = form.get("file");
  const title = String(form.get("title") ?? "");
  let apartmentId = form.get("apartmentId") ? String(form.get("apartmentId")) : null;
  if (!(file instanceof File) || !title) throw new ApiError(400, "file and title are required");

  if (user.role === "tenant") {
    if (!user.apartment_id) throw new ApiError(409, "No apartment assigned");
    if (apartmentId && apartmentId !== user.apartment_id) {
      throw new ApiError(403, "Can only upload to your own apartment");
    }
    apartmentId = user.apartment_id;
  } else if (user.role !== "vaad" && user.role !== "super_admin") {
    throw new ApiError(403, "Forbidden");
  }

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
  return NextResponse.json(
    { document: { ...data, bucket: "documents", source: "document" } },
    { status: 201 },
  );
});

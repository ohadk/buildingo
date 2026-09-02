import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { ApiError, getCurrentUser, withErrorHandling } from "@/lib/auth/session";
import { extractSqmFromArnonaDoc } from "@/lib/arnona-extract";
import { supabaseAdmin } from "@/lib/supabase/admin";

const bodySchema = z.object({
  docPath: z.string().min(1).max(500),
});

/**
 * POST /api/join-requests/extract-sqm — read sqm from an uploaded Arnona bill.
 * Returns null when extraction fails; the tenant can enter sqm manually.
 */
export const POST = withErrorHandling(async (req: NextRequest) => {
  const user = await getCurrentUser(req);
  if (user.building_id) throw new ApiError(409, "You already belong to a building");

  const { docPath } = bodySchema.parse(await req.json());
  if (!docPath.startsWith(`join-requests/${user.id}/`)) {
    throw new ApiError(403, "Invalid document path");
  }

  const db = supabaseAdmin();
  const { data: blob, error } = await db.storage.from("documents").download(docPath);
  if (error || !blob) throw new ApiError(404, "Document not found");

  const bytes = Buffer.from(await blob.arrayBuffer());
  const contentType = blob.type || "application/octet-stream";
  const result = await extractSqmFromArnonaDoc(bytes, contentType);

  return NextResponse.json(result);
});

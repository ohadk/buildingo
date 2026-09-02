import { NextRequest, NextResponse } from "next/server";
import { ApiError, getCurrentUser, withErrorHandling } from "@/lib/auth/session";
import { supabaseAdmin } from "@/lib/supabase/admin";

const BUCKETS = new Set(["leases", "receipts", "documents", "avatars"]);

/**
 * Building members may open:
 * - building-wide files (`…/building/…`)
 * - their own apartment folder
 * - ticket photos (`…/tickets/…`) — shared across the building
 * - expense receipts under their building
 * Vaad / super_admin may open anything in their building.
 */
function assertCanReadPath(
  user: { role: string; building_id: string | null; apartment_id: string | null },
  path: string,
) {
  const [buildingFolder, secondFolder] = path.split("/");
  if (user.role === "super_admin") return;
  if (!user.building_id || buildingFolder !== user.building_id) {
    throw new ApiError(403, "File outside your building");
  }
  if (user.role === "vaad") return;
  if (
    secondFolder === "building" ||
    secondFolder === "tickets" ||
    secondFolder === "expenses" ||
    secondFolder === "payments" ||
    secondFolder === user.apartment_id
  ) {
    return;
  }
  throw new ApiError(403, "File outside your apartment vault");
}

/**
 * GET /api/files/content?bucket=documents&path=…
 *
 * Streams a private storage object through the API so the mobile app can
 * load it with the Firebase Bearer token (avoids Flutter Image.network
 * SSL failures against Supabase signed URLs on simulator / some devices).
 */
export const GET = withErrorHandling(async (req: NextRequest) => {
  const user = await getCurrentUser(req);
  const bucket = req.nextUrl.searchParams.get("bucket") ?? "";
  const path = req.nextUrl.searchParams.get("path") ?? "";
  if (!BUCKETS.has(bucket)) throw new ApiError(400, "Invalid bucket");
  if (!path || path.includes("..")) throw new ApiError(400, "Invalid path");

  assertCanReadPath(user, path);

  const { data, error } = await supabaseAdmin().storage.from(bucket).download(path);
  if (error || !data) throw new ApiError(404, "File not found");

  const bytes = Buffer.from(await data.arrayBuffer());
  const contentType = data.type || guessContentType(path);
  return new NextResponse(bytes, {
    status: 200,
    headers: {
      "Content-Type": contentType,
      "Cache-Control": "private, max-age=300",
      "Content-Length": String(bytes.length),
    },
  });
});

function guessContentType(path: string): string {
  const lower = path.toLowerCase();
  if (lower.endsWith(".png")) return "image/png";
  if (lower.endsWith(".jpg") || lower.endsWith(".jpeg")) return "image/jpeg";
  if (lower.endsWith(".webp")) return "image/webp";
  if (lower.endsWith(".gif")) return "image/gif";
  if (lower.endsWith(".heic") || lower.endsWith(".heif")) return "image/heic";
  if (lower.endsWith(".pdf")) return "application/pdf";
  return "application/octet-stream";
}

import { NextRequest, NextResponse } from "next/server";
import { ApiError, requireRole, withErrorHandling } from "@/lib/auth/session";
import { supabaseAdmin } from "@/lib/supabase/admin";
import { getQrImage, getSession, isWahaConfigured, sessionNameForBuilding } from "@/lib/waha/client";

/** GET /api/whatsapp/qr — PNG (or JSON data-URL) for scanning. */
export const GET = withErrorHandling(async (req: NextRequest) => {
  const user = await requireRole(req, "vaad", "super_admin");
  if (!user.building_id) throw new ApiError(409, "Not mapped to a building");
  if (!isWahaConfigured()) throw new ApiError(503, "WAHA is not configured");

  const { data: building } = await supabaseAdmin()
    .from("buildings")
    .select("waha_session")
    .eq("id", user.building_id)
    .single();
  const session = building?.waha_session || sessionNameForBuilding(user.building_id);
  const info = await getSession(session);
  if (!info) throw new ApiError(404, "Session not started yet");

  const png = await getQrImage(session);
  if (!png) {
    return NextResponse.json({
      status: info.status,
      qrBase64: null,
      message: info.status === "WORKING" ? "Already connected" : "QR not available yet",
    });
  }

  const format = new URL(req.url).searchParams.get("format");
  if (format === "json") {
    return NextResponse.json({
      status: info.status,
      qrBase64: `data:image/png;base64,${png.toString("base64")}`,
    });
  }

  return new NextResponse(new Uint8Array(png), {
    headers: {
      "Content-Type": "image/png",
      "Cache-Control": "no-store",
    },
  });
});

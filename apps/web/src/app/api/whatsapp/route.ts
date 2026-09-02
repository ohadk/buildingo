import { NextRequest, NextResponse } from "next/server";
import { ApiError, requireRole, withErrorHandling } from "@/lib/auth/session";
import { env } from "@/lib/env";
import { supabaseAdmin } from "@/lib/supabase/admin";
import {
  createOrStartSession,
  getQrImage,
  getSession,
  isWahaConfigured,
  sessionNameForBuilding,
} from "@/lib/waha/client";

async function buildingSession(buildingId: string) {
  const db = supabaseAdmin();
  const { data: building, error } = await db
    .from("buildings")
    .select("id, waha_session, whatsapp_group_id, whatsapp_linked_at")
    .eq("id", buildingId)
    .single();
  if (error || !building) throw new ApiError(404, "Building not found");
  const session = building.waha_session || sessionNameForBuilding(buildingId);
  return { building, session };
}

/** GET /api/whatsapp — Vaad: connection status for this building. */
export const GET = withErrorHandling(async (req: NextRequest) => {
  const user = await requireRole(req, "vaad", "super_admin");
  if (!user.building_id) throw new ApiError(409, "Not mapped to a building");
  if (!isWahaConfigured()) {
    return NextResponse.json({
      configured: false,
      status: null,
      session: null,
      me: null,
      groupId: null,
      linkedAt: null,
      qrAvailable: false,
    });
  }

  const { building, session } = await buildingSession(user.building_id);
  const info = await getSession(session);
  return NextResponse.json({
    configured: true,
    status: info?.status ?? "STOPPED",
    session,
    me: info?.me ?? null,
    groupId: building.whatsapp_group_id,
    linkedAt: building.whatsapp_linked_at,
    qrAvailable: info?.status === "SCAN_QR_CODE" || info?.status === "STARTING",
  });
});

/**
 * POST /api/whatsapp — Vaad: create/start WAHA session for the building.
 * Returns status; client should poll GET and show QR while SCAN_QR_CODE.
 */
export const POST = withErrorHandling(async (req: NextRequest) => {
  const user = await requireRole(req, "vaad", "super_admin");
  if (!user.building_id) throw new ApiError(409, "Not mapped to a building");
  if (!isWahaConfigured()) throw new ApiError(503, "WAHA is not configured on the server");

  const { building, session } = await buildingSession(user.building_id);
  const webhookUrl = env.publicWebUrl ? `${env.publicWebUrl}/api/webhooks/waha` : null;
  const info = await createOrStartSession(session, webhookUrl);

  await supabaseAdmin()
    .from("buildings")
    .update({ waha_session: session })
    .eq("id", building.id);

  let qrBase64: string | null = null;
  if (info.status === "SCAN_QR_CODE" || info.status === "STARTING") {
    const png = await getQrImage(session);
    if (png) qrBase64 = `data:image/png;base64,${png.toString("base64")}`;
  }

  return NextResponse.json({
    configured: true,
    status: info.status,
    session,
    me: info.me ?? null,
    groupId: building.whatsapp_group_id,
    linkedAt: building.whatsapp_linked_at,
    qrAvailable: Boolean(qrBase64) || info.status === "SCAN_QR_CODE",
    qrBase64,
  });
});

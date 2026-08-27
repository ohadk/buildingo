import { NextRequest, NextResponse } from "next/server";
import { ApiError, requireRole, withErrorHandling } from "@/lib/auth/session";
import { supabaseAdmin } from "@/lib/supabase/admin";

/**
 * GET /api/audit-logs — the building activity trail.
 *  - Vaad: their own building's log.
 *  - Super admin: everything, optionally ?buildingId=<uuid> to filter.
 * Cursor pagination via ?before=<ISO timestamp>, page size via ?limit.
 */
export const GET = withErrorHandling(async (req: NextRequest) => {
  const user = await requireRole(req, "vaad", "super_admin");
  const params = req.nextUrl.searchParams;
  const limit = Math.min(Number(params.get("limit")) || 100, 200);
  const before = params.get("before");

  let query = supabaseAdmin()
    .from("audit_logs")
    .select(
      "*, actor:users!audit_logs_actor_id_fkey(full_name, phone_number), buildings(name)",
    )
    .order("created_at", { ascending: false })
    .limit(limit);

  if (user.role === "super_admin") {
    const buildingId = params.get("buildingId");
    if (buildingId) query = query.eq("building_id", buildingId);
  } else {
    if (!user.building_id) throw new ApiError(409, "Not mapped to a building");
    query = query.eq("building_id", user.building_id);
  }
  if (before) query = query.lt("created_at", before);

  const { data, error } = await query;
  if (error) throw new ApiError(500, error.message);
  return NextResponse.json({ logs: data });
});

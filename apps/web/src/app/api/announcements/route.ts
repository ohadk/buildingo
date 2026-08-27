import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { ApiError, getCurrentUser, requireRole, withErrorHandling } from "@/lib/auth/session";
import { logAudit } from "@/lib/audit";
import { supabaseAdmin } from "@/lib/supabase/admin";

const createSchema = z.object({
  title: z.string().min(2).max(255),
  body: z.string().min(1),
});

/** GET /api/announcements — the building's community board. */
export const GET = withErrorHandling(async (req: NextRequest) => {
  const user = await getCurrentUser(req);
  if (!user.building_id) throw new ApiError(409, "Not mapped to a building");

  const { data, error } = await supabaseAdmin()
    .from("announcements")
    .select("*")
    .eq("building_id", user.building_id)
    .order("created_at", { ascending: false })
    .limit(50);
  if (error) throw new ApiError(500, error.message);
  return NextResponse.json({ announcements: data });
});

/** POST /api/announcements — Vaad posts to the board. */
export const POST = withErrorHandling(async (req: NextRequest) => {
  const user = await requireRole(req, "vaad", "super_admin");
  const body = createSchema.parse(await req.json());

  const { data, error } = await supabaseAdmin()
    .from("announcements")
    .insert({
      building_id: user.building_id,
      title: body.title,
      body: body.body,
      created_by: user.id,
    })
    .select("*")
    .single();
  if (error) throw new ApiError(500, error.message);

  await logAudit({
    buildingId: user.building_id,
    actorId: user.id,
    action: "announcement_published",
    entityType: "announcement",
    entityId: data.id,
    details: { title: body.title },
  });

  return NextResponse.json({ announcement: data }, { status: 201 });
});

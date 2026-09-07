import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { ApiError, requireRole, withErrorHandling } from "@/lib/auth/session";
import { logAudit } from "@/lib/audit";
import { supabaseAdmin } from "@/lib/supabase/admin";

const updateSchema = z.object({
  title: z.string().min(2).max(255).optional(),
  body: z.string().min(1).optional(),
  eventDate: z
    .string()
    .regex(/^\d{4}-\d{2}-\d{2}$/)
    .nullable()
    .optional(),
  category: z
    .enum(["update", "meeting", "maintenance", "tip", "other"])
    .optional(),
});

async function findScoped(
  id: string,
  buildingId: string | null,
  isSuperAdmin: boolean,
) {
  const { data, error } = await supabaseAdmin()
    .from("announcements")
    .select("id, building_id, title")
    .eq("id", id)
    .maybeSingle();
  if (error) throw new ApiError(500, error.message);
  if (!data) throw new ApiError(404, "Announcement not found");
  if (!isSuperAdmin && data.building_id !== buildingId) {
    throw new ApiError(403, "This announcement belongs to another building");
  }
  return data;
}

/** PATCH /api/announcements/[id] — Vaad edits a board message. */
export const PATCH = withErrorHandling(
  async (req: NextRequest, ctx: { params: Promise<{ id: string }> }) => {
    const user = await requireRole(req, "vaad", "super_admin");
    const { id } = await ctx.params;
    const scoped = await findScoped(
      id,
      user.building_id,
      user.role === "super_admin",
    );
    const body = updateSchema.parse(await req.json());
    if (
      body.title === undefined &&
      body.body === undefined &&
      body.eventDate === undefined &&
      body.category === undefined
    ) {
      throw new ApiError(400, "Nothing to update");
    }

    const patch: Record<string, unknown> = {};
    if (body.title != null) patch.title = body.title;
    if (body.body != null) patch.body = body.body;
    if (body.eventDate !== undefined) patch.event_date = body.eventDate;
    if (body.category != null) patch.category = body.category;

    const { data, error } = await supabaseAdmin()
      .from("announcements")
      .update(patch)
      .eq("id", id)
      .select("*")
      .single();
    if (error) throw new ApiError(500, error.message);

    await logAudit({
      buildingId: scoped.building_id,
      actorId: user.id,
      action: "announcement_updated",
      entityType: "announcement",
      entityId: id,
      details: { title: body.title ?? scoped.title },
    });

    return NextResponse.json({ announcement: data });
  },
);

/** DELETE /api/announcements/[id] — Vaad removes a board message. */
export const DELETE = withErrorHandling(
  async (req: NextRequest, ctx: { params: Promise<{ id: string }> }) => {
    const user = await requireRole(req, "vaad", "super_admin");
    const { id } = await ctx.params;
    const scoped = await findScoped(
      id,
      user.building_id,
      user.role === "super_admin",
    );

    const { error } = await supabaseAdmin()
      .from("announcements")
      .delete()
      .eq("id", id);
    if (error) throw new ApiError(500, error.message);

    await logAudit({
      buildingId: scoped.building_id,
      actorId: user.id,
      action: "announcement_deleted",
      entityType: "announcement",
      entityId: id,
      details: { title: scoped.title },
    });

    return NextResponse.json({ ok: true });
  },
);

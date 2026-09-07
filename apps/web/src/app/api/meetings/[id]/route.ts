import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { ApiError, requireRole, withErrorHandling } from "@/lib/auth/session";
import { logAudit } from "@/lib/audit";
import { supabaseAdmin } from "@/lib/supabase/admin";

const updateSchema = z.object({
  title: z.string().min(2).max(255).optional(),
  agenda: z.string().min(2).optional(),
  meetingDate: z.string().optional(), // ISO timestamp
  location: z.string().max(255).nullable().optional(),
});

async function findScoped(
  id: string,
  buildingId: string | null,
  isSuperAdmin: boolean,
) {
  const { data, error } = await supabaseAdmin()
    .from("meetings")
    .select("id, building_id, title, is_closed")
    .eq("id", id)
    .maybeSingle();
  if (error) throw new ApiError(500, error.message);
  if (!data) throw new ApiError(404, "Meeting not found");
  if (!isSuperAdmin && data.building_id !== buildingId) {
    throw new ApiError(403, "This meeting belongs to another building");
  }
  return data;
}

/** PATCH /api/meetings/[id] — Vaad updates an open assembly. */
export const PATCH = withErrorHandling(
  async (req: NextRequest, ctx: { params: Promise<{ id: string }> }) => {
    const user = await requireRole(req, "vaad", "super_admin");
    const { id } = await ctx.params;
    const scoped = await findScoped(
      id,
      user.building_id,
      user.role === "super_admin",
    );
    if (scoped.is_closed) {
      throw new ApiError(409, "Closed meetings cannot be edited");
    }
    const body = updateSchema.parse(await req.json());
    if (
      body.title === undefined &&
      body.agenda === undefined &&
      body.meetingDate === undefined &&
      body.location === undefined
    ) {
      throw new ApiError(400, "Nothing to update");
    }

    const patch: Record<string, unknown> = {};
    if (body.title != null) patch.title = body.title;
    if (body.agenda != null) patch.agenda = body.agenda;
    if (body.meetingDate != null) patch.meeting_date = body.meetingDate;
    if (body.location !== undefined) patch.location = body.location;

    const { data, error } = await supabaseAdmin()
      .from("meetings")
      .update(patch)
      .eq("id", id)
      .select("*")
      .single();
    if (error) throw new ApiError(500, error.message);

    await logAudit({
      buildingId: scoped.building_id,
      actorId: user.id,
      action: "meeting_updated",
      entityType: "meeting",
      entityId: id,
      details: { title: body.title ?? scoped.title },
    });

    return NextResponse.json({ meeting: data });
  },
);

/** DELETE /api/meetings/[id] — Vaad removes a meeting (votes cascade). */
export const DELETE = withErrorHandling(
  async (req: NextRequest, ctx: { params: Promise<{ id: string }> }) => {
    const user = await requireRole(req, "vaad", "super_admin");
    const { id } = await ctx.params;
    const scoped = await findScoped(
      id,
      user.building_id,
      user.role === "super_admin",
    );

    const { error } = await supabaseAdmin().from("meetings").delete().eq("id", id);
    if (error) throw new ApiError(500, error.message);

    await logAudit({
      buildingId: scoped.building_id,
      actorId: user.id,
      action: "meeting_deleted",
      entityType: "meeting",
      entityId: id,
      details: { title: scoped.title },
    });

    return NextResponse.json({ ok: true });
  },
);

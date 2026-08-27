import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { ApiError, getCurrentUser, requireRole, withErrorHandling } from "@/lib/auth/session";
import { logAudit } from "@/lib/audit";
import { supabaseAdmin } from "@/lib/supabase/admin";

const createSchema = z.object({
  title: z.string().min(2).max(255),
  agenda: z.string().min(2),
  meetingDate: z.string(), // ISO timestamp
  location: z.string().optional(),
  votes: z
    .array(
      z.object({
        title: z.string().min(2).max(255),
        options: z.array(z.string().min(1).max(100)).min(2).max(12),
        allowMultiple: z.boolean().default(false),
      }),
    )
    .optional(),
});

/** GET /api/meetings — building meetings with their polls + ballots. */
export const GET = withErrorHandling(async (req: NextRequest) => {
  const user = await getCurrentUser(req);
  if (!user.building_id) throw new ApiError(409, "Not mapped to a building");

  const { data, error } = await supabaseAdmin()
    .from("meetings")
    .select("*, votes(*, vote_ballots(apartment_id, selected_option))")
    .eq("building_id", user.building_id)
    .order("meeting_date", { ascending: false });
  if (error) throw new ApiError(500, error.message);
  return NextResponse.json({ meetings: data });
});

/** POST /api/meetings — Vaad creates a meeting agenda + optional polls. */
export const POST = withErrorHandling(async (req: NextRequest) => {
  const user = await requireRole(req, "vaad", "super_admin");
  const body = createSchema.parse(await req.json());
  const db = supabaseAdmin();

  const { data: meeting, error } = await db
    .from("meetings")
    .insert({
      building_id: user.building_id,
      title: body.title,
      agenda: body.agenda,
      meeting_date: body.meetingDate,
      location: body.location ?? null,
      created_by: user.id,
    })
    .select("*")
    .single();
  if (error) throw new ApiError(500, error.message);

  if (body.votes?.length) {
    const { error: voteError } = await db.from("votes").insert(
      body.votes.map((v) => ({
        meeting_id: meeting.id,
        building_id: user.building_id,
        title: v.title,
        options: v.options,
        allow_multiple: v.allowMultiple,
      })),
    );
    if (voteError) throw new ApiError(500, voteError.message);
  }

  await logAudit({
    buildingId: user.building_id,
    actorId: user.id,
    action: "meeting_created",
    entityType: "meeting",
    entityId: meeting.id,
    details: {
      title: body.title,
      date: body.meetingDate,
      votes: body.votes?.length ?? 0,
    },
  });

  return NextResponse.json({ meeting }, { status: 201 });
});

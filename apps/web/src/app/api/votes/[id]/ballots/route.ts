import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { ApiError, getCurrentUser, withErrorHandling } from "@/lib/auth/session";
import { logAudit } from "@/lib/audit";
import { supabaseAdmin } from "@/lib/supabase/admin";

// New clients send selectedOptions; selectedOption kept for older builds.
const castSchema = z.object({
  selectedOptions: z.array(z.string().min(1)).min(1).max(12).optional(),
  selectedOption: z.string().min(1).optional(),
});

/**
 * POST /api/votes/:id/ballots — casts (or re-casts) the apartment's
 * ballot, one row per selected option. Multi-answer polls accept
 * several options; single-answer polls exactly one. Voting again
 * replaces the apartment's previous picks, WhatsApp-poll style.
 */
export const POST = withErrorHandling(
  async (req: NextRequest, { params }: { params: Promise<{ id: string }> }) => {
    const user = await getCurrentUser(req);
    if (!user.building_id || !user.apartment_id) {
      throw new ApiError(409, "Only residents mapped to an apartment can vote");
    }
    const { id } = await params;
    const body = castSchema.parse(await req.json());
    const selected = [
      ...new Set(body.selectedOptions ?? (body.selectedOption ? [body.selectedOption] : [])),
    ];
    if (selected.length === 0) throw new ApiError(400, "No option selected");
    const db = supabaseAdmin();

    const { data: vote } = await db
      .from("votes")
      .select("*")
      .eq("id", id)
      .eq("building_id", user.building_id)
      .eq("is_active", true)
      .maybeSingle();
    if (!vote) throw new ApiError(404, "Vote not found or closed");

    const options = vote.options as string[];
    if (selected.some((o) => !options.includes(o))) {
      throw new ApiError(400, "Not a valid option for this vote");
    }
    if (!vote.allow_multiple && selected.length > 1) {
      throw new ApiError(400, "This vote allows a single answer");
    }

    // Replace the apartment's previous ballot (residents may change
    // their mind while the poll is open).
    await db
      .from("vote_ballots")
      .delete()
      .eq("vote_id", vote.id)
      .eq("apartment_id", user.apartment_id);

    const { data, error } = await db
      .from("vote_ballots")
      .insert(
        selected.map((option) => ({
          vote_id: vote.id,
          building_id: user.building_id,
          apartment_id: user.apartment_id,
          user_id: user.id,
          selected_option: option,
        })),
      )
      .select("*");
    if (error) throw new ApiError(500, error.message);

    await logAudit({
      buildingId: user.building_id,
      actorId: user.id,
      action: "vote_cast",
      entityType: "vote",
      entityId: vote.id,
      details: { title: vote.title, option: selected.join(", ") },
    });

    return NextResponse.json({ ballots: data }, { status: 201 });
  },
);

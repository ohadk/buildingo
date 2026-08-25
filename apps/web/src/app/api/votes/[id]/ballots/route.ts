import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { ApiError, getCurrentUser, withErrorHandling } from "@/lib/auth/session";
import { supabaseAdmin } from "@/lib/supabase/admin";

const castSchema = z.object({ selectedOption: z.string().min(1) });

/**
 * POST /api/votes/:id/ballots — casts the apartment's ballot.
 * DB-level UNIQUE(vote_id, apartment_id) guarantees one vote per unit.
 */
export const POST = withErrorHandling(
  async (req: NextRequest, { params }: { params: Promise<{ id: string }> }) => {
    const user = await getCurrentUser(req);
    if (!user.building_id || !user.apartment_id) {
      throw new ApiError(409, "Only residents mapped to an apartment can vote");
    }
    const { id } = await params;
    const { selectedOption } = castSchema.parse(await req.json());
    const db = supabaseAdmin();

    const { data: vote } = await db
      .from("votes")
      .select("*")
      .eq("id", id)
      .eq("building_id", user.building_id)
      .eq("is_active", true)
      .maybeSingle();
    if (!vote) throw new ApiError(404, "Vote not found or closed");
    if (!(vote.options as string[]).includes(selectedOption)) {
      throw new ApiError(400, "Not a valid option for this vote");
    }

    const { data, error } = await db
      .from("vote_ballots")
      .insert({
        vote_id: vote.id,
        building_id: user.building_id,
        apartment_id: user.apartment_id,
        user_id: user.id,
        selected_option: selectedOption,
      })
      .select("*")
      .single();
    if (error) {
      if (error.code === "23505") throw new ApiError(409, "Your apartment already voted");
      throw new ApiError(500, error.message);
    }
    return NextResponse.json({ ballot: data }, { status: 201 });
  },
);

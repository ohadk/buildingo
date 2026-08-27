import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import {
  ApiError,
  getCurrentUser,
  getCurrentUserWithAccess,
  withErrorHandling,
} from "@/lib/auth/session";
import { supabaseAdmin } from "@/lib/supabase/admin";
import type { AppUser } from "@/lib/types";

/** Attaches a short-lived signed URL for the profile picture, if any. */
async function withAvatarUrl(user: AppUser) {
  if (!user.avatar_path) return { ...user, avatar_url: null };
  const { data } = await supabaseAdmin()
    .storage.from("avatars")
    .createSignedUrl(user.avatar_path, 60 * 60);
  return { ...user, avatar_url: data?.signedUrl ?? null };
}

/**
 * GET /api/auth/me — current profile + building/apartment context.
 * Never fails for a blocked/expired building: returns `blockedReason`
 * so the app can show a "trial ended / access suspended" screen.
 */
export const GET = withErrorHandling(async (req: NextRequest) => {
  const { user, blockedReason } = await getCurrentUserWithAccess(req);
  const db = supabaseAdmin();

  const [building, apartment, joinRequest] = await Promise.all([
    user.building_id
      ? db.from("buildings").select("*").eq("id", user.building_id).single()
      : Promise.resolve({ data: null }),
    user.apartment_id
      ? db.from("apartments").select("*").eq("id", user.apartment_id).single()
      : Promise.resolve({ data: null }),
    // Users still outside a building may have an open (or just-rejected)
    // request to join one — the app shows a waiting/rejected screen.
    user.building_id
      ? Promise.resolve({ data: null })
      : db
          .from("join_requests")
          .select(
            "id, status, apartment_number, created_at, buildings(name, address, city)",
          )
          .eq("user_id", user.id)
          .order("created_at", { ascending: false })
          .limit(1)
          .maybeSingle(),
  ]);

  return NextResponse.json({
    user: await withAvatarUrl(user),
    building: building.data,
    apartment: apartment.data,
    joinRequest: joinRequest.data,
    blockedReason,
  });
});

const patchSchema = z.object({
  fullName: z.string().min(2).max(255).optional(),
  email: z.string().email().nullable().optional(),
  numOccupants: z.number().int().min(1).max(20).optional(),
});

/** PATCH /api/auth/me — the signed-in user edits their own profile. */
export const PATCH = withErrorHandling(async (req: NextRequest) => {
  const user = await getCurrentUser(req);
  const body = patchSchema.parse(await req.json());

  const updates: Record<string, unknown> = {};
  if (body.fullName !== undefined) updates.full_name = body.fullName.trim();
  if (body.email !== undefined) updates.email = body.email;
  if (body.numOccupants !== undefined) updates.num_occupants = body.numOccupants;
  if (Object.keys(updates).length === 0) {
    throw new ApiError(400, "Nothing to update");
  }

  const { data: updated, error } = await supabaseAdmin()
    .from("users")
    .update(updates)
    .eq("id", user.id)
    .select("*")
    .single();
  if (error) throw new ApiError(500, error.message);

  return NextResponse.json({ user: await withAvatarUrl(updated) });
});

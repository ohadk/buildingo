import { NextRequest, NextResponse } from "next/server";
import { ApiError, getCurrentUser, withErrorHandling } from "@/lib/auth/session";
import { decryptDirectoryApartments, decryptInvitationRows } from "@/lib/pii";
import { supabaseAdmin } from "@/lib/supabase/admin";

type NestedUser = {
  num_occupants?: number | null;
};

type NestedTenancy = {
  started_at?: string | null;
  num_occupants?: number | null;
  status?: string | null;
};

/**
 * GET /api/directory — floor/apartment resident listing with parking
 * space IDs, occupant counts, and current tenancy start date.
 */
export const GET = withErrorHandling(async (req: NextRequest) => {
  const user = await getCurrentUser(req);
  if (!user.building_id) throw new ApiError(409, "Not mapped to a building");

  const db = supabaseAdmin();
  const { data, error } = await db
    .from("apartments")
    .select(
      "id, apartment_number, floor, parking_spots, monthly_fee, size_sqm, users(id, full_name, phone_number, role, num_occupants), tenancies(started_at, num_occupants, status)",
    )
    .eq("building_id", user.building_id)
    .order("floor")
    .order("apartment_number");
  if (error) throw new ApiError(500, error.message);

  // Vaad also sees which apartments have an invite out that hasn't been
  // accepted yet ("invited, waiting to connect").
  let pendingInvitations: unknown[] = [];
  if (user.role === "vaad" || user.role === "super_admin") {
    const { data: invites, error: invErr } = await db
      .from("invitations")
      .select("id, apartment_id, phone_number, invite_code, created_at")
      .eq("building_id", user.building_id)
      .eq("status", "pending")
      .gt("expires_at", new Date().toISOString());
    if (invErr) throw new ApiError(500, invErr.message);
    pendingInvitations = invites ?? [];
  }

  const apartments = decryptDirectoryApartments(data ?? []).map((apt) => {
    const users = (Array.isArray(apt.users) ? apt.users : []) as NestedUser[];
    const tenancies = (
      Array.isArray(apt.tenancies) ? apt.tenancies : []
    ) as NestedTenancy[];
    const active = tenancies.find((t) => t.status === "active");
    const fromUsers = users
      .map((u) => u.num_occupants)
      .filter((n): n is number => typeof n === "number" && n > 0);
    const numOccupants =
      (typeof active?.num_occupants === "number" && active.num_occupants > 0
        ? active.num_occupants
        : null) ??
      (fromUsers.length > 0 ? Math.max(...fromUsers) : null) ??
      (users.length > 0 ? users.length : null);

    // Drop nested tenancies from the client payload; expose a flat date.
    const { tenancies: _tenancies, ...rest } = apt as typeof apt & {
      tenancies?: NestedTenancy[];
    };
    return {
      ...rest,
      num_occupants: numOccupants,
      resident_since: active?.started_at ?? null,
    };
  });

  return NextResponse.json({
    directory: apartments,
    pendingInvitations: decryptInvitationRows(
      (pendingInvitations as Record<string, unknown>[]) ?? [],
    ),
  });
});

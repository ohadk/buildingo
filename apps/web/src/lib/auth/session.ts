import { cookies } from "next/headers";
import { NextRequest, NextResponse } from "next/server";
import { adminAuth } from "@/lib/firebase/admin";
import { supabaseAdmin } from "@/lib/supabase/admin";
import { decryptUserRow } from "@/lib/pii";
import type { AppUser, UserRole } from "@/lib/types";

export const SESSION_COOKIE = "dira_session";
export const SESSION_DURATION_MS = 14 * 24 * 60 * 60 * 1000; // 14 days

export class ApiError extends Error {
  constructor(
    public status: number,
    message: string,
  ) {
    super(message);
  }
}

/**
 * Resolves the caller's Firebase UID from either:
 *  - the `dira_session` cookie (web console), or
 *  - an `Authorization: Bearer <Firebase ID token>` header (Flutter app).
 */
async function resolveFirebaseUid(req: NextRequest): Promise<string> {
  const bearer = req.headers.get("authorization");
  if (bearer?.startsWith("Bearer ")) {
    const decoded = await adminAuth().verifyIdToken(bearer.slice(7), true);
    return decoded.uid;
  }

  const cookieStore = await cookies();
  const session = cookieStore.get(SESSION_COOKIE)?.value;
  if (session) {
    const decoded = await adminAuth().verifySessionCookie(session, true);
    return decoded.uid;
  }

  throw new ApiError(401, "Not authenticated");
}

type BuildingPlanRow = {
  is_active: boolean;
  plan_status: "trial" | "active" | "blocked";
  trial_ends_at: string;
};

/** Why a building has no data access (null = access OK). */
export function buildingBlockReason(
  b: BuildingPlanRow | null,
): "blocked" | "trial_expired" | null {
  if (!b) return null;
  if (!b.is_active || b.plan_status === "blocked") return "blocked";
  if (b.plan_status === "trial" && new Date(b.trial_ends_at) < new Date()) {
    return "trial_expired";
  }
  return null;
}

const USER_WITH_PLAN =
  "*, buildings!users_building_id_fkey(is_active, plan_status, trial_ends_at)";

/**
 * Like getCurrentUser but never rejects a blocked/expired building —
 * returns the reason instead so /api/auth/me can show a friendly screen.
 */
export async function getCurrentUserWithAccess(
  req: NextRequest,
): Promise<{ user: AppUser; blockedReason: "blocked" | "trial_expired" | null }> {
  const uid = await resolveFirebaseUid(req);
  const { data, error } = await supabaseAdmin()
    .from("users")
    .select(USER_WITH_PLAN)
    .eq("firebase_uid", uid)
    .maybeSingle();
  if (error) throw new ApiError(500, error.message);
  if (!data || !data.is_active) throw new ApiError(403, "No active profile for this account");
  const { buildings, ...user } = data as AppUser & { buildings: BuildingPlanRow | null };
  const blockedReason =
    user.role === "super_admin" ? null : buildingBlockReason(buildings);
  return { user: decryptUserRow(user) as AppUser, blockedReason };
}

export async function getCurrentUser(req: NextRequest): Promise<AppUser> {
  const { user, blockedReason } = await getCurrentUserWithAccess(req);
  if (blockedReason === "blocked") {
    throw new ApiError(403, "Building access is suspended");
  }
  if (blockedReason === "trial_expired") {
    throw new ApiError(402, "The building's free trial has ended");
  }
  return user;
}

export async function requireRole(req: NextRequest, ...roles: UserRole[]): Promise<AppUser> {
  const user = await getCurrentUser(req);
  if (!roles.includes(user.role)) {
    throw new ApiError(403, `Requires role: ${roles.join(" or ")}`);
  }
  return user;
}

/**
 * Session lookup for Server Components (no NextRequest available).
 * Returns null instead of throwing so pages can redirect.
 */
export async function getSessionUser(): Promise<AppUser | null> {
  try {
    const cookieStore = await cookies();
    const session = cookieStore.get(SESSION_COOKIE)?.value;
    if (!session) return null;
    const decoded = await adminAuth().verifySessionCookie(session, true);
    const { data } = await supabaseAdmin()
      .from("users")
      .select(USER_WITH_PLAN)
      .eq("firebase_uid", decoded.uid)
      .maybeSingle();
    if (!data || !data.is_active) return null;
    const { buildings, ...user } = data as AppUser & { buildings: BuildingPlanRow | null };
    if (user.role !== "super_admin" && buildingBlockReason(buildings)) return null;
    return decryptUserRow(user) as AppUser;
  } catch {
    return null;
  }
}

/** Uniform error handling wrapper for route handlers. */
export function withErrorHandling<T extends unknown[]>(
  handler: (req: NextRequest, ...rest: T) => Promise<NextResponse>,
) {
  return async (req: NextRequest, ...rest: T): Promise<NextResponse> => {
    try {
      return await handler(req, ...rest);
    } catch (err) {
      if (err instanceof ApiError) {
        return NextResponse.json({ error: err.message }, { status: err.status });
      }
      console.error("Unhandled API error:", err);
      return NextResponse.json({ error: "Internal server error" }, { status: 500 });
    }
  };
}

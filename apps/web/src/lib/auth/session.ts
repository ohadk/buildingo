import { cookies } from "next/headers";
import { NextRequest, NextResponse } from "next/server";
import { adminAuth } from "@/lib/firebase/admin";
import { supabaseAdmin } from "@/lib/supabase/admin";
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

export async function getCurrentUser(req: NextRequest): Promise<AppUser> {
  const uid = await resolveFirebaseUid(req);
  const { data, error } = await supabaseAdmin()
    .from("users")
    .select("*, buildings!users_building_id_fkey(is_active)")
    .eq("firebase_uid", uid)
    .maybeSingle();
  if (error) throw new ApiError(500, error.message);
  if (!data || !data.is_active) throw new ApiError(403, "No active profile for this account");
  const { buildings, ...user } = data as AppUser & { buildings: { is_active: boolean } | null };
  if (user.role !== "super_admin" && buildings && !buildings.is_active) {
    throw new ApiError(403, "Building access is suspended");
  }
  return user as AppUser;
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
      .select("*, buildings!users_building_id_fkey(is_active)")
      .eq("firebase_uid", decoded.uid)
      .maybeSingle();
    if (!data || !data.is_active) return null;
    const { buildings, ...user } = data as AppUser & { buildings: { is_active: boolean } | null };
    if (user.role !== "super_admin" && buildings && !buildings.is_active) return null;
    return user as AppUser;
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

import { NextRequest, NextResponse } from "next/server";
import { getCurrentUser, withErrorHandling } from "@/lib/auth/session";
import { supabaseAdmin } from "@/lib/supabase/admin";

/** GET /api/auth/me — current profile + building/apartment context. */
export const GET = withErrorHandling(async (req: NextRequest) => {
  const user = await getCurrentUser(req);
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
          .select("id, status, apartment_number, created_at, buildings(name, address, city)")
          .eq("user_id", user.id)
          .order("created_at", { ascending: false })
          .limit(1)
          .maybeSingle(),
  ]);

  return NextResponse.json({
    user,
    building: building.data,
    apartment: apartment.data,
    joinRequest: joinRequest.data,
  });
});

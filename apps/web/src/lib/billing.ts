import { ApiError } from "@/lib/auth/session";
import { supabaseAdmin } from "@/lib/supabase/admin";

/** Monthly price per apartment after the 14-day trial (ILS). */
export const PRICE_PER_APARTMENT_ILS = 4.9;

/**
 * Capacity guard for every join path. The Vaad declared how many
 * apartments the building has, and that is the hard limit:
 *  - the requested apartment number must be one of the declared units
 *  - the number of residents cannot exceed the number of apartments
 * Throws a 409 ApiError when the request would exceed the capacity.
 */
export async function assertBuildingCapacity(
  buildingId: string,
  apartmentNumber?: number | null,
): Promise<void> {
  const db = supabaseAdmin();
  const [apartments, residents] = await Promise.all([
    db
      .from("apartments")
      .select("apartment_number", { count: "exact" })
      .eq("building_id", buildingId),
    db
      .from("users")
      .select("id", { count: "exact", head: true })
      .eq("building_id", buildingId)
      .eq("is_active", true)
      .neq("role", "super_admin"),
  ]);
  if (apartments.error) throw new ApiError(500, apartments.error.message);
  if (residents.error) throw new ApiError(500, residents.error.message);

  const totalApartments = apartments.count ?? 0;
  if ((residents.count ?? 0) >= totalApartments) {
    throw new ApiError(
      409,
      "הבניין מלא — מספר הדיירים המחוברים הגיע למספר הדירות שהוגדר. פנו לוועד הבית.",
    );
  }
  if (
    apartmentNumber != null &&
    !apartments.data?.some((a) => a.apartment_number === apartmentNumber)
  ) {
    throw new ApiError(
      409,
      `דירה ${apartmentNumber} לא קיימת בבניין — יש בו ${totalApartments} דירות.`,
    );
  }
}

import type { SupabaseClient } from "@supabase/supabase-js";
import { ApiError } from "@/lib/auth/session";

type Db = SupabaseClient;

export async function validateJoinSubmission(
  db: Db,
  buildingId: string,
  apartmentNumber: number,
  input: {
    docPath?: string | null;
    arnonaDocPath?: string | null;
    sizeSqm?: number | null;
  },
) {
  const { data: building, error: bErr } = await db
    .from("buildings")
    .select("fee_method, require_join_docs")
    .eq("id", buildingId)
    .single();
  if (bErr || !building) throw new ApiError(404, "Building not found");

  const { data: apartment } = await db
    .from("apartments")
    .select("size_sqm")
    .eq("building_id", buildingId)
    .eq("apartment_number", apartmentNumber)
    .maybeSingle();

  const existingSqm =
    apartment?.size_sqm != null ? Number(apartment.size_sqm) : null;
  const perSqm = building.fee_method === "per_sqm";

  if (building.require_join_docs && (!input.docPath || !input.arnonaDocPath)) {
    throw new ApiError(
      400,
      "ועד הבית דורש לצרף חשבון ארנונה ואישור מגורים כדי להצטרף",
    );
  }

  if (perSqm && existingSqm == null) {
    if (!input.arnonaDocPath) {
      throw new ApiError(400, "חשבון ארנונה נדרש כדי לקבוע את גודל הדירה (מ\"ר)");
    }
    if (input.sizeSqm == null || input.sizeSqm <= 0) {
      throw new ApiError(400, "יש להזין את גודל הדירה במ\"ר (מחשבון הארנונה)");
    }
  }

  const sizeSqm = existingSqm ?? input.sizeSqm ?? null;
  return { building, sizeSqm };
}

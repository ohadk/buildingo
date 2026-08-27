import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { ApiError, requireRole, withErrorHandling } from "@/lib/auth/session";
import { supabaseAdmin } from "@/lib/supabase/admin";

const patchSchema = z
  .object({
    sizeSqm: z.number().min(1).max(10000).optional(),
    parkingSpot: z.string().max(50).nullable().optional(),
    monthlyFee: z.number().min(0).optional(),
  })
  .refine((b) => Object.keys(b).length > 0, { message: "Nothing to update" });

/**
 * GET /api/apartments/:id — the apartment card for the Vaad: unit
 * details, residents with contact info, the documents attached when
 * they joined (Arnona bill / proof of residence), pending invites and
 * open debt.
 */
export const GET = withErrorHandling(
  async (req: NextRequest, { params }: { params: Promise<{ id: string }> }) => {
    const user = await requireRole(req, "vaad", "super_admin");
    const { id } = await params;
    const db = supabaseAdmin();

    const { data: apartment } = await db
      .from("apartments")
      .select("*")
      .eq("id", id)
      .eq("building_id", user.building_id!)
      .maybeSingle();
    if (!apartment) throw new ApiError(404, "Apartment not found in your building");

    const [{ data: residents }, { data: invites }, { data: payments }, { data: tenancies }] =
      await Promise.all([
        db
          .from("users")
          .select("id, full_name, phone_number, email, role, num_occupants, is_active")
          .eq("apartment_id", id)
          .eq("is_active", true),
        db
          .from("invitations")
          .select("phone_number, role, created_at")
          .eq("apartment_id", id)
          .eq("status", "pending")
          .gt("expires_at", new Date().toISOString()),
        db
          .from("payments")
          .select("month, year, amount, status")
          .eq("apartment_id", id)
          .neq("status", "paid"),
        db
          .from("tenancies")
          .select("id, full_name, phone_number, holder_type, num_occupants, started_at, ended_at, end_debt_policy, status")
          .eq("apartment_id", id)
          .order("started_at", { ascending: false }),
      ]);

    // Documents the residents attached when joining.
    const residentIds = (residents ?? []).map((r) => r.id);
    const documents: {
      kind: "arnona" | "residence";
      user_name: string | null;
      url: string;
      created_at: string;
    }[] = [];
    if (residentIds.length > 0) {
      const { data: requests } = await db
        .from("join_requests")
        .select("full_name, doc_path, arnona_doc_path, created_at")
        .eq("building_id", user.building_id!)
        .eq("status", "approved")
        .in("user_id", residentIds);
      const sign = async (path: string | null) => {
        if (!path) return null;
        const { data: signed } = await db.storage
          .from("documents")
          .createSignedUrl(path, 60 * 60);
        return signed?.signedUrl ?? null;
      };
      for (const r of requests ?? []) {
        const arnona = await sign(r.arnona_doc_path);
        const residence = await sign(r.doc_path);
        if (arnona) {
          documents.push({
            kind: "arnona",
            user_name: r.full_name,
            url: arnona,
            created_at: r.created_at,
          });
        }
        if (residence) {
          documents.push({
            kind: "residence",
            user_name: r.full_name,
            url: residence,
            created_at: r.created_at,
          });
        }
      }
    }

    const now = new Date();
    const debt = (payments ?? [])
      .filter(
        (p) =>
          p.year < now.getFullYear() ||
          (p.year === now.getFullYear() && p.month <= now.getMonth() + 1),
      )
      .reduce((s, p) => s + Number(p.amount), 0);

    return NextResponse.json({
      apartment,
      residents: residents ?? [],
      pendingInvites: invites ?? [],
      documents,
      debt,
      tenancies: tenancies ?? [],
    });
  },
);

/**
 * PATCH /api/apartments/:id — Vaad updates unit details: size in sqm
 * (used for per-sqm dues), parking spot, or a manual fee override.
 */
export const PATCH = withErrorHandling(
  async (req: NextRequest, { params }: { params: Promise<{ id: string }> }) => {
    const user = await requireRole(req, "vaad", "super_admin");
    const { id } = await params;
    const body = patchSchema.parse(await req.json());

    const { data, error } = await supabaseAdmin()
      .from("apartments")
      .update({
        ...(body.sizeSqm !== undefined ? { size_sqm: body.sizeSqm } : {}),
        ...(body.parkingSpot !== undefined ? { parking_spot: body.parkingSpot } : {}),
        ...(body.monthlyFee !== undefined ? { monthly_fee: body.monthlyFee } : {}),
      })
      .eq("id", id)
      .eq("building_id", user.building_id!)
      .select("*")
      .single();
    if (error || !data) throw new ApiError(404, "Apartment not found in your building");
    return NextResponse.json({ apartment: data });
  },
);

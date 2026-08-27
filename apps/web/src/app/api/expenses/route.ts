import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { ApiError, getCurrentUser, requireRole, withErrorHandling } from "@/lib/auth/session";
import { logAudit } from "@/lib/audit";
import { supabaseAdmin } from "@/lib/supabase/admin";

const createSchema = z.object({
  title: z.string().min(2).max(255),
  category: z.string().min(2).max(100),
  amount: z.number().positive(),
  expenseDate: z.string(), // YYYY-MM-DD
  receiptPath: z.string().optional(),
  description: z.string().max(2000).optional(),
  provider: z.string().max(255).optional(),
});

/** GET /api/expenses — building outflows, visible to all residents. */
export const GET = withErrorHandling(async (req: NextRequest) => {
  const user = await getCurrentUser(req);
  if (!user.building_id) throw new ApiError(409, "Not mapped to a building");

  const db = supabaseAdmin();
  const { data, error } = await db
    .from("expenses")
    .select("*")
    .eq("building_id", user.building_id)
    .order("expense_date", { ascending: false });
  if (error) throw new ApiError(500, error.message);

  // Attach a viewable link for any uploaded receipt.
  const expenses = await Promise.all(
    (data ?? []).map(async (e) => {
      if (!e.receipt_path) return { ...e, receipt_url: null };
      const { data: signed } = await db.storage
        .from("receipts")
        .createSignedUrl(e.receipt_path, 60 * 60);
      return { ...e, receipt_url: signed?.signedUrl ?? null };
    }),
  );
  return NextResponse.json({ expenses });
});

/** POST /api/expenses — Vaad records a manual expense. */
export const POST = withErrorHandling(async (req: NextRequest) => {
  const user = await requireRole(req, "vaad", "super_admin");
  const body = createSchema.parse(await req.json());

  const { data, error } = await supabaseAdmin()
    .from("expenses")
    .insert({
      building_id: user.building_id,
      title: body.title,
      category: body.category,
      amount: body.amount,
      expense_date: body.expenseDate,
      receipt_path: body.receiptPath ?? null,
      description: body.description || null,
      provider: body.provider || null,
      created_by: user.id,
    })
    .select("*")
    .single();
  if (error) throw new ApiError(500, error.message);

  await logAudit({
    buildingId: user.building_id,
    actorId: user.id,
    action: "expense_added",
    entityType: "expense",
    entityId: data.id,
    details: { title: body.title, amount: body.amount, category: body.category },
  });

  return NextResponse.json({ expense: data }, { status: 201 });
});

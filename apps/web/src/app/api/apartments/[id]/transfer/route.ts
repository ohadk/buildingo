import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { ApiError, requireRole, withErrorHandling } from "@/lib/auth/session";
import { logAudit } from "@/lib/audit";
import { supabaseAdmin } from "@/lib/supabase/admin";
import { sendSms } from "@/lib/notify";

const transferSchema = z.object({
  endDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
  // What happens to open dues of the outgoing holder.
  debtPolicy: z.enum(["keep_with_outgoing", "transfer_to_owner", "closed"]),
  incoming: z.object({
    // self: the holder completes their own details via the invite link.
    // vaad: the Vaad fills them in now.
    mode: z.enum(["self", "vaad"]),
    fullName: z.string().max(255).optional(),
    phone: z
      .string()
      .regex(/^\+[1-9]\d{6,14}$/)
      .optional(),
    holderType: z.enum(["owner", "renter"]).default("renter"),
    startDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
    occupants: z.number().int().min(1).max(50).optional(),
  }),
  sendSms: z.boolean().default(false),
});

/**
 * POST /api/apartments/:id/transfer — the Vaad replaces the apartment's
 * holder. The apartment card (payments, tickets, history) stays with the
 * unit; the outgoing tenancy is closed with a debt decision; the
 * outgoing resident loses access; the incoming holder either gets a
 * pending tenancy to complete via invite link, or a filled-in one.
 */
export const POST = withErrorHandling(
  async (req: NextRequest, { params }: { params: Promise<{ id: string }> }) => {
    const user = await requireRole(req, "vaad", "super_admin");
    const { id } = await params;
    const body = transferSchema.parse(await req.json());
    const db = supabaseAdmin();

    const { data: apartment } = await db
      .from("apartments")
      .select("id, apartment_number, building_id")
      .eq("id", id)
      .eq("building_id", user.building_id!)
      .maybeSingle();
    if (!apartment) throw new ApiError(404, "Apartment not found in your building");

    // 1) Close the current tenancy rows with the debt decision.
    const { data: outgoing } = await db
      .from("tenancies")
      .select("id, full_name, phone_number, user_id")
      .eq("apartment_id", id)
      .eq("status", "active");
    await db
      .from("tenancies")
      .update({
        status: "ended",
        ended_at: body.endDate,
        end_debt_policy: body.debtPolicy,
      })
      .eq("apartment_id", id)
      .eq("status", "active");
    // A previous incomplete transfer shouldn't leave a stale pending row.
    await db.from("tenancies").delete().eq("apartment_id", id).eq("status", "pending");

    // 2) Detach outgoing residents — they lose app access to this building.
    //    The Vaad transferring themselves out is not supported here.
    const { data: outgoingUsers } = await db
      .from("users")
      .select("id, full_name")
      .eq("apartment_id", id)
      .eq("role", "tenant");
    if (outgoingUsers && outgoingUsers.length > 0) {
      await db
        .from("users")
        .update({ building_id: null, apartment_id: null })
        .in(
          "id",
          outgoingUsers.map((u) => u.id),
        );
    }
    // Any dangling pending invites for the unit are now obsolete.
    await db
      .from("invitations")
      .update({ status: "revoked" })
      .eq("apartment_id", id)
      .eq("status", "pending");

    // 3) Debt closed by Vaad decision: settle the open dues rows so they
    //    stop counting as debt; the decision itself is in the audit log.
    if (body.debtPolicy === "closed") {
      const end = new Date(body.endDate);
      const { data: open } = await db
        .from("payments")
        .select("id, year, month")
        .eq("apartment_id", id)
        .neq("status", "paid");
      const toClose = (open ?? []).filter(
        (p) =>
          p.year < end.getFullYear() ||
          (p.year === end.getFullYear() && p.month <= end.getMonth() + 1),
      );
      if (toClose.length > 0) {
        await db
          .from("payments")
          .update({
            status: "paid",
            payment_date: new Date().toISOString().slice(0, 10),
            notes: "debt closed by Vaad decision on holder transfer",
          })
          .in(
            "id",
            toClose.map((p) => p.id),
          );
      }
    }

    // 4) Open the incoming tenancy. Details filled by the Vaad become
    //    part of the row now; in self mode the holder completes them
    //    when accepting the invite (activateTenancy claims this row).
    const { data: newTenancy, error: tenancyError } = await db
      .from("tenancies")
      .insert({
        building_id: apartment.building_id,
        apartment_id: id,
        full_name: body.incoming.fullName ?? null,
        phone_number: body.incoming.phone ?? null,
        holder_type: body.incoming.holderType,
        num_occupants: body.incoming.occupants ?? null,
        started_at: body.incoming.startDate,
        status: "pending",
      })
      .select("*")
      .single();
    if (tenancyError) throw new ApiError(500, tenancyError.message);

    // 5) With a phone we can invite right away (and optionally SMS).
    let inviteCode: string | null = null;
    if (body.incoming.phone) {
      await db
        .from("invitations")
        .update({ status: "revoked" })
        .eq("building_id", apartment.building_id)
        .eq("phone_number", body.incoming.phone)
        .eq("status", "pending");
      const { data: invite, error: inviteError } = await db
        .from("invitations")
        .insert({
          building_id: apartment.building_id,
          apartment_id: id,
          phone_number: body.incoming.phone,
          role: "tenant",
          created_by: user.id,
        })
        .select("invite_code")
        .single();
      if (inviteError) throw new ApiError(500, inviteError.message);
      inviteCode = invite.invite_code;

      if (body.sendSms) {
        await sendSms(
          body.incoming.phone,
          `You've been invited to apartment ${apartment.apartment_number} in your building on Dira. ` +
            `Sign in with this phone number to complete your details — code ${invite.invite_code}`,
        );
      }
    }

    await logAudit({
      buildingId: apartment.building_id,
      actorId: user.id,
      action: "tenant_transferred",
      entityType: "apartment",
      entityId: id,
      details: {
        apartment: apartment.apartment_number,
        outgoing: outgoing?.map((t) => t.full_name ?? t.phone_number) ?? [],
        incoming: body.incoming.fullName ?? body.incoming.phone ?? null,
        holderType: body.incoming.holderType,
        endDate: body.endDate,
        startDate: body.incoming.startDate,
        debtPolicy: body.debtPolicy,
      },
    });

    return NextResponse.json(
      { tenancy: newTenancy, inviteCode },
      { status: 201 },
    );
  },
);

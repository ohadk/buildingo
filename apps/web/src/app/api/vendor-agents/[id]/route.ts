import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { ApiError, requireRole, withErrorHandling } from "@/lib/auth/session";
import { logAudit } from "@/lib/audit";
import { supabaseAdmin } from "@/lib/supabase/admin";

const updateSchema = z.object({
  vendorName: z.string().min(2).max(255),
  serviceType: z.string().min(2).max(100),
  vendorEmail: z.string().email().optional(),
  vendorPhone: z.string().optional(),
  preferredChannels: z.array(z.enum(["email", "sms", "whatsapp"])).min(1),
  contractDetails: z.string().optional(),
  aiInstructions: z.string().optional(),
});

async function findScoped(id: string, buildingId: string | null, isSuperAdmin: boolean) {
  const { data, error } = await supabaseAdmin()
    .from("vendor_agents")
    .select("id, building_id")
    .eq("id", id)
    .maybeSingle();
  if (error) throw new ApiError(500, error.message);
  if (!data) throw new ApiError(404, "Vendor agent not found");
  if (!isSuperAdmin && data.building_id !== buildingId) {
    throw new ApiError(403, "This vendor agent belongs to another building");
  }
  return data;
}

/** PATCH /api/vendor-agents/[id] — Vaad updates a vendor agent. */
export const PATCH = withErrorHandling(
  async (req: NextRequest, ctx: { params: Promise<{ id: string }> }) => {
    const user = await requireRole(req, "vaad", "super_admin");
    const { id } = await ctx.params;
    await findScoped(id, user.building_id, user.role === "super_admin");

    const body = updateSchema.parse(await req.json());
    if (!body.vendorEmail && !body.vendorPhone) {
      throw new ApiError(400, "Provide at least one contact: vendorEmail or vendorPhone");
    }
    if (body.preferredChannels.includes("email") && !body.vendorEmail) {
      throw new ApiError(400, "The email channel requires vendorEmail");
    }
    if (
      (body.preferredChannels.includes("sms") || body.preferredChannels.includes("whatsapp")) &&
      !body.vendorPhone
    ) {
      throw new ApiError(400, "The SMS/WhatsApp channels require vendorPhone");
    }

    const { data, error } = await supabaseAdmin()
      .from("vendor_agents")
      .update({
        vendor_name: body.vendorName,
        service_type: body.serviceType,
        vendor_email: body.vendorEmail ?? null,
        vendor_phone: body.vendorPhone ?? null,
        preferred_channels: body.preferredChannels,
        contract_details: body.contractDetails ?? null,
        ai_instructions: body.aiInstructions ?? null,
      })
      .eq("id", id)
      .select("*")
      .single();
    if (error) throw new ApiError(500, error.message);

    await logAudit({
      buildingId: data.building_id,
      actorId: user.id,
      action: "vendor_updated",
      entityType: "vendor_agent",
      entityId: data.id,
      details: { name: body.vendorName, service: body.serviceType },
    });

    return NextResponse.json({ vendorAgent: data });
  },
);

/** DELETE /api/vendor-agents/[id] — Vaad removes a vendor agent. */
export const DELETE = withErrorHandling(
  async (req: NextRequest, ctx: { params: Promise<{ id: string }> }) => {
    const user = await requireRole(req, "vaad", "super_admin");
    const { id } = await ctx.params;
    const scoped = await findScoped(id, user.building_id, user.role === "super_admin");

    // Tickets reference vendor agents; detach them before deleting so
    // history is preserved.
    const db = supabaseAdmin();
    const { data: vendor } = await db
      .from("vendor_agents")
      .select("vendor_name")
      .eq("id", id)
      .maybeSingle();
    await db
      .from("tickets")
      .update({ assigned_vendor_agent_id: null })
      .eq("assigned_vendor_agent_id", id);
    const { error } = await db.from("vendor_agents").delete().eq("id", id);
    if (error) throw new ApiError(500, error.message);

    await logAudit({
      buildingId: scoped.building_id,
      actorId: user.id,
      action: "vendor_deleted",
      entityType: "vendor_agent",
      entityId: id,
      details: { name: vendor?.vendor_name ?? "" },
    });

    return NextResponse.json({ ok: true });
  },
);

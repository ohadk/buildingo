import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { ApiError, getCurrentUser, requireRole, withErrorHandling } from "@/lib/auth/session";
import { logAudit } from "@/lib/audit";
import { supabaseAdmin } from "@/lib/supabase/admin";

const createSchema = z.object({
  vendorName: z.string().min(2).max(255),
  serviceType: z.string().min(2).max(100),
  vendorEmail: z.string().email().optional(),
  vendorPhone: z.string().optional(),
  preferredChannels: z.array(z.enum(["email", "sms", "whatsapp"])).min(1),
  contractDetails: z.string().optional(),
  aiInstructions: z.string().optional(),
});

/** GET /api/vendor-agents — Vaad lists the building's vendor agents. */
export const GET = withErrorHandling(async (req: NextRequest) => {
  const user = await getCurrentUser(req);
  if (!user.building_id) throw new ApiError(409, "Not mapped to a building");

  const { data, error } = await supabaseAdmin()
    .from("vendor_agents")
    .select("*")
    .eq("building_id", user.building_id)
    .order("created_at", { ascending: false });
  if (error) throw new ApiError(500, error.message);
  return NextResponse.json({ vendorAgents: data });
});

/** POST /api/vendor-agents — Vaad configures a new AI vendor agent. */
export const POST = withErrorHandling(async (req: NextRequest) => {
  const user = await requireRole(req, "vaad", "super_admin");
  const body = createSchema.parse(await req.json());
  if (!body.vendorEmail && !body.vendorPhone) {
    throw new ApiError(400, "Provide at least one contact: vendorEmail or vendorPhone");
  }
  // Every dispatch channel the agent may use must have its contact detail,
  // otherwise the agent has no way to open a ticket with the vendor.
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
    .insert({
      building_id: user.building_id,
      vendor_name: body.vendorName,
      service_type: body.serviceType,
      vendor_email: body.vendorEmail ?? null,
      vendor_phone: body.vendorPhone ?? null,
      preferred_channels: body.preferredChannels,
      contract_details: body.contractDetails ?? null,
      ai_instructions: body.aiInstructions ?? null,
    })
    .select("*")
    .single();
  if (error) throw new ApiError(500, error.message);

  await logAudit({
    buildingId: user.building_id,
    actorId: user.id,
    action: "vendor_added",
    entityType: "vendor_agent",
    entityId: data.id,
    details: { name: body.vendorName, service: body.serviceType },
  });

  return NextResponse.json({ vendorAgent: data }, { status: 201 });
});

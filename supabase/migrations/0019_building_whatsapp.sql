-- Building WhatsApp (WAHA) connection + inbound message log for ticket detection.

ALTER TABLE buildings
  ADD COLUMN IF NOT EXISTS waha_session TEXT,
  ADD COLUMN IF NOT EXISTS whatsapp_group_id TEXT,
  ADD COLUMN IF NOT EXISTS whatsapp_linked_by UUID REFERENCES users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS whatsapp_linked_at TIMESTAMPTZ;

CREATE TABLE IF NOT EXISTS whatsapp_inbound (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    building_id UUID NOT NULL REFERENCES buildings(id) ON DELETE CASCADE,
    waha_message_id TEXT NOT NULL,
    chat_id TEXT NOT NULL,
    from_phone TEXT,
    body TEXT,
    created_ticket_id UUID REFERENCES tickets(id) ON DELETE SET NULL,
    skipped_reason TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (waha_message_id)
);
CREATE INDEX IF NOT EXISTS idx_whatsapp_inbound_building ON whatsapp_inbound(building_id);

ALTER TABLE whatsapp_inbound ENABLE ROW LEVEL SECURITY;

CREATE POLICY superadmin_all_whatsapp_inbound ON whatsapp_inbound FOR ALL
    USING (is_super_admin()) WITH CHECK (is_super_admin());

CREATE POLICY view_building_whatsapp_inbound ON whatsapp_inbound FOR SELECT
    USING (in_building(building_id));

CREATE POLICY vaad_manage_whatsapp_inbound ON whatsapp_inbound FOR ALL
    USING (is_vaad_of(building_id)) WITH CHECK (is_vaad_of(building_id));

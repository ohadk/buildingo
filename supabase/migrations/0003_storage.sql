-- ====================================================================
-- 0003_storage.sql — Supabase Storage buckets + object policies
--
-- Bucket layout (all private; access via signed URLs from the server,
-- policies below additionally allow direct authenticated reads):
--   leases/     {building_id}/{apartment_id}/{filename}
--   receipts/   {building_id}/{apartment_id}/{filename}
--   documents/  {building_id}/{apartment_id|building}/{filename}
-- ====================================================================

INSERT INTO storage.buckets (id, name, public)
VALUES ('leases', 'leases', false),
       ('receipts', 'receipts', false),
       ('documents', 'documents', false)
ON CONFLICT (id) DO NOTHING;

-- Path helpers: first folder = building_id, second folder = apartment_id
CREATE OR REPLACE FUNCTION storage_path_building(object_name TEXT)
RETURNS UUID AS $$
    SELECT NULLIF((storage.foldername(object_name))[1], '')::uuid
$$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE FUNCTION storage_path_apartment(object_name TEXT)
RETURNS UUID AS $$
    SELECT CASE
        WHEN (storage.foldername(object_name))[2] ~ '^[0-9a-f-]{36}$'
        THEN (storage.foldername(object_name))[2]::uuid
        ELSE NULL
    END
$$ LANGUAGE sql IMMUTABLE;

-- Vaad: full management of all three buckets within their building
CREATE POLICY vaad_manage_storage ON storage.objects FOR ALL
    USING (
        bucket_id IN ('leases', 'receipts', 'documents')
        AND is_vaad_of(storage_path_building(name))
    )
    WITH CHECK (
        bucket_id IN ('leases', 'receipts', 'documents')
        AND is_vaad_of(storage_path_building(name))
    );

-- Tenants: read files scoped to their own apartment (or building-wide docs)
CREATE POLICY tenant_read_own_unit_files ON storage.objects FOR SELECT
    USING (
        bucket_id IN ('leases', 'receipts', 'documents')
        AND in_building(storage_path_building(name))
        AND (
            storage_path_apartment(name) IS NULL
            OR storage_path_apartment(name) = app_user_apartment()
        )
    );

-- Tenants: upload their own lease during onboarding
CREATE POLICY tenant_upload_own_lease ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id = 'leases'
        AND in_building(storage_path_building(name))
        AND storage_path_apartment(name) = app_user_apartment()
    );

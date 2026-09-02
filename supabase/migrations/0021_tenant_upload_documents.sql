-- Tenants may upload documents scoped to their own apartment vault.
CREATE POLICY tenant_upload_own_documents ON documents FOR INSERT
    WITH CHECK (
        in_building(building_id)
        AND apartment_id = app_user_apartment()
    );

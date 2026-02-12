-- Tax Documents: retention lock (v1)
--
-- Requirement: "all paperwork docs need to be kept"
-- Enforce at the database policy level by removing user UPDATE/DELETE access.
--
-- Users can still:
-- - INSERT (upload new documents under their own folder)
-- - SELECT (read their documents)
--
-- Service role can still manage everything for compliance/admin needs.

drop policy if exists "Users can update their own tax documents" on storage.objects;
drop policy if exists "Users can delete their own tax documents" on storage.objects;


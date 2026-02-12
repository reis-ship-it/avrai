-- Tax Documents: Supabase Storage bucket + per-user RLS (v1)
--
-- Purpose:
-- - Migrate tax document storage off Firebase Storage to Supabase Storage.
-- - Keep docs private: only the owning user can read/write their objects.
--
-- Bucket:
-- - id/name: tax-documents
-- - public: false
--
-- Object naming convention:
-- - <userId>/<taxYear>/<documentId>.pdf
--   (foldername(name)[1] == userId)

insert into storage.buckets (id, name, public)
values ('tax-documents', 'tax-documents', false)
on conflict (id) do nothing;

-- Policies (drop-if-exists to allow safe re-apply)
drop policy if exists "Users can upload their own tax documents" on storage.objects;
create policy "Users can upload their own tax documents" on storage.objects
  for insert
  with check (
    bucket_id = 'tax-documents'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

drop policy if exists "Users can view their own tax documents" on storage.objects;
create policy "Users can view their own tax documents" on storage.objects
  for select
  using (
    bucket_id = 'tax-documents'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

drop policy if exists "Users can update their own tax documents" on storage.objects;
create policy "Users can update their own tax documents" on storage.objects
  for update
  using (
    bucket_id = 'tax-documents'
    and auth.uid()::text = (storage.foldername(name))[1]
  )
  with check (
    bucket_id = 'tax-documents'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

drop policy if exists "Users can delete their own tax documents" on storage.objects;
create policy "Users can delete their own tax documents" on storage.objects
  for delete
  using (
    bucket_id = 'tax-documents'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

drop policy if exists "Service role can manage tax documents" on storage.objects;
create policy "Service role can manage tax documents" on storage.objects
  for all
  using ((select auth.role()) = 'service_role' and bucket_id = 'tax-documents')
  with check ((select auth.role()) = 'service_role' and bucket_id = 'tax-documents');


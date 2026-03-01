-- Purpose: Retention-locked storage bucket for legal/payment “paperwork” artifacts.
--
-- Scope examples:
-- - dispute evidence (screenshots/photos)
-- - contract PDFs (host ↔ business or similar)
-- - any future “paperwork” docs tied to payments/event hosting
--
-- Bucket:
-- - id/name: paperwork-documents
-- - private: true
--
-- Path convention (v1):
--   <owner_user_id>/<doc_type>/<context_id>/<document_id>.<ext>
--
-- Retention:
-- - Users can INSERT and SELECT
-- - Users CANNOT UPDATE or DELETE (no policies created)
--
-- Multi-party access:
-- - Optional grants table to allow read access for additional users (e.g., counterparties).

-- 1) Grants table (optional multi-party access)
create table if not exists public.paperwork_object_grants_v1 (
  bucket_id text not null,
  object_name text not null,
  grantee_user_id uuid not null,
  granted_at timestamptz not null default now(),
  granted_by uuid,
  note text,
  primary key (bucket_id, object_name, grantee_user_id)
);

alter table public.paperwork_object_grants_v1 enable row level security;

drop policy if exists "Users can view their paperwork grants" on public.paperwork_object_grants_v1;
create policy "Users can view their paperwork grants"
  on public.paperwork_object_grants_v1
  for select
  using (
    grantee_user_id = auth.uid()
    or (select auth.role()) = 'service_role'
  );

drop policy if exists "Service role can manage paperwork grants" on public.paperwork_object_grants_v1;
create policy "Service role can manage paperwork grants"
  on public.paperwork_object_grants_v1
  for all
  using ((select auth.role()) = 'service_role')
  with check ((select auth.role()) = 'service_role');

-- 2) Bucket
insert into storage.buckets (id, name, public)
values ('paperwork-documents', 'paperwork-documents', false)
on conflict (id) do nothing;

-- 3) Policies (INSERT + SELECT only for users)
drop policy if exists "Users can upload their own paperwork documents" on storage.objects;
create policy "Users can upload their own paperwork documents" on storage.objects
  for insert
  with check (
    (select auth.role()) = 'authenticated'
    and bucket_id = 'paperwork-documents'
    and name like (auth.uid()::text || '/%')
  );

drop policy if exists "Users can view paperwork documents they own or are granted" on storage.objects;
create policy "Users can view paperwork documents they own or are granted" on storage.objects
  for select
  using (
    bucket_id = 'paperwork-documents'
    and (
      name like (auth.uid()::text || '/%')
      or exists (
        select 1
        from public.paperwork_object_grants_v1 g
        where g.bucket_id = storage.objects.bucket_id
          and g.object_name = storage.objects.name
          and g.grantee_user_id = auth.uid()
      )
    )
  );

-- 4) Service role full access (admin/backoffice workflows)
drop policy if exists "Service role can manage paperwork documents" on storage.objects;
create policy "Service role can manage paperwork documents" on storage.objects
  for all
  using ((select auth.role()) = 'service_role' and bucket_id = 'paperwork-documents')
  with check ((select auth.role()) = 'service_role' and bucket_id = 'paperwork-documents');


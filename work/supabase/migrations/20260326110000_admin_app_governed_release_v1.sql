create table if not exists public.admin_app_release_candidates_v1 (
  candidate_id text primary key,
  proposal_id text not null,
  actor_alias text not null,
  device_id text not null,
  base_commit text not null,
  resolved_commit text not null,
  changed_paths jsonb not null default '[]'::jsonb,
  test_results text not null,
  analysis_results text not null,
  build_version text not null,
  artifact_sha256 text not null,
  artifact_uri text not null,
  build_log_uri text not null,
  metadata jsonb not null default '{}'::jsonb,
  created_at_utc timestamptz not null default timezone('utc', now())
);
create table if not exists public.admin_app_release_leases_v1 (
  lease_id text primary key,
  candidate_id text not null,
  proposal_id text not null,
  actor_alias text not null,
  device_id text not null,
  lease_token text not null,
  state text not null,
  developer_id_identity text not null,
  approved_by_actor_alias text,
  second_operator_alias text,
  notary_keychain_profile text,
  sparkle_private_key_ref text,
  metadata jsonb not null default '{}'::jsonb,
  requested_at_utc timestamptz not null default timezone('utc', now()),
  expires_at_utc timestamptz not null
);
create table if not exists public.admin_app_publish_receipts_v1 (
  publish_id text primary key,
  candidate_id text not null,
  proposal_id text not null,
  lease_id text not null,
  published_by_actor_alias text not null,
  approved_by_actor_alias text not null,
  published_from_device_id text not null,
  notary_submission_id text not null,
  sparkle_version text not null,
  sparkle_build_number text not null,
  appcast_entry_uri text not null,
  artifact_uri text not null,
  receipt_sha256 text not null,
  metadata jsonb not null default '{}'::jsonb,
  published_at_utc timestamptz not null default timezone('utc', now())
);
create index if not exists admin_app_release_candidates_proposal_idx
  on public.admin_app_release_candidates_v1 (proposal_id, created_at_utc desc);
create index if not exists admin_app_release_leases_candidate_idx
  on public.admin_app_release_leases_v1 (candidate_id, requested_at_utc desc);
create index if not exists admin_app_publish_receipts_proposal_idx
  on public.admin_app_publish_receipts_v1 (proposal_id, published_at_utc desc);
alter table public.admin_app_release_candidates_v1 enable row level security;
alter table public.admin_app_release_leases_v1 enable row level security;
alter table public.admin_app_publish_receipts_v1 enable row level security;
drop policy if exists admin_app_release_candidates_authenticated_rw
  on public.admin_app_release_candidates_v1;
create policy admin_app_release_candidates_authenticated_rw
  on public.admin_app_release_candidates_v1
  for all
  to authenticated
  using (true)
  with check (true);
drop policy if exists admin_app_release_leases_authenticated_rw
  on public.admin_app_release_leases_v1;
create policy admin_app_release_leases_authenticated_rw
  on public.admin_app_release_leases_v1
  for all
  to authenticated
  using (true)
  with check (true);
drop policy if exists admin_app_publish_receipts_authenticated_rw
  on public.admin_app_publish_receipts_v1;
create policy admin_app_publish_receipts_authenticated_rw
  on public.admin_app_publish_receipts_v1
  for all
  to authenticated
  using (true)
  with check (true);
insert into storage.buckets (id, name, public)
values ('admin-release-artifacts', 'admin-release-artifacts', false)
on conflict (id) do nothing;
drop policy if exists "Authenticated operators can manage admin release artifacts"
  on storage.objects;
create policy "Authenticated operators can manage admin release artifacts"
  on storage.objects
  for all
  to authenticated
  using (bucket_id = 'admin-release-artifacts')
  with check (bucket_id = 'admin-release-artifacts');

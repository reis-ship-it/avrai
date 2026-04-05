-- Admin Private Control-Plane Infrastructure
-- Purpose:
-- - bind gateway-issued sessions to token hashes for server-side validation
-- - add quarantine storage metadata for brokered open-web evidence
-- - keep all privileged control-plane and broker state service-role only

alter table public.admin_control_plane_sessions
  add column if not exists session_token_hash text not null default '';
create index if not exists idx_admin_control_plane_sessions_token_hash
  on public.admin_control_plane_sessions(session_token_hash);
create table if not exists public.admin_research_quarantined_payloads (
  id text primary key,
  run_id text not null references public.admin_research_runs(id) on delete cascade,
  artifact_id text references public.admin_research_artifacts(id) on delete set null,
  source_uri_hash text not null,
  source_host text not null,
  content_type text,
  payload_sha256 text not null,
  size_bytes bigint not null default 0,
  scan_status text not null default 'pending',
  normalized_summary jsonb not null default '{}'::jsonb,
  storage_key text not null,
  expires_at timestamptz not null,
  created_at timestamptz not null default now()
);
create index if not exists idx_admin_research_quarantined_payloads_run_created
  on public.admin_research_quarantined_payloads(run_id, created_at desc);
create index if not exists idx_admin_research_quarantined_payloads_expires
  on public.admin_research_quarantined_payloads(expires_at asc);
alter table public.admin_research_quarantined_payloads enable row level security;
drop policy if exists "Service role can manage admin_research_quarantined_payloads"
  on public.admin_research_quarantined_payloads;
create policy "Service role can manage admin_research_quarantined_payloads"
  on public.admin_research_quarantined_payloads
  for all
  using ((select auth.role()) = 'service_role')
  with check ((select auth.role()) = 'service_role');
comment on column public.admin_control_plane_sessions.session_token_hash is
  'SHA-256 hash of the gateway-issued session token. Raw tokens are never stored in the database.';
comment on table public.admin_research_quarantined_payloads is
  'Broker-quarantined outbound evidence payload metadata. Raw payloads must not be rendered directly in admin surfaces.';

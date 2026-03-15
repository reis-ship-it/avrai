-- Governed Autoresearch Beta Control Plane
-- Purpose:
-- - Provision private admin-only sandbox research tables.
-- - Keep all autoresearch state append-only or server-authoritative.
-- - Restrict access to service-role execution paths only.

create table if not exists public.admin_research_runs (
  id text primary key,
  title text not null,
  hypothesis text not null default '',
  layer text not null,
  owner_agent_alias text not null,
  lifecycle_state text not null,
  human_access text not null default 'adminOnly',
  visibility_scope text not null default 'runtimeInternalProjection',
  lane text not null default 'sandboxReplay',
  charter jsonb not null default '{}'::jsonb,
  egress_mode text not null default 'internalOnly',
  requires_admin_approval boolean not null default true,
  sandbox_only boolean not null default true,
  model_version text not null default '',
  policy_version text not null default '',
  metrics jsonb not null default '{}'::jsonb,
  tags jsonb not null default '[]'::jsonb,
  latest_explanation jsonb,
  latest_sandbox_projection jsonb,
  last_heartbeat_at timestamptz,
  active_checkpoint_id text,
  redirect_directive text,
  contradiction_detected boolean not null default false,
  kill_switch_active boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.admin_research_control_actions (
  id text primary key,
  run_id text not null references public.admin_research_runs(id) on delete cascade,
  action_type text not null,
  actor_alias text not null,
  rationale text not null default '',
  model_version text not null default '',
  policy_version text not null default '',
  details jsonb not null default '{}'::jsonb,
  checkpoint_id text,
  created_at timestamptz not null default now()
);

create table if not exists public.admin_research_checkpoints (
  id text primary key,
  run_id text not null references public.admin_research_runs(id) on delete cascade,
  summary text not null default '',
  state text not null,
  metric_snapshot jsonb not null default '{}'::jsonb,
  artifact_ids jsonb not null default '[]'::jsonb,
  requires_human_review boolean not null default false,
  contradiction_detected boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.admin_research_approvals (
  id text primary key,
  run_id text not null references public.admin_research_runs(id) on delete cascade,
  kind text not null,
  status text not null,
  actor_alias text,
  reason text,
  decided_at timestamptz,
  expires_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.admin_research_artifacts (
  id text primary key,
  run_id text not null references public.admin_research_runs(id) on delete cascade,
  kind text not null,
  storage_key text not null,
  summary text not null default '',
  is_redacted boolean not null default true,
  checksum text,
  expires_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.admin_research_alerts (
  id text primary key,
  run_id text not null references public.admin_research_runs(id) on delete cascade,
  severity text not null,
  title text not null,
  message text not null,
  created_at timestamptz not null default now()
);

create index if not exists idx_admin_research_runs_updated_at
  on public.admin_research_runs(updated_at desc);
create index if not exists idx_admin_research_runs_state
  on public.admin_research_runs(lifecycle_state, updated_at desc);
create index if not exists idx_admin_research_control_actions_run_created
  on public.admin_research_control_actions(run_id, created_at desc);
create index if not exists idx_admin_research_checkpoints_run_created
  on public.admin_research_checkpoints(run_id, created_at desc);
create index if not exists idx_admin_research_approvals_run_created
  on public.admin_research_approvals(run_id, created_at desc);
create index if not exists idx_admin_research_artifacts_run_created
  on public.admin_research_artifacts(run_id, created_at desc);
create index if not exists idx_admin_research_alerts_run_created
  on public.admin_research_alerts(run_id, created_at desc);

alter table public.admin_research_runs enable row level security;
alter table public.admin_research_control_actions enable row level security;
alter table public.admin_research_checkpoints enable row level security;
alter table public.admin_research_approvals enable row level security;
alter table public.admin_research_artifacts enable row level security;
alter table public.admin_research_alerts enable row level security;

drop policy if exists "Service role can manage admin_research_runs"
  on public.admin_research_runs;
create policy "Service role can manage admin_research_runs"
  on public.admin_research_runs
  for all
  using ((select auth.role()) = 'service_role')
  with check ((select auth.role()) = 'service_role');

drop policy if exists "Service role can manage admin_research_control_actions"
  on public.admin_research_control_actions;
create policy "Service role can manage admin_research_control_actions"
  on public.admin_research_control_actions
  for all
  using ((select auth.role()) = 'service_role')
  with check ((select auth.role()) = 'service_role');

drop policy if exists "Service role can manage admin_research_checkpoints"
  on public.admin_research_checkpoints;
create policy "Service role can manage admin_research_checkpoints"
  on public.admin_research_checkpoints
  for all
  using ((select auth.role()) = 'service_role')
  with check ((select auth.role()) = 'service_role');

drop policy if exists "Service role can manage admin_research_approvals"
  on public.admin_research_approvals;
create policy "Service role can manage admin_research_approvals"
  on public.admin_research_approvals
  for all
  using ((select auth.role()) = 'service_role')
  with check ((select auth.role()) = 'service_role');

drop policy if exists "Service role can manage admin_research_artifacts"
  on public.admin_research_artifacts;
create policy "Service role can manage admin_research_artifacts"
  on public.admin_research_artifacts
  for all
  using ((select auth.role()) = 'service_role')
  with check ((select auth.role()) = 'service_role');

drop policy if exists "Service role can manage admin_research_alerts"
  on public.admin_research_alerts;
create policy "Service role can manage admin_research_alerts"
  on public.admin_research_alerts
  for all
  using ((select auth.role()) = 'service_role')
  with check ((select auth.role()) = 'service_role');

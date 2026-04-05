-- Admin Research Governance Extensions (v1)
-- Adds:
-- - role/visibility permissions fields
-- - approval workflow fields
-- - impact linking + rollback checkpoint references
-- - alert table
-- - control action audit trail table

alter table public.admin_research_projects
  add column if not exists visibility_scope text not null default 'adminAndRealityModel',
  add column if not exists allowed_roles jsonb not null default '["admin_operator","reality_model_primary"]'::jsonb,
  add column if not exists approval_status text not null default 'pending',
  add column if not exists approved_by text,
  add column if not exists approved_at timestamptz,
  add column if not exists rejected_reason text;
do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'admin_research_projects_visibility_scope_check'
  ) then
    alter table public.admin_research_projects
      add constraint admin_research_projects_visibility_scope_check
      check (visibility_scope in ('adminOnly', 'adminAndRealityModel', 'adminAndModelOps'));
  end if;
end;
$$;
do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'admin_research_projects_approval_status_check'
  ) then
    alter table public.admin_research_projects
      add constraint admin_research_projects_approval_status_check
      check (approval_status in ('notRequired', 'pending', 'approved', 'rejected'));
  end if;
end;
$$;
create table if not exists public.admin_research_project_impacts (
  id uuid primary key default gen_random_uuid(),
  project_id text not null references public.admin_research_projects(id) on delete cascade,
  entity_type text not null,
  entity_id text not null,
  before_metric double precision not null default 0,
  after_metric double precision not null default 0,
  rollback_checkpoint_id text not null,
  recorded_by text not null,
  recorded_at timestamptz not null default now()
);
create index if not exists idx_admin_research_project_impacts_project_id
  on public.admin_research_project_impacts(project_id);
create index if not exists idx_admin_research_project_impacts_entity
  on public.admin_research_project_impacts(entity_type, entity_id);
create table if not exists public.admin_research_alerts (
  id uuid primary key default gen_random_uuid(),
  project_id text not null references public.admin_research_projects(id) on delete cascade,
  severity text not null,
  title text not null,
  message text not null,
  created_at timestamptz not null default now(),
  resolved_at timestamptz
);
do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'admin_research_alerts_severity_check'
  ) then
    alter table public.admin_research_alerts
      add constraint admin_research_alerts_severity_check
      check (severity in ('info', 'warning', 'critical'));
  end if;
end;
$$;
create index if not exists idx_admin_research_alerts_project_created
  on public.admin_research_alerts(project_id, created_at desc);
create index if not exists idx_admin_research_alerts_resolved
  on public.admin_research_alerts(resolved_at);
create table if not exists public.admin_research_control_actions (
  id uuid primary key default gen_random_uuid(),
  action text not null,
  actor_id text not null,
  project_id text references public.admin_research_projects(id) on delete set null,
  source text not null default 'admin_app',
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create index if not exists idx_admin_research_control_actions_project_created
  on public.admin_research_control_actions(project_id, created_at desc);
create index if not exists idx_admin_research_control_actions_actor_created
  on public.admin_research_control_actions(actor_id, created_at desc);
alter table public.admin_research_project_impacts enable row level security;
alter table public.admin_research_alerts enable row level security;
alter table public.admin_research_control_actions enable row level security;
drop policy if exists "Service role can manage admin_research_project_impacts"
  on public.admin_research_project_impacts;
create policy "Service role can manage admin_research_project_impacts"
  on public.admin_research_project_impacts
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
drop policy if exists "Service role can manage admin_research_control_actions"
  on public.admin_research_control_actions;
create policy "Service role can manage admin_research_control_actions"
  on public.admin_research_control_actions
  for all
  using ((select auth.role()) = 'service_role')
  with check ((select auth.role()) = 'service_role');
comment on table public.admin_research_project_impacts is
  'Impact links between research projects and world/universe/reality entities with rollback checkpoint references.';
comment on table public.admin_research_alerts is
  'Operational alerts for research health and policy monitoring.';
comment on table public.admin_research_control_actions is
  'Audit trail of all admin control actions against research projects.';

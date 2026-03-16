-- Private Admin Control-Plane Gateway Hardening
-- Purpose:
-- - add gateway-issued session, audit, and policy-decision tables
-- - resolve legacy table name conflicts for governed autoresearch alerts/actions
-- - freeze legacy project tables as read-only compatibility data
-- - backfill active legacy project rows into governed run rows

do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'admin_research_alerts'
      and column_name = 'project_id'
  ) and not exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'admin_research_alerts'
      and column_name = 'run_id'
  ) then
    alter table public.admin_research_alerts
      rename to admin_research_project_alerts_legacy;
  end if;
end;
$$;

do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'admin_research_control_actions'
      and column_name = 'project_id'
  ) and not exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'admin_research_control_actions'
      and column_name = 'run_id'
  ) then
    alter table public.admin_research_control_actions
      rename to admin_research_project_control_actions_legacy;
  end if;
end;
$$;

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

create table if not exists public.admin_research_alerts (
  id text primary key,
  run_id text not null references public.admin_research_runs(id) on delete cascade,
  severity text not null,
  title text not null,
  message text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.admin_control_plane_sessions (
  id text primary key,
  actor_alias text not null,
  role text not null default 'adminOperator',
  issued_by text not null,
  policy_version text not null,
  device_id text not null,
  mesh_identity text not null,
  client_certificate_fingerprint text not null,
  device_attestation jsonb not null default '{}'::jsonb,
  expires_at timestamptz not null,
  revoked_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.admin_control_plane_audit_events (
  id text primary key,
  action text not null,
  actor_alias text not null,
  run_id text,
  checkpoint_id text,
  model_version text,
  policy_version text,
  device_id text,
  session_id text references public.admin_control_plane_sessions(id) on delete set null,
  step_up_satisfied boolean not null default false,
  second_operator_alias text,
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.admin_control_plane_policy_decisions (
  id text primary key,
  session_id text references public.admin_control_plane_sessions(id) on delete set null,
  actor_alias text not null,
  action text not null,
  allowed boolean not null,
  rationale text not null default '',
  step_up_satisfied boolean not null default false,
  second_operator_alias text,
  policy_version text not null,
  created_at timestamptz not null default now()
);

create index if not exists idx_admin_control_plane_sessions_actor_expires
  on public.admin_control_plane_sessions(actor_alias, expires_at desc);
create index if not exists idx_admin_control_plane_audit_events_run_created
  on public.admin_control_plane_audit_events(run_id, created_at desc);
create index if not exists idx_admin_control_plane_audit_events_session_created
  on public.admin_control_plane_audit_events(session_id, created_at desc);
create index if not exists idx_admin_control_plane_policy_decisions_session_created
  on public.admin_control_plane_policy_decisions(session_id, created_at desc);
create index if not exists idx_admin_research_control_actions_run_created
  on public.admin_research_control_actions(run_id, created_at desc);
create index if not exists idx_admin_research_alerts_run_created
  on public.admin_research_alerts(run_id, created_at desc);

alter table public.admin_research_control_actions enable row level security;
alter table public.admin_research_alerts enable row level security;
alter table public.admin_control_plane_sessions enable row level security;
alter table public.admin_control_plane_audit_events enable row level security;
alter table public.admin_control_plane_policy_decisions enable row level security;

drop policy if exists "Service role can manage governed admin_research_control_actions"
  on public.admin_research_control_actions;
create policy "Service role can manage governed admin_research_control_actions"
  on public.admin_research_control_actions
  for all
  using ((select auth.role()) = 'service_role')
  with check ((select auth.role()) = 'service_role');

drop policy if exists "Service role can manage governed admin_research_alerts"
  on public.admin_research_alerts;
create policy "Service role can manage governed admin_research_alerts"
  on public.admin_research_alerts
  for all
  using ((select auth.role()) = 'service_role')
  with check ((select auth.role()) = 'service_role');

drop policy if exists "Service role can manage admin_control_plane_sessions"
  on public.admin_control_plane_sessions;
create policy "Service role can manage admin_control_plane_sessions"
  on public.admin_control_plane_sessions
  for all
  using ((select auth.role()) = 'service_role')
  with check ((select auth.role()) = 'service_role');

drop policy if exists "Service role can manage admin_control_plane_audit_events"
  on public.admin_control_plane_audit_events;
create policy "Service role can manage admin_control_plane_audit_events"
  on public.admin_control_plane_audit_events
  for all
  using ((select auth.role()) = 'service_role')
  with check ((select auth.role()) = 'service_role');

drop policy if exists "Service role can manage admin_control_plane_policy_decisions"
  on public.admin_control_plane_policy_decisions;
create policy "Service role can manage admin_control_plane_policy_decisions"
  on public.admin_control_plane_policy_decisions
  for all
  using ((select auth.role()) = 'service_role')
  with check ((select auth.role()) = 'service_role');

do $$
begin
  if exists (
    select 1
    from information_schema.tables
    where table_schema = 'public'
      and table_name = 'admin_research_projects'
  ) then
    execute $policy$
      drop policy if exists "Service role can manage admin_research_projects"
        on public.admin_research_projects
    $policy$;
    execute $policy$
      create policy "Service role can read admin_research_projects compatibility"
        on public.admin_research_projects
        for select
        using ((select auth.role()) = 'service_role')
    $policy$;
  end if;
end;
$$;

do $$
begin
  if exists (
    select 1
    from information_schema.tables
    where table_schema = 'public'
      and table_name = 'admin_research_project_logs'
  ) then
    execute $policy$
      drop policy if exists "Service role can manage admin_research_project_logs"
        on public.admin_research_project_logs
    $policy$;
    execute $policy$
      create policy "Service role can read admin_research_project_logs compatibility"
        on public.admin_research_project_logs
        for select
        using ((select auth.role()) = 'service_role')
    $policy$;
  end if;
end;
$$;

do $$
begin
  if exists (
    select 1
    from information_schema.tables
    where table_schema = 'public'
      and table_name = 'admin_research_project_impacts'
  ) then
    execute $policy$
      drop policy if exists "Service role can manage admin_research_project_impacts"
        on public.admin_research_project_impacts
    $policy$;
    execute $policy$
      create policy "Service role can read admin_research_project_impacts compatibility"
        on public.admin_research_project_impacts
        for select
        using ((select auth.role()) = 'service_role')
    $policy$;
  end if;
end;
$$;

do $$
begin
  if exists (
    select 1
    from information_schema.tables
    where table_schema = 'public'
      and table_name = 'admin_research_projects'
  ) then
    insert into public.admin_research_runs (
      id,
      title,
      hypothesis,
      layer,
      owner_agent_alias,
      lifecycle_state,
      human_access,
      visibility_scope,
      lane,
      charter,
      egress_mode,
      requires_admin_approval,
      sandbox_only,
      model_version,
      policy_version,
      metrics,
      tags,
      created_at,
      updated_at
    )
    select
      'legacy_' || p.id as id,
      p.title,
      p.hypothesis,
      p.layer,
      p.owner_agent_id as owner_agent_alias,
      case p.status
        when 'proposed' then 'draft'
        when 'running' then 'running'
        when 'humanReview' then 'review'
        when 'completed' then 'completed'
        when 'paused' then 'paused'
        else 'draft'
      end as lifecycle_state,
      'adminOnly' as human_access,
      'runtimeInternalProjection' as visibility_scope,
      'sandboxReplay' as lane,
      jsonb_build_object(
        'id', 'legacy_charter_' || p.id,
        'title', p.title,
        'objective', coalesce(p.hypothesis, ''),
        'hypothesis', coalesce(p.hypothesis, ''),
        'allowedExperimentSurfaces', '[]'::jsonb,
        'successMetrics', '[]'::jsonb,
        'stopConditions', '[]'::jsonb,
        'hardBans', '["production_mutation","consumer_surface_access"]'::jsonb,
        'createdAt', p.created_at,
        'updatedAt', p.updated_at,
        'approvedBy', p.approved_by,
        'approvedAt', p.approved_at
      ) as charter,
      'internalOnly' as egress_mode,
      coalesce(p.requires_human_approval, true) as requires_admin_approval,
      true as sandbox_only,
      'legacy-backfill' as model_version,
      'opa-gar-beta-v1' as policy_version,
      coalesce(p.metrics, '{}'::jsonb) as metrics,
      coalesce(p.tags, '[]'::jsonb) as tags,
      p.created_at,
      p.updated_at
    from public.admin_research_projects p
    where not exists (
      select 1
      from public.admin_research_runs r
      where r.id = 'legacy_' || p.id
    );
  end if;
end;
$$;

comment on table public.admin_control_plane_sessions is
  'Gateway-issued private admin control-plane sessions bound to device and mesh identity.';
comment on table public.admin_control_plane_audit_events is
  'Immutable audit ledger for privileged admin control-plane actions.';
comment on table public.admin_control_plane_policy_decisions is
  'OPA-style policy decision log for admin control-plane authorization.';

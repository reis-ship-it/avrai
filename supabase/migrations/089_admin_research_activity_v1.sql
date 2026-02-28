-- Admin Research Activity Backend (v1)
-- Purpose:
-- - Persist research projects for admin + reality model oversight workflows
-- - Persist project audit/log notes
-- - Support internal backend adapter in app layer
--
-- Security model:
-- - RLS enabled on both tables
-- - Service-role only access (intended for internal backend server usage)

create table if not exists public.admin_research_projects (
  id text primary key,
  title text not null,
  hypothesis text not null default '',
  layer text not null,
  status text not null,
  owner_agent_id text not null,
  reality_model_can_view boolean not null default true,
  requires_human_approval boolean not null default true,
  tags jsonb not null default '[]'::jsonb,
  metrics jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint admin_research_projects_layer_check
    check (layer in ('reality', 'universe', 'world', 'crossLayer')),
  constraint admin_research_projects_status_check
    check (status in ('proposed', 'running', 'humanReview', 'completed', 'paused'))
);

create table if not exists public.admin_research_project_logs (
  id uuid primary key default gen_random_uuid(),
  project_id text not null references public.admin_research_projects(id) on delete cascade,
  actor_id text not null,
  message text not null,
  created_at timestamptz not null default now()
);

create index if not exists idx_admin_research_projects_updated_at
  on public.admin_research_projects(updated_at desc);
create index if not exists idx_admin_research_projects_layer_status
  on public.admin_research_projects(layer, status);
create index if not exists idx_admin_research_project_logs_project_created
  on public.admin_research_project_logs(project_id, created_at asc);

-- Keep updated_at current on any project update.
create or replace function public.set_admin_research_projects_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_admin_research_projects_updated_at
  on public.admin_research_projects;
create trigger trg_admin_research_projects_updated_at
before update on public.admin_research_projects
for each row
execute function public.set_admin_research_projects_updated_at();

alter table public.admin_research_projects enable row level security;
alter table public.admin_research_project_logs enable row level security;

drop policy if exists "Service role can manage admin_research_projects"
  on public.admin_research_projects;
create policy "Service role can manage admin_research_projects"
  on public.admin_research_projects
  for all
  using ((select auth.role()) = 'service_role')
  with check ((select auth.role()) = 'service_role');

drop policy if exists "Service role can manage admin_research_project_logs"
  on public.admin_research_project_logs;
create policy "Service role can manage admin_research_project_logs"
  on public.admin_research_project_logs
  for all
  using ((select auth.role()) = 'service_role')
  with check ((select auth.role()) = 'service_role');

comment on table public.admin_research_projects is
  'Research projects tracked by admin/reality oversight workflows (service-role managed).';
comment on table public.admin_research_project_logs is
  'Append-style log/audit notes for admin_research_projects (service-role managed).';

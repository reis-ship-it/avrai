create table if not exists public.governed_improvement_proposals_v1 (
  proposal_id text primary key,
  account_id text not null,
  delivery_target text not null,
  state text not null,
  created_by_operator_id text not null,
  created_by_device_id text not null,
  assigned_operator_id text,
  base_commit text,
  code_change_bundle_uri text,
  candidate_id text,
  lease_id text,
  publish_receipt_id text,
  proposal_payload jsonb not null default '{}'::jsonb,
  updated_at_utc timestamptz not null default timezone('utc', now()),
  version integer not null default 1
);
create table if not exists public.governed_improvement_proposal_transitions_v1 (
  transition_id text primary key,
  proposal_id text not null references public.governed_improvement_proposals_v1(proposal_id) on delete cascade,
  account_id text not null,
  from_state text,
  to_state text not null,
  actor_operator_id text not null,
  actor_alias text,
  actor_device_id text not null,
  rationale text,
  metadata jsonb not null default '{}'::jsonb,
  created_at_utc timestamptz not null default timezone('utc', now())
);
create index if not exists governed_improvement_proposals_account_updated_idx
  on public.governed_improvement_proposals_v1 (account_id, updated_at_utc desc);
create index if not exists governed_improvement_proposals_account_state_updated_idx
  on public.governed_improvement_proposals_v1 (account_id, state, updated_at_utc desc);
create index if not exists governed_improvement_proposal_transitions_proposal_created_idx
  on public.governed_improvement_proposal_transitions_v1 (proposal_id, created_at_utc desc);
create index if not exists governed_improvement_proposal_transitions_account_created_idx
  on public.governed_improvement_proposal_transitions_v1 (account_id, created_at_utc desc);
alter table public.governed_improvement_proposals_v1 enable row level security;
alter table public.governed_improvement_proposal_transitions_v1 enable row level security;
drop policy if exists governed_improvement_proposals_authenticated_rw
  on public.governed_improvement_proposals_v1;
create policy governed_improvement_proposals_authenticated_rw
  on public.governed_improvement_proposals_v1
  for all
  to authenticated
  using (true)
  with check (true);
drop policy if exists governed_improvement_proposal_transitions_authenticated_rw
  on public.governed_improvement_proposal_transitions_v1;
create policy governed_improvement_proposal_transitions_authenticated_rw
  on public.governed_improvement_proposal_transitions_v1
  for all
  to authenticated
  using (true)
  with check (true);
do $$
begin
  if exists (
    select 1
    from pg_publication
    where pubname = 'supabase_realtime'
  ) then
    if not exists (
      select 1
      from pg_publication_tables
      where pubname = 'supabase_realtime'
        and schemaname = 'public'
        and tablename = 'governed_improvement_proposals_v1'
    ) then
      alter publication supabase_realtime add table public.governed_improvement_proposals_v1;
    end if;

    if not exists (
      select 1
      from pg_publication_tables
      where pubname = 'supabase_realtime'
        and schemaname = 'public'
        and tablename = 'governed_improvement_proposal_transitions_v1'
    ) then
      alter publication supabase_realtime add table public.governed_improvement_proposal_transitions_v1;
    end if;

    if not exists (
      select 1
      from pg_publication_tables
      where pubname = 'supabase_realtime'
        and schemaname = 'public'
        and tablename = 'admin_app_release_candidates_v1'
    ) then
      alter publication supabase_realtime add table public.admin_app_release_candidates_v1;
    end if;

    if not exists (
      select 1
      from pg_publication_tables
      where pubname = 'supabase_realtime'
        and schemaname = 'public'
        and tablename = 'admin_app_release_leases_v1'
    ) then
      alter publication supabase_realtime add table public.admin_app_release_leases_v1;
    end if;

    if not exists (
      select 1
      from pg_publication_tables
      where pubname = 'supabase_realtime'
        and schemaname = 'public'
        and tablename = 'admin_app_publish_receipts_v1'
    ) then
      alter publication supabase_realtime add table public.admin_app_publish_receipts_v1;
    end if;

    if not exists (
      select 1
      from pg_publication_tables
      where pubname = 'supabase_realtime'
        and schemaname = 'public'
        and tablename = 'admin_assistant_memory_tuples_v1'
    ) then
      alter publication supabase_realtime add table public.admin_assistant_memory_tuples_v1;
    end if;

    if not exists (
      select 1
      from pg_publication_tables
      where pubname = 'supabase_realtime'
        and schemaname = 'public'
        and tablename = 'admin_assistant_operator_preferences_v1'
    ) then
      alter publication supabase_realtime add table public.admin_assistant_operator_preferences_v1;
    end if;
  end if;
end
$$;

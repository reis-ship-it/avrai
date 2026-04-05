-- Human connection control plane for direct matches and friend requests.
--
-- Purpose:
-- - Provide a shared cross-device invitation / decision ledger for human chat opt-in.
-- - Keep participant visibility scoped via RLS.
-- - Allow both AI2AI direct-match invites and explicit friend requests to open the
--   same direct-chat door without inventing a second transport system.

create table if not exists public.human_connection_invitations (
  invitation_id uuid primary key default gen_random_uuid(),
  kind text not null
    check (kind in ('directMatch', 'friendRequest')),
  user_a_id uuid not null references auth.users(id) on delete cascade,
  user_b_id uuid not null references auth.users(id) on delete cascade,
  user_a_agent_id text,
  user_b_agent_id text,
  compatibility_score double precision,
  source text not null,
  status text not null default 'pending'
    check (status in ('pending', 'declined', 'chat_enabled')),
  chat_thread_id text,
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint human_connection_invitations_distinct_users
    check (user_a_id <> user_b_id)
);
create index if not exists idx_human_connection_invitations_user_a
  on public.human_connection_invitations (user_a_id, created_at desc);
create index if not exists idx_human_connection_invitations_user_b
  on public.human_connection_invitations (user_b_id, created_at desc);
create index if not exists idx_human_connection_invitations_kind_status
  on public.human_connection_invitations (kind, status, created_at desc);
alter table public.human_connection_invitations enable row level security;
drop policy if exists human_connection_invitations_select_participants
  on public.human_connection_invitations;
create policy human_connection_invitations_select_participants
  on public.human_connection_invitations
  for select
  to authenticated
  using (auth.uid() = user_a_id or auth.uid() = user_b_id);
drop policy if exists human_connection_invitations_insert_creator
  on public.human_connection_invitations;
create policy human_connection_invitations_insert_creator
  on public.human_connection_invitations
  for insert
  to authenticated
  with check (
    auth.uid() is not null
    and auth.uid() = created_by
    and auth.uid() = user_a_id
  );
drop policy if exists human_connection_invitations_update_participants
  on public.human_connection_invitations;
create policy human_connection_invitations_update_participants
  on public.human_connection_invitations
  for update
  to authenticated
  using (auth.uid() = user_a_id or auth.uid() = user_b_id)
  with check (auth.uid() = user_a_id or auth.uid() = user_b_id);
create table if not exists public.human_connection_decisions (
  id bigserial primary key,
  invitation_id uuid not null
    references public.human_connection_invitations(invitation_id)
    on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  accepted boolean not null,
  decided_at timestamptz not null default now(),
  metadata jsonb not null default '{}'::jsonb,
  unique (invitation_id, user_id)
);
create index if not exists idx_human_connection_decisions_invitation
  on public.human_connection_decisions (invitation_id, decided_at desc);
create index if not exists idx_human_connection_decisions_user
  on public.human_connection_decisions (user_id, decided_at desc);
alter table public.human_connection_decisions enable row level security;
drop policy if exists human_connection_decisions_select_participants
  on public.human_connection_decisions;
create policy human_connection_decisions_select_participants
  on public.human_connection_decisions
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.human_connection_invitations i
      where i.invitation_id = human_connection_decisions.invitation_id
        and (i.user_a_id = auth.uid() or i.user_b_id = auth.uid())
    )
  );
drop policy if exists human_connection_decisions_insert_own
  on public.human_connection_decisions;
create policy human_connection_decisions_insert_own
  on public.human_connection_decisions
  for insert
  to authenticated
  with check (
    auth.uid() is not null
    and auth.uid() = user_id
    and exists (
      select 1
      from public.human_connection_invitations i
      where i.invitation_id = human_connection_decisions.invitation_id
        and (i.user_a_id = auth.uid() or i.user_b_id = auth.uid())
    )
  );
drop policy if exists human_connection_decisions_update_own
  on public.human_connection_decisions;
create policy human_connection_decisions_update_own
  on public.human_connection_decisions
  for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
create or replace function public.update_human_connection_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;
drop trigger if exists human_connection_invitations_updated_at_trigger
  on public.human_connection_invitations;
create trigger human_connection_invitations_updated_at_trigger
  before update on public.human_connection_invitations
  for each row
  execute function public.update_human_connection_updated_at();
do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'human_connection_invitations'
  ) then
    alter publication supabase_realtime add table public.human_connection_invitations;
  end if;

  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'human_connection_decisions'
  ) then
    alter publication supabase_realtime add table public.human_connection_decisions;
  end if;
end
$$;

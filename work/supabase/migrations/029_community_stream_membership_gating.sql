-- Phase 14 / Community Chat: single-stream delivery (no per-user notify fanout)
--
-- Adds:
-- - community_memberships: membership gate based on having received a sender-key share
-- - community_message_events: single row per message; members subscribe via RLS
--
-- This reduces writes from O(n members) -> O(1) per message for notifications.

create table if not exists public.community_memberships (
  community_id text not null,
  user_id uuid not null references auth.users(id) on delete cascade,
  key_id uuid not null,
  joined_at timestamptz not null default now(),
  primary key (community_id, user_id)
);

alter table public.community_memberships enable row level security;

-- Members can read their own membership row
drop policy if exists community_memberships_select_own on public.community_memberships;
create policy community_memberships_select_own
  on public.community_memberships
  for select
  to authenticated
  using (auth.uid() = user_id);

-- Allow a user to upsert their membership ONLY if they have a sender-key share for the active key.
--
-- This prevents arbitrary users from joining the stream unless they were included
-- in the sender-key distribution.
drop policy if exists community_memberships_insert_with_key_share on public.community_memberships;
create policy community_memberships_insert_with_key_share
  on public.community_memberships
  for insert
  to authenticated
  with check (
    auth.uid() is not null
    and auth.uid() = user_id
    and exists (
      select 1
      from public.community_sender_key_state s
      join public.community_sender_key_shares sh
        on sh.community_id = s.community_id
       and sh.key_id = s.key_id
       and sh.to_user_id = auth.uid()
      where s.community_id = community_memberships.community_id
        and community_memberships.key_id = s.key_id
    )
  );

drop policy if exists community_memberships_update_with_key_share on public.community_memberships;
create policy community_memberships_update_with_key_share
  on public.community_memberships
  for update
  to authenticated
  using (auth.uid() = user_id)
  with check (
    auth.uid() is not null
    and auth.uid() = user_id
    and exists (
      select 1
      from public.community_sender_key_state s
      join public.community_sender_key_shares sh
        on sh.community_id = s.community_id
       and sh.key_id = s.key_id
       and sh.to_user_id = auth.uid()
      where s.community_id = community_memberships.community_id
        and community_memberships.key_id = s.key_id
    )
  );

-- Allow a user to leave (delete own membership)
drop policy if exists community_memberships_delete_own on public.community_memberships;
create policy community_memberships_delete_own
  on public.community_memberships
  for delete
  to authenticated
  using (auth.uid() = user_id);

create index if not exists idx_community_memberships_user_id
  on public.community_memberships (user_id);

create table if not exists public.community_message_events (
  id bigserial primary key,
  community_id text not null,
  message_id uuid not null references public.community_message_blobs(message_id) on delete cascade,
  sender_user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (community_id, message_id)
);

alter table public.community_message_events enable row level security;

-- Members can see events for communities they are members of
drop policy if exists community_message_events_select_member on public.community_message_events;
create policy community_message_events_select_member
  on public.community_message_events
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.community_memberships m
      where m.community_id = community_message_events.community_id
        and m.user_id = auth.uid()
    )
  );

-- Sender can insert events only for communities they are a member of
drop policy if exists community_message_events_insert_member on public.community_message_events;
create policy community_message_events_insert_member
  on public.community_message_events
  for insert
  to authenticated
  with check (
    auth.uid() is not null
    and auth.uid() = sender_user_id
    and exists (
      select 1
      from public.community_memberships m
      where m.community_id = community_message_events.community_id
        and m.user_id = auth.uid()
    )
  );

create index if not exists idx_community_message_events_community_created_at
  on public.community_message_events (community_id, created_at desc);

-- Realtime publication
alter publication supabase_realtime add table public.community_message_events;


-- Rooms and Messages schema for invisible backend-managed rooms
-- Coordinator/Rooms agents (service role) manage rooms and memberships

create table if not exists public.rooms (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  metadata jsonb not null default '{}'::jsonb
);

alter table public.rooms enable row level security;

-- Deny all to anon/auth users; service role bypasses RLS
create policy rooms_no_access on public.rooms for all using (false) with check (false);

create table if not exists public.room_memberships (
  room_id uuid not null references public.rooms(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  joined_at timestamptz not null default now(),
  primary key (room_id, user_id)
);

alter table public.room_memberships enable row level security;

-- Allow users to see only their own memberships
create policy room_memberships_select_own
  on public.room_memberships for select
  using (auth.uid() = user_id);

-- Inserts/updates/deletes restricted to service role (no policies for anon)

create table if not exists public.room_messages (
  id bigserial primary key,
  room_id uuid not null references public.rooms(id) on delete cascade,
  sender_user_id uuid not null references auth.users(id) on delete set null,
  payload jsonb not null,
  created_at timestamptz not null default now()
);

alter table public.room_messages enable row level security;

-- Users can read messages only in rooms they belong to
create policy room_messages_select_member
  on public.room_messages for select
  using (exists (
    select 1 from public.room_memberships m
    where m.room_id = room_id and m.user_id = auth.uid()
  ));

-- Users can post only to rooms they belong to
create policy room_messages_insert_member
  on public.room_messages for insert
  with check (exists (
    select 1 from public.room_memberships m
    where m.room_id = room_id and m.user_id = auth.uid()
  ));

-- Add to realtime publication for changefeeds
alter publication supabase_realtime add table public.room_messages;

-- Private messages to deliver summaries invisibly to users' AIs
create table if not exists public.private_messages (
  id bigserial primary key,
  to_user_id uuid not null references auth.users(id) on delete cascade,
  payload jsonb not null,
  created_at timestamptz not null default now()
);

alter table public.private_messages enable row level security;

-- Only the recipient can read
create policy private_messages_select_own
  on public.private_messages for select
  using (auth.uid() = to_user_id);

-- Inserts restricted to service role only (no policy for anon)

alter publication supabase_realtime add table public.private_messages;



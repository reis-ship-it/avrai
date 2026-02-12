-- Section 29 (6.8): Communities — persistence v1 (local-first sync)
--
-- Adds:
-- - public.communities_v1: community definitions (discoverable list)
-- - public.community_members_v1: per-user membership rows (join/leave)
-- - public.community_vibe_contributions_v1: per-user anonymized 12D contributions
--
-- Notes:
-- - `community_id` is TEXT to match app model ids (not guaranteed UUIDs).
-- - Membership and vibe contributions are user-owned rows (RLS: users can only mutate their own).
-- - Centroid aggregation can be computed client-side (local-first) or later via server-side views/triggers.

create table if not exists public.communities_v1 (
  id text primary key,
  name text not null,
  description text,
  category text not null,
  originating_event_id text,
  originating_event_type text,
  founder_user_id uuid references auth.users(id) on delete set null,
  original_locality text,
  current_localities text[] not null default '{}'::text[],
  member_count int not null default 0,
  event_count int not null default 0,
  activity_level text,
  engagement_score double precision,
  diversity_score double precision,
  -- Privacy-safe aggregated centroid; nullable until enough contributors.
  vibe_centroid jsonb,
  vibe_centroid_contributors int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.communities_v1 enable row level security;

-- Any authenticated user may read communities (discover surface).
drop policy if exists communities_v1_select_authenticated on public.communities_v1;
create policy communities_v1_select_authenticated
  on public.communities_v1
  for select
  to authenticated
  using (auth.uid() is not null);

-- Founder can create (insert) their community definition.
drop policy if exists communities_v1_insert_founder on public.communities_v1;
create policy communities_v1_insert_founder
  on public.communities_v1
  for insert
  to authenticated
  with check (
    auth.uid() is not null
    and founder_user_id = auth.uid()
  );

-- Founder can update their community definition.
drop policy if exists communities_v1_update_founder on public.communities_v1;
create policy communities_v1_update_founder
  on public.communities_v1
  for update
  to authenticated
  using (
    auth.uid() is not null
    and founder_user_id = auth.uid()
  )
  with check (
    auth.uid() is not null
    and founder_user_id = auth.uid()
  );

create index if not exists idx_communities_v1_category
  on public.communities_v1 (category);

create index if not exists idx_communities_v1_updated_at
  on public.communities_v1 (updated_at desc);

-- Per-user community memberships (join/leave).
create table if not exists public.community_members_v1 (
  community_id text not null references public.communities_v1(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  joined_at timestamptz not null default now(),
  primary key (community_id, user_id)
);

alter table public.community_members_v1 enable row level security;

drop policy if exists community_members_v1_select_own on public.community_members_v1;
create policy community_members_v1_select_own
  on public.community_members_v1
  for select
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists community_members_v1_insert_own on public.community_members_v1;
create policy community_members_v1_insert_own
  on public.community_members_v1
  for insert
  to authenticated
  with check (auth.uid() is not null and auth.uid() = user_id);

drop policy if exists community_members_v1_delete_own on public.community_members_v1;
create policy community_members_v1_delete_own
  on public.community_members_v1
  for delete
  to authenticated
  using (auth.uid() = user_id);

create index if not exists idx_community_members_v1_user_id
  on public.community_members_v1 (user_id);

create index if not exists idx_community_members_v1_community_id
  on public.community_members_v1 (community_id);

-- Per-user anonymized 12D vibe contributions (privacy-preserving; no raw profiles).
create table if not exists public.community_vibe_contributions_v1 (
  community_id text not null references public.communities_v1(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  agent_id text not null,
  dimensions jsonb not null,
  quantization_bins int not null default 64,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (community_id, user_id)
);

alter table public.community_vibe_contributions_v1 enable row level security;

drop policy if exists community_vibe_contributions_v1_select_own on public.community_vibe_contributions_v1;
create policy community_vibe_contributions_v1_select_own
  on public.community_vibe_contributions_v1
  for select
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists community_vibe_contributions_v1_insert_own on public.community_vibe_contributions_v1;
create policy community_vibe_contributions_v1_insert_own
  on public.community_vibe_contributions_v1
  for insert
  to authenticated
  with check (auth.uid() is not null and auth.uid() = user_id);

drop policy if exists community_vibe_contributions_v1_update_own on public.community_vibe_contributions_v1;
create policy community_vibe_contributions_v1_update_own
  on public.community_vibe_contributions_v1
  for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() is not null and auth.uid() = user_id);

drop policy if exists community_vibe_contributions_v1_delete_own on public.community_vibe_contributions_v1;
create policy community_vibe_contributions_v1_delete_own
  on public.community_vibe_contributions_v1
  for delete
  to authenticated
  using (auth.uid() = user_id);

create index if not exists idx_community_vibe_contributions_v1_user_id
  on public.community_vibe_contributions_v1 (user_id);

create index if not exists idx_community_vibe_contributions_v1_community_updated_at
  on public.community_vibe_contributions_v1 (community_id, updated_at desc);


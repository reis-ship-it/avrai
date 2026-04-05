-- Universal external intake metadata and review queue.
--
-- This keeps source-of-truth sync data generic across spots, events, and communities
-- so Birmingham can launch first without baking Birmingham-specific assumptions into
-- the shared storage layer.

create table if not exists public.external_sources_v1 (
  id text primary key,
  owner_user_id uuid references auth.users(id) on delete cascade,
  source_provider text not null,
  source_url text,
  connection_mode text not null default 'manual',
  entity_hint text,
  source_label text,
  city_code text,
  locality_code text,
  is_one_way_sync boolean not null default true,
  is_claimable boolean not null default false,
  sync_state text not null default 'pending',
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  last_synced_at timestamptz
);
alter table public.external_sources_v1 enable row level security;
drop policy if exists external_sources_v1_select_owner on public.external_sources_v1;
create policy external_sources_v1_select_owner
  on public.external_sources_v1
  for select
  to authenticated
  using (auth.uid() = owner_user_id);
drop policy if exists external_sources_v1_insert_owner on public.external_sources_v1;
create policy external_sources_v1_insert_owner
  on public.external_sources_v1
  for insert
  to authenticated
  with check (auth.uid() is not null and auth.uid() = owner_user_id);
drop policy if exists external_sources_v1_update_owner on public.external_sources_v1;
create policy external_sources_v1_update_owner
  on public.external_sources_v1
  for update
  to authenticated
  using (auth.uid() = owner_user_id)
  with check (auth.uid() is not null and auth.uid() = owner_user_id);
create index if not exists idx_external_sources_v1_owner_updated
  on public.external_sources_v1 (owner_user_id, updated_at desc);
create table if not exists public.external_entity_links_v1 (
  source_id text not null references public.external_sources_v1(id) on delete cascade,
  entity_type text not null,
  entity_id text not null,
  external_id text,
  sync_state text not null default 'pending',
  needs_review boolean not null default false,
  is_imported boolean not null default true,
  imported_at timestamptz not null default now(),
  last_synced_at timestamptz,
  city_code text,
  locality_code text,
  primary key (source_id, entity_type, entity_id)
);
alter table public.external_entity_links_v1 enable row level security;
drop policy if exists external_entity_links_v1_owner_select on public.external_entity_links_v1;
create policy external_entity_links_v1_owner_select
  on public.external_entity_links_v1
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.external_sources_v1 s
      where s.id = source_id
        and s.owner_user_id = auth.uid()
    )
  );
drop policy if exists external_entity_links_v1_owner_write on public.external_entity_links_v1;
create policy external_entity_links_v1_owner_write
  on public.external_entity_links_v1
  for all
  to authenticated
  using (
    exists (
      select 1
      from public.external_sources_v1 s
      where s.id = source_id
        and s.owner_user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1
      from public.external_sources_v1 s
      where s.id = source_id
        and s.owner_user_id = auth.uid()
    )
  );
create index if not exists idx_external_entity_links_v1_entity
  on public.external_entity_links_v1 (entity_type, entity_id);
create table if not exists public.external_review_queue_v1 (
  id text primary key,
  source_id text not null references public.external_sources_v1(id) on delete cascade,
  owner_user_id uuid references auth.users(id) on delete cascade,
  target_type text not null,
  title text not null,
  summary text not null,
  missing_fields text[] not null default '{}'::text[],
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
alter table public.external_review_queue_v1 enable row level security;
drop policy if exists external_review_queue_v1_owner_select on public.external_review_queue_v1;
create policy external_review_queue_v1_owner_select
  on public.external_review_queue_v1
  for select
  to authenticated
  using (auth.uid() = owner_user_id);
drop policy if exists external_review_queue_v1_owner_write on public.external_review_queue_v1;
create policy external_review_queue_v1_owner_write
  on public.external_review_queue_v1
  for all
  to authenticated
  using (auth.uid() = owner_user_id)
  with check (auth.uid() is not null and auth.uid() = owner_user_id);
create index if not exists idx_external_review_queue_v1_owner_created
  on public.external_review_queue_v1 (owner_user_id, created_at desc);

-- Remote admin observability for external source/signature health.
-- Stores operational health state, not raw signature vectors.

create table if not exists public.external_source_health_v1 (
  id text primary key,
  owner_user_id uuid references public.users(id) on delete cascade,
  source_id text not null,
  provider text not null,
  source_label text,
  entity_type text not null,
  category_label text not null,
  city_code text,
  locality_code text,
  confidence double precision not null default 0,
  freshness double precision not null default 0,
  fallback_rate double precision not null default 0,
  review_needed boolean not null default false,
  sync_state text not null default 'pending',
  health_category text not null default 'weakData',
  summary text not null default '',
  last_sync_at timestamptz,
  last_signature_rebuild_at timestamptz,
  updated_at timestamptz not null default now()
);

alter table public.external_source_health_v1 enable row level security;

drop policy if exists "Owners can read external source health" on public.external_source_health_v1;
create policy "Owners can read external source health" on public.external_source_health_v1
  for select using (auth.uid() = owner_user_id);

drop policy if exists "Owners can write external source health" on public.external_source_health_v1;
create policy "Owners can write external source health" on public.external_source_health_v1
  for all using (auth.uid() = owner_user_id)
  with check (auth.uid() is not null and auth.uid() = owner_user_id);

drop policy if exists "Admins can read external source health" on public.external_source_health_v1;
create policy "Admins can read external source health" on public.external_source_health_v1
  for select using (
    exists (
      select 1
      from public.users
      where users.id = auth.uid() and users.role = 'admin'
    )
  );

create index if not exists idx_external_source_health_v1_updated
  on public.external_source_health_v1 (updated_at desc);

create index if not exists idx_external_source_health_v1_grouping
  on public.external_source_health_v1 (health_category, entity_type, provider, city_code, locality_code);

do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'external_source_health_v1'
  ) then
    alter publication supabase_realtime add table public.external_source_health_v1;
  end if;
end;
$$;

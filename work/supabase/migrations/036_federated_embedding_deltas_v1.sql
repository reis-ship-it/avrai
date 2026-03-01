-- Migration: Federated embedding deltas (v1)
-- Created: 2026-01-01
-- Purpose:
-- - Store privacy-bounded federated "embedding delta" vectors contributed by devices
-- - Support hybrid federated learning:
--   - Pattern 1: offline AI2AI BLE gossip (device-to-device)
--   - Pattern 2: optional cloud aggregation (edge function)
--
-- Notes:
-- - This table is NOT exported to outside buyers.
-- - User-level reads are optional; service role is the primary consumer (aggregation).

create table if not exists public.federated_embedding_deltas_v1 (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade not null,
  category text not null,
  delta double precision[] not null,
  created_at timestamptz not null default now(),
  source text not null default 'edge',
  metadata jsonb not null default '{}'::jsonb
);

create index if not exists idx_federated_embedding_deltas_v1_user_id_created_at
  on public.federated_embedding_deltas_v1(user_id, created_at desc);
create index if not exists idx_federated_embedding_deltas_v1_category_created_at
  on public.federated_embedding_deltas_v1(category, created_at desc);

alter table public.federated_embedding_deltas_v1 enable row level security;

-- Users can insert their own updates (edge function validates shapes as well).
drop policy if exists "Users can insert own federated deltas" on public.federated_embedding_deltas_v1;
create policy "Users can insert own federated deltas"
  on public.federated_embedding_deltas_v1
  for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

-- Optional: allow users to see their own contributed rows (useful for debugging).
drop policy if exists "Users can select own federated deltas" on public.federated_embedding_deltas_v1;
create policy "Users can select own federated deltas"
  on public.federated_embedding_deltas_v1
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

-- Service role can manage all rows (aggregation + monitoring).
drop policy if exists "Service role can manage federated deltas" on public.federated_embedding_deltas_v1;
create policy "Service role can manage federated deltas"
  on public.federated_embedding_deltas_v1
  for all
  using ((select auth.role()) = 'service_role')
  with check ((select auth.role()) = 'service_role');

comment on table public.federated_embedding_deltas_v1 is
  'Federated embedding delta vectors contributed by devices (v1). Used for optional cloud aggregation; not exported.';


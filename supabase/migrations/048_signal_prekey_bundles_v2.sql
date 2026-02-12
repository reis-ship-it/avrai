-- Phase 14 / Signal Protocol: Prekey bundles v2 (owner-keyed, multi-device-ready)
--
-- Problem (v1):
-- - `signal_prekey_bundles.agent_id` was treated as `auth.uid()`, but in SPOTS the
--   “agent id” is NOT the Supabase user UUID (see AgentIdService + secure mapping).
-- - That makes real session establishment fail in production.
--
-- Fix (v2):
-- - Key prekey bundles by **user_id** (auth uid) + **device_id**.
-- - Keep `agent_id` as optional metadata (for diagnostics / future agent-addressed flows),
--   but do not use it for ownership.
-- - Do NOT expose an “open directory” SELECT policy. Fetch for others should be via an
--   eligibility-gated RPC.

create table if not exists public.signal_prekey_bundles_v2 (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  device_id int not null default 1,
  agent_id text,
  prekey_bundle_json jsonb not null,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default (now() + interval '7 days'),
  consumed boolean not null default false,
  consumed_at timestamptz
);

create index if not exists idx_signal_prekey_bundles_v2_user_device_created
  on public.signal_prekey_bundles_v2 (user_id, device_id, created_at desc);

create index if not exists idx_signal_prekey_bundles_v2_expires_at
  on public.signal_prekey_bundles_v2 (expires_at);

create index if not exists idx_signal_prekey_bundles_v2_consumed
  on public.signal_prekey_bundles_v2 (consumed);

-- Unique “active bundle” per user/device (only one unconsumed row at a time).
create unique index if not exists ux_signal_prekey_bundles_v2_active
  on public.signal_prekey_bundles_v2 (user_id, device_id)
  where consumed = false;

alter table public.signal_prekey_bundles_v2 enable row level security;

-- Owner can read their own bundles.
drop policy if exists signal_prekey_bundles_v2_select_own on public.signal_prekey_bundles_v2;
create policy signal_prekey_bundles_v2_select_own
  on public.signal_prekey_bundles_v2
  for select
  to authenticated
  using (auth.uid() = user_id);

-- Owner can insert their own bundles.
drop policy if exists signal_prekey_bundles_v2_insert_own on public.signal_prekey_bundles_v2;
create policy signal_prekey_bundles_v2_insert_own
  on public.signal_prekey_bundles_v2
  for insert
  to authenticated
  with check (auth.uid() = user_id);

-- Owner can update their own bundles (e.g., mark consumed).
drop policy if exists signal_prekey_bundles_v2_update_own on public.signal_prekey_bundles_v2;
create policy signal_prekey_bundles_v2_update_own
  on public.signal_prekey_bundles_v2
  for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Cleanup helper (called by cron if desired).
create or replace function public.cleanup_expired_signal_prekey_bundles_v2()
returns void
language plpgsql
as $$
begin
  delete from public.signal_prekey_bundles_v2
  where expires_at < now() - interval '1 day';
end;
$$;

comment on table public.signal_prekey_bundles_v2 is
  'Signal prekey bundles keyed by user_id + device_id (v2). Fetch for others must be via eligibility-gated RPC, not open SELECT.';

comment on column public.signal_prekey_bundles_v2.user_id is 'Supabase auth user id (ownership).';
comment on column public.signal_prekey_bundles_v2.device_id is 'Per-install device id (multi-device).';
comment on column public.signal_prekey_bundles_v2.agent_id is 'Optional SPOTS agent id (metadata only; not ownership).';


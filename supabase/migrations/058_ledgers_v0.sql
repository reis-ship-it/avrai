-- Ledgers (v0): shared append-only journal + canonical "current" view
--
-- Design goals:
-- - Strict append-only for authenticated users (no UPDATE/DELETE policies)
-- - Modifiable via revisions (amend/void/restate are new rows)
-- - One shared schema for multiple logical ledgers (domain column)
-- - Optional multi-party read access via audience grants (service-role minted)
--
-- Related docs:
-- - docs/plans/ledgers/LEDGER_SYSTEM_V0.md
-- - docs/plans/ledgers/LEDGER_EVENT_CATALOG_V0.md

create table if not exists public.ledger_events_v0 (
  id uuid primary key default gen_random_uuid(),

  -- Which logical ledger this event belongs to.
  -- Keeping one shared table avoids schema drift while still allowing domain-specific views.
  domain text not null check (
    domain in (
      'expertise',
      'payments',
      'moderation',
      'identity',
      'security',
      'geo_expansion',
      'model_lifecycle',
      'data_export',
      'device_capability'
    )
  ),

  -- Ownership for RLS (align with user_id-based RLS migrations).
  owner_user_id uuid not null references auth.users(id) on delete cascade,

  -- Privacy-safe routing identifier (stored but NOT used for RLS).
  owner_agent_id text not null,

  -- Revision chain
  logical_id uuid not null,
  revision int not null check (revision >= 0),
  supersedes_id uuid references public.ledger_events_v0(id) on delete restrict,

  -- Operation semantics (append-only corrections)
  op text not null check (op in ('assert', 'amend', 'void', 'restate')),

  -- Classification
  event_type text not null,
  entity_type text,
  entity_id text,
  category text,

  -- Optional geo scope (used heavily by expertise/events/community expansion)
  city_code text,
  locality_code text,

  -- Core timestamps
  occurred_at timestamptz not null,
  atomic_timestamp_id text,

  -- Flexible payload
  payload jsonb not null default '{}'::jsonb,

  created_at timestamptz not null default now()
);

-- Uniqueness of revision numbering per logical event
create unique index if not exists ux_ledger_v0_logical_revision
  on public.ledger_events_v0 (logical_id, revision);

-- Fast lookup by owner + time
create index if not exists idx_ledger_v0_owner_time
  on public.ledger_events_v0 (owner_user_id, occurred_at desc);

-- Fast lookup by domain + time
create index if not exists idx_ledger_v0_domain_time
  on public.ledger_events_v0 (domain, occurred_at desc);

-- Fast lookup by domain + type
create index if not exists idx_ledger_v0_domain_type_time
  on public.ledger_events_v0 (domain, event_type, occurred_at desc);

-- Fast lookup by entity
create index if not exists idx_ledger_v0_entity_time
  on public.ledger_events_v0 (entity_type, entity_id, occurred_at desc);

comment on table public.ledger_events_v0 is
  'v0 shared append-only ledger journal (multiple logical ledgers via domain).';

-- Canonical view: latest revision per logical_id (derived "current truth")
create or replace view public.ledger_current_v0 as
select distinct on (logical_id)
  *
from public.ledger_events_v0
order by logical_id, revision desc, created_at desc;

-- Optional: audience grants for legitimate multi-party visibility (partnerships, communities).
create table if not exists public.ledger_audience_v0 (
  ledger_row_id uuid not null references public.ledger_events_v0(id) on delete cascade,
  audience_user_id uuid not null references auth.users(id) on delete cascade,
  granted_at timestamptz not null default now(),
  granted_by text not null check (granted_by in ('service_role', 'system')),
  primary key (ledger_row_id, audience_user_id)
);

comment on table public.ledger_audience_v0 is
  'v0 ledger audience grants for multi-party read access (recommended: service-role only writes).';

-- ============================================================================
-- RLS: strict append-only for authenticated users
-- ============================================================================

alter table public.ledger_events_v0 enable row level security;
alter table public.ledger_audience_v0 enable row level security;

-- Read: user can read rows they own OR rows granted to them via ledger_audience_v0.
drop policy if exists ledger_events_v0_select_own_or_audience on public.ledger_events_v0;
create policy ledger_events_v0_select_own_or_audience
  on public.ledger_events_v0
  for select
  to authenticated
  using (
    (select auth.uid()) = owner_user_id
    or exists (
      select 1
      from public.ledger_audience_v0 aud
      where aud.ledger_row_id = public.ledger_events_v0.id
        and aud.audience_user_id = (select auth.uid())
    )
  );

-- Insert: user can insert rows they own.
-- Optional strictness: if supersedes_id is present, it must point to a row the user owns
-- AND it must match the same logical_id.
drop policy if exists ledger_events_v0_insert_own_strict on public.ledger_events_v0;
create policy ledger_events_v0_insert_own_strict
  on public.ledger_events_v0
  for insert
  to authenticated
  with check (
    (select auth.uid()) = owner_user_id
    and (
      supersedes_id is null
      or exists (
        select 1
        from public.ledger_events_v0 prev
        where prev.id = supersedes_id
          and prev.owner_user_id = (select auth.uid())
          and prev.logical_id = public.ledger_events_v0.logical_id
      )
    )
  );

-- No UPDATE / DELETE policies: strict append-only by default-deny.

-- Audience table: user can read grants addressed to them.
drop policy if exists ledger_audience_v0_select_own on public.ledger_audience_v0;
create policy ledger_audience_v0_select_own
  on public.ledger_audience_v0
  for select
  to authenticated
  using ((select auth.uid()) = audience_user_id);

-- Audience writes should be service role only (server-side validation).
drop policy if exists ledger_audience_v0_service_role_all on public.ledger_audience_v0;
create policy ledger_audience_v0_service_role_all
  on public.ledger_audience_v0
  for all
  using ((select auth.role()) = 'service_role')
  with check ((select auth.role()) = 'service_role');

-- Service role: internal pipelines can read/insert/update/delete if absolutely necessary.
drop policy if exists ledger_events_v0_service_role_all on public.ledger_events_v0;
create policy ledger_events_v0_service_role_all
  on public.ledger_events_v0
  for all
  using ((select auth.role()) = 'service_role')
  with check ((select auth.role()) = 'service_role');

-- ============================================================================
-- Domain-specific "ledger surfaces" (views)
-- These make each logical ledger feel like its own object in Supabase.
-- ============================================================================

create or replace view public.ledger_expertise_events_v0 as
select * from public.ledger_events_v0 where domain = 'expertise';

create or replace view public.ledger_expertise_current_v0 as
select * from public.ledger_current_v0 where domain = 'expertise';

create or replace view public.ledger_payments_events_v0 as
select * from public.ledger_events_v0 where domain = 'payments';

create or replace view public.ledger_payments_current_v0 as
select * from public.ledger_current_v0 where domain = 'payments';

create or replace view public.ledger_moderation_events_v0 as
select * from public.ledger_events_v0 where domain = 'moderation';

create or replace view public.ledger_moderation_current_v0 as
select * from public.ledger_current_v0 where domain = 'moderation';

create or replace view public.ledger_identity_events_v0 as
select * from public.ledger_events_v0 where domain = 'identity';

create or replace view public.ledger_identity_current_v0 as
select * from public.ledger_current_v0 where domain = 'identity';

create or replace view public.ledger_security_events_v0 as
select * from public.ledger_events_v0 where domain = 'security';

create or replace view public.ledger_security_current_v0 as
select * from public.ledger_current_v0 where domain = 'security';

create or replace view public.ledger_geo_expansion_events_v0 as
select * from public.ledger_events_v0 where domain = 'geo_expansion';

create or replace view public.ledger_geo_expansion_current_v0 as
select * from public.ledger_current_v0 where domain = 'geo_expansion';

create or replace view public.ledger_model_lifecycle_events_v0 as
select * from public.ledger_events_v0 where domain = 'model_lifecycle';

create or replace view public.ledger_model_lifecycle_current_v0 as
select * from public.ledger_current_v0 where domain = 'model_lifecycle';

create or replace view public.ledger_data_export_events_v0 as
select * from public.ledger_events_v0 where domain = 'data_export';

create or replace view public.ledger_data_export_current_v0 as
select * from public.ledger_current_v0 where domain = 'data_export';

create or replace view public.ledger_device_capability_events_v0 as
select * from public.ledger_events_v0 where domain = 'device_capability';

create or replace view public.ledger_device_capability_current_v0 as
select * from public.ledger_current_v0 where domain = 'device_capability';


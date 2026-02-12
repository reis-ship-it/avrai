-- Ledgers (v0): signed receipts (tamper-evident)
--
-- Adds:
-- - public.ledger_receipt_signatures_v0: server-minted signatures over canonical ledger rows
-- - public.ledger_receipts_v0: convenience view (ledger row + optional signature)
--
-- Philosophy: doors must be truthful (receipts), not vibes.
--
-- Related docs:
-- - docs/plans/ledgers/LEDGER_SYSTEM_V0.md
-- - docs/plans/ledgers/LEDGER_EVENT_CATALOG_V0.md
--
-- Notes:
-- - Ledger rows remain strictly append-only (no UPDATE/DELETE for authenticated users).
-- - Signatures are written by service-role code (edge functions / pipelines).
-- - Users can read a signature only if they can read the underlying ledger row
--   (owner or audience grant).

-- Helper to check whether a user can read a ledger row, without RLS recursion.
-- SECURITY DEFINER is used to bypass RLS and evaluate against base tables directly.
create or replace function public.ledger_v0_can_read_row(
  target_row_id uuid,
  target_user_id uuid
)
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.ledger_events_v0 le
    where le.id = target_row_id
      and (
        le.owner_user_id = target_user_id
        or exists (
          select 1
          from public.ledger_audience_v0 aud
          where aud.ledger_row_id = le.id
            and aud.audience_user_id = target_user_id
        )
      )
  );
$$;

revoke all on function public.ledger_v0_can_read_row(uuid, uuid) from public;
grant execute on function public.ledger_v0_can_read_row(uuid, uuid) to authenticated;

-- Signature table (one signature per ledger row id)
create table if not exists public.ledger_receipt_signatures_v0 (
  ledger_row_id uuid primary key references public.ledger_events_v0(id) on delete cascade,

  schema_version int not null default 0,
  canon_algo text not null default 'v0_sorted_keys_json',
  canonical_json text not null,
  sha256 text not null,
  signature_b64 text not null,
  key_id text not null,
  signed_at timestamptz not null default now(),

  created_at timestamptz not null default now()
);

comment on table public.ledger_receipt_signatures_v0 is
  'v0 signatures over canonical ledger rows (tamper-evident receipts).';

create index if not exists idx_ledger_receipt_sig_key_id_signed_at
  on public.ledger_receipt_signatures_v0 (key_id, signed_at desc);

alter table public.ledger_receipt_signatures_v0 enable row level security;

-- Read: allowed only if user can read the underlying ledger row.
drop policy if exists ledger_receipt_signatures_v0_select_can_read_row on public.ledger_receipt_signatures_v0;
create policy ledger_receipt_signatures_v0_select_can_read_row
  on public.ledger_receipt_signatures_v0
  for select
  to authenticated
  using (public.ledger_v0_can_read_row(ledger_row_id, auth.uid()));

-- Writes should be service-role only (server-side).
drop policy if exists ledger_receipt_signatures_v0_service_role_all on public.ledger_receipt_signatures_v0;
create policy ledger_receipt_signatures_v0_service_role_all
  on public.ledger_receipt_signatures_v0
  for all
  using ((select auth.role()) = 'service_role')
  with check ((select auth.role()) = 'service_role');

-- Convenience view: ledger row + optional signature (NULL when unsigned).
create or replace view public.ledger_receipts_v0 as
select
  le.*,
  sig.schema_version as receipt_schema_version,
  sig.canon_algo,
  sig.canonical_json,
  sig.sha256,
  sig.signature_b64,
  sig.key_id,
  sig.signed_at
from public.ledger_events_v0 le
left join public.ledger_receipt_signatures_v0 sig
  on sig.ledger_row_id = le.id;


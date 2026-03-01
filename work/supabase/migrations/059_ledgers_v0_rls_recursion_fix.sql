-- Fix RLS recursion for ledger_events_v0 insert policy
--
-- The original insert policy referenced public.ledger_events_v0 inside its own WITH CHECK
-- to validate supersedes_id ownership. Postgres detects this as infinite recursion.
--
-- We move that check into a SECURITY DEFINER helper (owned by postgres in migrations),
-- which bypasses RLS and avoids recursive policy evaluation.

create or replace function public.ledger_v0_can_supersede(
  prev_id uuid,
  expected_owner uuid,
  expected_logical uuid
)
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.ledger_events_v0 prev
    where prev.id = prev_id
      and prev.owner_user_id = expected_owner
      and prev.logical_id = expected_logical
  );
$$;

revoke all on function public.ledger_v0_can_supersede(uuid, uuid, uuid) from public;
grant execute on function public.ledger_v0_can_supersede(uuid, uuid, uuid) to authenticated;

drop policy if exists ledger_events_v0_insert_own_strict on public.ledger_events_v0;
create policy ledger_events_v0_insert_own_strict
  on public.ledger_events_v0
  for insert
  to authenticated
  with check (
    auth.uid() = owner_user_id
    and (
      supersedes_id is null
      or public.ledger_v0_can_supersede(
        supersedes_id,
        auth.uid(),
        public.ledger_events_v0.logical_id
      )
    )
  );


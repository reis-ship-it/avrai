-- Phase 14 / Community Sender Key rotation + stream gating by active key
--
-- Enables:
-- - Sender key rotation (UPDATE community_sender_key_state.key_id)
-- - Stream gating that requires membership row to match the active key_id
--
-- Rationale:
-- - After rotation, members must "rejoin" by decrypting their new key share and
--   upserting community_memberships with the new key_id.
-- - This prevents stale-key members from receiving new events they can't decrypt.

alter table public.community_sender_key_state
  add column if not exists updated_at timestamptz not null default now();

-- Allow the original creator to rotate (update) the active key id.
drop policy if exists community_sender_key_state_update_creator on public.community_sender_key_state;
create policy community_sender_key_state_update_creator
  on public.community_sender_key_state
  for update
  to authenticated
  using (auth.uid() is not null and auth.uid() = created_by)
  with check (auth.uid() is not null and auth.uid() = created_by);

-- Maintain updated_at on key rotations (best-effort; client also sets updated_at via default).
-- NOTE: Supabase SQL editor might not allow create trigger without additional privileges in some setups.
-- For MVP, we rely on the client to only update key_id; updated_at can be updated by the client as well.

-- Tighten stream gating: membership must match the active key.
drop policy if exists community_message_events_select_member on public.community_message_events;
create policy community_message_events_select_member
  on public.community_message_events
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.community_memberships m
      join public.community_sender_key_state s
        on s.community_id = m.community_id
      where m.community_id = community_message_events.community_id
        and m.user_id = auth.uid()
        and m.key_id = s.key_id
    )
  );

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
      join public.community_sender_key_state s
        on s.community_id = m.community_id
      where m.community_id = community_message_events.community_id
        and m.user_id = auth.uid()
        and m.key_id = s.key_id
    )
  );


-- Phase 14 / Community Sender Key rotation: grace window + seamless member continuity
--
-- Goal:
-- - Preserve privacy/security (rotate sender key) without creating user-visible "rejoin" friction.
-- - Members who were valid *before* rotation should keep receiving the community stream during
--   a short grace window, so the client can silently fetch/decrypt the new key share and
--   upsert `community_memberships.key_id` to the active key.
--
-- Design:
-- - `community_sender_key_state` tracks:
--   - `key_id`: current active sender key id
--   - `previous_key_id`: prior active key id (optional)
--   - `grace_expires_at`: window during which `previous_key_id` is accepted for stream gating
-- - RLS gate for `community_message_events` allows membership key_id to match:
--   - active key_id, OR
--   - previous_key_id *while* grace window is still valid
--
-- Security notes:
-- - "Hard" rotations (revocations) should set `grace_expires_at` NULL (or <= now()) and avoid
--   sharing the new key to removed members, immediately cutting off access.

alter table public.community_sender_key_state
  add column if not exists previous_key_id uuid,
  add column if not exists grace_expires_at timestamptz;

-- Stream gating: allow active key or (previous key within grace window).
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
        and (
          m.key_id = s.key_id
          or (
            s.previous_key_id is not null
            and s.grace_expires_at is not null
            and now() < s.grace_expires_at
            and m.key_id = s.previous_key_id
          )
        )
    )
  );

-- Insert gating: mirror select gating so send continues seamlessly during grace,
-- while still requiring the sender to be an authenticated member.
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
        and (
          m.key_id = s.key_id
          or (
            s.previous_key_id is not null
            and s.grace_expires_at is not null
            and now() < s.grace_expires_at
            and m.key_id = s.previous_key_id
          )
        )
    )
  );


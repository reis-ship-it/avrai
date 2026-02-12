-- Phase 14 / Community Chat: allow community members to fetch message blobs
--
-- Problem:
-- - The newer "single community stream" design delivers only `message_id` via
--   `public.community_message_events` (RLS-gated).
-- - Clients then fetch ciphertext from `public.community_message_blobs` by `message_id`.
-- - Prior RLS limited blob reads to per-user notifications (`community_message_notifications`),
--   but the community stream no longer fan-outs notifications per member.
--
-- Fix:
-- - Gate blob SELECT/INSERT by community membership + sender-key epoch eligibility.
-- - Mirror the same active/previous-with-grace logic used for `community_message_events`.

-- Allow members to read ciphertext blobs for their communities (active key or previous key in grace).
drop policy if exists community_message_blobs_select_by_notification on public.community_message_blobs;
drop policy if exists community_message_blobs_select_member on public.community_message_blobs;
create policy community_message_blobs_select_member
  on public.community_message_blobs
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.community_memberships m
      join public.community_sender_key_state s
        on s.community_id = m.community_id
      where m.community_id = community_message_blobs.community_id
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

-- Restrict blob INSERT to authenticated members of the community (active key or previous key in grace).
drop policy if exists community_message_blobs_insert_sender on public.community_message_blobs;
drop policy if exists community_message_blobs_insert_member on public.community_message_blobs;
create policy community_message_blobs_insert_member
  on public.community_message_blobs
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
      where m.community_id = community_message_blobs.community_id
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


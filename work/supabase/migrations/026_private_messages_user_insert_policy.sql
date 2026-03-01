-- Phase 14 / Hybrid Chat Transport
-- Enable authenticated clients to insert DM mailbox messages into `public.private_messages`.
--
-- IMPORTANT:
-- - Payloads are end-to-end encrypted (Signal/AES) at the application layer.
-- - RLS ensures only recipients can read their mailbox rows.
-- - This policy allows any authenticated user to insert messages to any recipient.
--   Abuse/spam controls should be layered in later (rate limits, block lists, allow lists).

alter table public.private_messages enable row level security;

-- Allow authenticated users to insert messages, but require they truthfully claim their auth uid.
-- The app writes payload.from_user_id = auth.uid() as a basic anti-spoof measure.
drop policy if exists private_messages_insert_authenticated on public.private_messages;
create policy private_messages_insert_authenticated
  on public.private_messages
  for insert
  to authenticated
  with check (
    auth.uid() is not null
    and (payload->'metadata'->>'from_user_id') is not null
    and (payload->'metadata'->>'from_user_id')::uuid = auth.uid()
  );

-- Allow recipients to delete their own mailbox rows (optional cleanup).
drop policy if exists private_messages_delete_own on public.private_messages;
create policy private_messages_delete_own
  on public.private_messages
  for delete
  to authenticated
  using (auth.uid() = to_user_id);


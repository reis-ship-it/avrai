-- Phase 14 / Hybrid Chat Transport (Big Win: payloadless realtime)
--
-- Goal:
-- - Realtime notifications contain only a message_id (minimal metadata)
-- - Ciphertext is stored separately and fetched by recipients ("mailbox/pull")
-- - RLS restricts access so only recipient can read ciphertext rows
--
-- Tables:
-- 1) dm_message_blobs: stores ciphertext + minimal routing info
-- 2) dm_notifications: per-recipient notification rows (realtime-enabled)

create table if not exists public.dm_message_blobs (
  message_id uuid primary key,
  from_user_id uuid not null references auth.users(id) on delete cascade,
  to_user_id uuid not null references auth.users(id) on delete cascade,
  sender_agent_id text not null,
  recipient_agent_id text not null,
  encryption_type text not null,
  ciphertext_base64 text not null,
  sent_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

alter table public.dm_message_blobs enable row level security;

-- Only recipient can read ciphertext
drop policy if exists dm_message_blobs_select_recipient on public.dm_message_blobs;
create policy dm_message_blobs_select_recipient
  on public.dm_message_blobs
  for select
  to authenticated
  using (auth.uid() = to_user_id);

-- Sender can insert, but must claim their real auth uid.
drop policy if exists dm_message_blobs_insert_sender on public.dm_message_blobs;
create policy dm_message_blobs_insert_sender
  on public.dm_message_blobs
  for insert
  to authenticated
  with check (
    auth.uid() is not null
    and auth.uid() = from_user_id
  );

-- Optional cleanup: recipient can delete their own ciphertext rows
drop policy if exists dm_message_blobs_delete_recipient on public.dm_message_blobs;
create policy dm_message_blobs_delete_recipient
  on public.dm_message_blobs
  for delete
  to authenticated
  using (auth.uid() = to_user_id);

create index if not exists idx_dm_message_blobs_to_user_id_created_at
  on public.dm_message_blobs (to_user_id, created_at desc);

create table if not exists public.dm_notifications (
  id bigserial primary key,
  to_user_id uuid not null references auth.users(id) on delete cascade,
  message_id uuid not null references public.dm_message_blobs(message_id) on delete cascade,
  created_at timestamptz not null default now()
);

alter table public.dm_notifications enable row level security;

-- Only recipient can read notifications
drop policy if exists dm_notifications_select_recipient on public.dm_notifications;
create policy dm_notifications_select_recipient
  on public.dm_notifications
  for select
  to authenticated
  using (auth.uid() = to_user_id);

-- Any authenticated user may insert a notification for a recipient,
-- but only if they are also the sender of the referenced blob.
--
-- This ties the notification to the blob row, preventing spoofed message_id fanout.
drop policy if exists dm_notifications_insert_sender on public.dm_notifications;
create policy dm_notifications_insert_sender
  on public.dm_notifications
  for insert
  to authenticated
  with check (
    auth.uid() is not null
    and exists (
      select 1
      from public.dm_message_blobs b
      where b.message_id = dm_notifications.message_id
        and b.from_user_id = auth.uid()
        and b.to_user_id = dm_notifications.to_user_id
    )
  );

-- Optional cleanup: recipient can delete their own notifications
drop policy if exists dm_notifications_delete_recipient on public.dm_notifications;
create policy dm_notifications_delete_recipient
  on public.dm_notifications
  for delete
  to authenticated
  using (auth.uid() = to_user_id);

create index if not exists idx_dm_notifications_to_user_id_created_at
  on public.dm_notifications (to_user_id, created_at desc);

-- Realtime changefeed support
alter publication supabase_realtime add table public.dm_notifications;


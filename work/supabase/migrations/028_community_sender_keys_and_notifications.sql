-- Phase 14 / Community Chat Sender Keys (scalable fanout)
--
-- Goals:
-- - Encrypt each community message ONCE with a shared "sender key" (AES-256-GCM).
-- - Distribute/rotate that sender key via Signal-encrypted key shares (rare, not per message).
-- - Deliver payloadless realtime notifications: notification rows only contain message_id.
-- - Store ciphertext separately and fetch by message_id (mailbox/pull).
--
-- Note:
-- - `community_id` is TEXT to match app model ids (not guaranteed UUID in DB).
-- - Membership enforcement is application-level for MVP; RLS limits reads by notification ownership.

create table if not exists public.community_sender_key_state (
  community_id text primary key,
  key_id uuid not null,
  created_by uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

alter table public.community_sender_key_state enable row level security;

-- Any authenticated user may read key state (contains only key_id, no secret material).
drop policy if exists community_sender_key_state_select_authenticated on public.community_sender_key_state;
create policy community_sender_key_state_select_authenticated
  on public.community_sender_key_state
  for select
  to authenticated
  using (auth.uid() is not null);

-- Any authenticated user may create key state for a community.
-- Conflicts are handled by application (insert-once, then read existing).
drop policy if exists community_sender_key_state_insert_creator on public.community_sender_key_state;
create policy community_sender_key_state_insert_creator
  on public.community_sender_key_state
  for insert
  to authenticated
  with check (
    auth.uid() is not null
    and auth.uid() = created_by
  );

create table if not exists public.community_sender_key_shares (
  community_id text not null,
  key_id uuid not null,
  to_user_id uuid not null references auth.users(id) on delete cascade,
  from_user_id uuid not null references auth.users(id) on delete cascade,
  sender_agent_id text not null,
  encryption_type text not null,
  encrypted_key_base64 text not null,
  created_at timestamptz not null default now(),
  primary key (key_id, to_user_id)
);

alter table public.community_sender_key_shares enable row level security;

-- Only the recipient can read their key share
drop policy if exists community_sender_key_shares_select_recipient on public.community_sender_key_shares;
create policy community_sender_key_shares_select_recipient
  on public.community_sender_key_shares
  for select
  to authenticated
  using (auth.uid() = to_user_id);

-- Sender can insert shares for a key_id that exists in key state.
drop policy if exists community_sender_key_shares_insert_sender on public.community_sender_key_shares;
create policy community_sender_key_shares_insert_sender
  on public.community_sender_key_shares
  for insert
  to authenticated
  with check (
    auth.uid() is not null
    and auth.uid() = from_user_id
    and exists (
      select 1
      from public.community_sender_key_state s
      where s.community_id = community_sender_key_shares.community_id
        and s.key_id = community_sender_key_shares.key_id
    )
  );

create index if not exists idx_community_sender_key_shares_to_user_created_at
  on public.community_sender_key_shares (to_user_id, created_at desc);

create table if not exists public.community_message_blobs (
  message_id uuid primary key,
  community_id text not null,
  sender_user_id uuid not null references auth.users(id) on delete cascade,
  sender_agent_id text not null,
  key_id uuid not null,
  algorithm text not null,
  ciphertext_base64 text not null,
  sent_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

alter table public.community_message_blobs enable row level security;

-- Sender can insert their own blobs
drop policy if exists community_message_blobs_insert_sender on public.community_message_blobs;
create policy community_message_blobs_insert_sender
  on public.community_message_blobs
  for insert
  to authenticated
  with check (
    auth.uid() is not null
    and auth.uid() = sender_user_id
  );

create table if not exists public.community_message_notifications (
  id bigserial primary key,
  to_user_id uuid not null references auth.users(id) on delete cascade,
  message_id uuid not null references public.community_message_blobs(message_id) on delete cascade,
  created_at timestamptz not null default now()
);

alter table public.community_message_notifications enable row level security;

-- Only recipient can read notifications
drop policy if exists community_message_notifications_select_recipient on public.community_message_notifications;
create policy community_message_notifications_select_recipient
  on public.community_message_notifications
  for select
  to authenticated
  using (auth.uid() = to_user_id);

-- Sender can notify any recipient, but only for a blob they authored.
drop policy if exists community_message_notifications_insert_sender on public.community_message_notifications;
create policy community_message_notifications_insert_sender
  on public.community_message_notifications
  for insert
  to authenticated
  with check (
    auth.uid() is not null
    and exists (
      select 1
      from public.community_message_blobs b
      where b.message_id = community_message_notifications.message_id
        and b.sender_user_id = auth.uid()
    )
  );

-- Recipient can fetch blobs only if they have a notification row for them.
drop policy if exists community_message_blobs_select_by_notification on public.community_message_blobs;
create policy community_message_blobs_select_by_notification
  on public.community_message_blobs
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.community_message_notifications n
      where n.message_id = community_message_blobs.message_id
        and n.to_user_id = auth.uid()
    )
  );

-- Optional cleanup: recipient can delete their notifications
drop policy if exists community_message_notifications_delete_recipient on public.community_message_notifications;
create policy community_message_notifications_delete_recipient
  on public.community_message_notifications
  for delete
  to authenticated
  using (auth.uid() = to_user_id);

-- Optional cleanup: recipient can delete blobs once read (only if notified)
drop policy if exists community_message_blobs_delete_by_notification on public.community_message_blobs;
create policy community_message_blobs_delete_by_notification
  on public.community_message_blobs
  for delete
  to authenticated
  using (
    exists (
      select 1
      from public.community_message_notifications n
      where n.message_id = community_message_blobs.message_id
        and n.to_user_id = auth.uid()
    )
  );

create index if not exists idx_community_message_blobs_community_created_at
  on public.community_message_blobs (community_id, created_at desc);

create index if not exists idx_community_message_notifications_to_user_created_at
  on public.community_message_notifications (to_user_id, created_at desc);

-- Realtime notifications table
alter publication supabase_realtime add table public.community_message_notifications;


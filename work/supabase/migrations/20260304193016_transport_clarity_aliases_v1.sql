-- Supabase naming clarity + compatibility aliases for transport layers.
--
-- Canonical naming:
-- - dm_transport_blobs / dm_transport_notifications
-- - dm_transport_enqueue_v1 / dm_transport_notify_v1
-- - wormhole_message_queue
--
-- This migration is intentionally non-breaking: legacy names remain valid.

create or replace view public.dm_transport_blobs as
select * from public.dm_message_blobs;
comment on view public.dm_transport_blobs is
  'Canonical transport view over dm_message_blobs (legacy physical table).';
create or replace view public.dm_transport_notifications as
select * from public.dm_notifications;
comment on view public.dm_transport_notifications is
  'Canonical transport view over dm_notifications (legacy physical table).';
create or replace function public.dm_transport_enqueue_v1(
  p_message_id uuid,
  p_from_user_id uuid,
  p_to_user_id uuid,
  p_sender_agent_id text,
  p_recipient_agent_id text,
  p_encryption_type text,
  p_ciphertext_base64 text,
  p_sent_at timestamptz default now(),
  p_recipient_device_id text default 'legacy'
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  has_recipient_device_id boolean;
begin
  if auth.uid() is null then
    raise exception 'unauthenticated';
  end if;

  if auth.uid() <> p_from_user_id then
    raise exception 'sender mismatch';
  end if;

  if p_message_id is null or p_to_user_id is null then
    raise exception 'message_id and to_user_id are required';
  end if;

  select exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'dm_message_blobs'
      and column_name = 'recipient_device_id'
  )
  into has_recipient_device_id;

  if has_recipient_device_id then
    insert into public.dm_message_blobs (
      message_id,
      from_user_id,
      to_user_id,
      sender_agent_id,
      recipient_agent_id,
      encryption_type,
      ciphertext_base64,
      sent_at,
      recipient_device_id
    )
    values (
      p_message_id,
      p_from_user_id,
      p_to_user_id,
      p_sender_agent_id,
      p_recipient_agent_id,
      p_encryption_type,
      p_ciphertext_base64,
      p_sent_at,
      coalesce(nullif(p_recipient_device_id, ''), 'legacy')
    );
  else
    insert into public.dm_message_blobs (
      message_id,
      from_user_id,
      to_user_id,
      sender_agent_id,
      recipient_agent_id,
      encryption_type,
      ciphertext_base64,
      sent_at
    )
    values (
      p_message_id,
      p_from_user_id,
      p_to_user_id,
      p_sender_agent_id,
      p_recipient_agent_id,
      p_encryption_type,
      p_ciphertext_base64,
      p_sent_at
    );
  end if;

  insert into public.dm_notifications (
    to_user_id,
    message_id
  )
  values (
    p_to_user_id,
    p_message_id
  );
end;
$$;
revoke all on function public.dm_transport_enqueue_v1(
  uuid, uuid, uuid, text, text, text, text, timestamptz, text
) from public;
grant execute on function public.dm_transport_enqueue_v1(
  uuid, uuid, uuid, text, text, text, text, timestamptz, text
) to authenticated;
create or replace function public.dm_transport_notify_v1(
  p_to_user_id uuid,
  p_message_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'unauthenticated';
  end if;

  if not exists (
    select 1
    from public.dm_message_blobs b
    where b.message_id = p_message_id
      and b.from_user_id = auth.uid()
      and b.to_user_id = p_to_user_id
  ) then
    raise exception 'message not owned by sender or recipient mismatch';
  end if;

  insert into public.dm_notifications (
    to_user_id,
    message_id
  )
  values (
    p_to_user_id,
    p_message_id
  );
end;
$$;
revoke all on function public.dm_transport_notify_v1(uuid, uuid) from public;
grant execute on function public.dm_transport_notify_v1(uuid, uuid) to authenticated;
create or replace function public.enqueue_dm_message_v1(
  p_message_id uuid,
  p_from_user_id uuid,
  p_to_user_id uuid,
  p_sender_agent_id text,
  p_recipient_agent_id text,
  p_encryption_type text,
  p_ciphertext_base64 text,
  p_sent_at timestamptz default now(),
  p_recipient_device_id text default 'legacy'
)
returns void
language sql
security definer
set search_path = public
as $$
  select public.dm_transport_enqueue_v1(
    p_message_id,
    p_from_user_id,
    p_to_user_id,
    p_sender_agent_id,
    p_recipient_agent_id,
    p_encryption_type,
    p_ciphertext_base64,
    p_sent_at,
    p_recipient_device_id
  );
$$;
revoke all on function public.enqueue_dm_message_v1(
  uuid, uuid, uuid, text, text, text, text, timestamptz, text
) from public;
grant execute on function public.enqueue_dm_message_v1(
  uuid, uuid, uuid, text, text, text, text, timestamptz, text
) to authenticated;
create or replace function public.enqueue_dm_notification_v1(
  p_to_user_id uuid,
  p_message_id uuid
)
returns void
language sql
security definer
set search_path = public
as $$
  select public.dm_transport_notify_v1(
    p_to_user_id,
    p_message_id
  );
$$;
revoke all on function public.enqueue_dm_notification_v1(uuid, uuid) from public;
grant execute on function public.enqueue_dm_notification_v1(uuid, uuid) to authenticated;
do $$
begin
  if exists (
    select 1
    from information_schema.tables
    where table_schema = 'public'
      and table_name = 'ai2ai_message_queue'
  ) then
    execute 'create or replace view public.wormhole_message_queue as select * from public.ai2ai_message_queue';
    execute $sql$
      comment on view public.wormhole_message_queue is
      'Canonical wormhole/DTN queue view over ai2ai_message_queue (legacy physical table).'
    $sql$;
  end if;
end;
$$;
create or replace function public.mark_expired_wormhole_messages()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if exists (
    select 1
    from pg_proc
    where pronamespace = 'public'::regnamespace
      and proname = 'mark_expired_ai2ai_messages'
  ) then
    perform public.mark_expired_ai2ai_messages();
  end if;
end;
$$;
revoke all on function public.mark_expired_wormhole_messages() from public;
grant execute on function public.mark_expired_wormhole_messages() to authenticated;
create or replace function public.cleanup_expired_wormhole_messages()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if exists (
    select 1
    from pg_proc
    where pronamespace = 'public'::regnamespace
      and proname = 'cleanup_expired_ai2ai_messages'
  ) then
    perform public.cleanup_expired_ai2ai_messages();
  end if;
end;
$$;
revoke all on function public.cleanup_expired_wormhole_messages() from public;
grant execute on function public.cleanup_expired_wormhole_messages() to authenticated;

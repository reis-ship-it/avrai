create or replace function public.dm_transport_consume_v1(
  p_message_id uuid,
  p_to_user_id uuid,
  p_recipient_device_id text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  has_recipient_device_id boolean;
  normalized_recipient_device_id text;
  deleted_blob_count integer := 0;
  deleted_notification_count integer := 0;
  remaining_blob_count integer := 0;
begin
  if auth.uid() is null then
    raise exception 'unauthenticated';
  end if;

  if auth.uid() <> p_to_user_id then
    raise exception 'recipient mismatch';
  end if;

  if p_message_id is null or p_to_user_id is null then
    raise exception 'message_id and to_user_id are required';
  end if;

  normalized_recipient_device_id := nullif(trim(coalesce(p_recipient_device_id, '')), '');

  select exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'dm_message_blobs'
      and column_name = 'recipient_device_id'
  )
  into has_recipient_device_id;

  if has_recipient_device_id and normalized_recipient_device_id is not null then
    delete from public.dm_message_blobs
    where message_id = p_message_id
      and to_user_id = p_to_user_id
      and recipient_device_id = normalized_recipient_device_id;
    get diagnostics deleted_blob_count = row_count;
  else
    delete from public.dm_message_blobs
    where message_id = p_message_id
      and to_user_id = p_to_user_id;
    get diagnostics deleted_blob_count = row_count;
  end if;

  select count(*)
  into remaining_blob_count
  from public.dm_message_blobs
  where message_id = p_message_id
    and to_user_id = p_to_user_id;

  if remaining_blob_count = 0 then
    delete from public.dm_notifications
    where message_id = p_message_id
      and to_user_id = p_to_user_id;
    get diagnostics deleted_notification_count = row_count;
  end if;

  return jsonb_build_object(
    'ok', true,
    'deleted_blob_count', deleted_blob_count,
    'deleted_notification_count', deleted_notification_count,
    'remaining_blob_count', remaining_blob_count
  );
end;
$$;
revoke all on function public.dm_transport_consume_v1(uuid, uuid, text) from public;
grant execute on function public.dm_transport_consume_v1(uuid, uuid, text) to authenticated;
create or replace function public.consume_dm_message_v1(
  p_message_id uuid,
  p_to_user_id uuid,
  p_recipient_device_id text default null
)
returns jsonb
language sql
security definer
set search_path = public
as $$
  select public.dm_transport_consume_v1(
    p_message_id,
    p_to_user_id,
    p_recipient_device_id
  );
$$;
revoke all on function public.consume_dm_message_v1(uuid, uuid, text) from public;
grant execute on function public.consume_dm_message_v1(uuid, uuid, text) to authenticated;

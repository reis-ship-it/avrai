create or replace function public.community_message_consume_v1(
  p_message_id uuid,
  p_to_user_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  deleted_notification_count integer := 0;
  deleted_blob_count integer := 0;
  remaining_notification_count integer := 0;
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

  delete from public.community_message_notifications
  where message_id = p_message_id
    and to_user_id = p_to_user_id;
  get diagnostics deleted_notification_count = row_count;

  select count(*)
  into remaining_notification_count
  from public.community_message_notifications
  where message_id = p_message_id;

  if remaining_notification_count = 0 then
    delete from public.community_message_blobs
    where message_id = p_message_id;
    get diagnostics deleted_blob_count = row_count;
  end if;

  return jsonb_build_object(
    'ok', true,
    'deleted_notification_count', deleted_notification_count,
    'deleted_blob_count', deleted_blob_count,
    'remaining_notification_count', remaining_notification_count
  );
end;
$$;

revoke all on function public.community_message_consume_v1(uuid, uuid) from public;
grant execute on function public.community_message_consume_v1(uuid, uuid) to authenticated;

create or replace function public.consume_community_message_v1(
  p_message_id uuid,
  p_to_user_id uuid
)
returns jsonb
language sql
security definer
set search_path = public
as $$
  select public.community_message_consume_v1(
    p_message_id,
    p_to_user_id
  );
$$;

revoke all on function public.consume_community_message_v1(uuid, uuid) from public;
grant execute on function public.consume_community_message_v1(uuid, uuid) to authenticated;

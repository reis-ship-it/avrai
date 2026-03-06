-- Ensure DM blob schema supports recipient-device-targeted transport payloads.
do $$
begin
  if to_regclass('public.dm_message_blobs') is not null then
    alter table public.dm_message_blobs
      add column if not exists recipient_device_id text;

    update public.dm_message_blobs
       set recipient_device_id = 'legacy'
     where recipient_device_id is null;

    alter table public.dm_message_blobs
      alter column recipient_device_id set default 'legacy';
  end if;
end
$$;

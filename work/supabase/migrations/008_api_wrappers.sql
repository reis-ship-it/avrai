-- Create API schema wrappers so PostgREST with schemas=["api"] can call into public tables
create schema if not exists api;

-- Private message wrapper
create or replace function api.send_private_message(p_recipient uuid, p_payload jsonb)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  insert into public.private_messages(to_user_id, payload)
  values (p_recipient, p_payload);
end; $$;

-- Rooms wrappers
create or replace function api.create_room(p_metadata jsonb)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_room_id uuid;
begin
  insert into public.rooms(metadata) values (coalesce(p_metadata, '{}'::jsonb)) returning id into v_room_id;
  return v_room_id;
end; $$;

create or replace function api.add_membership(p_room_id uuid, p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  insert into public.room_memberships(room_id, user_id) values (p_room_id, p_user_id)
  on conflict (room_id, user_id) do nothing;
end; $$;

create or replace function api.post_room_message(p_room_id uuid, p_sender_id uuid, p_payload jsonb)
returns void
language plpgsql
security definer
as $$
begin
  insert into public.room_messages(room_id, sender_user_id, payload)
  values (p_room_id, p_sender_id, p_payload);
end; $$;



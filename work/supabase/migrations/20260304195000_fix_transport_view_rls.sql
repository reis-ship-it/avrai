-- Enforce invoker-security on transport compatibility views so underlying
-- table RLS policies are respected for caller roles.

create or replace view public.dm_transport_blobs
with (security_invoker = true)
as
select * from public.dm_message_blobs;

create or replace view public.dm_transport_notifications
with (security_invoker = true)
as
select * from public.dm_notifications;

create or replace view public.wormhole_message_queue
with (security_invoker = true)
as
select * from public.ai2ai_message_queue;

-- Ensure wormhole/DTN queue primitives exist on environments where
-- historical migration state may have been repaired manually.

create table if not exists public.ai2ai_message_queue (
  id uuid primary key default gen_random_uuid(),
  message_id text not null,
  sender_agent_id text not null,
  target_agent_id text not null,
  encrypted_payload text not null,
  message_type text not null,
  timestamp timestamptz not null default now(),
  expires_at timestamptz not null,
  routing_hops jsonb,
  status text not null default 'pending',
  delivery_attempts int not null default 0,
  last_delivery_attempt timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint ai2ai_message_queue_message_id_key unique (message_id),
  constraint ai2ai_message_queue_status_check
    check (status in ('pending', 'delivered', 'failed', 'expired'))
);
create index if not exists idx_ai2ai_message_queue_target_agent_id
  on public.ai2ai_message_queue(target_agent_id);
create index if not exists idx_ai2ai_message_queue_sender_agent_id
  on public.ai2ai_message_queue(sender_agent_id);
create index if not exists idx_ai2ai_message_queue_status
  on public.ai2ai_message_queue(status);
create index if not exists idx_ai2ai_message_queue_expires_at
  on public.ai2ai_message_queue(expires_at);
create index if not exists idx_ai2ai_message_queue_timestamp
  on public.ai2ai_message_queue(timestamp);
create index if not exists idx_ai2ai_message_queue_pending
  on public.ai2ai_message_queue(target_agent_id, status)
  where status = 'pending';
alter table public.ai2ai_message_queue enable row level security;
do $$
begin
  if exists (
    select 1 from information_schema.tables
    where table_schema = 'public' and table_name = 'user_agent_mappings'
  ) then
    if not exists (
      select 1 from pg_policies
      where schemaname = 'public'
        and tablename = 'ai2ai_message_queue'
        and policyname = 'Agents can read own messages'
    ) then
      execute $sql$
        create policy "Agents can read own messages"
          on public.ai2ai_message_queue
          for select
          using (
            (select auth.uid()) is not null and exists (
              select 1 from public.user_agent_mappings
              where user_id = (select auth.uid())
                and agent_id = ai2ai_message_queue.target_agent_id
            )
          )
      $sql$;
    end if;

    if not exists (
      select 1 from pg_policies
      where schemaname = 'public'
        and tablename = 'ai2ai_message_queue'
        and policyname = 'Agents can insert messages'
    ) then
      execute $sql$
        create policy "Agents can insert messages"
          on public.ai2ai_message_queue
          for insert
          with check (
            (select auth.uid()) is not null and exists (
              select 1 from public.user_agent_mappings
              where user_id = (select auth.uid())
                and agent_id = ai2ai_message_queue.sender_agent_id
            )
          )
      $sql$;
    end if;

    if not exists (
      select 1 from pg_policies
      where schemaname = 'public'
        and tablename = 'ai2ai_message_queue'
        and policyname = 'Agents can update own messages'
    ) then
      execute $sql$
        create policy "Agents can update own messages"
          on public.ai2ai_message_queue
          for update
          using (
            (select auth.uid()) is not null and exists (
              select 1 from public.user_agent_mappings
              where user_id = (select auth.uid())
                and agent_id = ai2ai_message_queue.target_agent_id
            )
          )
      $sql$;
    end if;

    if not exists (
      select 1 from pg_policies
      where schemaname = 'public'
        and tablename = 'ai2ai_message_queue'
        and policyname = 'Agents can delete own messages'
    ) then
      execute $sql$
        create policy "Agents can delete own messages"
          on public.ai2ai_message_queue
          for delete
          using (
            (select auth.uid()) is not null and exists (
              select 1 from public.user_agent_mappings
              where user_id = (select auth.uid())
                and agent_id = ai2ai_message_queue.target_agent_id
            )
          )
      $sql$;
    end if;
  end if;
end;
$$;
create or replace function public.mark_expired_ai2ai_messages()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.ai2ai_message_queue
  set status = 'expired',
      updated_at = now()
  where expires_at < now()
    and status = 'pending';
end;
$$;
create or replace function public.cleanup_expired_ai2ai_messages()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  delete from public.ai2ai_message_queue
  where status = 'expired'
    and updated_at < now() - interval '7 days';
end;
$$;
create or replace function public.update_ai2ai_message_queue_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;
do $$
begin
  if not exists (
    select 1
    from pg_trigger
    where tgname = 'ai2ai_message_queue_updated_at_trigger'
  ) then
    create trigger ai2ai_message_queue_updated_at_trigger
      before update on public.ai2ai_message_queue
      for each row
      execute function public.update_ai2ai_message_queue_updated_at();
  end if;
end;
$$;
create or replace view public.wormhole_message_queue as
select * from public.ai2ai_message_queue;

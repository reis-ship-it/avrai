-- Latency probe table and publication for DB -> Realtime E2E checks
create table if not exists public.latency_probe (
  id uuid primary key default gen_random_uuid(),
  trace_id text not null,
  created_at timestamptz not null default now(),
  payload jsonb not null default '{}'::jsonb
);

-- Basic RLS: allow authenticated insert/select on own probes via trace prefix if desired
alter table public.latency_probe enable row level security;

do $$
begin
  if not exists (
    select 1 from pg_policies where tablename = 'latency_probe' and schemaname = 'public'
  ) then
    create policy latency_probe_insert on public.latency_probe for insert to authenticated using (true) with check (true);
    create policy latency_probe_select on public.latency_probe for select to authenticated using (true);
  end if;
end $$;

-- Publish table changes for Realtime if publication exists
do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    alter publication supabase_realtime add table public.latency_probe;
  end if;
end $$;



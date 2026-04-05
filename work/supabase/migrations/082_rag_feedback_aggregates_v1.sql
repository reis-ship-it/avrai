-- RAG feedback aggregates (v1): device-level, no PII.
-- Plan: RAG wiring + RAG-as-answer — Phase 7 optional federated RAG feedback.

create table if not exists public.rag_feedback_aggregates_v1 (
  id uuid primary key default gen_random_uuid(),
  retrieved_group_counts jsonb not null default '{}'::jsonb,
  network_cues_used int not null default 0,
  search_used int not null default 0,
  created_at timestamptz not null default now(),
  source text not null default 'federated_sync'
);
create index if not exists idx_rag_feedback_aggregates_v1_created_at
  on public.rag_feedback_aggregates_v1(created_at desc);
alter table public.rag_feedback_aggregates_v1 enable row level security;
-- Only service role can insert/select (edge function uses service role).
drop policy if exists "Service role can manage rag feedback aggregates" on public.rag_feedback_aggregates_v1;
create policy "Service role can manage rag feedback aggregates"
  on public.rag_feedback_aggregates_v1
  for all
  using ((select auth.role()) = 'service_role')
  with check ((select auth.role()) = 'service_role');
comment on table public.rag_feedback_aggregates_v1 is
  'Device-level RAG feedback aggregates (no PII). Used for optional federated learning; v1.';

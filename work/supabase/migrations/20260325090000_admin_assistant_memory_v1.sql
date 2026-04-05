create table if not exists public.admin_assistant_operator_preferences_v1 (
  operator_key text primary key,
  account_scope text not null,
  pinned_mode text,
  updated_at timestamptz not null default timezone('utc', now()),
  created_at timestamptz not null default timezone('utc', now())
);
create table if not exists public.admin_assistant_memory_tuples_v1 (
  tuple_id text primary key,
  operator_key text not null,
  account_scope text not null,
  route_scope text not null,
  prompt_intent text not null,
  prompt_domain text not null,
  response_mode text not null,
  refinement_status text not null,
  deterministic_outcome text not null,
  refined_outcome text not null,
  preferred_answer_style text,
  preferred_follow_up_style text,
  planning_domains jsonb not null default '[]'::jsonb,
  approved_draft_categories jsonb not null default '[]'::jsonb,
  rejected_draft_categories jsonb not null default '[]'::jsonb,
  metadata jsonb not null default '{}'::jsonb,
  recorded_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);
create index if not exists admin_assistant_memory_tuples_operator_recorded_idx
  on public.admin_assistant_memory_tuples_v1 (operator_key, recorded_at desc);
alter table public.admin_assistant_operator_preferences_v1 enable row level security;
alter table public.admin_assistant_memory_tuples_v1 enable row level security;
drop policy if exists admin_assistant_operator_preferences_authenticated_rw
  on public.admin_assistant_operator_preferences_v1;
create policy admin_assistant_operator_preferences_authenticated_rw
  on public.admin_assistant_operator_preferences_v1
  for all
  to authenticated
  using (true)
  with check (true);
drop policy if exists admin_assistant_memory_tuples_authenticated_rw
  on public.admin_assistant_memory_tuples_v1;
create policy admin_assistant_memory_tuples_authenticated_rw
  on public.admin_assistant_memory_tuples_v1
  for all
  to authenticated
  using (true)
  with check (true);

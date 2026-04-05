-- Repair beta_feedback for live admin inbox.
-- Use this only against project nfzlwgbvezwwrutqpedy.

create table if not exists public.beta_feedback (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  type text not null,
  content text not null,
  status text not null default 'new',
  created_at timestamptz not null default now()
);
alter table public.beta_feedback enable row level security;
drop policy if exists "Users can insert their own feedback" on public.beta_feedback;
create policy "Users can insert their own feedback" on public.beta_feedback
  for insert
  with check (auth.uid() = user_id);
drop policy if exists "Users can read their own feedback" on public.beta_feedback;
create policy "Users can read their own feedback" on public.beta_feedback
  for select
  using (auth.uid() = user_id);
drop policy if exists "Admins can read all feedback" on public.beta_feedback;
drop policy if exists "Service role can read all feedback" on public.beta_feedback;
create policy "Service role can read all feedback" on public.beta_feedback
  for select
  using ((select auth.role()) = 'service_role');
drop policy if exists "Admins can update feedback status" on public.beta_feedback;
drop policy if exists "Service role can update feedback status" on public.beta_feedback;
create policy "Service role can update feedback status" on public.beta_feedback
  for update
  using ((select auth.role()) = 'service_role');
create index if not exists idx_beta_feedback_created_at
  on public.beta_feedback (created_at desc);
create index if not exists idx_beta_feedback_status
  on public.beta_feedback (status);
notify pgrst, 'reload schema';

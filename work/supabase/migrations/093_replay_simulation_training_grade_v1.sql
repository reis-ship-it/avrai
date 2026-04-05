-- Replay Simulation Training-Grade Indexing (v1)
-- Purpose:
-- - Extend replay_simulation with training-grade action, counterfactual,
--   outcome, truth-decision, higher-agent, variation, and holdout tables.
-- - Keep all indexing isolated from live app schemas and tables.

create table if not exists replay_simulation.replay_action_training_records (
  run_id text not null references replay_simulation.replay_runs(run_id) on delete cascade,
  record_id text not null,
  actor_id text not null,
  kind text not null,
  context_window text not null,
  context_id text not null,
  month_key text not null,
  locality_anchor text not null,
  chosen_id text not null,
  chosen_type text not null,
  outcome_ref text not null,
  source_provenance_refs jsonb not null default '[]'::jsonb,
  confidence double precision not null default 0,
  uncertainty double precision not null default 0,
  active_kernel_ids jsonb not null default '[]'::jsonb,
  higher_agent_guidance_ids jsonb not null default '[]'::jsonb,
  governance_disposition text not null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  primary key (run_id, record_id)
);
create table if not exists replay_simulation.replay_counterfactual_choices (
  run_id text not null references replay_simulation.replay_runs(run_id) on delete cascade,
  record_id text not null,
  ordinal_index integer not null,
  candidate_id text not null,
  candidate_type text not null,
  score double precision not null default 0,
  confidence double precision not null default 0,
  rejection_reason text not null default '',
  blocking_lane text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  primary key (run_id, record_id, ordinal_index)
);
create table if not exists replay_simulation.replay_outcome_labels (
  run_id text not null references replay_simulation.replay_runs(run_id) on delete cascade,
  label_id text not null,
  actor_id text not null,
  context_id text not null,
  context_type text not null,
  month_key text not null,
  outcome_kind text not null,
  outcome_value text not null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  primary key (run_id, label_id)
);
create table if not exists replay_simulation.replay_truth_decision_history (
  run_id text not null references replay_simulation.replay_runs(run_id) on delete cascade,
  record_id text not null,
  subject_id text not null,
  subject_type text not null,
  month_key text not null,
  locality_anchor text not null,
  decision_kind text not null,
  decision_status text not null,
  reason text not null default '',
  source_refs jsonb not null default '[]'::jsonb,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  primary key (run_id, record_id)
);
create table if not exists replay_simulation.replay_higher_agent_intervention_traces (
  run_id text not null references replay_simulation.replay_runs(run_id) on delete cascade,
  trace_id text not null,
  actor_id text not null,
  action_record_id text not null,
  locality_anchor text not null,
  month_key text not null,
  guidance_state text not null,
  guidance_ids jsonb not null default '[]'::jsonb,
  reason text not null default '',
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  primary key (run_id, trace_id)
);
create table if not exists replay_simulation.replay_run_variation_profiles (
  run_id text primary key references replay_simulation.replay_runs(run_id) on delete cascade,
  environment_id text not null,
  replay_year integer not null,
  run_config_json jsonb not null default '{}'::jsonb,
  same_seed_reproducible boolean not null default true,
  untracked_window_count integer not null default 0,
  offline_queued_count integer not null default 0,
  attendance_variation_count integer not null default 0,
  connectivity_variation_count integer not null default 0,
  route_variation_count integer not null default 0,
  exchange_timing_variation_count integer not null default 0,
  month_variation_counts jsonb not null default '{}'::jsonb,
  notes jsonb not null default '[]'::jsonb,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create table if not exists replay_simulation.replay_holdout_evaluations (
  run_id text not null references replay_simulation.replay_runs(run_id) on delete cascade,
  metric_id text not null,
  environment_id text not null,
  replay_year integer not null,
  metric_name text not null,
  training_value double precision not null default 0,
  validation_value double precision not null default 0,
  holdout_value double precision not null default 0,
  threshold double precision not null default 0,
  passed boolean not null default false,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  primary key (run_id, metric_id)
);
create index if not exists idx_replay_action_training_actor
  on replay_simulation.replay_action_training_records(actor_id, month_key);
create index if not exists idx_replay_counterfactual_record
  on replay_simulation.replay_counterfactual_choices(record_id);
create index if not exists idx_replay_outcome_labels_actor
  on replay_simulation.replay_outcome_labels(actor_id, month_key);
create index if not exists idx_replay_truth_decisions_subject
  on replay_simulation.replay_truth_decision_history(subject_id, month_key);
create index if not exists idx_replay_higher_agent_interventions_actor
  on replay_simulation.replay_higher_agent_intervention_traces(actor_id, month_key);
create index if not exists idx_replay_holdout_metric
  on replay_simulation.replay_holdout_evaluations(metric_name, passed);
alter table replay_simulation.replay_action_training_records enable row level security;
alter table replay_simulation.replay_counterfactual_choices enable row level security;
alter table replay_simulation.replay_outcome_labels enable row level security;
alter table replay_simulation.replay_truth_decision_history enable row level security;
alter table replay_simulation.replay_higher_agent_intervention_traces enable row level security;
alter table replay_simulation.replay_run_variation_profiles enable row level security;
alter table replay_simulation.replay_holdout_evaluations enable row level security;
drop policy if exists "Service role can manage replay_action_training_records"
  on replay_simulation.replay_action_training_records;
create policy "Service role can manage replay_action_training_records"
  on replay_simulation.replay_action_training_records
  for all
  using ((select auth.role()) = 'service_role')
  with check ((select auth.role()) = 'service_role');
drop policy if exists "Service role can manage replay_counterfactual_choices"
  on replay_simulation.replay_counterfactual_choices;
create policy "Service role can manage replay_counterfactual_choices"
  on replay_simulation.replay_counterfactual_choices
  for all
  using ((select auth.role()) = 'service_role')
  with check ((select auth.role()) = 'service_role');
drop policy if exists "Service role can manage replay_outcome_labels"
  on replay_simulation.replay_outcome_labels;
create policy "Service role can manage replay_outcome_labels"
  on replay_simulation.replay_outcome_labels
  for all
  using ((select auth.role()) = 'service_role')
  with check ((select auth.role()) = 'service_role');
drop policy if exists "Service role can manage replay_truth_decision_history"
  on replay_simulation.replay_truth_decision_history;
create policy "Service role can manage replay_truth_decision_history"
  on replay_simulation.replay_truth_decision_history
  for all
  using ((select auth.role()) = 'service_role')
  with check ((select auth.role()) = 'service_role');
drop policy if exists "Service role can manage replay_higher_agent_intervention_traces"
  on replay_simulation.replay_higher_agent_intervention_traces;
create policy "Service role can manage replay_higher_agent_intervention_traces"
  on replay_simulation.replay_higher_agent_intervention_traces
  for all
  using ((select auth.role()) = 'service_role')
  with check ((select auth.role()) = 'service_role');
drop policy if exists "Service role can manage replay_run_variation_profiles"
  on replay_simulation.replay_run_variation_profiles;
create policy "Service role can manage replay_run_variation_profiles"
  on replay_simulation.replay_run_variation_profiles
  for all
  using ((select auth.role()) = 'service_role')
  with check ((select auth.role()) = 'service_role');
drop policy if exists "Service role can manage replay_holdout_evaluations"
  on replay_simulation.replay_holdout_evaluations;
create policy "Service role can manage replay_holdout_evaluations"
  on replay_simulation.replay_holdout_evaluations
  for all
  using ((select auth.role()) = 'service_role')
  with check ((select auth.role()) = 'service_role');

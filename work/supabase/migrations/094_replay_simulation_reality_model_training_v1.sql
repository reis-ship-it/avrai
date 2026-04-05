-- Replay Simulation Reality-Model Training (v1)
-- Purpose:
-- - Extend replay_simulation with replay-only memory/dispersion, Monte Carlo,
--   branch execution, dataset snapshot, shadow evaluation, and promotion tables.
-- - Keep all writes isolated from live app schemas and limited to service-role access.

create table if not exists replay_simulation.replay_personal_memory_ledgers (
  run_id text not null references replay_simulation.replay_runs(run_id) on delete cascade,
  ledger_id text not null,
  actor_id text not null,
  memory_scope text not null,
  relationship_count integer not null default 0,
  venue_trust_count integer not null default 0,
  organizer_trust_count integer not null default 0,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  primary key (run_id, ledger_id)
);
create table if not exists replay_simulation.replay_relationship_states (
  run_id text not null references replay_simulation.replay_runs(run_id) on delete cascade,
  relationship_id text not null,
  actor_id text not null,
  counterpart_ref text not null,
  counterpart_type text not null,
  strength double precision not null default 0,
  reply_reliability double precision not null default 0,
  group_tenure_band text not null,
  last_outcome text not null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  primary key (run_id, relationship_id)
);
create table if not exists replay_simulation.replay_venue_trust_records (
  run_id text not null references replay_simulation.replay_runs(run_id) on delete cascade,
  record_id text not null,
  actor_id text not null,
  venue_id text not null,
  satisfaction_score double precision not null default 0,
  return_likelihood double precision not null default 0,
  last_outcome text not null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  primary key (run_id, record_id)
);
create table if not exists replay_simulation.replay_organizer_trust_records (
  run_id text not null references replay_simulation.replay_runs(run_id) on delete cascade,
  record_id text not null,
  actor_id text not null,
  organizer_ref text not null,
  trust_score double precision not null default 0,
  follow_through_score double precision not null default 0,
  last_outcome text not null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  primary key (run_id, record_id)
);
create table if not exists replay_simulation.replay_locality_behavior_generalizations (
  run_id text not null references replay_simulation.replay_runs(run_id) on delete cascade,
  generalization_id text not null,
  locality_anchor text not null,
  month_key text not null,
  turnout_momentum double precision not null default 0,
  venue_pull_score double precision not null default 0,
  organizer_reputation_score double precision not null default 0,
  trust_caution_score double precision not null default 0,
  everyday_business_pressure double precision not null default 0,
  dispersion_signal_count integer not null default 0,
  advertising_pressure_count integer not null default 0,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  primary key (run_id, generalization_id)
);
create table if not exists replay_simulation.replay_pheromone_dispersion_signals (
  run_id text not null references replay_simulation.replay_runs(run_id) on delete cascade,
  signal_id text not null,
  generalization_id text not null,
  locality_anchor text not null,
  month_key text not null,
  signal_kind text not null,
  subject_ref text not null,
  subject_type text not null,
  gradient double precision not null default 0,
  guidance_strength double precision not null default 0,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  primary key (run_id, signal_id)
);
create table if not exists replay_simulation.replay_advertising_pressure_records (
  run_id text not null references replay_simulation.replay_runs(run_id) on delete cascade,
  record_id text not null,
  generalization_id text not null,
  locality_anchor text not null,
  subject_ref text not null,
  subject_type text not null,
  pressure_kind text not null,
  intensity double precision not null default 0,
  guidance_strength double precision not null default 0,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  primary key (run_id, record_id)
);
create table if not exists replay_simulation.replay_monte_carlo_branch_policies (
  run_id text not null references replay_simulation.replay_runs(run_id) on delete cascade,
  policy_id text not null,
  branch_id text not null,
  branch_class text not null,
  seed integer not null,
  modeled_actor_count integer not null default 0,
  sparse_user_count integer,
  locality_refs jsonb not null default '[]'::jsonb,
  stress_families jsonb not null default '[]'::jsonb,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  primary key (run_id, branch_id)
);
create table if not exists replay_simulation.replay_branch_evaluations (
  run_id text not null references replay_simulation.replay_runs(run_id) on delete cascade,
  branch_id text not null,
  branch_class text not null,
  passed boolean not null default false,
  metric_scores jsonb not null default '{}'::jsonb,
  notes jsonb not null default '[]'::jsonb,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  primary key (run_id, branch_id)
);
create table if not exists replay_simulation.replay_branch_divergence_records (
  run_id text not null references replay_simulation.replay_runs(run_id) on delete cascade,
  branch_id text not null,
  metric_key text not null,
  baseline_value double precision not null default 0,
  branch_value double precision not null default 0,
  delta double precision not null default 0,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  primary key (run_id, branch_id, metric_key)
);
create table if not exists replay_simulation.replay_monte_carlo_branch_executions (
  run_id text not null references replay_simulation.replay_runs(run_id) on delete cascade,
  execution_run_id text not null,
  base_year_run_id text not null,
  branch_id text not null,
  branch_class text not null,
  seed integer not null,
  modeled_actor_count integer not null default 0,
  sparse_user_count integer,
  locality_refs jsonb not null default '[]'::jsonb,
  stress_families jsonb not null default '[]'::jsonb,
  action_training_record_count integer not null default 0,
  outcome_label_count integer not null default 0,
  truth_decision_record_count integer not null default 0,
  connectivity_receipt_count integer not null default 0,
  personal_memory_ledger_count integer not null default 0,
  locality_generalization_count integer not null default 0,
  exchange_event_count integer not null default 0,
  admin_case_count integer not null default 0,
  higher_agent_action_count integer not null default 0,
  artifact_refs jsonb not null default '[]'::jsonb,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  primary key (run_id, branch_id)
);
create table if not exists replay_simulation.replay_training_snapshot_manifests (
  run_id text not null references replay_simulation.replay_runs(run_id) on delete cascade,
  snapshot_id text not null,
  model_id text not null,
  domain text not null,
  replay_year integer not null,
  base_year_run_id text not null,
  source_branch_ids jsonb not null default '[]'::jsonb,
  validation_branch_ids jsonb not null default '[]'::jsonb,
  holdout_branch_ids jsonb not null default '[]'::jsonb,
  record_count integer not null default 0,
  label_distribution jsonb not null default '{}'::jsonb,
  sparse_user_coverage jsonb not null default '[]'::jsonb,
  data_path text not null,
  artifact_refs jsonb not null default '[]'::jsonb,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  primary key (run_id, snapshot_id)
);
create table if not exists replay_simulation.replay_reality_model_training_results (
  run_id text not null references replay_simulation.replay_runs(run_id) on delete cascade,
  model_id text not null,
  domain text not null,
  snapshot_id text not null,
  profile_version text not null,
  training_record_count integer not null default 0,
  validation_record_count integer not null default 0,
  holdout_record_count integer not null default 0,
  average_positive_rate double precision not null default 0,
  average_calibration_error double precision not null default 0,
  training_passed boolean not null default false,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  primary key (run_id, model_id)
);
create table if not exists replay_simulation.replay_reality_model_shadow_comparisons (
  run_id text not null references replay_simulation.replay_runs(run_id) on delete cascade,
  comparison_id text not null,
  model_id text not null,
  domain text not null,
  branch_id text not null,
  split text not null,
  request_id text not null,
  candidate_ref text not null,
  locality_code text not null,
  baseline_score double precision not null default 0,
  baseline_confidence double precision not null default 0,
  candidate_score double precision not null default 0,
  candidate_confidence double precision not null default 0,
  actual_label_value double precision not null default 0,
  candidate_won boolean not null default false,
  uncertainty_honest boolean not null default false,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  primary key (run_id, comparison_id)
);
create table if not exists replay_simulation.replay_reality_model_promotion_states (
  run_id text not null references replay_simulation.replay_runs(run_id) on delete cascade,
  model_id text not null,
  domain text not null,
  state text not null,
  passed boolean not null default false,
  primary_metric text not null,
  metric_value double precision not null default 0,
  threshold double precision not null default 0,
  notes jsonb not null default '[]'::jsonb,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  primary key (run_id, model_id)
);
create index if not exists idx_replay_personal_memory_ledgers_actor
  on replay_simulation.replay_personal_memory_ledgers(actor_id);
create index if not exists idx_replay_relationship_states_actor
  on replay_simulation.replay_relationship_states(actor_id, counterpart_type);
create index if not exists idx_replay_venue_trust_actor
  on replay_simulation.replay_venue_trust_records(actor_id, venue_id);
create index if not exists idx_replay_organizer_trust_actor
  on replay_simulation.replay_organizer_trust_records(actor_id, organizer_ref);
create index if not exists idx_replay_locality_generalizations_locality
  on replay_simulation.replay_locality_behavior_generalizations(locality_anchor, month_key);
create index if not exists idx_replay_dispersion_signals_locality
  on replay_simulation.replay_pheromone_dispersion_signals(locality_anchor, month_key);
create index if not exists idx_replay_advertising_pressure_locality
  on replay_simulation.replay_advertising_pressure_records(locality_anchor, pressure_kind);
create index if not exists idx_replay_branch_policies_class
  on replay_simulation.replay_monte_carlo_branch_policies(branch_class, sparse_user_count);
create index if not exists idx_replay_branch_evaluations_passed
  on replay_simulation.replay_branch_evaluations(branch_class, passed);
create index if not exists idx_replay_branch_executions_class
  on replay_simulation.replay_monte_carlo_branch_executions(branch_class, sparse_user_count);
create index if not exists idx_replay_training_snapshot_model
  on replay_simulation.replay_training_snapshot_manifests(model_id, domain);
create index if not exists idx_replay_training_results_model
  on replay_simulation.replay_reality_model_training_results(model_id, training_passed);
create index if not exists idx_replay_shadow_comparisons_model
  on replay_simulation.replay_reality_model_shadow_comparisons(model_id, candidate_won, uncertainty_honest);
create index if not exists idx_replay_promotion_states_model
  on replay_simulation.replay_reality_model_promotion_states(model_id, state, passed);
alter table replay_simulation.replay_personal_memory_ledgers enable row level security;
alter table replay_simulation.replay_relationship_states enable row level security;
alter table replay_simulation.replay_venue_trust_records enable row level security;
alter table replay_simulation.replay_organizer_trust_records enable row level security;
alter table replay_simulation.replay_locality_behavior_generalizations enable row level security;
alter table replay_simulation.replay_pheromone_dispersion_signals enable row level security;
alter table replay_simulation.replay_advertising_pressure_records enable row level security;
alter table replay_simulation.replay_monte_carlo_branch_policies enable row level security;
alter table replay_simulation.replay_branch_evaluations enable row level security;
alter table replay_simulation.replay_branch_divergence_records enable row level security;
alter table replay_simulation.replay_monte_carlo_branch_executions enable row level security;
alter table replay_simulation.replay_training_snapshot_manifests enable row level security;
alter table replay_simulation.replay_reality_model_training_results enable row level security;
alter table replay_simulation.replay_reality_model_shadow_comparisons enable row level security;
alter table replay_simulation.replay_reality_model_promotion_states enable row level security;
drop policy if exists "Service role can manage replay_personal_memory_ledgers"
  on replay_simulation.replay_personal_memory_ledgers;
create policy "Service role can manage replay_personal_memory_ledgers"
  on replay_simulation.replay_personal_memory_ledgers
  for all
  using ((select auth.role()) = 'service_role')
  with check ((select auth.role()) = 'service_role');
drop policy if exists "Service role can manage replay_relationship_states"
  on replay_simulation.replay_relationship_states;
create policy "Service role can manage replay_relationship_states"
  on replay_simulation.replay_relationship_states
  for all
  using ((select auth.role()) = 'service_role')
  with check ((select auth.role()) = 'service_role');
drop policy if exists "Service role can manage replay_venue_trust_records"
  on replay_simulation.replay_venue_trust_records;
create policy "Service role can manage replay_venue_trust_records"
  on replay_simulation.replay_venue_trust_records
  for all
  using ((select auth.role()) = 'service_role')
  with check ((select auth.role()) = 'service_role');
drop policy if exists "Service role can manage replay_organizer_trust_records"
  on replay_simulation.replay_organizer_trust_records;
create policy "Service role can manage replay_organizer_trust_records"
  on replay_simulation.replay_organizer_trust_records
  for all
  using ((select auth.role()) = 'service_role')
  with check ((select auth.role()) = 'service_role');
drop policy if exists "Service role can manage replay_locality_behavior_generalizations"
  on replay_simulation.replay_locality_behavior_generalizations;
create policy "Service role can manage replay_locality_behavior_generalizations"
  on replay_simulation.replay_locality_behavior_generalizations
  for all
  using ((select auth.role()) = 'service_role')
  with check ((select auth.role()) = 'service_role');
drop policy if exists "Service role can manage replay_pheromone_dispersion_signals"
  on replay_simulation.replay_pheromone_dispersion_signals;
create policy "Service role can manage replay_pheromone_dispersion_signals"
  on replay_simulation.replay_pheromone_dispersion_signals
  for all
  using ((select auth.role()) = 'service_role')
  with check ((select auth.role()) = 'service_role');
drop policy if exists "Service role can manage replay_advertising_pressure_records"
  on replay_simulation.replay_advertising_pressure_records;
create policy "Service role can manage replay_advertising_pressure_records"
  on replay_simulation.replay_advertising_pressure_records
  for all
  using ((select auth.role()) = 'service_role')
  with check ((select auth.role()) = 'service_role');
drop policy if exists "Service role can manage replay_monte_carlo_branch_policies"
  on replay_simulation.replay_monte_carlo_branch_policies;
create policy "Service role can manage replay_monte_carlo_branch_policies"
  on replay_simulation.replay_monte_carlo_branch_policies
  for all
  using ((select auth.role()) = 'service_role')
  with check ((select auth.role()) = 'service_role');
drop policy if exists "Service role can manage replay_branch_evaluations"
  on replay_simulation.replay_branch_evaluations;
create policy "Service role can manage replay_branch_evaluations"
  on replay_simulation.replay_branch_evaluations
  for all
  using ((select auth.role()) = 'service_role')
  with check ((select auth.role()) = 'service_role');
drop policy if exists "Service role can manage replay_branch_divergence_records"
  on replay_simulation.replay_branch_divergence_records;
create policy "Service role can manage replay_branch_divergence_records"
  on replay_simulation.replay_branch_divergence_records
  for all
  using ((select auth.role()) = 'service_role')
  with check ((select auth.role()) = 'service_role');
drop policy if exists "Service role can manage replay_monte_carlo_branch_executions"
  on replay_simulation.replay_monte_carlo_branch_executions;
create policy "Service role can manage replay_monte_carlo_branch_executions"
  on replay_simulation.replay_monte_carlo_branch_executions
  for all
  using ((select auth.role()) = 'service_role')
  with check ((select auth.role()) = 'service_role');
drop policy if exists "Service role can manage replay_training_snapshot_manifests"
  on replay_simulation.replay_training_snapshot_manifests;
create policy "Service role can manage replay_training_snapshot_manifests"
  on replay_simulation.replay_training_snapshot_manifests
  for all
  using ((select auth.role()) = 'service_role')
  with check ((select auth.role()) = 'service_role');
drop policy if exists "Service role can manage replay_reality_model_training_results"
  on replay_simulation.replay_reality_model_training_results;
create policy "Service role can manage replay_reality_model_training_results"
  on replay_simulation.replay_reality_model_training_results
  for all
  using ((select auth.role()) = 'service_role')
  with check ((select auth.role()) = 'service_role');
drop policy if exists "Service role can manage replay_reality_model_shadow_comparisons"
  on replay_simulation.replay_reality_model_shadow_comparisons;
create policy "Service role can manage replay_reality_model_shadow_comparisons"
  on replay_simulation.replay_reality_model_shadow_comparisons
  for all
  using ((select auth.role()) = 'service_role')
  with check ((select auth.role()) = 'service_role');
drop policy if exists "Service role can manage replay_reality_model_promotion_states"
  on replay_simulation.replay_reality_model_promotion_states;
create policy "Service role can manage replay_reality_model_promotion_states"
  on replay_simulation.replay_reality_model_promotion_states
  for all
  using ((select auth.role()) = 'service_role')
  with check ((select auth.role()) = 'service_role');

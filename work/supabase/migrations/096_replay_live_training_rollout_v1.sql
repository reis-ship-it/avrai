-- Replay Live + Federated Training Rollout (v1)
-- Purpose:
-- - Extend replay_simulation with live-safe training receipt, aggregate,
--   combined snapshot, and kernel-guide rollout tables.
-- - Keep all writes isolated from live app schemas and limited to service-role.

create table if not exists replay_simulation.live_learning_receipts (
  run_id text not null references replay_simulation.replay_runs(run_id) on delete cascade,
  receipt_id text not null,
  pseudonymous_actor_id text not null,
  domain text not null,
  candidate_ref text not null,
  locality_code text not null,
  city_code text not null,
  captured_at_utc timestamptz not null,
  intake_mode text not null,
  consented_for_shared_learning boolean not null default false,
  local_only_adaptation_allowed boolean not null default false,
  training_source_mode text not null default 'live',
  replay_snapshot_refs jsonb not null default '[]'::jsonb,
  live_snapshot_refs jsonb not null default '[]'::jsonb,
  federated_aggregate_refs jsonb not null default '[]'::jsonb,
  kernel_target_ids jsonb not null default '[]'::jsonb,
  signal_tags jsonb not null default '[]'::jsonb,
  generalized_feature_values jsonb not null default '{}'::jsonb,
  outcome_resolution_status text not null default 'pending',
  raw_user_identifier_present boolean not null default false,
  personal_memory_exported boolean not null default false,
  request_json jsonb,
  evaluation_json jsonb,
  trace_json jsonb,
  outcome_receipt_json jsonb,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  primary key (run_id, receipt_id)
);
create table if not exists replay_simulation.federated_learning_aggregates (
  run_id text not null references replay_simulation.replay_runs(run_id) on delete cascade,
  aggregate_id text not null,
  model_id text not null,
  domain text not null,
  locality_code text not null,
  intake_mode text not null,
  participant_count integer not null default 0,
  receipt_refs jsonb not null default '[]'::jsonb,
  created_at_utc timestamptz not null,
  feature_averages jsonb not null default '{}'::jsonb,
  label_distribution jsonb not null default '{}'::jsonb,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  primary key (run_id, aggregate_id)
);
create table if not exists replay_simulation.live_training_snapshot_manifests (
  run_id text not null references replay_simulation.replay_runs(run_id) on delete cascade,
  snapshot_id text not null,
  model_id text not null,
  domain text not null,
  training_source_mode text not null,
  record_count integer not null default 0,
  label_distribution jsonb not null default '{}'::jsonb,
  local_only_adaptation_allowed boolean not null default false,
  data_path text not null,
  replay_snapshot_refs jsonb not null default '[]'::jsonb,
  live_snapshot_refs jsonb not null default '[]'::jsonb,
  federated_aggregate_refs jsonb not null default '[]'::jsonb,
  outcome_resolution_status text not null default 'resolved_only',
  artifact_refs jsonb not null default '[]'::jsonb,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  primary key (run_id, snapshot_id)
);
create table if not exists replay_simulation.combined_training_snapshot_manifests (
  run_id text not null references replay_simulation.replay_runs(run_id) on delete cascade,
  snapshot_id text not null,
  model_id text not null,
  domain text not null,
  training_source_mode text not null,
  replay_snapshot_refs jsonb not null default '[]'::jsonb,
  live_snapshot_refs jsonb not null default '[]'::jsonb,
  record_count integer not null default 0,
  local_only_adaptation_allowed boolean not null default false,
  data_path text not null,
  federated_aggregate_refs jsonb not null default '[]'::jsonb,
  outcome_resolution_status text not null default 'resolved_only',
  artifact_refs jsonb not null default '[]'::jsonb,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  primary key (run_id, snapshot_id)
);
create table if not exists replay_simulation.kernel_guide_training_results (
  run_id text not null references replay_simulation.replay_runs(run_id) on delete cascade,
  model_id text not null,
  kernel_target_id text not null,
  snapshot_id text not null,
  profile_version text not null,
  training_record_count integer not null default 0,
  validation_record_count integer not null default 0,
  holdout_record_count integer not null default 0,
  average_positive_rate double precision not null default 0,
  average_calibration_error double precision not null default 0,
  training_passed boolean not null default false,
  training_source_mode text not null default 'replay',
  live_snapshot_refs jsonb not null default '[]'::jsonb,
  federated_aggregate_refs jsonb not null default '[]'::jsonb,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  primary key (run_id, model_id)
);
create table if not exists replay_simulation.kernel_guide_shadow_evaluations (
  run_id text not null references replay_simulation.replay_runs(run_id) on delete cascade,
  model_id text not null,
  kernel_target_id text not null,
  holdout_count integer not null default 0,
  candidate_wins integer not null default 0,
  baseline_wins integer not null default 0,
  average_score_delta double precision not null default 0,
  uncertainty_honesty_rate double precision not null default 0,
  passed boolean not null default false,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  primary key (run_id, model_id, kernel_target_id)
);
create table if not exists replay_simulation.kernel_guide_promotion_states (
  run_id text not null references replay_simulation.replay_runs(run_id) on delete cascade,
  model_id text not null,
  kernel_target_id text not null,
  influence_mode text not null,
  passed boolean not null default false,
  primary_metric text not null,
  metric_value double precision not null default 0,
  threshold double precision not null default 0,
  notes jsonb not null default '[]'::jsonb,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  primary key (run_id, model_id)
);
create index if not exists idx_live_learning_receipts_actor
  on replay_simulation.live_learning_receipts (pseudonymous_actor_id, locality_code);
create index if not exists idx_federated_learning_aggregates_model
  on replay_simulation.federated_learning_aggregates (model_id, locality_code);
create index if not exists idx_live_training_snapshot_manifests_model
  on replay_simulation.live_training_snapshot_manifests (model_id);
create index if not exists idx_combined_training_snapshot_manifests_model
  on replay_simulation.combined_training_snapshot_manifests (model_id);
create index if not exists idx_kernel_guide_training_results_target
  on replay_simulation.kernel_guide_training_results (kernel_target_id);
create index if not exists idx_kernel_guide_shadow_evaluations_target
  on replay_simulation.kernel_guide_shadow_evaluations (kernel_target_id);
create index if not exists idx_kernel_guide_promotion_states_target
  on replay_simulation.kernel_guide_promotion_states (kernel_target_id);
alter table replay_simulation.live_learning_receipts enable row level security;
alter table replay_simulation.federated_learning_aggregates enable row level security;
alter table replay_simulation.live_training_snapshot_manifests enable row level security;
alter table replay_simulation.combined_training_snapshot_manifests enable row level security;
alter table replay_simulation.kernel_guide_training_results enable row level security;
alter table replay_simulation.kernel_guide_shadow_evaluations enable row level security;
alter table replay_simulation.kernel_guide_promotion_states enable row level security;
drop policy if exists live_learning_receipts_service_role_all
  on replay_simulation.live_learning_receipts;
create policy live_learning_receipts_service_role_all
  on replay_simulation.live_learning_receipts
  for all
  to service_role
  using (true)
  with check (true);
drop policy if exists federated_learning_aggregates_service_role_all
  on replay_simulation.federated_learning_aggregates;
create policy federated_learning_aggregates_service_role_all
  on replay_simulation.federated_learning_aggregates
  for all
  to service_role
  using (true)
  with check (true);
drop policy if exists live_training_snapshot_manifests_service_role_all
  on replay_simulation.live_training_snapshot_manifests;
create policy live_training_snapshot_manifests_service_role_all
  on replay_simulation.live_training_snapshot_manifests
  for all
  to service_role
  using (true)
  with check (true);
drop policy if exists combined_training_snapshot_manifests_service_role_all
  on replay_simulation.combined_training_snapshot_manifests;
create policy combined_training_snapshot_manifests_service_role_all
  on replay_simulation.combined_training_snapshot_manifests
  for all
  to service_role
  using (true)
  with check (true);
drop policy if exists kernel_guide_training_results_service_role_all
  on replay_simulation.kernel_guide_training_results;
create policy kernel_guide_training_results_service_role_all
  on replay_simulation.kernel_guide_training_results
  for all
  to service_role
  using (true)
  with check (true);
drop policy if exists kernel_guide_shadow_evaluations_service_role_all
  on replay_simulation.kernel_guide_shadow_evaluations;
create policy kernel_guide_shadow_evaluations_service_role_all
  on replay_simulation.kernel_guide_shadow_evaluations
  for all
  to service_role
  using (true)
  with check (true);
drop policy if exists kernel_guide_promotion_states_service_role_all
  on replay_simulation.kernel_guide_promotion_states;
create policy kernel_guide_promotion_states_service_role_all
  on replay_simulation.kernel_guide_promotion_states
  for all
  to service_role
  using (true)
  with check (true);

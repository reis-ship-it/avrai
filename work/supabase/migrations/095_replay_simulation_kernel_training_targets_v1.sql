create table if not exists replay_simulation.replay_kernel_training_snapshot_manifests (
  run_id text not null,
  snapshot_id text not null,
  model_id text not null,
  kernel_target_id text not null,
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
  created_at timestamptz not null default timezone('utc', now()),
  primary key (run_id, snapshot_id)
);
create index if not exists idx_replay_kernel_training_snapshot_manifests_model_id
  on replay_simulation.replay_kernel_training_snapshot_manifests (model_id);
create table if not exists replay_simulation.replay_kernel_training_records (
  run_id text not null,
  record_id text not null,
  snapshot_id text not null,
  model_id text not null,
  kernel_target_id text not null,
  domain text not null,
  split text not null,
  branch_id text not null,
  candidate_ref text not null,
  locality_code text not null,
  timestamp_utc timestamptz not null,
  label_value double precision not null,
  positive_outcome boolean not null default false,
  feature_values jsonb not null default '{}'::jsonb,
  native_payload jsonb not null default '{}'::jsonb,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  primary key (run_id, record_id)
);
create index if not exists idx_replay_kernel_training_records_model_id
  on replay_simulation.replay_kernel_training_records (model_id);
create index if not exists idx_replay_kernel_training_records_kernel_target_id
  on replay_simulation.replay_kernel_training_records (kernel_target_id);
alter table replay_simulation.replay_kernel_training_snapshot_manifests enable row level security;
alter table replay_simulation.replay_kernel_training_records enable row level security;
drop policy if exists replay_kernel_training_snapshot_manifests_service_role_all
  on replay_simulation.replay_kernel_training_snapshot_manifests;
create policy replay_kernel_training_snapshot_manifests_service_role_all
  on replay_simulation.replay_kernel_training_snapshot_manifests
  for all
  to service_role
  using (true)
  with check (true);
drop policy if exists replay_kernel_training_records_service_role_all
  on replay_simulation.replay_kernel_training_records;
create policy replay_kernel_training_records_service_role_all
  on replay_simulation.replay_kernel_training_records
  for all
  to service_role
  using (true)
  with check (true);

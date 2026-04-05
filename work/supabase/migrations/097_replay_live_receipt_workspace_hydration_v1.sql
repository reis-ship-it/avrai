-- Replay Live Receipt Workspace Hydration (v1)
-- Purpose:
-- - Track device-side live receipt export batches that are safe for shared
--   replay-only aggregation.
-- - Track workspace pull manifests that rebuild canonical receipt artifacts
--   such as 87_BHAM_REPLAY_LIVE_RECEIPTS_2023 from the shared cohort.

create table if not exists replay_simulation.live_receipt_export_batches (
  run_id text not null references replay_simulation.replay_runs(run_id) on delete cascade,
  batch_id text not null,
  target_environment_id text not null,
  target_replay_year integer not null,
  aggregator_environment_id text not null,
  device_runtime_source text not null,
  generated_at_utc timestamptz not null,
  receipt_ids jsonb not null default '[]'::jsonb,
  receipt_count integer not null default 0,
  shared_eligible_count integer not null default 0,
  local_only_count integer not null default 0,
  quarantined_count integer not null default 0,
  pending_count integer not null default 0,
  resolved_count integer not null default 0,
  source_surface_counts jsonb not null default '{}'::jsonb,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  primary key (run_id, batch_id)
);
create table if not exists replay_simulation.live_receipt_workspace_pull_manifests (
  run_id text not null references replay_simulation.replay_runs(run_id) on delete cascade,
  pull_id text not null,
  target_environment_id text not null,
  target_replay_year integer not null,
  aggregator_environment_id text not null,
  source_mode text not null,
  artifact_json_path text not null,
  artifact_markdown_path text not null,
  generated_at_utc timestamptz not null,
  imported_receipt_count integer not null default 0,
  deduped_receipt_count integer not null default 0,
  shared_eligible_resolved_count integer not null default 0,
  local_only_resolved_count integer not null default 0,
  quarantined_count integer not null default 0,
  source_surface_counts jsonb not null default '{}'::jsonb,
  export_batch_refs jsonb not null default '[]'::jsonb,
  first_captured_at_utc timestamptz,
  last_captured_at_utc timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  primary key (run_id, pull_id)
);
create index if not exists idx_live_receipt_export_batches_target
  on replay_simulation.live_receipt_export_batches (
    target_environment_id,
    target_replay_year,
    generated_at_utc
  );
create index if not exists idx_live_receipt_workspace_pull_manifests_target
  on replay_simulation.live_receipt_workspace_pull_manifests (
    target_environment_id,
    target_replay_year,
    generated_at_utc
  );
alter table replay_simulation.live_receipt_export_batches enable row level security;
alter table replay_simulation.live_receipt_workspace_pull_manifests enable row level security;
drop policy if exists live_receipt_export_batches_service_role_all
  on replay_simulation.live_receipt_export_batches;
create policy live_receipt_export_batches_service_role_all
  on replay_simulation.live_receipt_export_batches
  for all
  to service_role
  using (true)
  with check (true);
drop policy if exists live_receipt_workspace_pull_manifests_service_role_all
  on replay_simulation.live_receipt_workspace_pull_manifests;
create policy live_receipt_workspace_pull_manifests_service_role_all
  on replay_simulation.live_receipt_workspace_pull_manifests
  for all
  to service_role
  using (true)
  with check (true);

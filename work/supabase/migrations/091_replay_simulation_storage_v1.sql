-- Replay Simulation Storage + Indexing (v1)
-- Purpose:
-- - Create a replay-only schema for BHAM simulation metadata and indexing.
-- - Keep replay artifacts isolated from live app public-schema tables.
-- - Create replay-prefixed storage buckets for source packs, normalized observations,
--   world snapshots, training exports, and exchange logs.
-- - Restrict all replay storage and metadata access to service role only.

create schema if not exists replay_simulation;

create table if not exists replay_simulation.replay_runs (
  run_id text primary key,
  environment_id text not null,
  replay_year integer not null,
  status text not null,
  export_root text,
  partition_root text,
  project_isolation_mode text not null,
  replay_schema text not null default 'replay_simulation',
  artifact_count integer not null default 0,
  partition_entry_count integer not null default 0,
  total_bytes bigint not null default 0,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (environment_id, replay_year)
);

create table if not exists replay_simulation.replay_artifacts (
  run_id text not null references replay_simulation.replay_runs(run_id) on delete cascade,
  artifact_ref text not null,
  bucket_id text not null,
  object_path text not null,
  representation text not null,
  byte_size bigint not null default 0,
  partition_count integer not null default 0,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  primary key (run_id, artifact_ref),
  constraint replay_artifacts_representation_check
    check (representation in ('single_object', 'partitioned_ndjson'))
);

create table if not exists replay_simulation.replay_artifact_partitions (
  run_id text not null references replay_simulation.replay_runs(run_id) on delete cascade,
  artifact_ref text not null,
  section text not null,
  chunk_index integer not null,
  bucket_id text not null,
  object_path text not null,
  record_count integer not null default 0,
  byte_size bigint not null default 0,
  created_at timestamptz not null default now(),
  primary key (run_id, artifact_ref, section, chunk_index)
);

create table if not exists replay_simulation.replay_lineage (
  run_id text not null references replay_simulation.replay_runs(run_id) on delete cascade,
  environment_id text not null,
  replay_year integer not null,
  lineage_role text not null,
  source_artifact_ref text not null,
  upstream_artifact_refs jsonb not null default '[]'::jsonb,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  primary key (run_id, lineage_role)
);

create table if not exists replay_simulation.replay_calibration_reports (
  run_id text primary key references replay_simulation.replay_runs(run_id) on delete cascade,
  artifact_ref text not null,
  report_json jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists replay_simulation.replay_realism_gate_reports (
  run_id text primary key references replay_simulation.replay_runs(run_id) on delete cascade,
  artifact_ref text not null,
  report_json jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists replay_simulation.replay_training_exports (
  run_id text primary key references replay_simulation.replay_runs(run_id) on delete cascade,
  artifact_ref text not null,
  manifest_json jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create or replace function replay_simulation.set_replay_runs_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_replay_runs_updated_at
  on replay_simulation.replay_runs;
create trigger trg_replay_runs_updated_at
before update on replay_simulation.replay_runs
for each row
execute function replay_simulation.set_replay_runs_updated_at();

create index if not exists idx_replay_artifacts_bucket
  on replay_simulation.replay_artifacts(bucket_id);
create index if not exists idx_replay_artifact_partitions_bucket
  on replay_simulation.replay_artifact_partitions(bucket_id);
create index if not exists idx_replay_lineage_year
  on replay_simulation.replay_lineage(replay_year, lineage_role);

alter table replay_simulation.replay_runs enable row level security;
alter table replay_simulation.replay_artifacts enable row level security;
alter table replay_simulation.replay_artifact_partitions enable row level security;
alter table replay_simulation.replay_lineage enable row level security;
alter table replay_simulation.replay_calibration_reports enable row level security;
alter table replay_simulation.replay_realism_gate_reports enable row level security;
alter table replay_simulation.replay_training_exports enable row level security;

drop policy if exists "Service role can manage replay_runs"
  on replay_simulation.replay_runs;
create policy "Service role can manage replay_runs"
  on replay_simulation.replay_runs
  for all
  using ((select auth.role()) = 'service_role')
  with check ((select auth.role()) = 'service_role');

drop policy if exists "Service role can manage replay_artifacts"
  on replay_simulation.replay_artifacts;
create policy "Service role can manage replay_artifacts"
  on replay_simulation.replay_artifacts
  for all
  using ((select auth.role()) = 'service_role')
  with check ((select auth.role()) = 'service_role');

drop policy if exists "Service role can manage replay_artifact_partitions"
  on replay_simulation.replay_artifact_partitions;
create policy "Service role can manage replay_artifact_partitions"
  on replay_simulation.replay_artifact_partitions
  for all
  using ((select auth.role()) = 'service_role')
  with check ((select auth.role()) = 'service_role');

drop policy if exists "Service role can manage replay_lineage"
  on replay_simulation.replay_lineage;
create policy "Service role can manage replay_lineage"
  on replay_simulation.replay_lineage
  for all
  using ((select auth.role()) = 'service_role')
  with check ((select auth.role()) = 'service_role');

drop policy if exists "Service role can manage replay_calibration_reports"
  on replay_simulation.replay_calibration_reports;
create policy "Service role can manage replay_calibration_reports"
  on replay_simulation.replay_calibration_reports
  for all
  using ((select auth.role()) = 'service_role')
  with check ((select auth.role()) = 'service_role');

drop policy if exists "Service role can manage replay_realism_gate_reports"
  on replay_simulation.replay_realism_gate_reports;
create policy "Service role can manage replay_realism_gate_reports"
  on replay_simulation.replay_realism_gate_reports
  for all
  using ((select auth.role()) = 'service_role')
  with check ((select auth.role()) = 'service_role');

drop policy if exists "Service role can manage replay_training_exports"
  on replay_simulation.replay_training_exports;
create policy "Service role can manage replay_training_exports"
  on replay_simulation.replay_training_exports
  for all
  using ((select auth.role()) = 'service_role')
  with check ((select auth.role()) = 'service_role');

insert into storage.buckets (id, name, public)
values
  ('replay-source-packs', 'replay-source-packs', false),
  ('replay-normalized-observations', 'replay-normalized-observations', false),
  ('replay-world-snapshots', 'replay-world-snapshots', false),
  ('replay-training-exports', 'replay-training-exports', false),
  ('replay-exchange-logs', 'replay-exchange-logs', false)
on conflict (id) do nothing;

drop policy if exists "Service role can manage replay storage buckets"
  on storage.objects;
create policy "Service role can manage replay storage buckets"
  on storage.objects
  for all
  using (
    (select auth.role()) = 'service_role'
    and bucket_id in (
      'replay-source-packs',
      'replay-normalized-observations',
      'replay-world-snapshots',
      'replay-training-exports',
      'replay-exchange-logs'
    )
  )
  with check (
    (select auth.role()) = 'service_role'
    and bucket_id in (
      'replay-source-packs',
      'replay-normalized-observations',
      'replay-world-snapshots',
      'replay-training-exports',
      'replay-exchange-logs'
    )
  );

comment on schema replay_simulation is
  'Replay-only metadata/index schema for BHAM simulation artifacts.';

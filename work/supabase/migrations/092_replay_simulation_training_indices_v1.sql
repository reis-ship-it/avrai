-- Replay Simulation Training + Actor Indexing (v1)
-- Purpose:
-- - Extend the replay_simulation schema with per-actor, per-kernel,
--   connectivity, movement, and exchange indexing tables.
-- - Keep all replay indexing isolated from live application tables.
-- - Restrict access to service role only.

create table if not exists replay_simulation.replay_actor_profiles (
  run_id text not null references replay_simulation.replay_runs(run_id) on delete cascade,
  actor_id text not null,
  locality_anchor text not null,
  represented_population_count integer not null default 0,
  population_role text not null,
  lifecycle_state text not null,
  age_band text not null,
  life_stage text not null,
  household_type text not null,
  work_student_status text not null,
  has_personal_agent boolean not null default false,
  preferred_entity_types jsonb not null default '[]'::jsonb,
  kernel_bundle_json jsonb not null default '{}'::jsonb,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  primary key (run_id, actor_id)
);

create table if not exists replay_simulation.replay_actor_kernel_bundles (
  run_id text not null references replay_simulation.replay_runs(run_id) on delete cascade,
  actor_id text not null,
  locality_anchor text not null,
  has_full_bundle boolean not null default false,
  attached_kernel_ids jsonb not null default '[]'::jsonb,
  ready_kernel_ids jsonb not null default '[]'::jsonb,
  activation_count_by_kernel jsonb not null default '{}'::jsonb,
  higher_agent_guidance_count integer not null default 0,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  primary key (run_id, actor_id)
);

create table if not exists replay_simulation.replay_kernel_activation_traces (
  run_id text not null references replay_simulation.replay_runs(run_id) on delete cascade,
  trace_id text not null,
  actor_id text not null,
  context_type text not null,
  context_id text not null,
  activated_kernel_ids jsonb not null default '[]'::jsonb,
  higher_agent_guidance_ids jsonb not null default '[]'::jsonb,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  primary key (run_id, trace_id)
);

create table if not exists replay_simulation.replay_actor_connectivity_profiles (
  run_id text not null references replay_simulation.replay_runs(run_id) on delete cascade,
  actor_id text not null,
  locality_anchor text not null,
  dominant_mode text not null,
  device_profile_json jsonb not null default '{}'::jsonb,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  primary key (run_id, actor_id)
);

create table if not exists replay_simulation.replay_actor_connectivity_transitions (
  run_id text not null references replay_simulation.replay_runs(run_id) on delete cascade,
  transition_id text not null,
  actor_id text not null,
  month_key text not null,
  schedule_surface text not null,
  window_label text not null,
  locality_anchor text not null,
  mode text not null,
  reachable boolean not null default false,
  reason text not null default '',
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  primary key (run_id, transition_id)
);

alter table if exists replay_simulation.replay_actor_connectivity_transitions
  add column if not exists month_key text;

update replay_simulation.replay_actor_connectivity_transitions
set month_key = coalesce(metadata->>'month_key', 'unknown')
where month_key is null;

alter table replay_simulation.replay_actor_connectivity_transitions
  alter column month_key set not null;

create table if not exists replay_simulation.replay_actor_tracked_locations (
  run_id text not null references replay_simulation.replay_runs(run_id) on delete cascade,
  location_record_id text not null,
  actor_id text not null,
  month_key text not null,
  locality_anchor text not null,
  tracking_state text not null,
  location_kind text not null,
  physical_ref text not null,
  entity_id text,
  entity_type text,
  place_node_id text,
  reason text not null default '',
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  primary key (run_id, location_record_id)
);

create table if not exists replay_simulation.replay_actor_untracked_windows (
  run_id text not null references replay_simulation.replay_runs(run_id) on delete cascade,
  window_id text not null,
  actor_id text not null,
  month_key text not null,
  locality_anchor text not null,
  window_label text not null,
  reason text not null default '',
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  primary key (run_id, window_id)
);

create table if not exists replay_simulation.replay_actor_movements (
  run_id text not null references replay_simulation.replay_runs(run_id) on delete cascade,
  movement_id text not null,
  actor_id text not null,
  month_key text not null,
  origin_physical_ref text not null,
  destination_physical_ref text not null,
  origin_locality_anchor text not null,
  destination_locality_anchor text not null,
  mode text not null,
  tracked boolean not null default false,
  source_action_id text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  primary key (run_id, movement_id)
);

create table if not exists replay_simulation.replay_actor_flights (
  run_id text not null references replay_simulation.replay_runs(run_id) on delete cascade,
  flight_id text not null,
  actor_id text not null,
  month_key text not null,
  airport_node_id text not null,
  airport_physical_ref text not null,
  destination_region text not null,
  reason text not null default '',
  source_action_id text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  primary key (run_id, flight_id)
);

create table if not exists replay_simulation.replay_exchange_threads (
  run_id text not null references replay_simulation.replay_runs(run_id) on delete cascade,
  thread_id text not null,
  kind text not null,
  locality_anchor text not null,
  associated_entity_id text,
  participant_actor_ids jsonb not null default '[]'::jsonb,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  primary key (run_id, thread_id)
);

create table if not exists replay_simulation.replay_exchange_participations (
  run_id text not null references replay_simulation.replay_runs(run_id) on delete cascade,
  actor_id text not null,
  thread_id text not null,
  participation_state text not null,
  access_granted boolean not null default false,
  message_count integer not null default 0,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  primary key (run_id, actor_id, thread_id)
);

create table if not exists replay_simulation.replay_exchange_events (
  run_id text not null references replay_simulation.replay_runs(run_id) on delete cascade,
  event_id text not null,
  thread_id text not null,
  kind text not null,
  month_key text not null,
  locality_anchor text not null,
  sender_actor_id text not null,
  recipient_actor_ids jsonb not null default '[]'::jsonb,
  interaction_type text not null,
  connectivity_receipt_json jsonb not null default '{}'::jsonb,
  activated_kernel_ids jsonb not null default '[]'::jsonb,
  higher_agent_guidance_ids jsonb not null default '[]'::jsonb,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  primary key (run_id, event_id)
);

create table if not exists replay_simulation.replay_ai2ai_exchange_records (
  run_id text not null references replay_simulation.replay_runs(run_id) on delete cascade,
  record_id text not null,
  actor_id text not null,
  thread_id text not null,
  month_key text not null,
  locality_anchor text not null,
  route_mode text not null,
  status text not null,
  queued_offline boolean not null default false,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  primary key (run_id, record_id)
);

create index if not exists idx_replay_actor_profiles_locality
  on replay_simulation.replay_actor_profiles(locality_anchor);
create index if not exists idx_replay_kernel_activation_traces_actor
  on replay_simulation.replay_kernel_activation_traces(actor_id, context_type);
create index if not exists idx_replay_actor_connectivity_transitions_actor
  on replay_simulation.replay_actor_connectivity_transitions(actor_id, month_key);
create index if not exists idx_replay_actor_tracked_locations_actor
  on replay_simulation.replay_actor_tracked_locations(actor_id, month_key);
create index if not exists idx_replay_actor_movements_actor
  on replay_simulation.replay_actor_movements(actor_id, month_key);
create index if not exists idx_replay_exchange_events_thread
  on replay_simulation.replay_exchange_events(thread_id, month_key);
create index if not exists idx_replay_ai2ai_exchange_records_actor
  on replay_simulation.replay_ai2ai_exchange_records(actor_id, month_key);

alter table replay_simulation.replay_actor_profiles enable row level security;
alter table replay_simulation.replay_actor_kernel_bundles enable row level security;
alter table replay_simulation.replay_kernel_activation_traces enable row level security;
alter table replay_simulation.replay_actor_connectivity_profiles enable row level security;
alter table replay_simulation.replay_actor_connectivity_transitions enable row level security;
alter table replay_simulation.replay_actor_tracked_locations enable row level security;
alter table replay_simulation.replay_actor_untracked_windows enable row level security;
alter table replay_simulation.replay_actor_movements enable row level security;
alter table replay_simulation.replay_actor_flights enable row level security;
alter table replay_simulation.replay_exchange_threads enable row level security;
alter table replay_simulation.replay_exchange_participations enable row level security;
alter table replay_simulation.replay_exchange_events enable row level security;
alter table replay_simulation.replay_ai2ai_exchange_records enable row level security;

drop policy if exists "Service role can manage replay_actor_profiles"
  on replay_simulation.replay_actor_profiles;
create policy "Service role can manage replay_actor_profiles"
  on replay_simulation.replay_actor_profiles
  for all
  using ((select auth.role()) = 'service_role')
  with check ((select auth.role()) = 'service_role');

drop policy if exists "Service role can manage replay_actor_kernel_bundles"
  on replay_simulation.replay_actor_kernel_bundles;
create policy "Service role can manage replay_actor_kernel_bundles"
  on replay_simulation.replay_actor_kernel_bundles
  for all
  using ((select auth.role()) = 'service_role')
  with check ((select auth.role()) = 'service_role');

drop policy if exists "Service role can manage replay_kernel_activation_traces"
  on replay_simulation.replay_kernel_activation_traces;
create policy "Service role can manage replay_kernel_activation_traces"
  on replay_simulation.replay_kernel_activation_traces
  for all
  using ((select auth.role()) = 'service_role')
  with check ((select auth.role()) = 'service_role');

drop policy if exists "Service role can manage replay_actor_connectivity_profiles"
  on replay_simulation.replay_actor_connectivity_profiles;
create policy "Service role can manage replay_actor_connectivity_profiles"
  on replay_simulation.replay_actor_connectivity_profiles
  for all
  using ((select auth.role()) = 'service_role')
  with check ((select auth.role()) = 'service_role');

drop policy if exists "Service role can manage replay_actor_connectivity_transitions"
  on replay_simulation.replay_actor_connectivity_transitions;
create policy "Service role can manage replay_actor_connectivity_transitions"
  on replay_simulation.replay_actor_connectivity_transitions
  for all
  using ((select auth.role()) = 'service_role')
  with check ((select auth.role()) = 'service_role');

drop policy if exists "Service role can manage replay_actor_tracked_locations"
  on replay_simulation.replay_actor_tracked_locations;
create policy "Service role can manage replay_actor_tracked_locations"
  on replay_simulation.replay_actor_tracked_locations
  for all
  using ((select auth.role()) = 'service_role')
  with check ((select auth.role()) = 'service_role');

drop policy if exists "Service role can manage replay_actor_untracked_windows"
  on replay_simulation.replay_actor_untracked_windows;
create policy "Service role can manage replay_actor_untracked_windows"
  on replay_simulation.replay_actor_untracked_windows
  for all
  using ((select auth.role()) = 'service_role')
  with check ((select auth.role()) = 'service_role');

drop policy if exists "Service role can manage replay_actor_movements"
  on replay_simulation.replay_actor_movements;
create policy "Service role can manage replay_actor_movements"
  on replay_simulation.replay_actor_movements
  for all
  using ((select auth.role()) = 'service_role')
  with check ((select auth.role()) = 'service_role');

drop policy if exists "Service role can manage replay_actor_flights"
  on replay_simulation.replay_actor_flights;
create policy "Service role can manage replay_actor_flights"
  on replay_simulation.replay_actor_flights
  for all
  using ((select auth.role()) = 'service_role')
  with check ((select auth.role()) = 'service_role');

drop policy if exists "Service role can manage replay_exchange_threads"
  on replay_simulation.replay_exchange_threads;
create policy "Service role can manage replay_exchange_threads"
  on replay_simulation.replay_exchange_threads
  for all
  using ((select auth.role()) = 'service_role')
  with check ((select auth.role()) = 'service_role');

drop policy if exists "Service role can manage replay_exchange_participations"
  on replay_simulation.replay_exchange_participations;
create policy "Service role can manage replay_exchange_participations"
  on replay_simulation.replay_exchange_participations
  for all
  using ((select auth.role()) = 'service_role')
  with check ((select auth.role()) = 'service_role');

drop policy if exists "Service role can manage replay_exchange_events"
  on replay_simulation.replay_exchange_events;
create policy "Service role can manage replay_exchange_events"
  on replay_simulation.replay_exchange_events
  for all
  using ((select auth.role()) = 'service_role')
  with check ((select auth.role()) = 'service_role');

drop policy if exists "Service role can manage replay_ai2ai_exchange_records"
  on replay_simulation.replay_ai2ai_exchange_records;
create policy "Service role can manage replay_ai2ai_exchange_records"
  on replay_simulation.replay_ai2ai_exchange_records
  for all
  using ((select auth.role()) = 'service_role')
  with check ((select auth.role()) = 'service_role');

comment on table replay_simulation.replay_actor_profiles is
  'Replay-only actor profile index for simulation/training.';
comment on table replay_simulation.replay_actor_kernel_bundles is
  'Replay-only per-actor kernel bundle coverage.';
comment on table replay_simulation.replay_actor_connectivity_profiles is
  'Replay-only per-actor device and connectivity profile.';
comment on table replay_simulation.replay_exchange_events is
  'Replay-only simulated chat, admin, AI, and group exchange events.';

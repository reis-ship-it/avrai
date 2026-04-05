# BHAM Replay Supabase Upload And Index Summary

- Environment: `bham-replay-world-2023`
- Replay year: `2023`
- Replay schema: `replay_simulation`
- Dry run: `true`
- Project isolation mode: `shared_project_isolated_namespace`
- Upload entries: `1372`
- Total bytes: `1302054732`

## Notes

- This upload/index manifest was generated in dry-run mode.
- Replay objects target replay-prefixed buckets only.
- Partitioned artifacts are uploaded as NDJSON chunks under replay-only partition paths.
- Required replay schema migrations: work/supabase/migrations/091_replay_simulation_storage_v1.sql, work/supabase/migrations/092_replay_simulation_training_indices_v1.sql, and work/supabase/migrations/093_replay_simulation_training_grade_v1.sql
- Live upload/index was not attempted because replay Supabase credentials were not supplied.

## Representation Counts

- `partitioned_ndjson`: `1358`
- `single_object`: `14`

## Bucket Counts

- `replay-exchange-logs`: `51`
- `replay-normalized-observations`: `1`
- `replay-training-exports`: `648`
- `replay-world-snapshots`: `672`

## Indexed Tables

- none

## Planned Indexed Tables

- `replay_action_training_records`: `257898`
- `replay_actor_connectivity_profiles`: `25000`
- `replay_actor_connectivity_transitions`: `100000`
- `replay_actor_flights`: `910`
- `replay_actor_kernel_bundles`: `25000`
- `replay_actor_movements`: `117840`
- `replay_actor_profiles`: `25000`
- `replay_actor_tracked_locations`: `66930`
- `replay_actor_untracked_windows`: `75000`
- `replay_ai2ai_exchange_records`: `11691`
- `replay_artifacts`: `22`
- `replay_calibration_reports`: `1`
- `replay_counterfactual_choices`: `423666`
- `replay_exchange_events`: `11691`
- `replay_exchange_participations`: `14504`
- `replay_exchange_threads`: `11691`
- `replay_higher_agent_intervention_traces`: `128367`
- `replay_holdout_evaluations`: `6`
- `replay_kernel_activation_traces`: `128418`
- `replay_lineage`: `1`
- `replay_outcome_labels`: `257898`
- `replay_realism_gate_reports`: `1`
- `replay_run_variation_profiles`: `1`
- `replay_runs`: `1`
- `replay_training_exports`: `1`
- `replay_truth_decision_history`: `389`

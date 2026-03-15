# BHAM Replay Storage Boundary Report

- Environment: `bham-replay-2023`
- Replay year: `2023`
- Passed: `true`
- Project isolation mode: `shared_project_isolated_namespace`
- Replay schema: `replay_simulation`

## Replay Buckets

- `replay-exchange-logs`
- `replay-normalized-observations`
- `replay-source-packs`
- `replay-training-exports`
- `replay-world-snapshots`

## Replay Metadata Tables

- `replay_simulation.replay_artifact_partitions`
- `replay_simulation.replay_artifacts`
- `replay_simulation.replay_calibration_reports`
- `replay_simulation.replay_lineage`
- `replay_simulation.replay_realism_gate_reports`
- `replay_simulation.replay_runs`
- `replay_simulation.replay_training_exports`

## App Buckets

- `geo-packs`
- `list-images`
- `local-llm-models`
- `paperwork-documents`
- `spot-images`
- `tax-documents`
- `user-avatars`

## Policy Snapshot

- `appDirectReplayAccess`: `blocked`
- `liveAppBucketReuse`: `blocked`
- `liveAppSchemaReuse`: `blocked`
- `replayWriteAuthority`: `admin_tooling_or_service_role_only`

## Notes

- Replay storage may share the Supabase project, but must remain isolated by schema and replay-prefixed buckets.
- Replay artifacts must never be written through the live app SupabaseService surface.

## Violations

- `none`

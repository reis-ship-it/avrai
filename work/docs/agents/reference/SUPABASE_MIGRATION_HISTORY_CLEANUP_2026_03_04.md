# Supabase Migration History Cleanup (2026-03-04)

## Why this exists

The repository had multiple legacy migrations sharing the same numeric versions
(for example multiple `022`, `023`, `030` files). That causes `supabase db push`
to fail in linked remote environments.

On 2026-03-04 we performed a compatibility cleanup so migration execution is now
stable and deterministic.

## What changed

- Converted conflicting duplicate-number migration files into timestamped
  placeholders (`20260304193001` through `20260304193017`) so history alignment
  remains explicit without re-executing legacy SQL.
- Added `20260304193016_transport_clarity_aliases_v1.sql` to define canonical
  transport names and compatibility wrappers.
- Added `20260304194000_ensure_wormhole_queue_primitives.sql` to ensure
  `ai2ai_message_queue` and related queue primitives exist even on environments
  where older migration states were repaired manually.

## Operational guarantees after cleanup

- `supabase db push --linked --yes` completes successfully.
- Canonical DM transport RPCs exist:
  - `dm_transport_enqueue_v1`
  - `dm_transport_notify_v1`
- Legacy RPC names remain functional as wrappers:
  - `enqueue_dm_message_v1`
  - `enqueue_dm_notification_v1`
- Canonical edge function endpoint exists:
  - `dm-transport-enqueue-v1`
- Legacy edge endpoint remains available:
  - `dm-enqueue-v1`

## Follow-up policy

- New migrations must always use timestamped filenames.
- Do not re-introduce duplicate numeric migration versions.
- Remove runtime legacy fallbacks only after one full production-equivalent
  smoke run confirms canonical-only paths are healthy.

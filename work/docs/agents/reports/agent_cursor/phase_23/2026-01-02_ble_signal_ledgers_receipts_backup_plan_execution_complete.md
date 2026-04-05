## Summary
Implemented the “hardware-free regression + Ledgers v0 receipts expansion” backup plan:
- **Hardware-free evidence**: walk-by hotpath simulation is now part of the focused BLE/Signal fast-loop suite.
- **Correlated receipts**: device runs (especially the two-device Signal transport smoke) can emit a stitched audit trail in `ledger_events_v0` keyed by a shared correlation id.

## What changed (high-signal)
### Fast loop / regression surface
- Updated focused suite to run walk-by hotpath simulation:
  - `test/suites/ble_signal_suite.sh`
  - Adds: `test/unit/ai2ai/walkby_hotpath_simulation_test.dart`
- Updated dev-loop protocol to explicitly call out the walk-by regression:
  - `docs/agents/protocols/BLE_SIGNAL_DEV_LOOP.md`

### Ledgers v0 receipts (gated + correlated)
- Added audit gate + correlation plumbing:
  - `lib/core/services/ledgers/ledger_audit_v0.dart`
  - Opt-in flags:
    - `SPOTS_LEDGER_AUDIT=true`
    - `SPOTS_LEDGER_AUDIT_CORRELATION_ID=<RUN_ID>`
- Added production-path receipts (best-effort; never blocks core flows):
  - AI2AI walk-by + offline bootstrap: `lib/core/ai2ai/connection_orchestrator.dart`
  - Signal prekey lifecycle: `lib/core/crypto/signal/signal_key_manager.dart`
  - Transport storage receipts:
    - `lib/core/services/dm_message_store.dart`
    - `lib/core/services/community_message_store.dart`
- Updated catalog doc for new event types and payload shapes:
  - `docs/plans/ledgers/LEDGER_EVENT_CATALOG_V0.md`

### Two-device Signal smoke: correlation enabled by default
- Smoke runner now passes the ledger audit toggles using the existing `RUN_ID`:
  - `scripts/smoke/run_signal_two_device_transport_smoke.sh`
- Integration test emits additional receipts at key phases (notification insert + decrypt success):
  - `integration_test/signal_two_device_transport_smoke_test.dart`

## Verification performed (hardware-free)
- Focused suite:
  - `bash /Users/reisgordon/SPOTS/test/suites/ble_signal_suite.sh -j 1`
  - ✅ Pass
- `flutter analyze` was executed; repo currently has pre-existing warnings/infos, but no new analyzer **errors** were introduced by this change set.

## How to read tomorrow’s audit trail
Query rows by correlation id and order by `occurred_at`:

```sql
select occurred_at, domain, event_type, entity_type, entity_id, payload
from public.ledger_events_v0
where payload->>'correlation_id' = '<RUN_ID>'
order by occurred_at asc;
```

## Expected receipts ordering checklist (tomorrow’s device run)
This is meant to be a fast “did we regress?” scan. You should see **most** of these; exact interleaving can vary due to scheduling and realtime delivery.

### Two-device Signal DM smoke over real transport (A → B)
**Prereq:** runner sets `SPOTS_LEDGER_AUDIT=true` + `SPOTS_LEDGER_AUDIT_CORRELATION_ID=$RUN_ID` (already wired in `scripts/smoke/run_signal_two_device_transport_smoke.sh`).

- **(Either device early)** `signal_prekey_bundle_uploaded`
  - Expect one per device after key setup/rotation/upload (timing varies).
- **(Sender A)** `signal_dm_blob_written`
  - Entity: `dm_message:{messageId}`
  - Indicates ciphertext successfully stored in `dm_message_blobs`.
- **(Sender A)** `signal_dm_notification_written`
  - Entity: `dm_message:{messageId}`
  - Indicates the “payloadless realtime” notify row was inserted (`dm_notifications`).
- **(Receiver B)** `signal_dm_blob_read`
  - Entity: `dm_message:{messageId}`
  - Indicates receiver attempted to fetch the blob by id.
- **(Receiver B)** `signal_dm_decrypt_succeeded`
  - Entity: `dm_message:{messageId}`
  - Indicates Signal decrypt succeeded and plaintext bytes were produced.

**If something regressed, you’ll usually see:**
- `signal_prekey_bundle_fetch_failed` on the receiver (no bundle available via cloud or offline cache)
- `signal_dm_blob_read_failed` (RLS/row missing/transport issue)
- `signal_dm_blob_write_failed` (sender storage/transport issue)

### Optional: AI2AI walk-by receipts (if you also run the app with the same correlation id)
If you launch the app builds with the same audit flags, you should see:
- `ai2ai_orchestration_init_started` → `ai2ai_orchestration_init_completed`
- `ai2ai_ble_prekey_payload_published` (best-effort)
- `ai2ai_signal_prekey_cached_from_peer` (only if Stream 1 read succeeds)
- `ai2ai_silent_bootstrap_sent` (best-effort)
- `ai2ai_learning_insight_sent` (A) and `ai2ai_learning_insight_received` (B) (only if learning exchange triggers)
- `ai2ai_hotpath_latency_summary` (periodic; ~30s throttle)

## Notes / constraints
- Receipts are **best-effort**: failures are logged and do not throw.
- Receipts require:
  - `SPOTS_LEDGER_AUDIT=true`
  - non-empty `SPOTS_LEDGER_AUDIT_CORRELATION_ID`
  - authenticated user (RLS).


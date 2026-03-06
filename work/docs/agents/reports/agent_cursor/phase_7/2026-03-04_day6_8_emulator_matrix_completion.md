# Day 6-8 Completion (Emulator Matrix)

## Scope Completed

- Completed Day 6-8 matrix on two Android emulators:
  - `emulator-5554` (role A)
  - `emulator-5556` (role B)
- Executed all four lanes:
  1. Discovery
  2. Session setup (prekey upload/readiness)
  3. Learning exchange (DM hello/reply roundtrip)
  4. Offline recovery (forced wifi disable/enable on role B during run)

## Architecture Direction Applied

- Shifted DM transport writes to a server-authoritative path:
  - Added edge function: `work/supabase/functions/dm-enqueue-v1/index.ts`
  - Updated client store to prefer edge enqueue and fallback to RPC:
    - `runtime/avrai_runtime_os/lib/services/chat/dm_message_store.dart`
  - Updated direct DM send flow to use server-authoritative enqueue:
    - `runtime/avrai_runtime_os/lib/services/chat/friend_chat_service.dart`
  - Updated realtime backend DM notification branch to RPC-first with compatibility fallback:
    - `runtime/avrai_network/lib/backends/supabase/supabase_realtime_backend.dart`
- Updated smoke test to use server-authoritative enqueue for DM send:
  - `work/integration_test/signal_two_device_transport_smoke_test.dart`

## Key Infrastructure/Runtime Repairs Included

- Corrected Android Signal FFI jni path for packaged native libraries:
  - `apps/avrai_app/android/app/build.gradle`
- Added invite-token handshake in smoke test rendezvous to satisfy current prekey eligibility gates.
- Stabilized emulator infra for repeatability:
  - explicit DNS checks
  - wifi toggle reset when resolver state degraded

## Final Evidence (Pass)

### Baseline matrix pass (lanes 1-3)
- `RUN_ID=day6_8_clean_retry_20260304114924`
- Logs:
  - `work/docs/agents/reports/agent_cursor/phase_7/day6_8_logs/day6_8_clean_retry_20260304114924_roleA.log`
  - `work/docs/agents/reports/agent_cursor/phase_7/day6_8_logs/day6_8_clean_retry_20260304114924_roleB.log`
- Key markers:
  - Role A: signed in, peer discovered, signal init, DM send, DM roundtrip OK
  - Role B: signed in, peer discovered, signal init, received DM, sent reply

### Recovery lane pass (lane 4)
- `RUN_ID=day6_8_recovery_20260304115107`
- Logs:
  - `work/docs/agents/reports/agent_cursor/phase_7/day6_8_logs/day6_8_recovery_20260304115107_roleA.log`
  - `work/docs/agents/reports/agent_cursor/phase_7/day6_8_logs/day6_8_recovery_20260304115107_roleB.log`
  - `work/docs/agents/reports/agent_cursor/phase_7/day6_8_logs/day6_8_recovery_20260304115107_recovery_actions.log`
- Recovery action evidence:
  - wifi disabled on role B
  - wifi restored on role B
  - Supabase host ping succeeds post-restore
  - DM roundtrip still passes for both roles

## Day 6-8 Decision

- **Status: Complete (emulator matrix)**
- Constraint noted: physical-device cross-platform smoke remains a separate hardening opportunity, but Day 6-8 acceptance was completed within available device constraints (two emulators) with documented discovery/session/exchange/recovery evidence.

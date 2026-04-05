# Day 6-8 Emulator Matrix Progress (2026-03-04)

> Superseded by final completion evidence: `work/docs/agents/reports/agent_cursor/phase_7/2026-03-04_day6_8_emulator_matrix_completion.md`.

## Scope

- Executed the Day 6-8 two-device Signal transport smoke on Android emulators:
  - `emulator-5554` (role A)
  - `emulator-5556` (role B)
- Focused on unblock sequence:
  1. Infra/DNS recovery
  2. Auth account validation
  3. Discovery/session/DM transport matrix execution
  4. Failure signature capture for next repair

## What Was Fixed

1. **Infra DNS typo and emulator DNS routing**
   - Confirmed invalid host was being used (`...wwrup...`), while valid host is `...wwrut...`.
   - Relaunched emulators with explicit DNS servers so Supabase host resolution works from both devices.

2. **Android native Signal FFI packaging path**
   - Updated `apps/avrai_app/android/app/build.gradle` `jniLibs` path from:
     - `../../runtime/avrai_network/native/signal_ffi/android`
   - To:
     - `../../../../runtime/avrai_network/native/signal_ffi/android`
   - This fixed `libsignal_ffi_wrapper.so not found` during Signal stack init.

3. **Prekey eligibility for non-community DM smoke**
   - Updated `apps/avrai_app/integration_test/signal_two_device_transport_smoke_test.dart` to:
     - Create DM invite tokens via `create_dm_invite_token_v1`
     - Exchange invite tokens over rendezvous hello payload
     - Cache peer invite token before prekey fetch
   - This moved failures past `PREKEY_BUNDLE_NOT_FOUND`.

## Current Matrix Status

### Lane 1: Discovery
- **Pass**
- Evidence: both roles consistently log signed-in and peer discovery for same `RUN_ID`.

### Lane 2: Session Setup (prekey upload/fetch)
- **Pass after invite-token handshake update**
- Prior failure (`PREKEY_BUNDLE_NOT_FOUND`) is no longer the active blocker.

### Lane 3: Learning Exchange (DM hello/reply)
- **Blocked**
- Current failure signature on role A:
  - `PostgrestException: new row violates row-level security policy for table "dm_notifications" (42501)`
- Corresponding role B failure:
  - timeout waiting for hello/reply stream event.

### Lane 4: Offline/Permission Recovery
- **Not executed yet**
- Deferred until Lane 3 is green.

## Root-Cause Hypothesis for Current Blocker

- `dm_notifications` insert policy checks `exists (...)` against `dm_message_blobs`.
- `dm_message_blobs` has recipient-only select policy, so sender-side policy check can evaluate false.
- Result: notification insert denied by RLS even after successful prekey/session path.

## Evidence Artifacts

- Log directory:
  - `work/docs/agents/reports/agent_cursor/phase_7/day6_8_logs`
- Representative failing run:
  - `day6_8_emu_fix_20260304111944_roleA.log`
  - `day6_8_emu_fix_20260304111944_roleB.log`

## Next Repair Step (Required Before Marking Day 6-8 Complete)

- Add/fix Supabase RLS policy path so sender can successfully write `dm_notifications` tied to its own blob row (without opening recipient ciphertext broadly).
- Re-run two-emulator matrix for all lanes.
- Then run offline recovery lane:
  - disable wifi on one emulator
  - restore wifi
  - verify reconnect/retry behavior and completion.

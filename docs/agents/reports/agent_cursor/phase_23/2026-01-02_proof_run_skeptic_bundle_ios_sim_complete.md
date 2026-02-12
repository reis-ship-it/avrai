## Proof run skeptic bundle (iOS simulator) — complete

**Date:** 2026-01-02  
**Phase:** 23 (AI2AI walk-by / BLE fast loop)  
**Goal:** Create a repeatable, skeptic-proof artifact bundle: **video + logs + ledger receipts + focused tests**.

### Final run (authoritative)

- **timestamp**: `2026-01-02_15-19-59`
- **run_id**: `9b6f3cf8-9e0b-498c-9333-dcd4d6c2fec1`
- **git_sha**: `80c222c32da5e65c21954c0a73d6b84da3b6b252`
- **bundle folder**: `reports/proof_runs/2026-01-02_15-19-59_proof_run_9b6f3cf8-9e0b-498c-9333-dcd4d6c2fec1/`
- **bundle zip**: `reports/proof_runs/2026-01-02_15-19-59_proof_run_9b6f3cf8-9e0b-498c-9333-dcd4d6c2fec1.zip`

### Bundle contents (evidence)

- **Video**: `video/proof_run_2026-01-02_15-19-59.mp4`
- **Logs**: `logs/ios_simulator_log_stream.txt`
- **Ledger export**: `ledger/ledger_rows.jsonl` + `ledger/ledger_rows.csv`
- **Static analysis**: `tests/flutter_analyze.txt`
- **Focused suite**: `tests/ble_signal_suite.txt`
- **Integrity**: `checksums.sha256` + `manifest.json`

### Truth notes / constraints

- **iOS simulator cannot prove real BLE discovery.** The AI2AI step is recorded as **simulated** and labeled in:
  - `manifest.json`
  - the proof-run receipt payload for `proof_ai2ai_encounter_simulated`
- **iOS Google Maps hard-crash avoided** by defaulting to `flutter_map` on iOS unless explicitly enabled.
- **iOS BLE peripheral hard-crash avoided** by disabling BLE side effects on iOS by default (simulator-safe).

### Key issues found (and fixes applied)

- **Auth bounce** was due to Supabase `email_not_confirmed` for `reis@spots.app` → confirmed email in Supabase and improved client error messaging.
- **Post-onboarding crash (iOS)** from `GMSServices checkServicePreconditions` → gated Google Maps usage and defaulted to `flutter_map`.
- **Post-onboarding crash (iOS)** from CoreBluetooth peripheral restore-delegate mismatch → disabled BLE side effects on iOS by default.

### How to repeat

- Script: `scripts/proof_run/run_proof_run_bundle.sh`
- In-app: Profile → `Proof Run (debug)` page:
  1) Start run  
  2) Show offline AI provisioning state  
  3) Send one AI chat  
  4) Simulate AI2AI encounter  
  5) Export receipts


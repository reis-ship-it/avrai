# Proof Run (Skeptic Bundle) — Simulator / Emulator

This folder contains **repeatable proof/smoke bundle tooling** so you can hand a skeptic **proof exports + headless wake records + validation summaries**, not “it works on my machine.”

## What you get

Running the simulated smoke script produces:

- A timestamped folder under `reports/proof_runs/`
- A single `.zip` of that folder for easy sharing

Contents include:

- **Machine-readable smoke response** (`simulated_smoke_response.json`)
- **Driver log** (`flutter_drive.log`)
- **Exported proof bundle** pulled from the app container:
  - `ledger_rows.csv`
  - `ledger_rows.jsonl`
  - `background_wake_runs.json`
  - `field_validation_proofs.json`
  - `ambient_social_diagnostics.json`
- **Artifact manifest** (`manifest.json`) labeled as simulated
- **Validator summary** (`validation_summary.json`)

## Prereqs

- macOS with Xcode installed (for `xcrun`)
- An iOS simulator or Android emulator available locally
- avrai app installed (bundle id defaults to `com.avrai.app`)
- Debug build only

## Run it

From repo root, the deterministic smoke entrypoint is:

```bash
./scripts/proof_run/run_simulated_headless_smoke.sh ios
./scripts/proof_run/run_simulated_headless_smoke.sh android
```

Optional focused failure/profile runs use the same entrypoint with a second argument:

```bash
./scripts/proof_run/run_simulated_headless_smoke.sh ios duplicate_wake_delivery
./scripts/proof_run/run_simulated_headless_smoke.sh android trusted_route_unavailable_deferred
```

This boots the simulator/emulator if needed, launches the app, runs the in-app automation service through `flutter drive`, pulls the exported proof bundle, validates it, and zips the final artifact.

For BHAM beta, the required regression gate is the `baseline` profile on both platforms. The additional profiles are the compact failure-mode matrix:

- `duplicate_wake_delivery`
- `restart_mid_headless_run`
- `trusted_route_unavailable_deferred`
- `multi_peer_single_confirmation`

CI uses the same contract through:

```text
.github/workflows/simulated-headless-smoke-guard.yml
```

That workflow runs the Android emulator and iOS simulator smoke lanes against the same bundle validator and uploads the proof artifacts.

Optional override (if bundle id changes):

```bash
APP_BUNDLE_ID=com.avrai.app ./scripts/proof_run/run_simulated_headless_smoke.sh ios
```

The manual page-driven capture flow still exists:

```bash
./scripts/proof_run/run_proof_run_bundle.sh
```

That manual bundle flow now also writes:

- a per-run `ARTIFACT_INDEX.md`
- repo-level `proof_run_bundle_index.json`
- repo-level `proof_run_bundle_index.md`

## Simulated smoke contract

The automated smoke run always drives the same sequence:

- `proof_run_started`
- simulated AI2AI encounter
- simulated wake reasons:
  - `ble_encounter`
  - `trusted_announce_refresh`
  - `significant_location`
  - `background_task_window`
- controlled private-mesh validation
- proof export
- `proof_run_finished`

## Bundle validation

The validator is:

```bash
dart run work/tools/validate_simulated_smoke_bundle.dart <bundle_dir>
```

To validate the repo-level smoke index after one or more runs:

```bash
dart run work/tools/validate_simulated_smoke_artifact_index.dart reports/proof_runs
```

To validate the repo-level manual proof-run bundle index:

```bash
dart run work/tools/validate_proof_run_bundle_artifact_index.dart reports/proof_runs
```

To build a BHAM beta phone-QA readiness summary from the current proof artifacts:

```bash
dart run work/tools/build_bham_beta_readiness_summary.dart reports/proof_runs
```

Optional outputs:

```bash
dart run work/tools/build_bham_beta_readiness_summary.dart reports/proof_runs \
  --json-output=reports/proof_runs/bham_beta_readiness_summary.json \
  --markdown-output=reports/proof_runs/bham_beta_readiness_summary.md
```

It checks:

- required bundle files exist
- manifest includes simulated labeling, scenario profile, and `run_status: passed`
- background wake runs are present and include all required simulated wake reasons
- field validation proofs include trust, AI2AI, and ambient-social scenarios
- ambient-social diagnostics include candidate/confirmed counts, merge/rejection counts, and promotion lineage
- the manifest explicitly labels the artifact as simulated
- profile-specific expectations for the supported failure-mode matrix
- repo-level index entries match the on-disk smoke artifact directories
- manual proof-run bundle index entries match the on-disk bundle artifact directories
- BHAM beta readiness for phone QA based on green baseline smoke artifacts on
  both simulator platforms

## Manual debug page

The **Proof Run (debug)** page still exists for:

- manual milestone creation
- one-off encounter simulation
- ad hoc proof export
- demo walkthroughs

It is no longer the primary simulated smoke automation surface.

## Where the proof bundle comes from

The automated service still exports the existing proof bundle from:

- `Documents/proof_runs/<run_id>/ledger_rows.csv`
- `Documents/proof_runs/<run_id>/ledger_rows.jsonl`
- `Documents/proof_runs/<run_id>/background_wake_runs.json`
- `Documents/proof_runs/<run_id>/field_validation_proofs.json`
- `Documents/proof_runs/<run_id>/ambient_social_diagnostics.json`

The smoke wrapper copies those files out of the simulator/emulator container and adds the manifest, response payload, and validation summary.

## Truth note (important)

Simulator/emulator bundles are explicitly **simulated encounter/wake** coverage. They are useful for validating:

- startup
- headless wake execution
- proof export shape
- ambient-social diagnostics
- field proof persistence

They are **not** a claim of physical BLE/radio validation. For real BLE proof, use physical devices.

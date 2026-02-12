# Proof Run (Skeptic Bundle) — iOS Simulator

This folder contains a **repeatable “proof run” artifact bundle** generator so you can hand a skeptic **video + logs + ledger rows + test outputs**, not “it works on my machine.”

## What you get

Running the script produces:

- A timestamped folder under `reports/proof_runs/`
- A single `.zip` of that folder for easy sharing

Contents include:

- **Screen recording** (`video/*.mp4`) captured via `xcrun simctl io booted recordVideo`
- **Simulator log stream** (`logs/ios_simulator_log_stream.txt`)
- **Ledger receipt export** pulled from the app container (`ledger/ledger_rows.csv` + `ledger_rows.jsonl`)
- **`flutter analyze` output** (`tests/flutter_analyze.txt`)
- **Focused BLE/Signal suite output** (`tests/ble_signal_suite.txt`) from `test/suites/ble_signal_suite.sh`

## Prereqs

- macOS with Xcode installed (for `xcrun`)
- A **booted iOS Simulator**
- avrai app installed (bundle id defaults to `com.avrai.app`)
- In-app: **Proof Run (debug)** page available (debug builds only)

## Run it

From repo root:

```bash
./scripts/proof_run/run_proof_run_bundle.sh
```

Optional override (if bundle id changes):

```bash
APP_BUNDLE_ID=com.avrai.app ./scripts/proof_run/run_proof_run_bundle.sh
```

### Auto mode (non-interactive)

If you want the capture to run for a fixed duration (useful when driving the simulator with automation):

```bash
PROOF_RUN_AUTO=1 RECORD_SECONDS=720 ./scripts/proof_run/run_proof_run_bundle.sh
```

### Run id selection

By default the script will auto-detect the most recently exported run under:

- `Documents/proof_runs/<run_id>/`

If you want to force a specific run id (recommended if multiple exports exist):

```bash
RUN_ID=<run_id> ./scripts/proof_run/run_proof_run_bundle.sh
```

## In-app recording checklist (3–7 minutes)

The script will start capturing video + logs immediately. While it’s recording:

1. **Onboarding**: walk through onboarding (or show it already complete)
2. **Offline AI provisioning**: show the provisioning state/progress (Settings → On-Device AI)
3. **One AI chat**: use Proof Run page chat OR Home → Explore → AI tab
4. **One AI2AI encounter**: on iOS simulator this must be **simulated** (press “Simulate encounter” on Proof Run page)
5. **Export receipts**: Proof Run page → **Export**

When done, return to terminal and press ENTER to stop recording.

## Where the ledger export comes from

The app writes proof-run receipts to the v0 ledger (`ledger_events_v0`) with:

- `entity_type = 'proof_run'`
- `entity_id = <run_id>`

The Proof Run page’s **Export** writes:

- `Documents/proof_runs/<run_id>/ledger_rows.csv`
- `Documents/proof_runs/<run_id>/ledger_rows.jsonl`

The script pulls those files from the simulator container:

- `xcrun simctl get_app_container booted com.avrai.app data`

## Truth note (important)

iOS simulator cannot do real BLE discovery, so the AI2AI encounter in this bundle is a **simulation of the orchestrator hot-path** (it is labeled as simulated in the ledger receipt payload and in the bundle manifest). For real BLE proof, use Android physical devices.


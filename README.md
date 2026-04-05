# AVRAI

AVRAI is an offline-first, privacy-preserving intelligence platform for real-world discovery and connection.

## What This Project Is

- AI2AI-first architecture (device intelligence with secure coordination)
- World-model roadmap driven by measurable learning outcomes
- Strong security/compliance posture (Signal Protocol + policy guardrails)
- Build-enforced architecture placement and traceability rules

## Current Direction

The project is governed by:

- **PRD (requirements authority):** [`docs/PRD.md`](docs/PRD.md)
- **Master execution plan:** [`docs/MASTER_PLAN.md`](docs/MASTER_PLAN.md)
- **Execution board (milestones/phases):** [`docs/EXECUTION_BOARD.csv`](docs/EXECUTION_BOARD.csv)
- **Execution board guide:** [`docs/EXECUTION_BOARD.md`](docs/EXECUTION_BOARD.md)
- **Weekly operational status:** [`docs/STATUS_WEEKLY.md`](docs/STATUS_WEEKLY.md)
- **Program status companion:** [`docs/agents/status/status_tracker.md`](docs/agents/status/status_tracker.md)
- **Architecture index:** [`docs/plans/architecture/ARCHITECTURE_INDEX.md`](docs/plans/architecture/ARCHITECTURE_INDEX.md)

### Target Structure (Default for New Code)

All new code should converge to:

1. `apps/*` (UI + product surfaces)
2. `runtime/*` (endpoints, AI2AI/BLE transport, security, policy, orchestration)
3. `engine/*` (model truth: state/prediction/planning)
4. `shared/*` (schemas/primitives/contracts)

Reference docs:
- `docs/plans/architecture/MASTER_PLAN_3_PRONG_TARGET_END_STATE.md`
- `docs/plans/architecture/PRONG_APPS_CONCURRENT_EXECUTION_PLAN_2026-02-28.md`
- `docs/plans/architecture/PRONG_RUNTIME_OS_CONCURRENT_EXECUTION_PLAN_2026-02-28.md`
- `docs/plans/architecture/PRONG_REALITY_MODEL_CONCURRENT_EXECUTION_PLAN_2026-02-28.md`
- `docs/plans/architecture/TARGET_CODEBASE_STRUCTURE_ENFORCEMENT_2026-02-27.md`
- `docs/plans/architecture/CODEBASE_MIGRATION_CHECKLIST_3_PRONG_2026-02-27.md`
- `docs/plans/architecture/REFACTOR_FASTLANE_PLAYBOOK_2026-02-27.md`

## Quick Start

```bash
git clone https://github.com/AVRA-CADAVRA/avrai.git
cd avrai
flutter pub get
flutter run
```

Run consumer app explicitly:

```bash
flutter run -t lib/main.dart
```

Run admin app explicitly:

```bash
flutter run -t lib/main_admin.dart
```

Run extracted app packages:

```bash
cd apps/consumer_app && flutter pub get && flutter run
cd apps/admin_app && flutter pub get && flutter run
```

CI/CD split workflows:

- Consumer lane: `.github/workflows/consumer-app-ci-cd.yml`
- Admin lane: `.github/workflows/admin-app-ci-cd.yml`
- Both run app-scoped quality (`analyze` + `test`) and upload Android/Web build artifacts.

Current app housing (Flutter-compatible):

- Consumer app shell: `lib/apps/consumer_app/ui/consumer_app.dart`
- Admin app shell: `lib/apps/admin_app/ui/admin_app.dart`
- Admin bootstrap: `lib/apps/admin_app/bootstrap/admin_bootstrap.dart`
- Admin router: `lib/apps/admin_app/navigation/admin_router.dart`

Admin usage note:
- The admin app is internal-only because it exposes privileged governance controls, sensitive operational telemetry/decision traces, and administrative mutation paths that are not consumer-safe.

## Contributing

Before starting work:

1. Read `docs/PRD.md` for requirement IDs and acceptance criteria.
2. Confirm phase ownership in `docs/MASTER_PLAN.md`.
3. Pick exactly one execution milestone from `docs/EXECUTION_BOARD.csv` for the PR.
4. Keep file placement compliant with architecture guardrails in `docs/plans/architecture/`.
5. Use PR title format required by CI traceability guard: `PRD-### M#-P#-# <short summary>`.

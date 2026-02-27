# Repo Hygiene + Architecture Rules (Guardrails)

**Purpose:** keep the repository store-ready and professional by preventing:
- Package boundary leaks (`packages/*` depending on app `lib/`)
- Tracked generated artifacts (build outputs, Pods, temp/log dumps)

---

## 1) Architecture boundary rules

**Rule A (package -> app ban):** any Dart file under `packages/` must **not** `import` or `export`:
- `package:avrai/...`

**Rule B (engine/runtime/app layering):**
- Engine packages must not import runtime or app composition/presentation layers.
- Runtime packages must not import app composition/presentation layers.
- App may consume runtime and engine contracts, but must not bypass runtime contracts to call engine internals directly.

**Why:** packages and layers must remain independently testable and releasable. Boundary leaks lock us into monolith coupling and break migration safety.

**Enforcement:**
- Script: `scripts/ci/check_architecture.dart`
- Runner:
  - `melos run check:architecture`
  - CI: `Quick Tests` workflow runs it on PRs

### Baseline (incremental cleanup)

Today there are existing violations. To avoid “red CI forever”, the guard supports a baseline allowlist:
- Baseline file: `scripts/ci/baselines/avrai_app_imports_baseline.json`
- CI fails **only** if **new** violations are introduced.

Update baseline (temporary; prefer fixing imports instead):

```bash
dart run scripts/ci/check_architecture.dart --update-baseline
```

---

## 2) Repo hygiene rule (don’t track generated artifacts)

**Rule:** these directories must never contain **tracked** files:
- `build/`
- `Pods/`, `ios/Pods/`
- `android/.gradle/`, `android/app/build/`, `android/build/`
- `tmp/`, `temp/`, `logs/`

**Why:** tracked build outputs cause massive diffs, merge conflicts, and “generated repo smell”. They also break reproducible builds.

**Enforcement:**
- Script: `scripts/ci/check_repo_hygiene.dart`
- Runner:
  - `melos run check:repo_hygiene`
  - CI: `Quick Tests` workflow runs it on PRs

---

## 3) Next enforcement step (tighten over time)

Once package boundary leaks are fixed, we should:
- Shrink baseline → eventually delete it
- Flip the architecture guard to **strict mode** (no baseline)

This keeps the “store-ready repo” posture stable long-term.

# Master Plan Architecture Readiness QA (Prep-Only)

**Date:** February 13, 2026  
**Type:** Readiness audit report (no implementation/scaffolding changes)  
**Scope:** Architecture adaptability, design-system integration, testing-suite grouping readiness  
**Primary References:**  
- `docs/MASTER_PLAN.md`  
- `docs/plans/architecture/MASTER_PLAN_MULTI_APP_ARCHITECTURE_BLUEPRINT.md`  
- `docs/plans/architecture/MASTER_PLAN_ARCHITECTURE_EXECUTION_BACKLOG.md`  
- `docs/plans/architecture/MASTER_PLAN_ARCHITECTURE_IMPLEMENTATION_CHECKLIST.md`
- `docs/plans/architecture/IDENTITY_UNLINKABILITY_AND_ACCESS_GOVERNANCE_CONTRACT.md` (post-audit canonical contract)
- `docs/plans/architecture/REALITY_COHERENCE_TEST_MATRIX.md` (canonical coherence gate contract)

---

## 1) Executive Verdict

**Verdict:** **Conditionally ready** at planning layer.  

What is ready:
- Master Plan phase mapping and architecture prep artifacts are aligned (1-15).
- Design-system architecture files and CI guardrails are present.
- Backlog/checklist owner boundaries and phase gates are defined.

What blocks “grouped test suites without flaw”:
- Grouped suite scripts currently contain stale test paths after integration test reorganization.
- Grouped suite docs include stale repository paths/naming.
- Design golden tests are not included in grouped suites.

---

## 2) QA Results by Area

## A) Master Plan ↔ Architecture Prep Mapping

| Check | Result | Evidence |
|---|---|---|
| Backlog has phase sections 1-15 | PASS | `MASTER_PLAN_ARCHITECTURE_EXECUTION_BACKLOG.md` phase headers |
| Checklist has gate sections 1-15 | PASS | `MASTER_PLAN_ARCHITECTURE_IMPLEMENTATION_CHECKLIST.md` phase gates |
| Coherence matrix contract is linked in execution docs | PASS (post-audit normalization) | `REALITY_COHERENCE_TEST_MATRIX.md` + orchestration/checklist references |
| Tracker has phase registry rows 1-15 | PASS | `MASTER_PLAN_TRACKER.md` phase registry table |
| Tracker includes architecture prep artifacts | PASS | `MASTER_PLAN_TRACKER.md` Philosophy & Architecture rows |

## B) Design-System Architecture Integration

| Check | Result | Evidence |
|---|---|---|
| Design architecture map exists | PASS | `docs/design/DESIGN_SYSTEM_ARCHITECTURE.md` |
| Core design files referenced by map exist | PASS | `lib/core/design/*`, `lib/core/theme/*` |
| Navigation centralization artifacts exist | PASS | `lib/core/navigation/*`, wrappers in presentation |
| Design guardrails in CI | PASS | `.github/workflows/quick-tests.yml` runs `tool/design_guardrails.dart` |
| Design golden baseline exists | PASS | `test/widget/design/design_playground_golden_test.dart` + goldens |
| Grouped suite includes design golden checks | **FAIL** | no `test/widget/design` coverage in `test/suites/*_suite.sh` |

## C) Testing-Suite Grouping Readiness

| Check | Result | Evidence |
|---|---|---|
| Grouped suite framework exists | PASS | `test/suites/*.sh`, `all_suites.sh`, `README.md` |
| Referenced test paths resolve | **FAIL** | 41 missing paths of 140 references (suite scripts) |
| Missing paths are remappable to new structure | PASS (recoverable) | Most map to `test/integration/<domain>/...` |
| Grouped suite docs use current repo naming/paths | **FAIL** | `test/suites/README.md` uses `/Users/reisgordon/SPOTS/...` |
| Core CI test script uses current directory layout | PARTIAL | `scripts/test_core.sh` includes missing `test/unit/usecases` path (silently skipped) |
| Legacy testing plan is current | **FAIL** | `test/testing/comprehensive_testing_plan.md` is SPOTS-era and path-stale |

---

## 3) Detailed Findings (Ordered by Severity)

## High

1. **Grouped suite scripts reference stale integration paths**  
   - Impact: grouped domain suite runs are not reliable indicators of architecture/domain health.  
   - Evidence: 41 missing references across suite scripts under `test/suites/`.  
   - Pattern: old `test/integration/<file>.dart` paths now live under domain folders like:
     - `test/integration/ai/`
     - `test/integration/events/`
     - `test/integration/payments/`
     - `test/integration/infrastructure/`
     - `test/integration/security/`

2. **No grouped suite covers design golden tests**  
   - Impact: design-system regressions may pass grouped suite runs and appear later.  
   - Evidence: suite scripts do not include `test/widget/design/`; only CI guardrails run.

## Medium

3. **Suite documentation uses stale SPOTS absolute paths**  
   - Impact: onboarding/usage confusion, lower reliability for manual runs.  
   - Evidence: `test/suites/README.md` uses `/Users/reisgordon/SPOTS/...`.

4. **Core test script includes non-existent directory**  
   - Impact: expected coverage area can silently skip (`test/unit/usecases`).  
   - Evidence: `scripts/test_core.sh` references `test/unit/usecases`; current layout has `test/unit/domain/usecases`.

5. **Comprehensive testing plan is stale relative to architecture and repo naming**  
   - Impact: planning drift and incorrect operational assumptions for monitoring setup.  
   - Evidence: `test/testing/comprehensive_testing_plan.md` (SPOTS naming, absolute SPOTS cron paths).

---

## 4) Readiness Matrix (Architecture + Design + Tests)

| Area | Status | Ready for Execution? | Notes |
|---|---|---|---|
| Architecture phase mapping | Green | Yes | 1-15 mapped and gated |
| Owner boundaries | Green | Yes | Backlog ownership model present |
| Design architecture and guardrails | Green | Yes | Files + CI guardrail present |
| Grouped test suites (domain) | Red | No | stale path references must be normalized |
| Design test grouping | Red | No | add design grouping path into suite strategy |
| Test ops documentation freshness | Amber | Partial | stale docs need refresh before relying operationally |

---

## 5) Prep-Only Remediation Backlog (No Code Scaffolding)

These are planning/governance updates to complete before implementation starts:

1. **Suite Path Normalization Plan (Phase 10 / QAE)**
   - Define and approve canonical suite path map from old flat integration paths to new domainized paths.
   - Add this as explicit story under `MPA-P10-E1`.

2. **Design Test Grouping Plan (Phase 10 / QAE+APP)**
   - Define grouped suite coverage for `test/widget/design` golden tests and route-level design checks.
   - Add this as explicit story under `MPA-P10-E2`.

3. **Testing Docs Freshness Plan (Phase 10 / PMO+QAE)**
   - Refresh `test/suites/README.md` and `test/testing/comprehensive_testing_plan.md` to AVRAI naming and current layout.
   - Add as prep checklist gate before “execution-ready” mark.

4. **Core Test Target Manifest Plan (Phase 10 / QAE)**
   - Document the authoritative list of target directories for `scripts/test_core.sh`.
   - Explicitly include `test/unit/domain/usecases`.

---

## 6) Master Plan Connection

This audit maps primarily to:

- **Phase 10** (Feature completion, cleanup, codebase polish, quality hardening)
- **Phase 7.12** (Observation and introspection signals for quality)
- **Phase 12.2** (Self-coding/testing gate rigor)

---

## 7) Final Statement

The architecture and design layers are materially prepared.  
The **single remaining prep-risk** to “grouped testing without flaws” is suite/path freshness and grouping completeness.  
Once the prep-only remediation items above are planned and accepted, readiness is fully green.

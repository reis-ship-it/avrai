# Codebase -> Master Plan File Mapping (2026-02-15)

**Purpose:** File-level architecture mapping for keep/update/refactor/delete decisions aligned to `docs/MASTER_PLAN.md`.
**Coverage:** All tracked non-doc files under runtime/source/tooling roots (`lib/`, `packages/`, `native/`, `scripts/`, `supabase/`, `test/`, `tool/`, `assets/`, platform dirs).
**Total mapped files:** 497
**Generated artifact:** `docs/plans/architecture/generated/codebase_master_plan_mapping_2026-02-15.csv`
**Method:** Deterministic path-to-phase rules with explicit confidence values and strict per-file dependency-graph payloads (`dependency_graph`).

## Disposition Summary

| Disposition | File Count |
|---|---:|
| keep_review | 365 |
| keep_update | 132 |

## Domain Summary

| Domain | File Count |
|---|---:|
| tooling-ops | 365 |
| supabase-infra | 126 |
| data-platform-sql | 6 |

## Highest-Volume Buckets (Top 40)

| Bucket | File Count |
|---|---:|
| scripts/ecommerce_experiments/results | 28 |
| supabase/functions/ecommerce-enrichment | 6 |
| scripts/personality_data/converters | 5 |
| scripts/personality_data/processors | 4 |
| scripts/personality_data/utils | 4 |
| scripts/autopilot/hitl | 3 |
| scripts/autopilot/queue | 3 |
| scripts/ci/baselines | 3 |
| scripts/personality_data/cli | 3 |
| scripts/personality_data/loaders | 3 |
| scripts/personality_data/registry | 3 |
| scripts/autopilot/templates | 2 |
| supabase/functions/atomic-timing-orchestrator | 2 |
| supabase/functions/geo-place-insights-v1 | 2 |
| supabase/functions/llm-chat-stream | 2 |
| scripts/EXECUTE_SPOTS_DEVELOPMENT.sh | 1 |
| scripts/README_ADMIN_BACKEND_TEST.md | 1 |
| scripts/README_DESIGN_TOKEN_FIX.md | 1 |
| scripts/README_INTEGRATION_TESTING.md | 1 |
| scripts/README_TEST_FIX_AUTOMATION.md | 1 |
| scripts/add_admin_credential.dart | 1 |
| scripts/add_business_credential.dart | 1 |
| scripts/ai_list_generator.sh | 1 |
| scripts/ai_list_optimizer.sh | 1 |
| scripts/analyze_test_coverage.sh | 1 |
| scripts/analyze_test_failures.py | 1 |
| scripts/analyze_test_quality.py | 1 |
| scripts/analyze_unused_imports.py | 1 |
| scripts/android_build_fix.sh | 1 |
| scripts/android_version_manager.sh | 1 |
| scripts/audit_test_headers.sh | 1 |
| scripts/autopilot/README.md | 1 |
| scripts/autopilot/config.json | 1 |
| scripts/autopilot/milestones | 1 |
| scripts/autopilot/orchestrator.py | 1 |
| scripts/autopilot/run.sh | 1 |
| scripts/autopilot/snapshots | 1 |
| scripts/autopilot/state | 1 |
| scripts/background_agent_cleanup_integration.sh | 1 |
| scripts/background_agent_main.sh | 1 |

## Delete Candidates

- None identified by deterministic rules.

## Manual Review Required (Sample)

- None.

## Operational Use

1. Use the CSV as the execution source when scheduling keep/update/refactor/delete actions.
2. Any `delete_candidate` or `review_required` entry must be validated against runtime references (`rg`, DI registrations, imports) before deletion.
3. Refactor execution should follow phased dependencies in `docs/MASTER_PLAN.md` (notably 10.2, 10.7, 10.8).

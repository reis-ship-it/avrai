# Codebase -> Master Plan File Mapping (2026-02-15)

**Purpose:** File-level architecture mapping for keep/update/refactor/delete decisions aligned to `docs/MASTER_PLAN.md`.
**Coverage:** All tracked non-doc files under runtime/source/tooling roots (`lib/`, `packages/`, `native/`, `scripts/`, `supabase/`, `test/`, `tool/`, `assets/`, platform dirs).
**Total mapped files:** 2854
**Generated artifact:** `docs/plans/architecture/generated/codebase_master_plan_mapping_2026-02-15.csv`
**Method:** Deterministic path-to-phase rules with explicit confidence values and strict per-file dependency-graph payloads (`dependency_graph`).

## Disposition Summary

| Disposition | File Count |
|---|---:|
| keep_update | 2496 |
| keep_review | 332 |
| refactor_planned | 26 |

## Domain Summary

| Domain | File Count |
|---|---:|
| testing-quality | 873 |
| presentation | 381 |
| core-services-general | 366 |
| tooling-ops | 284 |
| package-modules | 207 |
| core-models | 141 |
| supabase-infra | 124 |
| world-model-ai-core | 108 |
| platform-runtime | 62 |
| data-layer | 55 |
| assets | 24 |
| native-modules | 24 |
| ml-legacy-and-transition | 22 |
| security-signal-ffi | 21 |
| workflow-controllers | 21 |
| ai2ai-network | 20 |
| domain-layer | 19 |
| config-and-theme | 15 |
| security-signal | 14 |
| app-composition-root | 13 |
| security-services | 11 |
| monitoring-observability | 9 |
| quantum-package | 7 |
| data-platform-sql | 6 |
| cloud-integration | 4 |
| crypto-core | 3 |
| legal-domain | 3 |
| search-retrieval | 3 |
| tooling-dev | 3 |
| core-utils | 2 |
| deployment-sync | 2 |
| legacy-advanced-services | 2 |
| legacy-p2p | 2 |
| supabase-integration-entrypoints | 2 |
| places-location-intelligence | 1 |

## Highest-Volume Buckets (Top 40)

| Bucket | File Count |
|---|---:|
| lib/core/services | 378 |
| lib/presentation/widgets | 204 |
| test/unit/services | 188 |
| lib/presentation/pages | 173 |
| lib/core/models | 141 |
| lib/core/ai | 108 |
| test/widget/widgets | 101 |
| packages/avrai_knot/lib | 84 |
| packages/avrai_network/lib | 67 |
| test/widget/pages | 56 |
| test/unit/models | 55 |
| test/unit/ai | 49 |
| packages/avrai_core/lib | 34 |
| scripts/ecommerce_experiments/results | 28 |
| android/app | 27 |
| lib/data/datasources | 26 |
| test/core/services | 24 |
| lib/core/ml | 22 |
| lib/core/controllers | 21 |
| lib/core/ai2ai | 20 |
| test/unit/data | 20 |
| test/integration/ai | 19 |
| test/unit/ai2ai | 18 |
| lib/core/crypto | 17 |
| test/integration/controllers | 17 |
| test/unit/controllers | 17 |
| lib/domain/usecases | 15 |
| native/knot_math/src | 15 |
| test/unit/domain | 14 |
| lib/data/repositories | 13 |
| test/core/crypto | 13 |
| test/integration/infrastructure | 12 |
| test/integration/services | 12 |
| assets/three_js/lib | 10 |
| lib/core/theme | 10 |
| lib/data/database | 10 |
| test/unit/ml | 10 |
| lib/core/monitoring | 9 |
| test/integration/security | 9 |
| test/integration/expertise | 8 |

## Delete Candidates

- None identified by deterministic rules.

## Manual Review Required (Sample)

- None.

## Operational Use

1. Use the CSV as the execution source when scheduling keep/update/refactor/delete actions.
2. Any `delete_candidate` or `review_required` entry must be validated against runtime references (`rg`, DI registrations, imports) before deletion.
3. Refactor execution should follow phased dependencies in `docs/MASTER_PLAN.md` (notably 10.2, 10.7, 10.8).

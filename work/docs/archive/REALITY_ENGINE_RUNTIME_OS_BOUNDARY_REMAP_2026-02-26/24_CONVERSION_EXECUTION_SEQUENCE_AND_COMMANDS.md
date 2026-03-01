# 24 - Conversion Execution Sequence and Commands

## 1) Recommended Sequence

1. Patch docs (master plan + architecture + governance)
2. Patch execution board and tracker docs
3. Regenerate board/mapping artifacts
4. Activate boundary checks (baseline mode)
5. Run validation commands
6. Merge conversion PR
7. Resume Phase 1 workstream

## 2) Command Runbook (Local)

```bash
# Board sync
dart run tool/update_execution_board.dart
dart run tool/update_execution_board.dart --check

# Architecture mapping and placement
python3 scripts/generate_master_plan_file_mapping.py
python3 scripts/generate_architecture_spots_registry.py
python3 scripts/validate_architecture_placement.py

# Existing architecture guard
melos run check:architecture

# Recommended new guard scripts (after added)
# dart run scripts/ci/check_engine_runtime_boundaries.dart
# dart run scripts/ci/check_runtime_contract_conformance.dart
# dart run scripts/ci/check_headless_engine_smoke.dart
# dart run scripts/ci/check_cross_os_capability_matrix.dart

# Traceability pre-check
python3 scripts/validate_pr_traceability.py \
  --title "PRD-XXX Mx-Py-z" \
  --body "refs: 10.10.1, 1.4.24" \
  --require-execution-id \
  --require-single-milestone \
  --require-master-plan-ref
```

## 3) PR Split Recommendation

PR 1: docs + board + tracker + governance text updates
PR 2: CI guard implementation
PR 3: first boundary-safe code extraction for Phase 1 modules

This reduces blast radius and shortens review cycles.

## 4) Immediate Resume Path for Phase 1

After PR 1 and PR 2 merge and checks are green:
1. Continue `1.4.24-1.4.29` decomposition tasks.
2. Require each extraction PR to pass boundary guards + parity tests.
3. Keep behavior-change work separate from structure-change work.


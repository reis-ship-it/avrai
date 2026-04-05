# Split-Pass CI Guard/Contract Hardening Report

**Source config:** `configs/runtime/split_pass_ci_guard_contract_hardening_controls.json`  
**Workflow path:** `.github/workflows/execution-board-guard.yml`  
**Generated at:** 2026-02-27T21:45:00Z  
**Required commands checked:** 12  
**Verdict:** FAIL

## Missing Commands

- dart run tool/update_execution_board.dart --check
- dart run tool/update_three_prong_reviews.dart --check

## Duplicated Commands

- None

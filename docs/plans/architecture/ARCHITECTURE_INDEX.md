# Architecture Documentation Index

**Last Updated:** February 28, 2026  
**Status:** Active Reference (Current Architecture)  
**Purpose:** Canonical navigation for architecture documents aligned to the current codebase and `docs/MASTER_PLAN.md`.

---

## Canonical Sources (Read First)

- **Product requirements authority:** [`docs/PRD.md`](../../PRD.md)
- **Execution plan:** [`docs/MASTER_PLAN.md`](../../MASTER_PLAN.md)
- **Build-doc wiring authority:** [`docs/plans/methodology/BUILD_DOCS_WIRING_INDEX.md`](../methodology/BUILD_DOCS_WIRING_INDEX.md)
- **Execution status (canonical):** [`docs/agents/status/status_tracker.md`](../../agents/status/status_tracker.md)
- **Plan registry (catalog, not live status):** [`docs/MASTER_PLAN_TRACKER.md`](../../MASTER_PLAN_TRACKER.md)
- **Phase rationale docs:** [`docs/plans/rationale/`](../rationale/)

---

## Codebase-to-Plan Mapping (Current)

- **File-level mapping summary:** [`CODEBASE_MASTER_PLAN_MAPPING_2026-02-15.md`](./CODEBASE_MASTER_PLAN_MAPPING_2026-02-15.md)
- **Generated full mapping CSV (2,844 files):** [`generated/codebase_master_plan_mapping_2026-02-15.csv`](./generated/codebase_master_plan_mapping_2026-02-15.csv)
- **Strict per-file dependency graph:** `dependency_graph` column in generated mapping CSV (authoritative move/refactor order + dependency edges)
- **Architecture spots registry (build-enforced):** [`ARCHITECTURE_SPOTS_REGISTRY.csv`](./ARCHITECTURE_SPOTS_REGISTRY.csv)
- **File placement policy (build-enforced):** [`FILE_PLACEMENT_POLICY.md`](./FILE_PLACEMENT_POLICY.md)
- **Generator script:** [`scripts/generate_master_plan_file_mapping.py`](../../../scripts/generate_master_plan_file_mapping.py)
- **Spots registry generator:** [`scripts/generate_architecture_spots_registry.py`](../../../scripts/generate_architecture_spots_registry.py)
- **Placement validator:** [`scripts/validate_architecture_placement.py`](../../../scripts/validate_architecture_placement.py)
- **Architecture alignment audit:** [`ARCHITECTURE_DOCS_ALIGNMENT_2026-02-15.md`](./ARCHITECTURE_DOCS_ALIGNMENT_2026-02-15.md)

Use this set when deciding file disposition (`keep_update`, `refactor_planned`, `delete_candidate`) and phase ownership.

---

## Core Architecture Guardrails

- **Repo hygiene and boundary rules:** [`REPO_HYGIENE_AND_ARCHITECTURE_RULES.md`](./REPO_HYGIENE_AND_ARCHITECTURE_RULES.md)
- **Universal self-healing contract (all subsystems):** [`docs/MASTER_PLAN.md` section `Universal Self-Healing Contract` + task `10.9.12`](../../MASTER_PLAN.md)
- **Autonomous research + experimentation governance:** [`AUTONOMOUS_RESEARCH_EXPERIMENTATION_ENGINE.md`](./AUTONOMOUS_RESEARCH_EXPERIMENTATION_ENGINE.md)
- **Dream training + conviction hierarchy governance:** [`DREAM_TRAINING_CONVICTION_GOVERNANCE.md`](./DREAM_TRAINING_CONVICTION_GOVERNANCE.md)
- **Canonical experiment registry (build-enforced):** [`docs/EXPERIMENT_REGISTRY.md`](../../EXPERIMENT_REGISTRY.md)
- **Experiment registry source CSV:** [`configs/experiments/EXPERIMENT_REGISTRY.csv`](../../../configs/experiments/EXPERIMENT_REGISTRY.csv)
- **Experiment registry generator:** [`scripts/generate_experiment_registry.py`](../../../scripts/generate_experiment_registry.py)
- **Experiment registry validator:** [`scripts/validate_experiment_registry.py`](../../../scripts/validate_experiment_registry.py)
- **ML training governance authority:** [`docs/plans/methodology/ML_TRAINING_AUTOMATION_GOVERNANCE.md`](../methodology/ML_TRAINING_AUTOMATION_GOVERNANCE.md)
- **Execution/PR traceability integration:** [`docs/plans/methodology/PRD_EXECUTION_BOARD_INTEGRATION.md`](../methodology/PRD_EXECUTION_BOARD_INTEGRATION.md)
- **Build enforcement setup:** [`docs/GITHUB_ENFORCEMENT_SETUP.md`](../../GITHUB_ENFORCEMENT_SETUP.md)
- **Red-team hijack/security matrix (governance authority):** [`docs/security/RED_TEAM_TEST_MATRIX.md`](../../security/RED_TEAM_TEST_MATRIX.md)
- **AVRAI native type contracts:** [`configs/ml/avrai_native_type_contracts.json`](../../../configs/ml/avrai_native_type_contracts.json)
- **AVRAI dataset builder:** [`scripts/ml/build_training_dataset.py`](../../../scripts/ml/build_training_dataset.py)

---

## Research Addenda (External -> AVRAI Mapping)

- [`EXTERNAL_RESEARCH_ANALYSIS_2026-02-23_ONLINE_OFFLINE_AI2AI.md`](./EXTERNAL_RESEARCH_ANALYSIS_2026-02-23_ONLINE_OFFLINE_AI2AI.md)
- [`generated/external_research_crossref_2026-02-23_online_offline_ai2ai.csv`](./generated/external_research_crossref_2026-02-23_online_offline_ai2ai.csv)
- [`EXTERNAL_RESEARCH_ADDENDUM_PHASE_PLACEMENT_MATRIX_2026-02-16.md`](./EXTERNAL_RESEARCH_ADDENDUM_PHASE_PLACEMENT_MATRIX_2026-02-16.md)
- [`EXTERNAL_RESEARCH_ADDENDUM_2026-02-15_ARXIV_2602_09000.md`](./EXTERNAL_RESEARCH_ADDENDUM_2026-02-15_ARXIV_2602_09000.md)
- [`EXTERNAL_RESEARCH_ADDENDUM_2026-02-15_ARXIV_2601_19897.md`](./EXTERNAL_RESEARCH_ADDENDUM_2026-02-15_ARXIV_2601_19897.md)
- [`EXTERNAL_RESEARCH_ADDENDUM_2026-02-15_ARXIV_2602_12259.md`](./EXTERNAL_RESEARCH_ADDENDUM_2026-02-15_ARXIV_2602_12259.md)
- [`EXTERNAL_RESEARCH_ADDENDUM_2026-02-16_ARXIV_2501_02305.md`](./EXTERNAL_RESEARCH_ADDENDUM_2026-02-16_ARXIV_2501_02305.md)
- [`EXTERNAL_RESEARCH_ADDENDUM_2026-02-16_ARXIV_2502_17779.md`](./EXTERNAL_RESEARCH_ADDENDUM_2026-02-16_ARXIV_2502_17779.md)
- [`EXTERNAL_RESEARCH_ADDENDUM_2026-02-16_ARXIV_2602_11136.md`](./EXTERNAL_RESEARCH_ADDENDUM_2026-02-16_ARXIV_2602_11136.md)
- [`EXTERNAL_RESEARCH_ADDENDUM_2026-02-16_ARXIV_2602_11865.md`](./EXTERNAL_RESEARCH_ADDENDUM_2026-02-16_ARXIV_2602_11865.md)
- [`EXTERNAL_RESEARCH_ADDENDUM_2026-02-16_BATCH_ADAPTIVE_REASONING_RUNTIME.md`](./EXTERNAL_RESEARCH_ADDENDUM_2026-02-16_BATCH_ADAPTIVE_REASONING_RUNTIME.md)
- [`EXTERNAL_RESEARCH_ADDENDUM_2026-02-17_FEEDBACK_CONVICTION_DATAOPS.md`](./EXTERNAL_RESEARCH_ADDENDUM_2026-02-17_FEEDBACK_CONVICTION_DATAOPS.md)
- [`EXTERNAL_RESEARCH_ADDENDUM_2026-02-19_RECURSIVE_META_KERNELS_AND_DISCOVERABILITY.md`](./EXTERNAL_RESEARCH_ADDENDUM_2026-02-19_RECURSIVE_META_KERNELS_AND_DISCOVERABILITY.md)
- [`EXTERNAL_RESEARCH_ADDENDUM_2026-02-19_ARXIV_2507_00885.md`](./EXTERNAL_RESEARCH_ADDENDUM_2026-02-19_ARXIV_2507_00885.md)
- [`EXTERNAL_RESEARCH_ADDENDUM_2026-02-20_ARXIV_2602_17632.md`](./EXTERNAL_RESEARCH_ADDENDUM_2026-02-20_ARXIV_2602_17632.md)
- [`EXTERNAL_RESEARCH_ADDENDUM_2026-02-20_ARXIV_2602_16873.md`](./EXTERNAL_RESEARCH_ADDENDUM_2026-02-20_ARXIV_2602_16873.md)
- [`EXTERNAL_RESEARCH_ADDENDUM_2026-02-15_GITHUB_NANOBOT.md`](./EXTERNAL_RESEARCH_ADDENDUM_2026-02-15_GITHUB_NANOBOT.md)
- [`EXTERNAL_RESEARCH_ADDENDUM_2026-02-15_BATCH_OTHERS.md`](./EXTERNAL_RESEARCH_ADDENDUM_2026-02-15_BATCH_OTHERS.md)

Use these when changing world-model training/planning behavior or model lifecycle policy.

---

## AI2AI / Offline / Runtime Architecture

- **Runtime transport migration status checkpoint (current):** [`MIGRATION_STATUS_RUNTIME_TRANSPORT_2026-02-28.md`](./MIGRATION_STATUS_RUNTIME_TRANSPORT_2026-02-28.md)
- **3-prong architecture visualization guide (external + internal + endpoint flows):** [`THREE_PRONG_ARCHITECTURE_VISUALIZATION_GUIDE_2026-02-27.md`](./THREE_PRONG_ARCHITECTURE_VISUALIZATION_GUIDE_2026-02-27.md)
- **Target codebase structure enforcement policy (default placement for new work):** [`TARGET_CODEBASE_STRUCTURE_ENFORCEMENT_2026-02-27.md`](./TARGET_CODEBASE_STRUCTURE_ENFORCEMENT_2026-02-27.md)
- **Refactor fast-lane playbook (slice-by-slice migration workflow):** [`REFACTOR_FASTLANE_PLAYBOOK_2026-02-27.md`](./REFACTOR_FASTLANE_PLAYBOOK_2026-02-27.md)
- **Unified Runtime Kernel canonical blueprint (current):** [`UNIFIED_RUNTIME_KERNEL_BLUEPRINT_2026-02-27.md`](./UNIFIED_RUNTIME_KERNEL_BLUEPRINT_2026-02-27.md)
- **Unified Runtime Kernel interface contracts (current):** [`URK_INTERFACE_CONTRACTS_2026-02-27.md`](./URK_INTERFACE_CONTRACTS_2026-02-27.md)
- **URK admin console route pathway (current):** [`URK_ADMIN_CONSOLE_PATHWAY_2026-02-27.md`](./URK_ADMIN_CONSOLE_PATHWAY_2026-02-27.md)
- **Online/offline strategy:** [`ONLINE_OFFLINE_STRATEGY.md`](./ONLINE_OFFLINE_STRATEGY.md)
- **Offline cloud AI architecture:** [`OFFLINE_CLOUD_AI_ARCHITECTURE.md`](./OFFLINE_CLOUD_AI_ARCHITECTURE.md)
- **AI2AI federated architecture:** [`architecture_ai_federated_p2p.md`](./architecture_ai_federated_p2p.md)
- **Offline AI2AI docs:** [`docs/plans/offline_ai2ai/`](../offline_ai2ai/)
- **Runtime/OS remap pack (including large-file split guide):**
  [`REALITY_ENGINE_RUNTIME_OS_REMAP_2026-02-26/README.md`](./REALITY_ENGINE_RUNTIME_OS_REMAP_2026-02-26/README.md)
  and [`../../../REALITY_ENGINE_RUNTIME_OS_BOUNDARY_REMAP_2026-02-26/26_CODE_SPLIT_AND_CROSS_OS_COMPATIBILITY_QUICK_GUIDE.md`](../../../REALITY_ENGINE_RUNTIME_OS_BOUNDARY_REMAP_2026-02-26/26_CODE_SPLIT_AND_CROSS_OS_COMPATIBILITY_QUICK_GUIDE.md)
  and [`../../../REALITY_ENGINE_RUNTIME_OS_BOUNDARY_REMAP_2026-02-26/27_LARGE_FILE_SPLIT_BACKLOG_AND_QUEUE.md`](../../../REALITY_ENGINE_RUNTIME_OS_BOUNDARY_REMAP_2026-02-26/27_LARGE_FILE_SPLIT_BACKLOG_AND_QUEUE.md)
- **3-prong boundary guard (build-enforced):** [`scripts/ci/check_three_prong_boundaries.py`](../../../scripts/ci/check_three_prong_boundaries.py)
- **Cross-OS runtime capability contracts:** `configs/runtime/capabilities/*.json`
- **Runtime capability contract validator:** [`scripts/ci/check_runtime_capability_contracts.py`](../../../scripts/ci/check_runtime_capability_contracts.py)

Canonical runtime transport source of truth:
- BLE transport lanes: `lib/runtime/avrai_runtime_os/services/transport/ble/*`
- Mesh transport lanes: `lib/runtime/avrai_runtime_os/services/transport/mesh/*`

Note: the historical filename `architecture_ai_federated_p2p.md` remains in use, but current architecture principle is **ai2ai-only (never p2p)** as defined in `docs/MASTER_PLAN.md`.

---

## Data/Ledger Architecture

- **Expertise ledger + capabilities:** [`EXPERTISE_LEDGER_AND_CAPABILITIES_V1.md`](./EXPERTISE_LEDGER_AND_CAPABILITIES_V1.md)
- **Shared append-only journal (v0):** [`docs/plans/ledgers/LEDGERS_V0_INDEX.md`](../ledgers/LEDGERS_V0_INDEX.md)

---

## How To Use This Index

1. Start with `docs/MASTER_PLAN.md` for phase ownership and sequencing.
2. Use the file mapping CSV to determine file-level actions for the current codebase.
3. Validate guardrails and governance docs before enabling autonomous/self-improving behavior.
4. Use status tracker for progress; do not infer execution status from architecture docs alone.

---

## Legacy/Reference Notes

Legacy documents may still be useful for context, but implementation authority comes from:
- `docs/MASTER_PLAN.md`
- `docs/agents/status/status_tracker.md`
- `docs/plans/rationale/`
- current mapping artifacts above

# Architecture Documentation Index

**Last Updated:** February 15, 2026  
**Status:** Active Reference (Current Architecture)  
**Purpose:** Canonical navigation for architecture documents aligned to the current codebase and `docs/MASTER_PLAN.md`.

---

## Canonical Sources (Read First)

- **Execution plan:** [`docs/MASTER_PLAN.md`](../../MASTER_PLAN.md)
- **Execution status (canonical):** [`docs/agents/status/status_tracker.md`](../../agents/status/status_tracker.md)
- **Plan registry (catalog, not live status):** [`docs/MASTER_PLAN_TRACKER.md`](../../MASTER_PLAN_TRACKER.md)
- **Phase rationale docs:** [`docs/plans/rationale/`](../rationale/)

---

## Codebase-to-Plan Mapping (Current)

- **File-level mapping summary:** [`CODEBASE_MASTER_PLAN_MAPPING_2026-02-15.md`](./CODEBASE_MASTER_PLAN_MAPPING_2026-02-15.md)
- **Generated full mapping CSV (2,842 files):** [`generated/codebase_master_plan_mapping_2026-02-15.csv`](./generated/codebase_master_plan_mapping_2026-02-15.csv)
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
- **Autonomous research + experimentation governance:** [`AUTONOMOUS_RESEARCH_EXPERIMENTATION_ENGINE.md`](./AUTONOMOUS_RESEARCH_EXPERIMENTATION_ENGINE.md)

---

## Research Addenda (External -> AVRAI Mapping)

- [`EXTERNAL_RESEARCH_ADDENDUM_2026-02-15_ARXIV_2602_09000.md`](./EXTERNAL_RESEARCH_ADDENDUM_2026-02-15_ARXIV_2602_09000.md)
- [`EXTERNAL_RESEARCH_ADDENDUM_2026-02-15_ARXIV_2601_19897.md`](./EXTERNAL_RESEARCH_ADDENDUM_2026-02-15_ARXIV_2601_19897.md)
- [`EXTERNAL_RESEARCH_ADDENDUM_2026-02-15_BATCH_OTHERS.md`](./EXTERNAL_RESEARCH_ADDENDUM_2026-02-15_BATCH_OTHERS.md)

Use these when changing world-model training/planning behavior or model lifecycle policy.

---

## AI2AI / Offline / Runtime Architecture

- **Online/offline strategy:** [`ONLINE_OFFLINE_STRATEGY.md`](./ONLINE_OFFLINE_STRATEGY.md)
- **Offline cloud AI architecture:** [`OFFLINE_CLOUD_AI_ARCHITECTURE.md`](./OFFLINE_CLOUD_AI_ARCHITECTURE.md)
- **AI2AI federated architecture:** [`architecture_ai_federated_p2p.md`](./architecture_ai_federated_p2p.md)
- **Offline AI2AI docs:** [`docs/plans/offline_ai2ai/`](../offline_ai2ai/)

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

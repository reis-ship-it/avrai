# Architecture Docs Alignment Audit (2026-02-15)

**Goal:** Ensure architecture documentation is aligned with the current codebase and `docs/MASTER_PLAN.md` execution model.  
**Scope:** `docs/plans/architecture/*` plus canonical status/rationale references.

## Alignment Decisions

- `docs/MASTER_PLAN.md` is the execution authority.
- `docs/agents/status/status_tracker.md` is the canonical progress tracker.
- Architecture docs are design references and must map to active phases or be marked as contextual/legacy.
- File-level execution decisions use the generated mapping artifacts:
  - `docs/plans/architecture/CODEBASE_MASTER_PLAN_MAPPING_2026-02-15.md`
  - `docs/plans/architecture/generated/codebase_master_plan_mapping_2026-02-15.csv`

## Coverage Summary

- Runtime/source/tooling files mapped: **2,844**
- Mapping disposition summary:
  - `keep_update`: 2,496
  - `keep_review`: 322
  - `refactor_planned`: 26
  - `delete_candidate`: 0

## Architecture Document Status Matrix

| Document | Status | Applies To Current Codebase | Master Plan Linkage | Notes |
|---|---|---|---|---|
| `ARCHITECTURE_INDEX.md` | Current | Yes | Global | Updated to reference canonical authorities + mapping artifacts |
| `CODEBASE_MASTER_PLAN_MAPPING_2026-02-15.md` | Current | Yes | Phases 1-11 | File-disposition summary over generated CSV |
| `ARCHITECTURE_SPOTS_REGISTRY.csv` | Current | Yes | Global | Registered architecture spots for build-time placement enforcement |
| `FILE_PLACEMENT_POLICY.md` | Current | Yes | Global | Build-enforced rule: every file must map to a registered spot |
| `.github/workflows/architecture-placement-guard.yml` | Current | Yes | Global | CI guard that fails on unmapped/unregistered file placement |
| `REPO_HYGIENE_AND_ARCHITECTURE_RULES.md` | Current | Yes | 10.7, methodology | Guardrails for boundaries and generated artifacts |
| `AUTONOMOUS_RESEARCH_EXPERIMENTATION_ENGINE.md` | Current | Yes | 7.x, 8, 11.4 | Governance for bounded autonomous improvement |
| `DREAM_TRAINING_CONVICTION_GOVERNANCE.md` | Current | Yes | 1.1E, 5.2, 6.2, 7.7, 7.9, 8.1, 10.9 | Belief-tier safety architecture for bounded dream training and conviction promotion |
| `EXTERNAL_RESEARCH_ADDENDUM_2026-02-15_*.md` | Current | Yes | 1, 3, 4, 5, 6 | Research-informed planning references |
| `OFFLINE_CLOUD_AI_ARCHITECTURE.md` | Reference | Partial | 6.7, 7.x | Useful, but verify implementation details before code changes |
| `ONLINE_OFFLINE_STRATEGY.md` | Reference | Partial | 7.5, 10.x | Strategy-level; not a file-level execution source |
| `architecture_ai_federated_p2p.md` | Reference (Name Legacy) | Partial | 8.x | Keep for context; architecture principle is ai2ai-only in Master Plan |
| `EXPERTISE_LEDGER_AND_CAPABILITIES_V1.md` | Reference | Yes | 9.x, 10.x | Domain-specific architecture reference |
| `AI_DATA_CENTER_RESILIENCE.md` | Reference | Contextual | 7.x, 8.x | Not execution-authoritative for current phase sequencing |
| `INTERNET_REPLACEMENT_AND_NETWORK_BACKUP.md` | Reference | Contextual | 7.x, 8.x | Validate assumptions before implementation |
| `LOCAL_LLM_MODEL_PACK_SYSTEM.md` | Reference | Contextual | 6.7, 7.5 | Align with current device-tier constraints before execution |
| `OUTSIDE_BUYER_PAID_ACCESS.md` | Reference | Contextual | 9.x | Business-focused; use with current compliance constraints |
| `OUTSIDE_DATA_BUYER_INSIGHTS_DATA_CONTRACT_V1.md` | Reference | Yes | 9.2.6 | Current for outside-buyer pipeline context |

## Required Execution Rule

For any architecture-driven code change:

1. Confirm phase ownership in `docs/MASTER_PLAN.md`.
2. Confirm rollout/status constraints in `docs/agents/status/status_tracker.md`.
3. Confirm file disposition in `generated/codebase_master_plan_mapping_2026-02-15.csv`.
4. If a file is `delete_candidate` or `refactor_planned`, run dependency checks before modification/deletion.

## Open Follow-Ups

1. Add a periodic review to upgrade `Reference` docs that become execution-critical.
2. Track rename plan for `architecture_ai_federated_p2p.md` to eliminate naming ambiguity.

# AVRAI Product Requirements Document (PRD)

**Version:** 1.0  
**Date:** February 15, 2026  
**Status:** Active (Canonical Product Requirements Layer)  
**Owner:** Product + Architecture + Core Engineering

## 1. Purpose

Define stable, testable product requirements that prevent execution drift across planning, implementation, and CI enforcement.

This PRD is the intent layer. It is implemented through:
- `docs/MASTER_PLAN.md` (phase execution plan)
- `docs/agents/status/status_tracker.md` (execution status)
- architecture placement/mapping guardrails in `docs/plans/architecture/`

## 2. Product Outcome

AVRAI must deliver privacy-preserving, offline-first, self-improving intelligence that helps users discover meaningful real-world people/places/events while maintaining strict safety/compliance boundaries.

## 3. Scope

In scope:
- World-model-driven recommendation and planning architecture
- AI2AI-first network intelligence and federated learning
- Privacy, security, and compliance hard constraints
- Build-enforced architecture placement and codebase-to-plan mapping

Out of scope:
- Reintroducing feature-first planning outside Master Plan sequencing
- Unbounded self-modifying production behavior without promotion gates

## 4. Requirement IDs (Canonical)

### 4.1 Product Requirements

- **PRD-001**: The product must optimize for meaningful real-world outcomes, not engagement-maximization.
- **PRD-002**: The system must improve from passive behavioral signals; chat is an accelerator, never a requirement.
- **PRD-003**: Recommendations must be explainable at the level of surfaced signals and policy constraints.

### 4.2 Architecture Requirements

- **PRD-010**: `docs/MASTER_PLAN.md` is the execution authority for sequencing and dependencies.
- **PRD-011**: `docs/agents/status/status_tracker.md` is the canonical execution status source.
- **PRD-012**: Every tracked code/infrastructure file must map to a Master Plan-aligned architecture classification.
- **PRD-013**: Every tracked file must belong to a registered architecture spot.
- **PRD-014**: If no existing architecture spot fits a new file, a new spot must be explicitly created before merge.

### 4.3 Safety, Compliance, and Governance

- **PRD-020**: Hard safety/compliance boundaries are immutable by autonomous tuning.
- **PRD-021**: Self-improving ranking/planning changes require shadow/canary gates and rollback paths.
- **PRD-022**: Promotions require traceable metrics and auditable artifacts.

### 4.4 Build and Process Requirements

- **PRD-030**: CI must fail if a tracked file is unmapped in architecture mapping artifacts.
- **PRD-031**: CI must fail if a tracked file maps to an unregistered architecture spot.
- **PRD-032**: CI must fail if mapping/registry generated artifacts are stale relative to repo state.
- **PRD-033**: PRs must declare impacted requirement IDs for traceability.

## 5. Acceptance Criteria

A change is PRD-compliant only if:

1. It maps to one or more requirement IDs in this PRD.
2. It maps to `MASTER_PLAN` phase/task ownership.
3. It passes architecture placement guard CI.
4. It preserves safety/compliance invariants.
5. It includes tests/validation appropriate to change risk.

## 6. Traceability Matrix

| PRD ID | Implemented/Enforced By | Primary Artifact |
|---|---|---|
| PRD-010 | Planning authority | `docs/MASTER_PLAN.md` |
| PRD-011 | Status authority | `docs/agents/status/status_tracker.md` |
| PRD-012 | File-level architecture mapping | `docs/plans/architecture/generated/codebase_master_plan_mapping_2026-02-15.csv` |
| PRD-013 | Spot registry | `docs/plans/architecture/ARCHITECTURE_SPOTS_REGISTRY.csv` |
| PRD-014 | Placement policy | `docs/plans/architecture/FILE_PLACEMENT_POLICY.md` |
| PRD-020 | Safety/compliance constraints | `docs/MASTER_PLAN.md` (Phases 2, 6.2, 7.7A) |
| PRD-021 | Gated autonomy | `docs/MASTER_PLAN.md` (7.7A), model lifecycle sections |
| PRD-022 | Audit + rollback | `docs/MASTER_PLAN.md` (7.7, 7.7A), architecture governance docs |
| PRD-030/31/32 | Build enforcement | `.github/workflows/architecture-placement-guard.yml`, `scripts/validate_architecture_placement.py` |
| PRD-033 | PR traceability discipline | `.github/pull_request_template.md` |

## 7. Change Management

PRD changes require:

1. Update this document with a version/date bump.
2. Update linked enforcement or planning artifacts if requirements changed.
3. Include migration notes for active workstreams impacted by the change.
4. Reference PRD IDs in the corresponding pull request.

## 8. Operational References

- `docs/MASTER_PLAN.md`
- `docs/MASTER_PLAN_TRACKER.md`
- `docs/agents/status/status_tracker.md`
- `docs/plans/architecture/ARCHITECTURE_INDEX.md`
- `docs/plans/architecture/ARCHITECTURE_DOCS_ALIGNMENT_2026-02-15.md`

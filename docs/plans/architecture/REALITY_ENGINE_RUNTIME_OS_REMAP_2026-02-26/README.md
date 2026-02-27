# Reality Engine + Runtime OS Remap (2026-02-26)

## Purpose

This folder defines the boundary remap for AVRAI as a 3-layer system:

1. Reality Engine (independent cognition layer)
2. AVRAI Runtime OS (downloadable coexisting runtime on top of device OS)
3. AVRAI Product App (host UX and product workflows)

This is the canonical package for turning separation intent into executable architecture and governance updates.

## Files

- `ARCHITECTURE_REMAP_AND_TARGET_STRUCTURE.md`
  - Optimized target file/package structure for engine, runtime, app, third-party, internal research, and system monitoring.
- `CROSS_OS_RUNTIME_ARCHITECTURE_AND_CAPABILITY_MATRIX.md`
  - Cross-OS architecture (iOS, Android, macOS, Windows, Linux) and capability-tier strategy.
- `MASTER_PLAN_IMPROVEMENT_PROPOSAL.md`
  - Concrete updates proposed for `docs/MASTER_PLAN.md` to reflect the 3-layer truth.
- `BUILD_CI_GOVERNANCE_UPDATE_SPEC.md`
  - Required CI/build/release-policy changes to enforce new boundaries.
- `IMPLEMENTATION_ROADMAP_AND_MILESTONES.md`
  - 30/60/90 and phase-linked rollout plan with acceptance criteria.

## Canonical Framing

- Reality Engine is product-agnostic but runtime-dependent.
- AVRAI Runtime OS is the required substrate that bridges device OS constraints.
- AVRAI Product App is one host application of the runtime+engine stack.


# Reality Engine + Runtime OS + AVRAI App Boundary Remap

Date: 2026-02-26
Status: Architecture recommendation package

## Objective

Define clear and enforceable boundaries for:
- Reality Engine (independent cognition system)
- AVRAI Runtime OS (downloadable coexisting runtime over native OS)
- AVRAI Product App (host UX and product workflows)

This package provides a practical, optimized working structure and the docs needed to update build/governance and master-plan direction without stopping ongoing delivery.

## Files

- `01_ARCHITECTURE_REMAP_AND_TARGET_STRUCTURE.md`
- `02_CROSS_OS_RUNTIME_ARCHITECTURE_AND_CAPABILITY_MATRIX.md`
- `03_MASTER_PLAN_IMPROVEMENT_PROPOSAL.md`
- `04_BUILD_CI_GOVERNANCE_UPDATE_SPEC.md`
- `05_IMPLEMENTATION_ROADMAP_AND_MILESTONES.md`
- `06_GLOSSARY_AND_BOUNDARY_RULES.md`
- `26_CODE_SPLIT_AND_CROSS_OS_COMPATIBILITY_QUICK_GUIDE.md`

## Canonical Truth

1. Reality Engine is product-agnostic, but runtime-contract dependent.
2. AVRAI Runtime OS is the required substrate for mesh/identity/policy/scheduling/security under device OS constraints.
3. AVRAI Product App is a host application of the runtime+engine stack.

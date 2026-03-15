# AVRAI Why Kernel Architecture And Rollout

**Date:** March 6, 2026  
**Status:** Initial implementation authority  
**Purpose:** Define the canonical `why` ontology and rollout path for causal attribution across AVRAI's cognitive OS.

## Scope

`why` is now treated as a core OS kernel concern rather than a locality-only helper. The first implementation slice keeps `explain_why` inside the existing native locality kernel boundary for compatibility, while the data model and runtime contracts are generalized for cross-kernel use.

## Implemented Contract

Shared canonical models live in:

- `shared/avrai_core/lib/models/why/why_models.dart`

Runtime support and redaction live in:

- `runtime/avrai_runtime_os/lib/kernel/why/why_kernel_contract.dart`
- `runtime/avrai_runtime_os/lib/kernel/why/why_kernel_support.dart`

Native canonical + legacy handling lives in:

- `runtime/avrai_network/native/locality_kernel/src/why_kernel.rs`

Compatibility export for existing locality callers remains:

- `runtime/avrai_runtime_os/lib/kernel/locality/locality_why_contract.dart`

## Request Model

The canonical `WhyKernelRequest` supports:

- `goal`
- `subjectRef`
- `actionRef`
- `outcomeRef`
- `queryKind`
- `evidenceBundle`
- `linkedWhoRefs`
- `linkedWhatRefs`
- `linkedWhereRefs`
- `linkedWhenRefs`
- `linkedHowRefs`
- `policyContext`
- `requestedPerspective`
- `maxCounterfactuals`
- `explanationDepth`

Legacy locality signal arrays are still accepted and normalized into canonical evidence.

## Snapshot Model

The canonical `WhySnapshot` now includes:

- query kind
- primary and alternate hypotheses
- ranked drivers and inhibitors
- bounded counterfactuals
- confidence and ambiguity
- root-cause classification
- trace refs
- conflicts
- governance envelope
- validation issues
- schema version

## Redaction Rules

- `system`, `admin`, `governance`: full structured explanation
- `agent`: redacts traces, conflicts, and policy refs
- `user_safe`: redacts traces, conflicts, policy refs, and escalation thresholds

## Rollout Notes

This slice establishes:

1. one canonical shared `why` ontology
2. canonical request decoding in the stub bridge
3. fallback/runtime explanation support with perspective-aware redaction
4. native Rust support for canonical and legacy payloads
5. tests for canonical bridge handling, policy explanations, and user-safe redaction

Remaining rollout work after this slice should focus on additional evidence producers and product/admin surfaces rather than redesigning the core `why` contract again.

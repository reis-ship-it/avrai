# AVRAI Language Kernel Stack Beta Authority

**Date:** March 12, 2026  
**Status:** Active beta implementation authority

## Purpose

Define the local-first language mediation stack that sits between users, the runtime, and the AVRAI brain:

1. `InterpretationKernel` = ears
2. `BoundaryKernel` = privacy membrane / air-gap-aware gate
3. `ExpressionKernel` = mouth

The stack exists so:

1. human input can be interpreted without giving raw text direct authority over the brain,
2. privacy and consent can be enforced before learning or egress,
3. all dynamic AVRAI-authored language can remain attached to grounded kernel truth.

## Placement

The stack belongs in the `runtime/*` prong.

1. `engine/*` owns truth, planning, memory, and explanation basis.
2. `runtime/*` owns interpretation, privacy gating, consent, policy, and expression.
3. `apps/*` own capture and rendering only.

## Kernel Responsibilities

### 1. InterpretationKernel

Consumes human-authored text and emits typed meaning artifacts:

1. intent
2. request summary
3. extracted questions
4. preference signals
5. learning artifact
6. privacy sensitivity
7. ambiguity / clarification state

It may learn local phrasing patterns. It may not persist raw text as brain truth.

### 2. BoundaryKernel

Consumes:

1. actor identity
2. consent scopes
3. privacy mode
4. raw text
5. interpretation result
6. egress intent

It emits:

1. disposition
2. storage / learning / egress permissions
3. air-gap requirement
4. reason codes
5. sanitized artifact

It is the runtime membrane around the existing engine-side Air Gap. It does not replace the `TupleExtractionEngine`; it governs when and how typed user language may become learnable or shareable.

### 3. ExpressionKernel

Consumes only grounded claims and emits:

1. `UtterancePlan`
2. deterministic rendered output
3. validation result

It never originates truth.

## Native Requirement

All three kernels are Rust-native by preference and are exposed to Dart through JSON FFI:

1. `runtime/avrai_network/native/interpretation_kernel/`
2. `runtime/avrai_network/native/boundary_kernel/`
3. `runtime/avrai_network/native/expression_kernel/`

Fallback behavior is deterministic local Dart logic only when native libraries are unavailable.

## Beta Live Path

Current live beta path:

1. `PersonalityAgentChatService` routes human input through `LanguageKernelOrchestratorService`
2. `LanguageKernelOrchestratorService` calls:
   - `InterpretationKernelService`
   - `BoundaryKernelService`
   - `LanguagePatternLearningService` only when learning is allowed
3. recommendation explanation output already routes through `ExpressionKernel`

## Non-Negotiable Rules

1. Raw human text is not source-of-truth for the brain.
2. Learning from human language is local-first and consent-gated.
3. Any outbound sharing of user-origin text-derived meaning must pass boundary review and, when allowed, egress through an air-gap-aware path.
4. Dynamic AVRAI-authored copy must be produced by `ExpressionKernel` or a future equivalent that preserves the same grounded-claim contract.

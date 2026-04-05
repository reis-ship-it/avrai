# AVRAI Expression Kernel Beta Architecture

**Date:** March 12, 2026  
**Status:** Proposed implementation authority for beta  
**Purpose:** Define a Rust-native, local-first `ExpressionKernel` that acts as the "mouth" of AVRAI while remaining fully attached to kernel truth.

---

## 1. Core Decision

AVRAI's user-facing language layer must be a **kernel projection system**, not an independent chatbot.

This means:

1. the mouth may only express claims that the AVRAI brain has authorized,
2. the mouth must work locally and fail closed when local language generation is unavailable,
3. adaptation for usability is allowed, but only as bounded local learning,
4. truth, policy, and governance remain upstream authorities,
5. cloud language generation is not a beta dependency.

The code name for this subsystem should be **`ExpressionKernel`**. "Mouth" remains the product metaphor.

---

## 2. Why This Exists

The AVRAI brain already has structured truth pathways:

1. model truth and learning in `engine/*`,
2. runtime execution and policy in `runtime/*`,
3. user-facing surfaces in `apps/*`,
4. explanation snapshots and kernel bundles in existing runtime/shared contracts.

What is missing is a **first-class output kernel** that:

1. consumes kernel truth,
2. binds it to the current user-safe perspective,
3. converts it into a typed utterance plan,
4. renders user-facing language without inventing reality.

This kernel should be treated the same way AVRAI treats `what`, `when`, `where`, `how`, and `why`: as a distinct cognitive OS authority with clear syscall boundaries.

---

## 3. Three-Prong Placement

This design must obey the repository's three-prong authority split:

1. **Apps Prong** in `apps/*`
2. **Runtime OS Prong** in `runtime/*`
3. **Reality Model Prong** in `engine/*`

### 3.1 Reality Model Prong responsibility

The reality model owns:

1. truth,
2. planning,
3. action choice,
4. uncertainty,
5. evidence and explanation basis.

It does **not** own final phrasing.

### 3.2 Runtime OS Prong responsibility

The runtime owns:

1. perspective selection,
2. permission enforcement,
3. policy filtering,
4. utterance compilation,
5. lexicalization backend routing,
6. output validation,
7. local adaptation state.

The `ExpressionKernel` therefore belongs in the **Runtime OS prong**.

### 3.3 Apps Prong responsibility

Apps own:

1. layout,
2. presentation,
3. animations,
4. interaction capture,
5. user feedback signals.

Apps must not decide meaning. They render `ExpressionKernel` output.

---

## 4. Native Placement

The beta target is a **Rust-native** expression kernel with a Dart/runtime bridge, matching the existing native kernel pattern under `runtime/avrai_network/native/*`.

Recommended path:

1. add `runtime/avrai_network/native/expression_kernel/`
2. expose a JSON FFI syscall entrypoint such as `avrai_expression_kernel_invoke_json`
3. mirror the current native kernel shape used by `who`, `what`, `why`, and governance kernels
4. keep platform adapters thin in Dart

The Rust kernel should be:

1. local-first,
2. deterministic at its contract boundary,
3. auditable,
4. versioned,
5. headless-OS compatible.

---

## 5. Upstream Authorities The Expression Kernel Must Consume

The runtime already exposes the correct three authority channels in `kernel_prong_ports.dart`:

1. `ModelTruthPort`
2. `RuntimeExecutionPort`
3. `TrustGovernancePort`

These are the expression kernel's primary upstream dependencies.

The expression kernel must also consume the fused kernel bundle:

1. `who`
2. `what`
3. `when`
4. `where`
5. `how`
6. `why`

Together these form the only allowed source of user-facing meaning.

---

## 6. Contract Shape

The expression kernel must not emit raw text as source-of-truth. It must emit a typed `UtterancePlan`.

Minimum contract:

1. `speechAct`
2. `audience`
3. `allowedClaims`
4. `forbiddenClaims`
5. `evidenceRefs`
6. `confidenceBand`
7. `uncertaintyNotice`
8. `toneProfile`
9. `surfaceShape`
10. `sections`
11. `cta`
12. `fallbackText`
13. `adaptationProfileRef`
14. `schemaVersion`

### 6.1 `speechAct`

Allowed beta acts:

1. `recommend`
2. `explain`
3. `clarify`
4. `ask`
5. `decline`
6. `reassure`
7. `confirm`
8. `warn`

### 6.2 `audience`

Allowed beta perspectives:

1. `user_safe`
2. `agent`
3. `admin`
4. `governance`

### 6.3 `surfaceShape`

Beta shapes:

1. card
2. chat_turn
3. banner
4. settings_explainer
5. modal
6. receipt
7. empty_state
8. error_state

---

## 7. Execution Pipeline

The beta expression pipeline should be:

1. **Intent selection**  
   Determine the allowed speech act from the event/request type.

2. **Claim ledger build**  
   Build the finite list of facts the mouth may say.

3. **Governance filter**  
   Remove claims that are not permitted for the current perspective or policy mode.

4. **Utterance plan compile**  
   Arrange claims into a structured output plan.

5. **Lexicalization**  
   Render the plan through one of the allowed backends.

6. **Validation**  
   Verify that output text contains no unsupported claims.

7. **Fallback**  
   If validation fails, return deterministic template output.

---

## 8. Rendering Backends

The expression kernel should support multiple renderers behind one contract.

### 8.1 Deterministic renderer

This is the mandatory beta fallback and should cover all critical surfaces.

Uses:

1. templates,
2. slot filling,
3. sentence planning,
4. confidence-aware phrasing,
5. explicit uncertainty handling.

### 8.2 Local lexicalizer

This is the preferred beta enhancement path.

It may:

1. smooth phrasing,
2. vary sentence rhythm,
3. compress or expand explanations,
4. personalize tone,
5. ask safe clarifying questions.

It may not:

1. invent new facts,
2. introduce new entities,
3. widen the topic beyond the `UtterancePlan`,
4. answer open-world questions without grounded claims.

### 8.3 Optional future renderers

Future-compatible but not beta-required:

1. Apple Foundation Models lexicalizer
2. bundled local model pack lexicalizer
3. larger local SLM on capable devices

Cloud rendering is optional future fallback, not a beta requirement.

---

## 9. Local Learning And Safe Self-Modification

The expression kernel should be learnable and adaptive, but **must not mutate truth, policy, or core kernel code**.

Safe self-modification means:

1. learning phrasing preferences,
2. learning readability preferences,
3. learning preferred sentence length,
4. learning preferred directness and warmth,
5. learning terminology the user responds to better,
6. learning which phrasing patterns reduce confusion and improve trust.

It does not mean:

1. rewriting core reasoning logic,
2. changing safety policy,
3. inventing unsupported claims,
4. silently changing governance rules,
5. modifying source code or native binaries at runtime.

### 9.1 Local adaptive state

Store on-device only:

1. `ExpressionProfile`
2. `LexiconMemory`
3. `ClarityFeedbackHistory`
4. `RepairHistory`
5. `TonePreferenceState`
6. `SurfacePerformanceStats`

### 9.2 What may adapt

Allowed adaptive dimensions:

1. verbosity,
2. sentence complexity,
3. concrete vs abstract phrasing,
4. uncertainty wording,
5. tone warmth,
6. preferred lexical choices,
7. explanation ordering,
8. CTA phrasing.

### 9.3 What may not adapt

Locked dimensions:

1. policy boundaries,
2. privacy rules,
3. allowed claim set,
4. forbidden claim set,
5. evidence provenance,
6. governance perspective rules.

### 9.4 Adaptation mechanism

For beta, adaptation should be lightweight and local:

1. ranking phrase variants,
2. adjusting template weights,
3. maintaining a user-local lexicon,
4. storing accepted/rejected clarification patterns,
5. optionally learning tiny adapter weights for a local lexicalizer.

Any adaptation must be:

1. reversible,
2. bounded,
3. attributable,
4. auditable,
5. resettable by the user.

---

## 10. Validation Rules

Every rendered utterance must pass validation before it is shown.

Required checks:

1. every factual phrase maps to an `allowedClaim`,
2. every named entity maps to an approved reference,
3. no unsupported temporal or locality claim may appear,
4. confidence language must reflect actual confidence band,
5. required uncertainty notices must be present when needed,
6. output must obey audience perspective,
7. output must obey policy restrictions.

If validation fails:

1. discard rendered text,
2. log local telemetry,
3. emit deterministic fallback text,
4. count failure for future adaptation penalties.

---

## 11. Rust-Native Beta Shape

The first Rust-native beta version should expose a small syscall surface:

1. `compile_utterance_plan`
2. `render_deterministic`
3. `render_local_lexicalized`
4. `validate_utterance`
5. `record_expression_feedback`
6. `snapshot_expression_profile`
7. `reset_expression_profile`
8. `diagnose_expression_kernel`

The kernel must remain useful even when only `compile_utterance_plan` and `render_deterministic` are implemented.

---

## 12. Recommended Beta Roadmap

### Phase A

1. Define shared `UtterancePlan` contract
2. Define `ExpressionProfile` contract
3. Add deterministic renderer
4. Add validator

### Phase B

1. Add Rust-native expression kernel crate
2. Bridge to Dart/runtime
3. Route core beta surfaces through it

### Phase C

1. Add local lexicalizer
2. Add local adaptation memory
3. Add resettable user-local preference learning

### Phase D

1. Add adapter-based refinement for tone and phrasing
2. Keep deterministic fallback mandatory

---

## 13. Beta Recommendation

For the beta, the correct mouth architecture is:

1. `ExpressionKernel` in Rust native under runtime,
2. local-first,
3. deterministic by default,
4. optional local lexicalizer on top,
5. user-language adaptation through bounded local learning,
6. no cloud dependency required,
7. no freeform truth invention permitted.

This preserves:

1. trust,
2. explainability,
3. local operation,
4. future usability learning,
5. compatibility with the AVRAI cognitive OS direction.

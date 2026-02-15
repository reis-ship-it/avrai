# Human Condition Spectra Plan

**Date:** February 14, 2026  
**Status:** Proposed Addendum (new)  
**Priority:** High  
**Scope:** Reality Model extension across individual, group, locality, and universe layers

---

## Purpose

Make "undefined human spectrums" first-class in AVRAI so the system can learn from human paradox without forcing hard labels.

This plan adds explicit architecture for:
- Human traits that are real in behavior but fuzzy in definition
- Contradictions between self-report, behavior, and outcomes
- Time-asymmetric identity (past self, present state, future self-belief)
- User agency to challenge model convictions safely

---

## Current State (Already Present)

The codebase and master plan already include strong primitives:
- Confidence-tagged, freshness-tagged input normalization
- Behavioral-first learning with chat as accelerator
- Drift detection and exploration adjustment
- Conviction challenge protocol and scope exceptions
- User agency doctrine (suggest, never force)
- Contextual personality planning (core + context + life-phase timeline)

These pieces exist, but there is no single explicit framework for "undefined spectrums" as a modeling doctrine.

---

## Gap To Close

Missing today:
1. A canonical model for spectrums that do not have universal definitions.
2. A user-facing conviction challenge flow (current challenge controls are mostly creator/admin side).
3. An explicit "state vs trait vs phase" contract used across planner, learning, and explanations.
4. Guardrails for high-noise/extreme signals so the model stays adaptive but stable.

---

## Core Design

### 1) Spectrum-First Representation

Do not represent fuzzy human concepts as single labels.

Represent each as:
- `latent_dimensions`: multi-axis values in `[0,1]`
- `confidence`
- `context_scope` (solo, social, work, location, time-window)
- `half_life` (how quickly signal decays)
- `evidence_depth`
- `contradiction_rate`

Interpretation rule:
- Never expose a latent axis as identity truth ("you are X").
- Expose as context-limited tendencies ("in this context, currently likely X").

### 2) State vs Trait vs Phase Contract

Every inference must be classified as:
- `State`: short-lived condition (hours-days)
- `Trait`: medium stability tendency (weeks-months)
- `Phase`: long transition pattern (months-years)

Update rules:
- State updates fast, decays fast.
- Trait updates moderate, requires repeated evidence.
- Phase changes require sustained evidence + contradiction tests.

### 3) User-Facing Conviction Challenge

Add user control surface:
- `Challenge this belief`
- Scope options: `just now`, `this context`, `this week`, `long-term`
- Strength options: `soft`, `hard`
- Reason tags: `temporary mood`, `life change`, `wrong context`, `not me`
- Immediate effect preview + undo window

Model behavior:
- Apply immediate local override for UX.
- Log challenge event to evidence graph.
- Evaluate over time before trait/phase/global propagation.
- Keep scope exceptions when disagreement stays local.

### 4) Spectrum Safety (Stability + Agency)

Safeguards:
- No single-session hard rewrites for trait/phase inferences.
- Mood-shock dampening for clustered negatives.
- Adversarial/noise detection (inconsistent challenge bursts).
- Blast-radius control: user challenge cannot directly rewrite community/universe convictions.
- Human override always allowed at delivery layer; epistemic update still evidence-based.

---

## Individual + Group + Both

### Individual Layer
- Learn personal latent distributions with uncertainty bands.
- Respect explicit user overrides as high-priority local constraints.
- Keep contradictory evidence as "parallel hypotheses" until resolved.

### Group/Community Layer
- Aggregate only DP-safe embeddings/statistics.
- Promote shared patterns only with multi-user, multi-context validation.
- Preserve minority/edge patterns as non-pruned hypotheses where outcome impact is high.

### Cross-Layer (Both)
- Bottom-up: repeated individual signals can become community priors.
- Top-down: community priors initialize cold start with low amplitude.
- Tension engine tracks persistent disagreement between layers and creates scope exceptions.

---

## Handling "No True Definition" Concepts

Principle:
- If a concept has no stable universal definition, AVRAI treats it as an operational family of measurable signals, not a universal ontology.

Example pattern:
- Replace one abstract label with a vector of observable proxies, each with confidence and context.
- Keep explanatory language soft and contextual.
- Optimize on outcomes, not semantic certainty.

Why:
- Prevents identity essentialism.
- Keeps model falsifiable and revisable.
- Matches reality-model doctrine: truths are earned and provisional.

---

## Implementation Tasks

### Phase A: Data Contract (1-2 weeks)
- Add `SpectrumInference` model with:
  - `spectrum_id`
  - `axes: Map<String,double>`
  - `confidence`
  - `scope`
  - `temporal_class` (`state|trait|phase`)
  - `half_life`
  - `evidence_count`
  - `contradiction_rate`
- Add storage + serialization.

### Phase B: Challenge UX + API (2-3 weeks)
- Add user-facing "Challenge this belief" controls.
- Add `UserConvictionChallenge` event schema.
- Add immediate local override and undo.
- Add explanation panel: "what changed and why".

### Phase C: Learning Logic (2-3 weeks)
- Implement state/trait/phase update rates.
- Add contradiction-aware hypothesis tracking.
- Add scope exception resolution in wisdom layer.
- Add propagation gates for community/universe updates.

### Phase D: Safety + Evaluation (1-2 weeks)
- Add volatility/abuse guards.
- Add bad-day dampening integration for challenge events.
- Add metrics + dashboards.
- Run canary experiments on recommendation quality and user trust.

---

## Success Metrics

Primary:
- Lower repeat "that's not me" rate
- Higher acceptance after challenge events
- Faster recovery from model misread after life changes
- No increase in overfitting instability

Safety:
- Reduced cross-user contamination from isolated edge signals
- Stable long-horizon planning quality
- No regression in user agency (override latency, undo success)

---

## Risks

1. Overfitting to short-term self-narratives  
Mitigation: state/trait/phase gating + evidence thresholds.

2. Model instability from high contradiction traffic  
Mitigation: contradiction queues, hypothesis budgeting, dampening.

3. Excess complexity in UX  
Mitigation: progressive disclosure (simple default, advanced controls optional).

---

## Why This Improves The Entire Reality Model

- Increases truthfulness under human paradox.
- Encodes agency without collapsing model rigor.
- Makes temporal identity explicit rather than implicit.
- Preserves edge-case human diversity while still learning collective patterns.

This is required for a reality model that aims to represent humans as they are: contextual, contradictory, evolving, and never fully reducible to fixed labels.


# TGTBT Master Plan Integration Source

**Last Updated:** February 23, 2026  
**Status:** Draft source for Master Plan + philosophy document integration

## 1. Purpose

This document is the single source for integrating "Too Good To Be True" (TGTBT) safeguards into:

- `docs/MASTER_PLAN.md`
- `docs/plans/philosophy_implementation/AVRAI_PHILOSOPHY_AND_ARCHITECTURE.md`
- `docs/plans/philosophy_implementation/BIAS_AND_DIGNITY_GUARDRAILS.md`

It combines:

- 16 TGTBT safeguards
- what is already written in the Master Plan
- what is partially covered
- what is not yet written
- exact insertion IDs and section placement guidance

Companion structured matrix:

- `docs/plans/philosophy_implementation/TOO_GOOD_TO_BE_TRUE_SAFEGUARD_PLACEMENT_MATRIX.csv`

## 2. Coverage Snapshot (Current Master Plan)

### 2.1 Already Written (Directly Supports TGTBT)

| Capability | Master Plan Reference |
|---|---|
| High-impact uncertainty/counter-view controls | `1.4.19` (`docs/MASTER_PLAN.md:394`), `6.2.24` (`docs/MASTER_PLAN.md:1045`) |
| Cognitive-surrender interaction telemetry | `1.4.18` (`docs/MASTER_PLAN.md:393`) |
| Confidence-after-error correction loop | `1.4.20` (`docs/MASTER_PLAN.md:395`), `6.2.26` (`docs/MASTER_PLAN.md:1047`) |
| Adaptive trust-profile pacing | `1.4.21` (`docs/MASTER_PLAN.md:396`), `6.2.27` (`docs/MASTER_PLAN.md:1048`) |
| Delayed conviction validation windows | `1.4.14` (`docs/MASTER_PLAN.md:389`), `10.9J row 14` (`docs/MASTER_PLAN.md:2139`) |
| Confidence-vs-outcome divergence promotion gate | `5.2.31` (`docs/MASTER_PLAN.md:967`), `7.7A.9` (`docs/MASTER_PLAN.md:1304`) |
| Self-healing evidence-quality requirements | `10.9.3` (`docs/MASTER_PLAN.md:1862`), `10.9J.1` (`docs/MASTER_PLAN.md:2162`) |
| Observability provenance for adaptive decisions | `10.9.9` (`docs/MASTER_PLAN.md:1868`) |

### 2.2 Partially Covered (Concept Exists, TGTBT-Specific Logic Missing)

| Gap Theme | Current Anchor | Missing Specificity |
|---|---|---|
| Conviction feedback | `1.4.13` (`docs/MASTER_PLAN.md:388`) | No explicit `too_good_to_be_true` enum/value |
| Reflective alternative controls | `1.4.19` (`docs/MASTER_PLAN.md:394`) | No explicit conservative-variant/pilot execution contract |
| Explainability and audit | Explainability row (`docs/MASTER_PLAN.md:78`), `10.9.9` | No explicit external machine-readable verifiability pack for entities |
| Delayed conviction discipline | `1.4.14` (`docs/MASTER_PLAN.md:389`) | No belief-outcome latency metrics tuned for high-upside claim classes |

### 2.3 Not Yet Written (Explicit Gaps)

| Missing Capability |
|---|
| Dedicated TGTBT signal schema + telemetry |
| Distinct `model_confidence` vs `adoption_confidence` channels |
| Automatic low-trust routing to pilot mode |
| Skepticism mismatch failure signature in `10.9J` |
| Skeptic persona promotion gate |
| Anti-hype language policy for high-upside claims |
| Claim class taxonomy tied to evidence floors |
| Extraordinary-claim evidence multiplier |
| Structured pre-mortem artifact requirement |
| Counterfactual baseline presentation requirement |
| Trust recovery cooldown policy after failed bold claims |
| Skepticism-preserving recourse UX (`challenge_assumption`) |
| Human skepticism research lane (quarterly) |

## 3. TGTBT Safeguards (16) with Integration Status

Status legend:

- `Already`: exists explicitly in current Master Plan
- `Partial`: adjacent capability exists; TGTBT-specific implementation missing
- `Not Written`: requires new plan/task text

| ID | Safeguard | Proposed Task ID | Status | Primary Placement |
|---|---|---|---|---|
| TGTBT-01 | Too-good-to-be-true explicit feedback signal | `1.4.22` | Not Written | Section 1.4 after `1.4.21` |
| TGTBT-02 | Plausibility translation contract for conversational SLM | `2.1.8D` | Not Written | Section 2.1 transparency tasks |
| TGTBT-03 | Trust-preserving pilot mode | `6.2.28` | Not Written | Section 6.2 after `6.2.27` |
| TGTBT-04 | Self-healing trigger for skepticism mismatch | `10.9.22` | Not Written | Section 10.9 + `10.9J` |
| TGTBT-05 | Human skepticism research lane | `7.9.51` | Not Written | Section 7.9 after `7.9.50` |
| TGTBT-06 | Claim class taxonomy (`incremental/step-change/breakthrough`) | `6.1.22` | Not Written | Section 6.1 after `6.1.18` |
| TGTBT-07 | Extraordinary-claim evidence multiplier | `7.7A.12` | Not Written | Section 7.7A after `7.7A.9` |
| TGTBT-08 | Pre-mortem requirement for high-upside recommendations | `6.2.29` | Partial | Section 6.2 |
| TGTBT-09 | Counterfactual baseline presentation | `6.1.23` | Partial | Section 6.1 explainability controls |
| TGTBT-10 | Two-channel confidence (`model` vs `adoption`) | `5.1.17` | Not Written | Section 5.1 after `5.1.16` |
| TGTBT-11 | Trust recovery policy after failed bold claim | `6.2.30` | Not Written | Section 6.2 + section 10.9 reference |
| TGTBT-12 | External verifiability pack for businesses/entities | `2.1.8E` | Partial | Section 2.1 + 7.7 manifest linkage |
| TGTBT-13 | Anti-hype language policy for high-upside claims | `2.1.8F` | Not Written | Section 2.1 + BIAS language section |
| TGTBT-14 | Skeptic persona red-team gate | `7.9.52` | Not Written | Section 7.9 + 7.7A gate linkage |
| TGTBT-15 | Belief-outcome latency tracking for bold claims | `1.4.23` | Not Written | Section 1.4 after `1.4.22` |
| TGTBT-16 | Skepticism-preserving recourse UX | `2.1.8G` | Not Written | Section 2.1 + recourse policy linkage |

## 4. Priority Packaging for Master Plan Add

### 4.1 P0 Insertions (First Pass)

- `1.4.22` TGTBT explicit signal
- `2.1.8D` plausibility translation contract
- `5.1.17` two-channel confidence
- `6.1.22` claim class taxonomy
- `6.2.28` trust-preserving pilot mode
- `6.2.29` pre-mortem requirement
- `6.2.30` trust recovery policy
- `7.7A.12` extraordinary-claim evidence multiplier
- `7.9.52` skeptic persona gate
- `10.9.22` skepticism mismatch self-healing control

### 4.2 P1 Insertions (Second Pass)

- `1.4.23` belief-outcome latency tracking
- `2.1.8E` external verifiability pack
- `2.1.8F` anti-hype language policy
- `2.1.8G` skepticism-preserving recourse UX
- `6.1.23` counterfactual baseline presentation
- `7.9.51` human skepticism research lane

## 5. Philosophy Document Placement (Companion Updates)

### 5.1 `AVRAI_PHILOSOPHY_AND_ARCHITECTURE.md`

Suggested additions:

- Section 8 Product Behavior Rules: skepticism is a valid correction signal, not resistance to be optimized away.
- Section 8.1 Tri-System Agency Boundary: high-impact claims require plausibility translation and reversible pilot path.
- Section 10 Success Condition: success includes trust calibration and recoverability after overclaim.

### 5.2 `BIAS_AND_DIGNITY_GUARDRAILS.md`

Suggested additions:

- Section 9 Language Guidance: anti-hype bounded-claim policy for high-upside recommendations.
- Section 10 Recourse and Repair: skepticism-specific challenge route and conservative variant path.
- Section 12 Cognitive Surrender Safeguard: treat TGTBT skepticism as safety signal and never as user-fault.

## 6. 10.9J Self-Healing Matrix Expansion Targets

Add canonical rows:

- Row 33: High-upside skepticism non-adoption
  - Trigger: repeated TGTBT signals on high-confidence high-upside claims
  - Control: translation recalibration + pilot-mode reroute
- Row 34: High-confidence low-adoption friction
  - Trigger: model confidence high, adoption confidence low
  - Control: conservative route + staged trust restoration
- Row 35: Output hype risk
  - Trigger: high-impact claim language implies certainty beyond evidence bounds
  - Control: anti-hype release block + bounded-language requirement + assumption/uncertainty rendering
- Row 36: Trust recovery failure
  - Trigger: repeated failed bold claims degrade trust in domain
  - Control: stricter evidence thresholds + conservative-route requirement + delayed conviction recovery criteria

## 7. Implementation Note

For machine-readable planning and spreadsheet analysis, use the CSV as source-of-truth field matrix:

- `docs/plans/philosophy_implementation/TOO_GOOD_TO_BE_TRUE_SAFEGUARD_PLACEMENT_MATRIX.csv`

For human-readable integration and writing updates, use this file:

- `docs/plans/philosophy_implementation/TGTBT_MASTER_PLAN_INTEGRATION_SOURCE.md`

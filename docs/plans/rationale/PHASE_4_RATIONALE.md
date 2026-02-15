# Phase 4 Rationale: Energy Function & Formula Replacement

**Phase:** 4 | **Tier:** 1 (Core intelligence, parallel with Phases 3 and 5) | **Duration:** 6-8 weeks  
**Companion to:** `docs/MASTER_PLAN.md` Phase 4  
**Read before starting:** `FOUNDATIONAL_DECISIONS.md` (Decisions #2, #3, #11, #14)

---

## Why This Phase Exists

This is the heart of the intelligence-first architecture. The energy function replaces ALL 30+ hardcoded scoring formulas with a single learned critic network. Instead of `0.4 * vibe + 0.3 * betterment + 0.15 * connection + 0.1 * context + 0.05 * timing`, the model learns the optimal combination from real outcomes.

**Why this is the gap other frameworks miss:** Even the latest unified world model proposals -- Zeng et al. (arXiv:2602.01630, Feb 2026) being the most comprehensive -- don't include a cost function or energy scoring concept. Their framework has Interaction (perception), Reasoning, Memory, Environment, and Multimodal Generation, but no component that answers "how good is this state-action pair?" numerically. Their Reasoning module infers causality and physical laws, which is useful for understanding *why* something happened, but not for ranking *which of 50 candidates is best for this person right now*. LeCun's Cost Module (Critic) -- implemented as AVRAI's energy function -- fills this gap. The energy function is a fast, differentiable scalar scorer that rank-orders candidates without needing symbolic reasoning for every comparison. This is why AVRAI can score 50 candidates in under 200ms on a mobile device: it's computing energy, not reasoning about each one.

---

## Key Design Decisions

### Why One Energy Function Replaces All Formulas
The 30+ existing formulas each have hand-tuned weights that:
- Were chosen by engineering intuition, not validated by outcomes
- Can't adapt to individual users (everyone gets the same weights)
- Can't adapt to changing user behavior over time
- Create inconsistency (is a 0.7 from `CallingScoreCalculator` comparable to a 0.7 from `GroupMatchingService`?)

A single energy function produces a unified scale (low energy = good) trained on what actually works for each user.

### Why the Replacement Schedule Is Ordered (4.2.1 through 4.2.26)
Formulas are replaced in priority order based on:
1. **Impact**: How many users does this formula affect?
2. **Data availability**: Does Phase 1 collect outcome data for this formula's domain?
3. **Complexity**: How many hand-tuned weights does it have?

`CallingScoreCalculator` is first (4.2.1) because it has the most weights (40/30/15/10/5) and already has a data collection pipeline (`CallingScoreDataCollector`).

### Why Bidirectional Energy (4.4)
See Foundational Decision #14. In short: user-to-spot matching is one-sided (does the user like it?), but communities, events, connections, lists, partnerships, and sponsorships are bilateral. A community that gains a member who damages community health is a bad match even if the user benefits.

The `entity_energy` guardrail (4.4.14) enforces this: if the entity-side energy is very high (bad for the community/list/business), the recommendation is suppressed even if the user-side energy is low (good for user).

### Why Explainability (4.6)
The energy function is a neural network -- it can't explain its decisions. But users need to know WHY something was recommended. Feature attribution (4.6.1) identifies which input features most influenced the score. The SLM (Phase 6.7) translates those attributions into "doors" language: "this spot resonates with your adventurous side" instead of "quantum state inner product was 0.87."

### Why Transition Period UX (4.5)
Users are currently getting recommendations from the formula system. When the energy function starts replacing formulas, recommendations will change. The blending mode (4.5.1) ensures this transition feels like improvement:
- `alpha * formula + (1 - alpha) * energy` where alpha decreases from 1.0 → 0.0
- Per-user rollback (4.5.4) if outcomes worsen
- Surprise detection (4.5.2) flags dramatic recommendation changes for review

### Why Business Entity State Encoders (4.4.8-4.4.12)
Businesses, brands, and sponsors need their own state representations for bidirectional energy. A business's quantum state already exists (`QuantumEntityType.business`) but isn't used for energy scoring. Phase 4 wires these into real scoring.

### Why Asymmetric Loss and Self-Monitoring (4.1.7-4.1.8)
The energy function needs asymmetric loss because negative outcomes are more informative than positive ones — a preference that aligns with loss aversion in real human decision-making. When the model predicts "high energy" (bad) and the user engages anyway and has a positive outcome, that's a strong signal the model was wrong. Conversely, when the model predicts "low energy" (good) and the user disengages or has a negative outcome, that's equally valuable. Positive outcomes reinforce what the model already thinks; negative outcomes correct it.

"Model failure" tuples deserve 3x weight because they represent exactly where the model is wrong. These are the highest-value training signals: the model predicted one thing, reality contradicted it, and the model must update. Treating all outcomes equally underweights the most informative examples.

Self-monitoring (per-category accuracy tracking) creates a self-correcting feedback loop. When a category (e.g., community recommendations, event suggestions) shows declining accuracy over time, the system automatically triggers exploration in that category. The model doesn't need manual intervention to know it's failing — it detects its own failure and corrects. This prevents the model from doubling down on strategies that have stopped working.

### Why Agent Happiness → Energy Function (4.5.6-4.5.7)
Agent happiness should feed back into energy function training because it closes the loop: recommendations affect happiness, and happiness should affect future recommendations. If the energy function recommends spots and communities that leave the user disengaged or unhappy, the model must learn from that. The happiness signal (collected via the agent's self-assessment of user engagement and satisfaction) becomes a training target — low happiness after a recommendation means the energy function's prediction was wrong.

Happiness-weighted exploration prevents the model from doubling down on failing strategies. When happiness drops in a category, exploration increases there. When happiness is high, the model can consolidate. Without this feedback, the energy function could drift toward recommendations that superficially match features but fail to improve the user's actual experience.

---

## Pre-Flight Checklist for Phases That Depend on Phase 4

**Before starting Phase 5 (Transition Predictor):**
- [ ] Energy function produces consistent scores across entity types
- [ ] VICReg training prevents embedding collapse (verify variance term is active)
- [ ] At least one formula (4.2.1 CallingScore) is in parallel-run mode

**Before starting Phase 6 (MPC Planner):**
- [ ] Energy function inference runs within 10ms budget
- [ ] Bidirectional energy is working for at least user↔community and user↔event
- [ ] Feature flag infrastructure supports per-formula A/B testing

**Before starting Phase 7 (Orchestrators):**
- [ ] `EnergyFunctionService` is registered in DI and callable from orchestrators
- [ ] Formula replacement schedule has at least 3 formulas in parallel-run mode

---

## Common Pitfalls

1. **Training the energy function before Phase 1 has enough data**: You need hundreds of episodic tuples with outcome signals before the energy function can learn anything meaningful. Don't rush Phase 4 if Phase 1 data is thin.
2. **Replacing formulas without the parallel-run phase**: Hard-swapping is dangerous. Always run both simultaneously and compare.
3. **Ignoring the bidirectional energy for business entities**: Business partnerships fail if only one side benefits. The energy function must score from both perspectives.
4. **Not tracking which formulas have been replaced**: The Phase 4.2 schedule is the source of truth. Feature flags per formula track the state.

---

---

## Why Multi-Dimensional Self-Calibrating Happiness (4.5B)

**Problem:** A single happiness score (0.0-1.0) hides why a user is happy or unhappy. A socially thriving but professionally miserable user looks the same as the reverse. The system can't diagnose problems or target specific improvement areas.

**Solution (4 parts):**
1. **Dimension decomposition** (4.5B.1) -- Replace scalar with a vector of 6+ dimensions (discovery, social, routine, professional, growth, trust). Scalar = weighted sum.
2. **Self-calibrating per-user weights** (4.5B.2) -- Learn which dimensions predict each user's engagement via weekly linear regression. A social person's social weight rises to 0.4; an explorer's discovery weight hits 0.5.
3. **Self-adjusting dimensions** (4.5B.3) -- Self-optimization engine proposes new dimensions when outcome clusters don't correlate with existing ones. Retires stale dimensions.
4. **Dynamic locality thresholds** (4.5B.4) -- Replace fixed 60% with locality-relative baselines (1 standard deviation below rolling 90-day average).
5. **Trajectory prediction** (4.5B.5) -- Forecast 7-day happiness direction. A user at 0.7 trending down is more urgent than 0.5 trending up.
6. **Professional fulfillment** (4.5B.6) -- Dedicated dimension for earners tracking booking/revenue/satisfaction trends.

**Alternatives considered:**
- **Keep single score:** Simpler, but hides diagnostic information. The MPC planner can't optimize for specific dimensions.
- **Fixed dimensions (no self-adjusting):** Easier, but the system can't discover happiness factors we haven't thought of.
- **Global weights (not per-user):** Less personalized. A single set of weights can't capture that social matters more to some than others.

**Pre-flight checklist:**
- [ ] `AgentHappinessService` currently produces scalar. Migration path: scalar = weighted sum of vector.
- [ ] Phase 1.1C consolidation cycle available for weekly weight updates.
- [ ] Phase 7.9C experiment orchestrator available for dimension proposal canary experiments.
- [ ] Phase 8.9B locality advisory currently uses fixed threshold. Must update to use dynamic baselines.

---

**Last Updated:** February 12, 2026 -- Version 1.2 (added Multi-Dimensional Self-Calibrating Happiness 4.5B rationale. Previous: 1.1 Zeng et al. 2026 context)

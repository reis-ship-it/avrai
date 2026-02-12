# Phase 5 Rationale: Transition Predictor & On-Device Training

**Phase:** 5 | **Tier:** 1 (Parallel with Phase 4) | **Duration:** 5-6 weeks  
**Companion to:** `docs/MASTER_PLAN.md` Phase 5  
**Read before starting:** `FOUNDATIONAL_DECISIONS.md` (Decisions #3, #4, #7)

---

## Why This Phase Exists

The energy function (Phase 4) answers "how good is this door for this person RIGHT NOW?" The transition predictor answers "if they open this door, how will their world change?" This is the difference between one-shot recommendations and trajectory planning.

Without a transition predictor, the MPC planner (Phase 6) can't simulate multi-step futures. It's stuck making one recommendation at a time instead of planning sequences like "coffee shop → writers' group → weekly meetup → community."

---

## Key Design Decisions

### Why `next_state = current_state + delta(current_state, action)`
The transition predictor doesn't predict the absolute next state -- it predicts the CHANGE (delta). This is more stable and easier to learn because:
- Most of the state doesn't change after a single action
- The delta is small and well-behaved (easier gradient flow)
- Adding a delta to current state preserves all the features that didn't change

### Why Variance Head (5.1.4)
The model can't predict the future perfectly. The variance head quantifies "how uncertain am I about this prediction?" This uncertainty is critical for:
- **MPC planner**: expected energy vs. worst-case energy across z-samples
- **Active exploration (Phase 6.2.9)**: high uncertainty means the model should recommend things that REDUCE uncertainty
- **Taste drift detection (5.1.9)**: when prediction residuals spike, the model knows something changed

### Why It Replaces Specific Existing Systems
Three existing systems use hardcoded evolution dynamics:
- `WorldsheetEvolutionDynamics`: ODE extrapolation `F(t) = F(t₀) + ∫dF/dt dt`
- `KnotEvolutionStringService._extrapolateFutureKnot()`: polynomial extrapolation
- `StringTheoryPossibilityEngine`: hardcoded stable/growth/consolidation branches

All three are replaced by the transition predictor because:
- ODE extrapolation assumes linear dynamics (personality changes aren't linear)
- Polynomial extrapolation diverges over longer horizons
- Hardcoded possibility branches can't learn new patterns

### Why Taste Drift Detection (5.1.9) Is Critical
Users' lives change (new city, new relationship, new job). Without the chat-as-accelerator principle (Decision #7), the model must detect these changes from BEHAVIOR alone. The EMA of prediction residuals catches this: when the model consistently predicts wrong, something changed. Trigger: reset confidence, re-enter exploration, log drift event.

**External validation (Zeng et al., arXiv:2602.01630, Feb 2026):** The Zeng paper's Future Work section identifies "Autonomous Reflection and Modular Continuous Evolution" as a critical research direction: "models should possess the ability for uncertainty estimation regarding their own predictions. When a significant discrepancy arises between a prediction and actual observation, the model should autonomously trigger a reflection mechanism to identify knowledge gaps." AVRAI's taste drift detection IS this mechanism -- the EMA of prediction residuals is the discrepancy detector, the exploration re-entry is the reflection trigger, and the confidence reset is the knowledge gap acknowledgment. The Zeng paper frames this as a future research challenge; AVRAI has it designed as a concrete Phase 5.1.9 implementation with specific triggers and responses. Similarly, AVRAI's dormancy prediction (5.1.11), self-monitoring accuracy tracking (Phase 4.1.8), and happiness-weighted exploration (Phase 4.5.7) all implement aspects of what Zeng calls "metacognition" -- the system knowing when it's failing and correcting autonomously rather than waiting for manual retraining.

### Why Temporal Pattern Learning (5.1.10)
Users have recurring cycles: summer vs. winter activities, weekday vs. weekend, morning vs. evening. Sinusoidal temporal embeddings (`sin(2pi * day/365)`, etc.) let the model learn "this user shifts from outdoor spots in summer to indoor spots in winter" purely from behavior. This isn't drift (permanent change) -- it's a CYCLE (predictable recurrence).

### Why Dormancy Prediction (5.1.11)
Predicting disengagement BEFORE it happens is more valuable than reacting after. Once a user has gone dormant, the damage is done: they've mentally checked out, and re-engagement is harder. The transition predictor can forecast "this user's engagement trajectory is trending toward dormancy" from declining interaction patterns, reduced response latency, or weaker state deltas. Early warning allows the system to adjust recommendations before the user disengages.

This is NOT a spam trigger. The goal is not to bombard inactive users with notifications. Rather, dormancy is a signal that the AI agent may be failing the user — the recommendations aren't resonating, the doors aren't opening. The correct response is to try different strategies (exploration, different categories, contextual shifts), not to send more of the same. This connects to Phase 6.2.12-6.2.15 (re-engagement guardrails): those guardrails constrain HOW re-engagement happens (no spam, respect user boundaries) while dormancy prediction provides the early signal that intervention may be needed.

### Why Wearable Temporal Conditioning (5.1.12)
Physiological context (heart rate, sleep, activity) should be CONDITIONING variables, not gating variables. The model must work WITHOUT wearable data — many users won't have wearables, or will have gaps in data. Wearable signals should enhance predictions when available, not block them when absent.

This means wearable data is treated as optional feature channels. When present, they add another layer of temporal context alongside Phase 5.1.10 temporal embeddings: "this user had poor sleep last night" or "heart rate variability suggests low energy" can condition the transition predictor to expect different state deltas. When absent, the model falls back to behavior-only signals. The architecture must support both modes from day one — gating would create a bifurcated user experience and block the majority of users who don't (yet) use wearables.

### Why On-Device Training (5.2)
Training on the user's own device means:
- Personal data never leaves the device
- The model personalizes to this specific user
- No cloud training infrastructure needed

Battery and thermal constraints (5.2.2-5.2.9) ensure training doesn't degrade the user's phone experience. Training happens during natural idle moments: charging, screen off, WiFi connected.

---

## Pre-Flight Checklist for Phases That Depend on Phase 5

**Before starting Phase 6 (MPC Planner):**
- [ ] Transition predictor produces state deltas within 20ms
- [ ] Variance head produces meaningful uncertainty estimates
- [ ] List state transitions (5.1.8) work for create/modify/share list actions
- [ ] Latent variable sampling (5.3) generates multiple plausible futures

**Before starting Phase 8 (Federated Learning):**
- [ ] On-device training loop (5.2) produces gradient updates
- [ ] Training respects battery constraints (no training below 50%)
- [ ] Model weight updates use exponential moving average (prevents catastrophic updates)

---

## Common Pitfalls

1. **Training the transition predictor without enough state transitions**: Each transition requires a BEFORE and AFTER state snapshot. If Phase 1 only captures outcomes without full state snapshots, you're missing half the training data.
2. **Ignoring the consolidation window dependency**: On-device training (5.2) runs during the nightly consolidation window (Phase 1.1C). Without 1.1C.6, there's no trigger for training.
3. **Confusing drift with seasonal cycles**: Taste drift (5.1.9) is a permanent change; seasonal patterns (5.1.10) are recurring cycles. The model needs both to avoid over-reacting to summer→winter transitions.

---

**Last Updated:** February 11, 2026 -- Version 1.1 (added Zeng et al. 2026 context -- autonomous self-reflection is a future research direction for Zeng; AVRAI has it as a concrete implementation. Previous: 1.0 v12 gap fill)

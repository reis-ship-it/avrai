# Phase 6 Rationale: MPC Planner, System 1/2, SLM & Agent

**Phase:** 6 | **Tier:** 2 (Depends on Phases 4 and 5) | **Duration:** 6-8 weeks  
**Companion to:** `docs/MASTER_PLAN.md` Phase 6  
**Read before starting:** `FOUNDATIONAL_DECISIONS.md` (Decisions #4, #7, #12)

---

## Why This Phase Exists

Phases 3-5 build the brain's components: perception (state encoder), evaluation (energy function), and prediction (transition predictor). Phase 6 is the brain itself -- the planning loop that uses all three to decide "what door should we show this person next?"

Without the MPC planner, the world model can score individual recommendations but can't plan SEQUENCES. The difference: "here's a good restaurant" vs. "here's a coffee shop that has a writers' group that meets Wednesdays that has members who also go to the jazz bar you liked."

**Why the Actor/Planner is the key differentiator from other frameworks:** Zeng et al. (arXiv:2602.01630, Feb 2026) propose a comprehensive unified world model framework with Interaction, Reasoning, Memory, Environment, and Multimodal Generation -- but have no planning component. Their framework perceives, reasons, remembers, and generates, but has no mechanism for simulating multi-step futures and selecting optimal action sequences. This is LeCun's Actor module, and it's what turns a world model from a "world understander" into a "world navigator." Without planning, you can answer "how good is this door?" but not "which sequence of doors leads this person to community and belonging over the next month?" The MPC planner IS the Spots → Community → Life journey expressed mathematically: simulate future trajectories, evaluate each with the energy function, pick the trajectory with the lowest total cost. This is the single most important capability gap between Zeng's framework and LeCun's -- and between most recommendation systems and AVRAI.

---

## Key Design Decisions

### Why Model-Predictive Control (MPC) Instead of Greedy Scoring
Greedy scoring picks the single best recommendation right now. MPC simulates multi-step futures:
1. Generate candidate actions (visit spot A, attend event B, join community C...)
2. For each, predict the next state (transition predictor)
3. From that predicted state, generate next-step candidates
4. Evaluate total energy across the sequence
5. Pick the sequence with lowest total energy

This captures sequential dependencies: "if they visit the coffee shop (Step 1), they'll be more receptive to the writers' group (Step 2), which leads to community membership (Step 3)." The Spots → Community → Life journey is a SEQUENCE, not a single recommendation.

### Why 3 Planning Horizons (Short/Medium/Long)
- **Short (1 action)**: "What should we recommend right now?" Concrete, specific, high confidence
- **Medium (3 actions)**: "What trajectory should they be on this week?" Moderately abstract
- **Long (7 actions)**: "Where is this user headed this month?" Highly abstract, lower confidence

LeCun's framework requires this: short-horizon plans are concrete, long-horizon plans are abstract. The planner shouldn't try to plan 7 specific restaurant visits a month out -- but it CAN plan "move toward more social spots over the next month."

### Why 11 Guardrail Objectives (6.2)
The energy function optimizes for outcomes, but unconstrained optimization can produce pathological results:
- **Diversity** (6.2.1): Don't recommend the same restaurant 10 days in a row
- **Exploration** (6.2.2): Recommend novel things to reduce uncertainty
- **Safety** (6.2.3): Never recommend flagged entities
- **Doors** (6.2.4): Every recommendation must open a door (not just optimize engagement)
- **Active uncertainty reduction** (6.2.9): Thompson sampling for cold-start -- if the model doesn't know if you like jazz or classical, recommend one of each
- **Lifecycle-stage exploration balance** (6.2.11): New users get 60% exploration; veteran users get 10%

These guardrails are how the doors philosophy (Decision #12) and chat-as-accelerator principle (Decision #7) manifest in the planner.

### Why System 1/System 2 (6.5)
MPC planning is powerful but takes ~6ms for 20 candidates. That's fine for important decisions but wasteful for routine recommendations. System 1/2 mirrors human cognition:
- **System 2 (slow)**: Full MPC planning. Used for first community recommendation, major events, low-confidence situations
- **System 1 (fast)**: Distilled ONNX model that imitates MPC's output. Microsecond inference. Handles 95% of recommendations

System 1 is TRAINED from System 2's outputs (distillation). Over time, System 2's wisdom gets compiled into System 1's reflexes. This is how the system gets fast WITHOUT losing intelligence.

### Why SLM Is "The Mouth, Not the Brain" (6.7)
The world model handles all decisions in ~6ms. A 1-3B SLM takes ~125ms per inference. If the SLM made decisions, the app would be 20,000x slower. The SLM's only job: translate numeric outputs into natural language. "Your quantum state compatibility is 0.87" → "This spot resonates with your adventurous side."

### Why Mesh-Fallback Communication & DTN Wormholes (6.6)
The MPC planner's action space includes "message_friend" and "drop_business_pheromone." If the user is offline but the friend is nearby on BLE mesh, the action must still be possible. Mesh-fallback ensures the planner's action space reflects reality, not just connectivity state.
More importantly, **Delay-Tolerant Networking (DTN)** allows messages to bridge massive geographic gaps (like NYC to LA). 
- **The Wormhole:** If an offline user passes an online user, the online user anonymously relays the encrypted message to the cloud.
- **Cultural Seed Dispersal:** As pheromones decay spatially, their underlying "scent vibes" are captured by travelers and injected into new cities, allowing local communities to organically pick up on foreign cultural trends (just like real life) without spamming the network with irrelevant out-of-state ads. This honors the user's "Exploration Note" (Replicator vs. Escapee).

### Why List Actions in MPC Space (6.1.6-6.1.8)
Creating a list is a valid recommendation. After visiting 3 similar spots, the planner might predict: "suggesting 'Create a list of your favorites' produces lower energy (better outcome) than suggesting a 4th similar spot." This models the desire to organize, not just consume. Lists also create conditional dependencies: saving a spot to a jazz list changes the user's state, making jazz events more likely next.

### Why Multi-Step Partnership Planning (6.1.9-6.1.12)
Business-expert matching isn't one-shot -- it's a relationship that unfolds: `outreach → chat → small collaboration → co-hosted event → formal partnership`. The MPC planner plans the optimal SEQUENCE, not just the best initial match. This replaces `BusinessExpertMatchingService.findExpertsForBusiness()` which returns a flat ranked list with no temporal planning.

### Why Creator-Side Intelligence (6.1.13-6.1.15)
The MPC planner shouldn't just help consumers -- it should help community hosts and event creators too. Creator-side planning is strategic: before hosting an event, the planner can predict optimal outcomes for different parameter choices (time, venue, capacity, pricing). Event parameter optimization BEFORE creation is more valuable than post-hoc analysis because it shapes the event itself rather than explaining why it underperformed. Creator feedback loops (predicted vs actual outcomes) are essential for improving creator-side predictions over time; without them, the planner would never learn which parameters actually drive success.

### Why Zero Trust Tool Registry (6.3.5-6.3.6)
The static tool list in 6.3.2 tells the agent what tools exist. But zero trust says: don't trust a tool just because it's listed — verify it before every invocation. `ToolRegistryService` (6.3.5) applies the same signed-manifest pattern as `KernelRegistry` (1.1E.12) to tools: each tool has a signed manifest declaring its capabilities, and the runtime verifies the signature before invocation. Tool capability constraints (6.3.6) enforce least privilege — a tool that says it can "search" cannot also "delete." This becomes critical when MCP tool calls or external APIs are added: every tool interaction is an attack surface that must be verified, scoped, and audited.

### Why AI Action Gateway (6.10)
The MPC planner generates action sequences. The agent executes them. But what sits between intent and action? In most agentic systems: nothing. That's the gap. The `AgentActionGateway` (6.10.1) is the zero trust inspection layer — every action passes through it before execution. It enforces action policies, scans for data leakage, detects anomalous action sequences, and provides an immutable audit trail. Think of it as an AI firewall: it doesn't stop the agent from being intelligent, but it prevents a compromised or poisoned agent from causing damage. The gateway's kill switch (6.10.6) connects to the digital twins intervention console (10.9.25) — if an admin sees an agent running out of control, they can halt all actions instantly.

### Why Re-Engagement Guardrails (6.2.12-6.2.15)
Re-engagement must be a strategic response (strategy selection), not a spam trigger. The MPC planner evaluates multiple re-engagement strategies and may decide "do nothing" is the best action -- natural breaks are healthy, and users who stepped away intentionally shouldn't be pestered. The 1/week frequency guardrail plus silent mode after 3 failures prevents annoyance: users who ignore multiple re-engagement attempts get a cooling-off period rather than escalating notifications. Returning users get a temporary exploration boost because their taste may have drifted during absence; the planner should not assume they want the same things as before. Dormancy prediction from Phase 5.1.11 feeds these guardrails: knowing *when* someone is likely to return informs *whether* and *how* to re-engage.

---

## Pre-Flight Checklist for Phases That Depend on Phase 6

**Before starting Phase 7 (Orchestrators):**
- [ ] MPC planner produces recommendation sequences within 500ms for 3-step horizon
- [ ] System 1 distillation is producing microsecond inference
- [ ] Guardrail objectives are enforced (at minimum: diversity, safety, doors)
- [ ] Agent architecture (6.3) has persistent memory and tool registry
- [ ] `AgentActionGateway` (6.10) is operational between planner and action execution
- [ ] Tool registry uses signed manifests with runtime verification (6.3.5)

**Before starting Phase 8 (Ecosystem Intelligence):**
- [ ] MPC planner handles `connect_ai2ai` as a candidate action
- [ ] Agent group negotiation (8.6) requires MPC planning from both agents
- [ ] Offline confirmation (6.4) works -- all inference on-device

---

## Common Pitfalls

1. **Building MPC without the transition predictor**: MPC literally cannot work without predicting next states. Phase 5 must be functional first.
2. **Making the SLM a decision-maker**: If the SLM influences recommendations (not just explains them), you've bypassed the world model and added 20,000x latency.
3. **Ignoring the exploration-exploitation balance for new users**: Without guardrails 6.2.9-6.2.11, new users get the model's "best guess" rather than diverse recommendations that help it LEARN what they like.
4. **Forgetting that System 1 needs retraining as System 2 improves**: System 1 is distilled from System 2. When the energy function improves (new outcome data), System 2 improves, and System 1 needs re-distillation.
5. **Treating the action gateway as optional**: Without the `AgentActionGateway` (6.10), there is no inspection between what the planner decides and what the agent does. A poisoned model or prompt injection that bypasses sanitization can execute arbitrary actions unchecked. The gateway is the last line of defense.
6. **Using a static tool list instead of verified registry**: A static list (6.3.2) becomes a liability when external tools are added. Every unverified tool is a potential supply chain attack vector. Signed manifests (6.3.5) are non-negotiable for any tool the agent can invoke.

---

**Last Updated:** March 5, 2026 -- Version 1.2 (added zero trust tool registry 6.3.5-6.3.6, AI action gateway 6.10, updated pre-flight checklist and pitfalls. Previous: 1.1 Zeng et al. 2026 context)

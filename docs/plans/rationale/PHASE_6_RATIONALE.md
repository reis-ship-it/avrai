# Phase 6 Rationale: MPC Planner, Translation Layer & Autonomous Agent

**Phase:** 6 | **Tier:** 2 (Depends on Phases 4 and 5) | **Duration:** 10-13 weeks  
**Companion to:** `docs/MASTER_PLAN.md` Phase 6  
**Read before starting:** `FOUNDATIONAL_DECISIONS.md` (Decisions #4, #7, #12, #51, #52, #53)

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

### Why Mesh-Fallback Communication (6.6)
The MPC planner's action space includes "message_friend." If the user is offline but the friend is nearby on BLE mesh, the action should still be possible. Mesh-fallback ensures the planner's action space reflects reality, not just connectivity state.

### Why List Actions in MPC Space (6.1.6-6.1.8)
Creating a list is a valid recommendation. After visiting 3 similar spots, the planner might predict: "suggesting 'Create a list of your favorites' produces lower energy (better outcome) than suggesting a 4th similar spot." This models the desire to organize, not just consume. Lists also create conditional dependencies: saving a spot to a jazz list changes the user's state, making jazz events more likely next.

### Why Multi-Step Partnership Planning (6.1.9-6.1.12)
Business-expert matching isn't one-shot -- it's a relationship that unfolds: `outreach → chat → small collaboration → co-hosted event → formal partnership`. The MPC planner plans the optimal SEQUENCE, not just the best initial match. This replaces `BusinessExpertMatchingService.findExpertsForBusiness()` which returns a flat ranked list with no temporal planning.

### Why Creator-Side Intelligence (6.1.13-6.1.15)
The MPC planner shouldn't just help consumers -- it should help community hosts and event creators too. Creator-side planning is strategic: before hosting an event, the planner can predict optimal outcomes for different parameter choices (time, venue, capacity, pricing). Event parameter optimization BEFORE creation is more valuable than post-hoc analysis because it shapes the event itself rather than explaining why it underperformed. Creator feedback loops (predicted vs actual outcomes) are essential for improving creator-side predictions over time; without them, the planner would never learn which parameters actually drive success.

### Why Re-Engagement Guardrails (6.2.12-6.2.15)
Re-engagement must be a strategic response (strategy selection), not a spam trigger. The MPC planner evaluates multiple re-engagement strategies and may decide "do nothing" is the best action -- natural breaks are healthy, and users who stepped away intentionally shouldn't be pestered. The 1/week frequency guardrail plus silent mode after 3 failures prevents annoyance: users who ignore multiple re-engagement attempts get a cooling-off period rather than escalating notifications. Returning users get a temporary exploration boost because their taste may have drifted during absence; the planner should not assume they want the same things as before. Dormancy prediction from Phase 5.1.11 feeds these guardrails: knowing *when* someone is likely to return informs *whether* and *how* to re-engage.

---

## Pre-Flight Checklist for Phases That Depend on Phase 6

**Before starting Phase 7 (Orchestrators):**
- [ ] MPC planner produces recommendation sequences within 500ms for 3-step horizon
- [ ] System 1 distillation is producing microsecond inference
- [ ] Guardrail objectives are enforced (at minimum: diversity, safety, doors)
- [ ] Agent architecture (6.3) has persistent memory and tool registry

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

---

## Why BLE Advertisement Payload Budget (6.6.6-6.6.7)

**The problem:** BLE advertisements have ~31 bytes of usable payload space. Multiple features now compete for this space: AI2AI personality deltas (existing), organic spot discovery signals (Phase 1.7), device discovery metadata (existing), mesh chat routing headers (6.6.1-6.6.2), and locality agent update summaries (Phase 8.9). Without a payload budget, features silently clobber each other's data -- the last feature to write wins, and all other data is lost.

**Why multiplexing (not larger payloads):** BLE Extended Advertising (BLE 5.0+) allows larger payloads, but: (a) not all devices support it, (b) larger advertisements consume more power, (c) the diversity of data types (personality, discovery, chat, locality) means different consumers need different data at different times. Rotating through payload types across successive advertisement intervals is more power-efficient and backwards-compatible.

**Why priority ordering matters:** When multiple features need to advertise simultaneously (e.g., mesh chat message pending + AI2AI learning exchange in progress), which one wins? Priority order: (1) mesh chat (user-facing, time-sensitive), (2) device discovery (enables other features), (3) AI2AI personality exchange, (4) organic spot discovery, (5) locality agent. This ordering prioritizes user-visible features over background learning -- but the self-optimization engine (Phase 7.9) can re-evaluate this ordering based on happiness outcomes.

**Post-quantum impact:** Phase 2.5 adds post-quantum encryption overhead to BLE payloads. The payload budget must account for larger encrypted headers, which may reduce the bytes available for feature data. The version header (2 bytes) in the schema enables forward compatibility when PQ overhead changes the byte allocation.

---

## Why Multi-Transport AI2AI (6.6.8-6.6.12)

**The problem:** AI2AI communication is currently BLE-only, but BLE's 31-byte advertisement payload is a hard ceiling. Learning insights must be lossy-compressed, personality exchange is limited to deltas, and mesh chat is constrained. WiFi provides orders-of-magnitude more bandwidth.

**Why WiFi local network:** When two devices are on the same WiFi network, they can exchange full-fidelity learning data. Solving the payload budget problem for co-located devices. No new hardware required -- just software routing.

**Why WiFi Direct:** For intentional deep exchanges (event mode, model weight transfer), WiFi Direct creates a direct device-to-device WiFi link without a router. Maximum bandwidth, maximum privacy. Requires user consent.

**Why VPN detection and fallback:** VPN tunnels block local network discovery (mDNS broadcasts don't escape the tunnel). Detecting VPN and falling back to BLE-only respects the user's privacy choice without breaking the system. Silent fallback -- no alarms.

**Why transport-agnostic encryption:** Signal Protocol encrypts the same way over BLE, WiFi, and WiFi Direct. One security layer, multiple physical channels. This is transport-layer independence -- the encryption doesn't care how the bytes travel.

---

### Why SLM Active Life Pattern Engine (6.7B)

**Problem:** The SLM (Phase 6.7) is limited to explaining recommendations. It's the mouth but not the ears. Users have no conversational interface for sharing context, plans, or immediate group needs.

**Solution:** Extend the SLM with:
1. **Intent extraction (6.7B.1):** Parse natural language into structured `SLMIntent` objects with action, who, what, when, where, sentiment.
2. **Tool-calling framework (6.7B.2):** 7 tools the SLM can invoke: search_entities, form_group, adjust_parameter, set_exploration_mode, book_service, update_routine, share_schedule.
3. **Conversational onboarding (6.7B.3):** "Tell me about your week" gives the routine model a 2-4 week head start from a 2-minute conversation.
4. **Preference extraction (6.7B.7):** User statements like "I love Thai food" become the highest-confidence preference signals (8x weight).
5. **Tier fallbacks (6.7B.8):** Cloud LLM on Tier 2, template matching on Tier 1/0 -- the active engine works on every device.

**Why not alternatives:**
- "Forms-based preference entry" -- Captures intent but loses nuance. "Somewhere quiet but not too fancy for my mom's birthday" can't be expressed in dropdown filters.
- "Skip conversational planning" -- Loses the highest-confidence signals. User statements are 8x more valuable than behavioral signals.
- "SLM-only, no fallbacks" -- Excludes Tier 1/2 users who make up the majority of the user base.

**Pre-flight checklist for Phase 6.7B:**
- [ ] Phase 6.7 SLM infrastructure exists (model loading, inference)
- [ ] Phase 7.5 device tier system exists for tier gating
- [ ] `LlmService` (Gemini cloud) exists for Tier 2 fallback
- [ ] Phase 7.10A routine model exists for conversational onboarding to populate
- [ ] Phase 1.4 signal hierarchy exists for 8x weighting
- [ ] AI2AI protocol supports `group_confirmation` message type for 8.6B integration

---

### Why Reality-to-Language Translation Layer (6.7C)

**Problem:** The world model's "brain" produces numeric outputs (energy scores, state vectors, transition probabilities). The SLM "mouth" produces natural language. There is no structured contract between them. Today the SLM receives raw numbers and improvises text, which leads to hallucinated explanations ("you'd love this because it's trendy" when the energy function scored high because of routine alignment, not trendiness). There is also no mechanism for the system to improve its OWN mathematical output formats -- if a state vector has 47 dimensions but only 12 carry information for a given recommendation, the wasted dimensions add noise to every translation.

**Solution:** A structured semantic bridge (Phase 6.7C) with two self-healing directions:
1. **Math → Language (vocabulary evolution, 6.7C.5):** The system learns which words produce user understanding vs. confusion. If users consistently misinterpret "routine alignment" but respond well to "fits your rhythm," the vocabulary evolves. Tracked by contrastive signals (Phase 1.2.16) -- "user acted on recommendation with explanation A" vs. "user ignored recommendation with explanation B."
2. **Language → Math (format optimization, 6.7C.4):** The system's own mathematical output formats are candidates for self-improvement. If the 47D state vector has 12 near-zero dimensions for 90% of users, the self-optimization engine (Phase 7.9) can propose a more compact format -- and the observation bus (Phase 7.12) monitors whether the new format degrades translation quality.

**Key architectural elements:**
- **Semantic Bridge Schema (6.7C.1):** Structured intermediate representation that both brain and mouth understand -- `{ decision_type, contributing_factors[], confidence, temporal_context, emotional_valence }`
- **Output Format Registry (6.7C.2):** Catalog of every world model output type with format, dimensionality, semantic meaning, and freshness requirements
- **Grounding Enforcement (6.7C.6):** Every SLM sentence must cite a specific bridge schema field. "This spot fits your rhythm" must map to `contributing_factors: [routine_alignment: 0.82]`. If the SLM generates text that references nothing in the schema, the output is blocked and falls back to template

**Why not alternatives:**
- "Just prompt-engineer the SLM better" -- Prompts don't enforce grounding. The SLM can still hallucinate plausible-sounding explanations. Grounding enforcement catches this at runtime.
- "Skip self-healing, just build a good bridge once" -- Violates the universal self-healing doctrine (Decision #52). The vocabulary that works for college students won't work for retirees. The formats that work for 1,000 users won't be optimal for 1,000,000.
- "Let the SLM access raw model weights" -- Dangerous. The SLM should only see the semantic bridge output, never raw parameters. This preserves the brain/mouth separation.

**Pre-flight checklist for Phase 6.7C:**
- [ ] Phase 6.7 SLM infrastructure exists (model loading, inference)
- [ ] Phase 4.6 explainability exists (feature attribution, energy decomposition)
- [ ] Phase 7.9 self-optimization engine exists (for self-healing experiments)
- [ ] Phase 7.12 observation bus exists (for monitoring translation quality)
- [ ] Phase 1.2.16 contrastive signals exist (for vocabulary effectiveness tracking)

---

**Last Updated:** February 13, 2026 -- Version 1.3 (added Reality-to-Language Translation Layer 6.7C rationale. Updated title, duration 6-8→10-13 weeks, added Foundational Decisions #51/#52/#53 reference. Previous: 1.2 Multi-Transport AI2AI 6.6.8-6.6.12. Previous: 1.1 Zeng et al. 2026 context)

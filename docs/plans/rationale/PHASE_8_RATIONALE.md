# Phase 8 Rationale: Ecosystem Intelligence, Group Negotiation & AI2AI

**Phase:** 8 | **Tier:** 3 (Depends on Phases 5 and 6) | **Duration:** 8-10 weeks (expanded from 6-8 for 8.9 Locality Happiness Advisory)  
**Companion to:** `docs/MASTER_PLAN.md` Phase 8  
**Read before starting:** `FOUNDATIONAL_DECISIONS.md` (Decisions #4, #8)

---

## Why This Phase Exists

Phases 1-7 build intelligence for INDIVIDUAL users. Phase 8 extends this to the NETWORK. Agents learn from each other's compressed experience, negotiate group activities, and share world model gradients -- all while keeping personal data on-device.

This is where AVRAI's AI2AI architecture becomes genuinely novel. No existing app has agents that plan social activities on behalf of users while preserving full privacy.

**External validation (Zeng et al., arXiv:2602.01630, Feb 2026):** Zeng's Future Work section calls for "Modular Continuous Evolution" -- world model modules (perception, memory, reasoning, planning) that "support independent fine-tuning and upgrades" so researchers can "iteratively improve specific weaknesses without impairing other capabilities, thereby achieving lifelong learning and agile evolution of the entire system." AVRAI's federated learning (Phase 8.1) IS this at a network scale: each device independently fine-tunes its world model from personal experience, then shares anonymized gradients that improve the global model. Individual modules improve (better energy function weights from federated aggregation, better transition predictions from on-device training) without disrupting the rest of the pipeline. The Locality Happiness Advisory (Phase 8.9) extends this further -- entire geographic regions can evolve their strategies by learning from thriving peer regions, creating a self-healing ecosystem. Zeng frames modular evolution as a single-system concept; AVRAI implements it as a *distributed* concept across millions of autonomous agents that collectively evolve while preserving individual autonomy and privacy.

---

## Key Design Decisions

### Why Federated Learning, Not Centralized Training (8.1)
Centralized training requires collecting user data on a server. Federated learning means:
- Each device trains locally on its own data
- Only anonymous, DP-protected gradient updates leave the device
- A server aggregates gradients into a global model improvement
- Each device applies the global update locally

User #100,000 benefits from User #1's learning without ever seeing their data.

### Why Gradient Bandwidth Budget (8.2)
BLE mesh throughput is ~100KB/s. World model gradients must fit. Solution:
- Gradient quantization: float32 → int8 (4x compression)
- Top-k sparsification: only share the k largest gradient components (5-10x compression)
- Result: < 2KB per gradient update, fits a single BLE MTU packet

### Why Expert Discovery Over Mesh (8.4)
`ExpertiseMatchingService._getAllUsers()` currently returns an empty list -- experts literally can't be found. Phase 8.4 extends BLE discovery to advertise expertise metadata (top 3 dimensions, golden expert flag). This makes `consult_expert` a real action in the MPC planner's space.

### Why Agent-to-Agent Insight Exchange (8.5)
Current AI2AI shares raw 12D personality deltas. Phase 8.5 upgrades this to structured `AgentInsight` objects: "coffee spots in Midtown are positive on weekday mornings." These compressed generalizations from semantic memory are far more useful than raw dimension numbers.

Foreign insights get a 0.5x confidence discount -- you trust your own experience more than a stranger's.

### Why Agent-to-Agent Group Negotiation (8.6)
When `QuantumEntanglementMLService` detects high entanglement between two users, both agents can plan a joint activity. The negotiation: Agent A proposes constraints (time, energy level), Agent B evaluates against own user's state, both run MPC planning for joint actions, converge on lowest combined energy.

Privacy is preserved: agents share vibe profiles and availability windows, NEVER raw personality states.

### Why Locality Happiness Advisory System (8.9)

Individual agent happiness stays trapped on each device. Locality agents know the 12D vibe of an area but have no signal for "how well are agents performing here?" The federated system shares model gradients but not happiness-driven strategies. Phase 8.9 connects all three.

**The feedback loop:**
1. Each agent's happiness (from `AgentHappinessService`) flows UP into its locality update
2. Supabase aggregates happiness per geohash cell into `aggregateHappiness` on `LocalityAgentGlobalStateV1`
3. When a locality drops below 60%, it enters advisory mode
4. The engine queries the federated system for strategies from high-happiness (> 70%) localities with similar vibe profiles
5. Advisory vectors are blended into the locality's global prior (20% advisory, 80% own)
6. The locality's agents benefit from strategies that work elsewhere
7. When happiness improves, the locality exits advisory mode and may itself become an advisor

**Why 60% threshold?** Below 0.5 means agents are doing worse than random. 0.6 gives a buffer: it catches localities that are mediocre (not terrible) before they degrade further. The hysteresis (exit at 0.65) prevents oscillation. Both values are feature-flagged for tuning.

**Why cross-region (not just neighbors)?** A struggling Tokyo locality may have no nearby high-happiness peers. But a Brooklyn locality with an identical vibe profile might be thriving. Vibe similarity matters more than geographic proximity for strategy transfer. This is the "same pattern, different place" principle.

**Agent happiness model:** The agent's happiness comes from (1) deeply learning the person (convergence satisfaction) and (2) guiding them to real-world activities they enjoy (fulfillment satisfaction). Both must be high. Advisory transfer addresses both: knowledge gaps (what patterns work?) and strategy gaps (how to deliver suggestions?).

**Third-party value:** Aggregate locality happiness (DP-protected) is valuable market intelligence — businesses see underserved areas (low happiness = unmet demand), event planners see what works where, sponsors target receptive localities. All through existing `ThirdPartyDataPrivacyService` pipeline.

**Quantum readiness:** All functions are pure: aggregation, similarity comparison, advisory search, strategy transfer. These map directly to quantum operations (Grover's search, amplitude estimation, QAOA routing) per Phase 11.4's architectural principle. Zero architecture changes needed when hardware arrives.

### Why This Is Tier 3 (Last Intelligence Phase)
Federated learning requires:
- Working on-device training (Phase 5.2) to produce gradients
- Working MPC planner (Phase 6) for group negotiation
- Working energy function (Phase 4) for connection value scoring
- Working mesh communication (Phase 3.7) for gradient transport

All prior intelligence phases must be functional. Building federated learning before on-device training produces gradients is building a pipeline with no input.

---

## Pre-Flight Checklist

**Before starting Phase 8:**
- [ ] On-device training (Phase 5.2) produces gradient updates
- [ ] MPC planner (Phase 6) handles `connect_ai2ai` actions
- [ ] `AnonymousCommunicationProtocol` is the unified mesh pathway (Phase 3.7)
- [ ] Differential privacy (Phase 2.2) protects gradient sharing
- [ ] Post-quantum covers BLE mesh (Phase 2.5.4) and gradient transport (Phase 2.5.5)

**Additional pre-flight for Phase 8.9 (Locality Happiness Advisory):**
- [ ] `AgentHappinessService` is recording signals from multiple sources (not just placeholder)
- [ ] `LocalityAgentGlobalStateV1` is being populated in Supabase (`locality_agent_global_v1` table has real data)
- [ ] `LocalityAgentUpdateEmitterV1` is emitting updates to Supabase successfully
- [ ] `LocalityAgentEngineV1.inferVector12()` is producing real locality vectors (not just defaults)
- [ ] Federated aggregation server (Phase 8.1.3) is operational (needed for server-side happiness aggregation)
- [ ] `FeatureFlagService` supports the `locality_happiness_advisory_enabled` flag
- [ ] `AdminSystemMonitoringService` (Phase 7.3.4) can receive new metric types

---

## Common Pitfalls

### Pitfall: Treating advisory as a real-time system
Advisory queries are rate-limited to once per 24 hours per locality (Phase 8.9B.6). The advisory system is a slow, background optimization -- not a real-time recommendation path. Don't try to make it faster; that would create query storms against Supabase.

### Pitfall: Over-weighting advisory vectors
The default advisory blend weight is 0.2 (20%). Increasing this makes localities copy happy localities instead of developing their own character. Advisory should nudge, not overwrite. The weight decays as own happiness improves.

### Pitfall: Using happiness as a reward signal
Locality happiness is a META-metric (how well is the system working here?), not a training label. Don't use it to train the energy function directly -- that creates a feedback loop where the system optimizes for its own satisfaction rather than user satisfaction. The energy function trains on user outcome data (Phase 4). Happiness is the diagnostic, not the objective.

---

## Why Cross-Locality Behavioral Archetypes (8.9E)

**The problem:** Locality agents share vibe vectors (what a place feels like), but not behavioral patterns (what people do there). Two localities can have different vibes but behaviorally similar users. Without archetype matching, cross-locality advisory misses "people like you, in a place unlike yours, found this strategy helpful."

**Why behavioral archetypes:** A compact representation of user behavior patterns: what they do, when they do it, how much they explore, and whether they prefer solo or group activities. Computed from aggregate data, never individual profiles.

**Why timezone-aware normalization:** "Morning coffee" in Tokyo and "morning coffee" in Portland is the same archetype. Without timezone normalization, temporal patterns become meaningless across timezone boundaries. The `AtomicClockService` already supports this -- just use local time for archetype computation.

**Why cross-archetype testing:** The self-optimization engine (7.9) should validate that parameter changes work across different behavioral types. Testing only on the majority archetype would over-optimize for the average and hurt edge cases. Opposite-archetype testing catches this.

**Why archetype evolution:** When a user's behavioral archetype shifts (e.g., "evening social" → "morning solo" after a life change), the system should adapt. The archetype transition is itself a strong signal for the transition predictor.

### Why Ad-Hoc Group Formation (8.6B)

**Problem:** Group negotiation (8.6) is agent-initiated -- agents detect high entanglement and propose joint activities. But real-world group decisions happen spontaneously: "the 5 of us are hungry right now." The system has no way to handle user-initiated, immediate group needs.

**Solution:** SLM intent extraction (Phase 6.7B) detects group intent → triggers BLE scan for nearby AVRAI agents → sends confirmation pop-ups → runs simplified joint energy scoring (average, not negotiated, for speed) → surfaces group recommendation in < 5 seconds. Handles partial AVRAI coverage gracefully (searches for stated group size even if not all members are on AVRAI).

**Why not alternatives:**
- "Just use the existing group negotiation (8.6)" -- Too slow. Entanglement-based negotiation is deliberate and agent-initiated. Ad-hoc groups need answers in seconds, not minutes.
- "Manual search, user picks for group" -- Loses the collaborative aspect. When multiple agents contribute preferences, the result is better for everyone.
- "Skip partial coverage handling" -- Most groups will have mixed AVRAI adoption. Graceful degradation is essential for real-world utility.

**Pre-flight checklist for Phase 8.6B:**
- [ ] Phase 6.7B SLM intent extraction and tool-calling exist
- [ ] Phase 6.6 BLE discovery works for nearby agent detection
- [ ] AI2AI protocol supports lightweight confirmation messages
- [ ] Phase 4.4 energy function can run in simplified aggregation mode
- [ ] Phase 9.4 service booking exists for group booking bridge

---

**Last Updated:** February 12, 2026 (v1.3 -- added Cross-Locality Behavioral Archetypes 8.9E rationale. Previous: v1.2 Zeng et al. 2026 context)

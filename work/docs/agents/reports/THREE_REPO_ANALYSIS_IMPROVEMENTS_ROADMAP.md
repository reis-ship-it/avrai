# Three-Repo Analysis: AVRAI Improvements Roadmap

**Date:** March 1, 2026  
**Source Repositories Analyzed:**
1. [Hermes Agent](https://github.com/NousResearch/hermes-agent)
2. [Automaton](https://github.com/Conway-Research/automaton)
3. [World Monitor](https://github.com/koala73/worldmonitor)

**Purpose:** Consolidated inventory of new ideas, architectural improvements, and gaps to realize — derived from comparing AVRAI's 3-prong architecture against three external repositories.

---

## NEW IDEAS (Things AVRAI Has Zero Version Of)

### From Hermes Agent

**1. Procedural Memory Layer**
A third memory type that doesn't exist in AVRAI. Episodic memory stores raw `(state, action, next_state, outcome)` tuples. Semantic memory stores knowledge. Procedural memory would distill recurring episodic patterns into reusable strategy documents — "when situation X arises, approach Y works." Feeds directly into MPC planner quality.

**2. Plan-Script Emission**
Instead of the planner recommending actions one at a time, let it emit a batch script of sequenced actions that execute atomically against runtime services. Only the final outcome returns to context. Different execution model from step-by-step recommendation. Reduces context consumption dramatically for complex planning.

**3. Hard Memory Budgets with Forced Consolidation**
Fixed size caps per memory category. When you hit the cap, the engine decides what to merge, summarize, or drop — rather than growing unbounded and relying on decay functions. Budgets force quality. Unbounded storage accumulates noise. 47 tuples about "morning coffee" become one high-confidence tuple.

### From Automaton

**4. User-Readable Reality Document (Reverse Air Gap)**
Run the air gap in reverse. Take abstract `SemanticTuple`s and synthesize a natural language `UserReality.md` that explains what the AI has learned about the user — without ever referencing the destroyed source data. Users get transparency into AI knowledge with zero privacy cost. Genuinely novel privacy primitive: explainability through the same boundary that provides privacy.

**5. Architecturally Isolated Heartbeat Daemon**
A lightweight process that ticks on its own schedule, independent of any kernel loop. Checks liveness of all kernels, engine responsiveness, storage pressure, battery, network. Can trigger self-healing even when the kernel it's monitoring is the one that's broken. Currently, AVRAI's health checks are computed on-demand — a broken kernel can't detect its own break.

**6. Governance State Versioning (Registry Snapshots)**
Version the full kernel registry state as an immutable numbered snapshot at every governance transition. Enables replay ("what would governance have decided under last week's registry?"), safe rollback to known-good governance states, and diff-based auditing. AVRAI currently tracks individual lineage events but not full-state snapshots.

**7. Automated Formula Deprecation (Selection Pressure)**
Wire conviction gates to auto-deprecate losing formulas after statistically significant outcome thresholds. When the energy function consistently outperforms the hardcoded formula in A/B testing, the switch fires automatically based on accumulated episodic evidence — no human review needed. The governance gate already has `modelSwitch` actions; the missing piece is an automated trigger.

### From World Monitor

**8. Intelligence Gap Tracking**
Explicitly track and surface what the system can't see. When data sources are down, don't silently degrade — tell the engine "these features are blind" and tell the user "this assessment has gaps." Every feature in the state vector should carry freshness/confidence metadata, and scoring should distinguish "I don't know" from "I observed and the value is low."

**9. Negative Caching**
Cache upstream failures for a defined cooldown period. Don't retry against known-dead sources. Prevents wasting battery and CPU on retries against endpoints you already know are down. Integrates with `BatteryAdaptiveTrainingScheduler` — when battery is low AND a source is negatively cached, deprioritize entirely.

**10. Baseline-Aware Anomaly Detection (Welford's Algorithm)**
Maintain streaming per-user behavioral baselines using Welford's online algorithm (O(1) time, O(1) space per update). Track visit frequency, social interaction rate, routine adherence, exploration rate. Flag deviations as first-class signals for the world model. A user exploring 3x more than usual might be going through a life change — the planner should adjust.

**11. Progressive Confidence Display**
Show users how confident the AI is, not just what it recommends. Surface confidence scores, observation counts, and data freshness alongside every recommendation. "Based on 14 observations over 3 months" versus "based on 2 observations from yesterday." The air gap already preserves confidence in `SemanticTuple` — surface it in the UI.

---

## THINGS TO IMPLEMENT (Architectural Improvements Informed by These Repos)

**12. Regime-Aware Signal Scaling** *(from World Monitor's CII)*
For users who explore constantly, a new spot visit is low-signal (logarithmic). For users who rarely deviate from routine, a new spot visit is high-signal (linear). Observation informativeness should scale based on the user's behavioral baseline, not be treated uniformly. Directly applies to the feature extractor.

**13. Circuit Breakers Per Data Source** *(from World Monitor's failure architecture)*
Per-service circuit breakers with cooldown periods across AVRAI's 19+ feature sources. When a service fails, trip the breaker, serve the last-known-good value, and don't retry until cooldown expires. Pairs with negative caching.

**14. Stale-On-Error Fallback** *(from World Monitor's caching)*
When a runtime service call fails, serve the last successful result rather than propagating the failure. The engine should never see a blank feature — it should see the last known value with a staleness flag.

**15. In-Flight Request Deduplication** *(from World Monitor's relay)*
When multiple kernel loops or mesh signals trigger the same service call concurrently, collapse them into a single upstream request. All callers share the result. Prevents wasted computation on-device.

**16. Event-Driven Kernel Wake** *(from Automaton's heartbeat + World Monitor's polling)*
Kernels should wake on events, not poll on timers. Automaton separates the heartbeat (always running) from the agent loop (event-driven). World Monitor pauses all polling when the tab is hidden. AVRAI's `AgentTriggerService` (Phase 7.4) plans this but it should also integrate idle-aware resource management — suspend kernel loops when the app is backgrounded, resume on foreground.

---

## THINGS THAT NEED TO HAPPEN / BE REALIZED (Current Gaps)

### Air Gap

**17. Wire the local LLM into `TupleExtractionEngine`.** The extraction is mocked. Until the local LLM runs the actual extraction prompt, the air gap is conceptual, not functional.

**18. Add a PII post-extraction scanner.** The local LLM could accidentally include raw PII in tuple output fields. A deterministic (non-LLM) validator should reject tuples containing names, addresses, phone numbers before they reach the `SemanticKnowledgeStore`.

**19. Fix the `data_intake_connection_page.dart` direct engine import.** The onboarding page directly imports `TupleExtractionEngine` from `reality_engine`, violating the prong rule (apps cannot import engine). DI should wire this through the abstract `AirGapContract`.

### Engine Prong

**20. Populate engine packages with actual code.** `avrai_ml`, `avrai_ai`, `avrai_quantum` are pubspec stubs with zero Dart source files. The actual ML/AI/quantum logic (629 files) lives in `runtime/`. The engine prong is architecturally defined but physically empty.

**21. Move model math out of runtime into engine.** Frame this as freeing the runtime to focus on kernel expansion, not as thinning the runtime. Quantum state computation, knot topology, energy scoring, state encoding — all pure math that belongs in `engine/` behind contracts.

**22. Generalize `AirGapContract` into `EngineContract<I, O>`.** Every engine computation should follow the same pattern: input in, abstract output out, input ephemeral. This is the universal privacy-preserving computation boundary.

### Runtime Prong

**23. Build `UrkRuntimeLoop` as executing code.** The 13-step loop (`ingestSignal` through `promotionPipelineIfApplicable`) exists only as spec. Even with stub scoring, get the loop running end-to-end. A running loop with stubs is infinitely more useful than a perfect spec that doesn't execute.

**24. The runtime stays fat, the engine gets real.** The runtime is an OS, not an orchestrator. It keeps kernel lifecycle management, activation policy, governance gates, privacy mode enforcement, transport, mesh, device tier adaptation, LLM provisioning, telemetry, lineage, and audit. It does NOT keep model math.

### Apps Prong

**25. Move `lib/apps/` code into `apps/` prong.** Consumer and admin app code currently lives in the main `lib/` directory, not in the `apps/` prong. Straightforward file moves + import updates.

### Self-Improvement System

**26. Replace the existing `AISelfImprovementSystem`.** The current implementation has hardcoded "improvement dimensions" like `creativity_level` and `meta_learning_ability` with no real learning mechanics. It needs to be replaced by the actual intelligence-first architecture: episodic tuples driving energy function training driving better scoring. The current system is a placeholder.

---

## PRIORITIZED EXECUTION ORDER

| Priority | Item | Type | Rationale |
|---|---|---|---|
| 1 | Wire local LLM into air gap (#17) | Realize | Foundation. Everything downstream depends on real extraction. |
| 2 | PII post-extraction scanner (#18) | Realize | Closes biggest security gap in the air gap. |
| 3 | Build `UrkRuntimeLoop` (#23) | Realize | The thing being governed needs to exist. Everything plugs into a running loop. |
| 4 | Isolated heartbeat daemon (#5) | New idea | Prerequisite for real self-healing. Broken kernels can't detect their own breaks. |
| 5 | Intelligence gap tracking (#8) | New idea | Engine needs to know what it can't see before scoring is meaningful. |
| 6 | Hard memory budgets (#3) | New idea | Changes data quality trajectory from noise accumulation to signal consolidation. |
| 7 | Negative caching + circuit breakers (#9, #13) | New idea + Implement | Battery-critical for on-device. Prevents wasted resources on known-dead sources. |
| 8 | Baseline anomaly detection (#10) | New idea | O(1) per-user baselines that make every observation contextually meaningful. |
| 9 | User-Readable Reality Document (#4) | New idea | Most visible user-facing differentiator. Turns air gap into tangible product. |
| 10 | Governance state versioning (#6) | New idea | Low cost, high safety payoff for kernel expansion. |
| 11 | Procedural memory layer (#1) | New idea | Third memory type. Enables strategy learning, not just fact learning. |
| 12 | Move engine code out of runtime (#20, #21) | Realize | Frees runtime for kernel expansion. Engine becomes real. |
| 13 | Generalize `EngineContract<I,O>` (#22) | Realize | Universal pattern for privacy-preserving engine computation. |
| 14 | Progressive confidence display (#11) | New idea | User transparency. Surfaces confidence alongside recommendations. |
| 15 | Regime-aware signal scaling (#12) | Implement | Makes observations informationally proportional to user baseline. |
| 16 | Move apps code into `apps/` (#25) | Realize | Straightforward. Completes the physical 3-prong separation. |
| 17 | Fix onboarding engine import (#19) | Realize | Quick fix. Eliminates prong violation. |
| 18 | Stale-on-error fallback (#14) | Implement | Engine never sees blank features. |
| 19 | In-flight deduplication (#15) | Implement | Prevents wasted on-device computation. |
| 20 | Event-driven kernel wake (#16) | Implement | Idle-aware resource management. |
| 21 | Automated formula deprecation (#7) | New idea | Only works after energy functions produce real scores. Later-stage. |
| 22 | Plan-script emission (#2) | New idea | Changes planner execution model. Depends on runtime loop being real. |
| 23 | Replace `AISelfImprovementSystem` (#26) | Realize | Current version is a placeholder with no real learning mechanics. |

---

## SUMMARY COUNTS

- **11** genuinely new ideas (AVRAI has zero version of these)
- **5** architectural improvements to implement (informed by external patterns)
- **7** things to realize / make real (current gaps in existing architecture)
- **23** total items

---

*Generated from analysis of Hermes Agent, Automaton, and World Monitor repositories against AVRAI's 3-prong architecture (apps, runtime, engine).*

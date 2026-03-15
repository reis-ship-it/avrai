# AVRAI Governance Kernels
**Date:** March 10, 2026
**Status:** Active working document
**Purpose:** Defining the strict architectural rules (Kernels) for how the AVRAI OS and Reality Engine process "Truth" (closures/events) and manage autonomous "Growth" (new geographic deployments).

---

## 1. Locality Governance: Venue Closure & Truth Verification

**The Problem:** Commercial data inputs (Google Places, Yelp, IRS filings) are often wrong or delayed. A restaurant might be marked "permanently closed" when it is merely renovating, or rumors on Reddit might preemptively declare a closure.

**The Governance Kernel:**
The Locality Model within the `avrai_runtime_os` **CANNOT** unilaterally accept a closure signal or delete a venue from the simulation based purely on an external API or single data ingestion source. 

**The Verification Protocol:**
When a "Closure Event" is ingested from a source (e.g., Tier 3 POI Data or Tier 5 Narrative Data), the Locality Model must freeze the venue's active status and immediately cross-reference the claim against two live reality checks:
1. **Physical User Behavior:** Are human users still physically pinging, checking in, traveling to, or clustering around those specific geographic coordinates?
2. **AI-to-AI / Human Consensus:** Are other agents (AI or human) interacting with the space, talking about the venue, or actively acknowledging the closing? 

This is a governance kernel, not a convenience heuristic.

The live-locality rule is:
1. a closure source alone is not enough
2. live locality behavior around the space must be considered
3. other agents or human-admin acknowledgements of the closure must be considered
4. the locality model may reduce confidence or freeze the node before it may kill the node

**The Resolution:**
Only when physical telemetry drops to zero and localized agent chatter confirms the closure can the Locality Model update the Reality Engine to permanently shut down that node. If users are still physically entering the space despite an official "closed" API status, the venue remains functionally alive in the AVRAI logic. The human behavior overrides the database.

The governance record should preserve:
1. the closure claim source
2. the cross-check evidence
3. the final locality decision
4. the timestamp of the decision

---

## 2. Scaling Governance: Autonomous Growth & Geography Seeding 

**The Problem:** The master Birmingham (BHAM) simulation provides the foundational training, but what happens when a real human user boots up an AVRAI agent in Savannah, Georgia for the very first time? 

**The Governance Kernel:**
There is only **ONE** Master Human Admin App for the AVRAI ecosystem at launch. If an agent boots in an unmapped zone without existing internal locality models, it must escalate up the hierarchy to the Reality Engine and explicitly request secure human authorization to "seed" the new city.

This is a joint engine + runtime OS governance kernel:
1. the Reality Engine owns the hierarchy decision
2. the runtime OS owns the secure operational seeding flow
3. the human admin owns permission to attach new intake sources

**The Action Flow (The "Savannah Drop"):**
1. **Boot:** An AVRAI Agent boots up in Savannah, GA.
2. **Hierarchy Search:** The agent looks up its immediate chain of command for Savannah Locality Agents. 
3. **Escalation:** It finds nothing. The highest level it can connect to is the global Reality Model above it.
4. **Trigger:** Because the Savannah locality agents do not exist, they must be created. The Reality Agent and the `avrai_runtime_os` coordinate an escalated request.
5. **The Admin Request:** A formal alert is pushed to the central Human Admin App requesting permission to attach to new data intake sources (the Savannah equivalents of our Tier 1-5 BHAM registries).
6. **Authorization & Seeding:** The Human Admin approves the intake. The OS sucks in the Savannah data, immediately spinning up and seeding the Savannah Locality Agents.
7. **The Golden Rule:** The new intake data is **NOT** permanently saved as a massive global database within AVRAI. The raw intake is used *strictly to seed* the starting assumptions of the Savannah Locality Agents. Once seeded, the raw intake may be discarded, but the seeding authorization, source provenance, and resulting locality-agent starting assumptions must remain auditable. The Savannah Locality Agents then learn and evolve through their interactions with the real human users and agents in that physical space.

---

## 3. Temporal Governance: One Source Of Truth For Timing

**The Problem:** AVRAI currently has multiple temporal surfaces: live device/server time, runtime temporal truth, and simulation time. If these drift apart, replay validity, route timing, governance inspection, and reality-model learning all become unreliable.

**The Governance Kernel:**
There must be one temporal authority for AVRAI:

1. the timing governance kernel is the source of truth for timing
2. runtime OS, engine, simulation, and admin all consume time through that kernel
3. quantum atomic time may improve the kernel, but may not create a parallel timing authority

**Improvement Rule:**
Quantum atomic time should be rethought and improved anywhere it materially strengthens:

1. mathematical timing precision
2. causal ordering
3. monotonic sequencing
4. uncertainty windows
5. timezone normalization
6. clock-regression detection
7. replay and Monte Carlo branch coherence

**Execution Rule:**
The simulation clock, replay clock, and live runtime timing should not remain independent conceptual systems. They should be separate modes of the same timing governance kernel.

---

## 4. Population Governance: Human Population Versus Agent Population

**The Problem:** A hyperrealistic city simulation should not assume every human has an AVRAI personal agent.

**The Governance Kernel:**
The Birmingham simulation must distinguish between:

1. humans who exist in the city model
2. humans who currently have a personal AVRAI agent
3. system agents such as locality, city, and reality agents

**Lifecycle Rule:**

1. a personal agent may appear when a user is created or adopts AVRAI
2. a personal agent may go dormant when a user stalls
3. a personal agent must terminate when a user deletes
4. system agents are governed separately from personal-agent lifecycles

**Age Rule:**

1. no personal AVRAI agent may exist for anyone under age 13
2. under-13 humans may still influence the simulation only as dependent-mobility factors affecting households, schools, youth activities, and locality rhythms
3. youth-source data may inform city movement and adult routine friction, but may not create under-13 personal AVRAI agents

---

## 5. Prediction Governance: Prediction Is Not Governance

**The Problem:** Wave 8 needs forecasting and branch-based prediction so replay, Monte Carlo, string-theory work, and quantum prediction work can train on real governed structure. But if prediction becomes a governance kernel, the same subsystem would both generate speculative futures and judge whether those futures are trustworthy.

**The Governance Kernel:**
Prediction must not be the governance kernel.

The operating split is:
1. the prediction or forecast kernel belongs to the Reality Engine
2. governance kernels judge forecast admissibility, validity window, contradiction stress, and actionability
3. live reality, locality truth, and human-admin correction can overrule prediction outputs immediately

**The Forecast Kernel Should Own:**
1. branch and run evaluation
2. Monte Carlo path generation
3. Markov or other internal transition structures
4. counterfactual generation
5. uncertainty-bearing future expectations
6. replay-to-forecast training outputs

**Governance Should Own:**
1. whether a prediction is current enough to be used
2. whether a prediction is contradicted by live evidence
3. whether a prediction may drive a user-visible action
4. whether a prediction is quarantined, downgraded, or blocked
5. whether a promoted prediction model is still safe and coherent enough to serve

**The Rule:**
Prediction is the forecaster.
Governance is the referee.
Reality is the final authority.

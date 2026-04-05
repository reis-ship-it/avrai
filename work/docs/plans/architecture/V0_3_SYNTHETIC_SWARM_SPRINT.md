# v0.3: The Synthetic Swarm & True Intelligence Sprint

## 1. Goal
Transition AVRAI's foundational intelligence away from hardcoded, legacy pseudoscience (Big Five OCEAN) toward a modern, behavioral-driven architecture (JEPA / Intelligence-First Architecture).

To achieve this "zero-user reliability" from day one, we will construct a **Multi-City Synthetic Swarm Simulation**. This swarm will pre-train federated Locality Agents and user models by simulating realistic populations in NYC, Denver, and Atlanta, utilizing real-world historical events. 

The core philosophy of this swarm is **"Routine Enhancement"**: agents must learn to find interstitial gaps to improve lives without blindly breaking routines, governed by strict **Dynamic Friction** and a **Trust/Disappointment Meter**.

## 2. Core Constraints & Rules
- **Quantum Atomic Timing is Mandatory:** All simulated actions, events, and trajectory updates in the swarm MUST use `AtomicClockService.getAtomicTimestamp()`. Standard `DateTime.now()` is forbidden.
- **Air Gap Event Ingestion:** All real-world historical locality events used to seed the swarm must be processed through the `TupleExtractionEngine` (Air Gap) to strip away PII and noise before reaching the `SemanticKnowledgeStore`.
- **The "No Pseudoscience" Mandate:** This sprint officially deprecates all Big Five OCEAN dataset dependencies, replacing them with Joint-Embedding Predictive Architecture (JEPA) behavioral observations.

---

## 3. Sprint Spikes

### Spike 1: The Atomic Simulation Environment (The Engine)
*Building the bedrock of the multi-city simulation.*

*   ✅ **1.1 City Profile Generation:** Establish baseline simulation parameters for NYC, Denver, and Atlanta. Each city must define variables for transportation types (walkability vs. subway vs. car-centric), population density, and macro lifestyle pacing.
*   ✅ **1.2 Atomic Synchronization Protocol:** Ensure the simulation loop explicitly passes simulated time via the `AtomicClockService`. The simulation must be able to fast-forward deterministic events while maintaining precise atomic temporal tracking for the `QuantumTemporalStateGenerator`.
*   ✅ **1.3 Macro Life Event Injectors:** Create system triggers to inject major life changes into simulated agents (e.g., "got a dog", "moved neighborhoods", "new job"). This will provide critical training data for Latent State Inference.

### Spike 2: Real-World Event Ingestion (The Baseline)
*Seeding the Locality Agents with truth.*

*   ✅ **2.1 Real-World Data Pipeline:** Build a script to ingest a static dataset of historical local events for the three target cities.
*   ✅ **2.2 The Air Gap Pass:** Pass every ingested event through the `TupleExtractionEngine`. Convert events into Semantic Tuples and mathematically defined Knowledge Vectors.
*   ✅ **2.3 Locality Agent Pre-seeding:** Feed these vectors into the federated Locality Agents for those cities, establishing an accurate baseline "vibe vector" for neighborhoods before the user swarms are introduced.

### Spike 3: Routine Enhancement & Latent State Inference (The Logic)
*Teaching the AI to improve life smoothly, not disrupt it forcefully.*

*   ✅ **3.1 The Interstitial Gap Finder:** Modify the agent pathfinding logic to identify natural gaps in existing routines (e.g., commute route overlaps, evening downtime).
*   ✅ **3.2 The Seamless Enhancement Reward Function:** Train the energy function to heavily reward suggestions that add high value with near-zero friction (e.g., suggesting a highly-compatible plant store perfectly aligned with a walking commute). 
*   ✅ **3.3 Latent State Inference (JEPA):** Train the `TransitionPredictor` to recognize the behavioral signatures of the "Macro Life Events" (from Spike 1.3). When detected, trigger the SLM to ask polite, non-invasive questions to confirm the life change (e.g., "Notice you've been taking earlier morning walks. Get a new dog?").

### Spike 4: Dynamic Friction & Fragile Trust (The Guardrails)
*Ensuring quality does not regress to the mean.*

*   ✅ **4.1 Dynamic Activation Energy:** Implement an agent state tracking metric. Initial friction to break routine is high. If an AI suggestion succeeds, willingness (activation energy) temporarily drops, making the agent more open to future suggestions.
*   ✅ **4.2 Trust/Disappointment Meter:** Prevent "regression to the mean." Even when an agent's friction drops, the AI's "Quality Threshold" for suggestions must remain rigid. If a mediocre suggestion is given and the agent is disappointed, trust plummets exponentially faster than it grows. The AI must learn it is better to stay silent than to offer a low-quality, high-friction recommendation.

### Spike 5: Swarm Execution & Locality Sync (The Training)
*Running the simulation and extracting the models.*

*   ✅ **5.1 Multi-City Swarm Execution:** Run the simulated swarms concurrently across NYC, Denver, and Atlanta environments using the `AtomicClockService` timeline.
*   ✅ **5.2 Federated Knowledge Exchange:** Enable Locality Agents to exchange learned pathways and common failure modes for agents who are "not fitting in" or struggling to find their communities.
*   ✅ **5.3 Model Extraction & Deprecation:** Finalize the deprecation of Big Five dataset loaders. Extract the learned embedding spaces and weights from the swarm to serve as the new default baseline for zero-user cold starts.

---

## 4. Expected Outcomes
*   `.cursorrules` updated to enforce Swarm Baseline over Big Five (✅ Completed).
*   [x] Simulation engine capable of deterministic replay using `AtomicClockService`.
*   [x] Three pre-trained, location-aware Locality Agents (NYC, Denver, Atlanta).
*   [x] A robust `TransitionPredictor` capable of identifying life changes and safely navigating dynamic friction thresholds.

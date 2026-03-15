## Release Gate Checklist — AVRAI Math-Driven Swarm (v0.1 - v0.3)

**Audience:** You + anyone doing a release cut  
**Goal:** A single go/no-go checklist for shipping a **fully functional AVRAI node** where:
- **Air Gap** is absolute (no cloud LLMs, all personal data stays on-device).
- **Daily Serendipity Drop** is the only UX (Trojan Horse / Addicted to the Real World).
- **Zero User Reliability** is active (passive listeners gather data without user effort).
- **Pheromone Mesh** works seamlessly via BLE (epidemic routing in the background).
- **Deterministic Quantum UX** matches DNA math strings instantly.
- **Nightly Digestion Job**: Local LLM runs securely when device is idle and battery >51%.

This checklist is **repo-specific** and aligns with the **3-Prong Architecture** (App ↔ Runtime OS ↔ Reality Engine).

---

## Scope (what “done” means for this release)

### In scope (must work)
- **3-Prong Boot**: `avrai_app` UI layer boots, connects to `avrai_runtime_os`, which initializes `avrai_reality_engine` (Rust FFI).
- **Daily Serendipity Drop**: User receives exactly 4 hyper-targeted recommendations per day. No infinite feeds.
- **Air Gap Core**: No personal data (tuples) leaves the device. Core operations run offline.
- **Zero User Reliability (Passive Listeners)**: Background listeners (GPS, Calendar, HealthKit, App Usage) collect data into `SemanticTuple` format.
- **Pheromone Mesh (BLE)**: Device broadcasts and receives 2KB DNA strings and "Digital Pheromones" seamlessly.
- **Deterministic Quantum Matching**: Match operations using energy-based math execute in <0.001ms.
- **Nightly Digestion Job**: Local LLM runs only when charging >80%, summarizing tuples into the "Soul Doc".

### Explicitly out of scope (allowed to be incomplete *only if gated/off*)
- Cloud-based chat interfaces (deprecated).
- Legacy hardcoded matching formulas (deprecated in favor of Energy Functions).
- Broad manual data entry UIs (replaced by passive listeners).

---

## Gate 0 — 3-Prong Build + Boot Sanity (required)

### Pass criteria
- **Android & iOS**: `debug` and `release` builds install.
- **Isolate Boot**: Runtime OS isolates spawn successfully.
- **Rust FFI Bindings**: Reality Engine math functions are callable without crashing.
- App boots entirely offline without requiring a cloud connection.

---

## Gate 1 — Core UX: Daily Serendipity Drop (required)

### Must pass (user-visible)
- User opens app and sees the "Drop" (4 curated doors).
- Interaction is minimal: User views, chooses, and leaves the app (Addicted to the Real World UX).
- UI does not contain a search bar or chat interface unless specifically gated.
- No network spinners for loading the Drop (it is pre-computed by the Nightly Digestion Job).

---

## Gate 2 — Air Gap & Local Persistence (required)

### Must pass
- `SemanticKnowledgeStore` (Drift/SQLite) persists tuples locally.
- Force-quitting the app does not lose tuple data.
- **Truth Check**: Ensure absolutely no `SemanticTuple` or PII is sent to Supabase or any external server.

---

## Gate 3 — Zero User Reliability (Passive Listeners) (required)

### Must pass
- Permissions flows (Location, HealthKit, Usage Access) are smooth and fail gracefully.
- Background listeners correctly format data into `(subject, predicate, object)` `SemanticTuples`.
- `observationCount` and `signalStrength` correctly increment without creating duplicate tuples.

---

## Gate 4 — Pheromone Mesh (BLE Epidemic Routing) (required)

### Must pass
- `PheromoneMeshRoutingService` broadcasts local DNA strings.
- Receiving device successfully parses the 2KB payload.
- Pheromone Time-To-Live (TTL) logic properly decays and deletes old pheromones from the local cache.
- (If enabled) Cryptographic signatures from `GovernanceKernelService` are verified for premium business pheromones.

---

## Gate 5 — Deterministic Quantum Matching (required)

### Must pass
- `OnnxDimensionScorer` or Rust FFI calculates inner products (`|⟨ψ_A|ψ_B⟩|²`) in <0.001ms.
- Energy function executes without OOM (Out of Memory) errors.
- Results dictate the Daily Serendipity Drop ordering.

---

## Gate 6 — Nightly Digestion Job & Soul Doc (required)

### Must pass
- Job only triggers when device is idle AND `batteryLevel > 51%`.
- Local LLM boots, processes the day's raw `SemanticTuples`, and generates a human-readable "Soul Doc".
- Memory is released properly after the LLM completes.
- Thermal safeguards trigger if device gets too hot, gracefully suspending the job.

---

## Gate 7 — Locality Agents & Federated Learning (required if visible)

### Must pass
- Device only uploads **anonymized gradients/deltas** to Locality Agents.
- The upload contains no raw context, no PII, no text.
- Device can pull global average priors without crashing.

---

## Gate 8 — Privacy + Security Invariants (required)

### Must pass
- No production `print()` logging (enforce `developer.log()`).
- Local DB is encrypted (SQLCipher).
- Business pheromone injection points are cryptographically secured against spoofing.

---

## Gate 10 — Real-Device Experimentation Matrix (go/no-go for production)

This is the “truth layer” that simulators can’t cover. Simulators do not simulate BLE, real battery constraints, or thermal throttling.

Mark each item: **GO** (validated) | **BLOCKED** (no devices yet) | **NO-GO** (validated failing)

### A) 3-Prong FFI Execution (Real device)
- Call a Rust math function from the UI thread and ensure no UI stutter.

### B) BLE Pheromone Mesh & Background Usage (Real device)
- Run two physical devices in proximity.
- Validate Epidemic Routing handoff occurs while app is backgrounded.
- Validate iOS Background Modes / Android Doze do not completely kill the mesh (or fail gracefully).
- Check battery drain over 24h (must be < 5% for the mesh service).

### C) Passive Listener Permissions & State (Real device)
- Test "Deny Once", "Allow while using", and "Allow all the time" for GPS.
- Validate iOS HealthKit and Android Health Connect real data extraction.

### D) Nightly Digestion & Local LLM Thermals (Real device)
- Leave device idle at >51% battery.
- Trigger `AdaptiveDigestionJob`.
- Monitor device temperature and ensure it doesn't hit thermal shutdown.
- Verify the Soul Doc is generated by the time the user wakes up.

### E) Air Gap Validation (Real device)
- Put device in Airplane mode.
- App must boot, load the Drop, and allow interaction entirely offline.
- Connect device to a proxy (e.g., Charles/Proxyman) and verify NO user data flows to external IPs.

### F) SQLite / Drift Concurrency (Real device)
- Simulate high-volume passive listener data (e.g., 5,000 tuple inserts) while simultaneously querying for the Drop.
- Ensure no database locks or UI freezes.

---

## Release Decision

### GO
All required gates (0–8) are green, and the real-device matrix has no **NO-GO** items for subsystems included in the release build.

### Conditional GO (internal/TestFlight only)
Required gates are green, but one or more real-device items are **BLOCKED** (no hardware yet). Ship only if the blocked subsystem is disabled/gated and cannot impact the core UX.

### NO-GO
Any of:
- App fails to boot in Airplane Mode (Air Gap violation).
- Local LLM causes thermal shutdown or infinite hang.
- BLE Mesh drains battery excessively.
- Tuples are lost upon app restart.
- Cloud API calls contain PII or raw tuple data.

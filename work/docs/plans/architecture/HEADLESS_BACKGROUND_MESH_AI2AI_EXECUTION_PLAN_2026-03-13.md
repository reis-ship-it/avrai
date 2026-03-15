# Headless Background Mesh + AI2AI Execution Plan

**Created:** March 13, 2026  
**Status:** Active architecture plan  
**Scope:** Current runtime architecture, not full Phase 12 extraction  
**Companion docs:** `AI2AI_MESH_KERNEL_IMPLEMENTATION_BACKLOG_2026-03-11.md`, `AI2AI_MESH_3_PRONG_GOVERNED_ARCHITECTURE_2026-03-11.md`, `PHASE_12_OS_RATIONALE.md`, `RETICULUM_SIGNAL_SIMPLE_MESH_BACKLOG.md`

---

## 1. Summary

AVRAI should not try to keep the app "visually open" with a widget.

The correct target is:

- a **headless/background execution envelope**
- around the **existing mesh and AI2AI kernels**
- fed by **event-driven passive sensing**
- aligned with the existing **Reticulum-style mesh control plane**

This means:

- `MeshKernel` remains the only transport authority
- `Ai2AiKernel` remains the only exchange authority
- human chat remains a governed surface over language, boundary, expression, and mesh transport
- background execution is **not** a new kernel family
- a widget is optional UI, not execution infrastructure

The human-facing goal is simple:

- the human should not need to open the phone for AVRAI's agent to keep working
- agents should be able to defer, wake, exchange, and learn automatically
- the system should prefer event-driven background work over foreground dependence

---

## 2. The Current State

AVRAI already has part of the right shape, but it is still mostly **app-runtime-booted**, not **OS/headless-wake-driven**.

What already exists:

1. `HeadlessAvraiOsHost` and `HeadlessAvraiOsBootstrapService` already define a headless runtime mediation surface.
2. `MeshKernelContract` and `Ai2AiKernelContract` already exist as domain execution kernels.
3. `Ai2AiRendezvousScheduler` already persists and releases deferred exchange when runtime conditions are met.
4. `MeshKernel` already owns:
   - route memory
   - announce memory
   - custody/store-carry-forward
   - trusted announce enforcement
5. passive collection already exists for:
   - motion
   - location
   - nearby BLE encounter adaptation
6. Android already has a BLE foreground-service bridge.

What is still missing:

1. rendezvous release is started from app boot, not from a true headless wake path
2. idle detection is tied to `WidgetsBindingObserver`, which is app-runtime lifecycle, not OS-level scheduling
3. Wi-Fi-triggered release is supported in the scheduler API but is not fully wired into the live registration path
4. passive sensing is still mostly in-process and app-lifecycle-bound
5. receiving-side AI2AI peer-truth still needs full live coverage on every deferred path
6. there is not yet a dedicated background execution coordinator for mesh + AI2AI + passive kernel learning

So the next serious step is not "add a widget."
It is "make the current kernel architecture runnable from OS-approved background/headless wake sources."

---

## 3. The Correct Architecture

### 3.1 Keep the current kernel doctrine

Do **not** introduce:

- a new `ChatKernel`
- a separate background kernel family
- a second mesh kernel family

Keep:

- `MeshKernel` as transport truth
- `Ai2AiKernel` as exchange truth
- `who/what/when/where/why/how` as governance surfaces
- human chat as a governed projection surface

### 3.2 Add a background execution envelope

The new layer should be an execution envelope around the existing kernels.

Recommended runtime seams:

1. `HeadlessBackgroundRuntimeCoordinator`
   - starts the background execution envelope
   - routes OS wake reasons into the proper lanes
   - owns no domain truth

2. `BackgroundWakeReason`
   - `ble_encounter`
   - `trusted_announce_refresh`
   - `connectivity_wifi`
   - `significant_location`
   - `background_task_window`
   - `boot_completed`
   - `segment_refresh_window`

3. `BackgroundCapabilitySnapshot`
   - current platform grants and limits
   - BLE capability
   - background execution window
   - connectivity class
   - battery/thermal budget
   - privacy mode

4. `PassiveKernelSignalIntakeLane`
   - converts background sensor events into governed kernel inputs
   - owns no final truth

5. `MeshBackgroundExecutionLane`
   - uses `MeshKernelContract`
   - handles announce refresh, custody replay, deferred delivery, and trusted-route recovery

6. `Ai2AiBackgroundExecutionLane`
   - uses `Ai2AiKernelContract`
   - handles deferred release, re-probe, exchange submission, and receiving-side receipt observation

These are **not** new kernels.
They are execution/orchestration seams that make the current kernels runnable when the UI is not active.

---

## 4. How This Fits Reticulum

The Reticulum-aligned part stays in mesh, not in app code.

This background plan should strengthen the parts of AVRAI that most closely match the useful Reticulum ideas:

1. **destination-first pathing**
   - wake on real route/announce changes, not only timer retry

2. **store-carry-forward**
   - keep deferred custody alive across app backgrounding and restarts

3. **trusted announce and segment policy**
   - only trusted routes are eligible when trust enforcement is on

4. **bearer-aware routing**
   - background release should know whether BLE, local relay, or later cloud-assist is actually eligible

5. **simple user semantics**
   - users still see only:
     - `sending`
     - `delivered`
     - `read`
     - `AI learning updated`
   - they do not need to know about custody queues, trusted announces, or rendezvous policy

Reticulum’s real lesson here is not "show users more network detail."
It is "move complexity into the transport/control plane so the user experience stays simple."

---

## 5. How This Fits the Reality Model and Six Kernels

The background path must feed the existing kernel surfaces, not bypass them.

### 5.1 `who`

Background sources:

- nearby agent continuity
- repeated peer encounters
- co-presence evidence
- trusted peer identity continuity

### 5.2 `what`

Background sources:

- encounter class
- activity class
- exchange artifact class
- queue/custody/exchange state

### 5.3 `when`

Background sources:

- wake timestamp
- dwell window
- route freshness
- replay window
- release window for deferred exchange

### 5.4 `where`

Background sources:

- significant location change
- dwell cluster
- locality segment
- trusted route scope
- bearer environment

### 5.5 `why`

Background sources:

- why a route was eligible or rejected
- why a rendezvous stayed deferred
- why learning was applied or skipped

### 5.6 `how`

Background sources:

- bearer path used
- trusted route chosen
- replay trigger source
- release path used for deferred exchange

The rule stays the same:

- background execution may **feed** the six surfaces
- background execution may **not** create a second truth system

---

## 6. What Must Become Real

### 6.1 Mesh in background/headless mode

`MeshKernel` must be able to run without the app UI being active.

That means:

1. restore route, announce, segment, and custody state from persistence
2. accept OS wake reasons and new producer events
3. replay custody only when trusted route conditions are satisfied
4. continue trusted multi-hop recovery
5. emit kernel-owned transport receipts and diagnostics

### 6.2 AI2AI in background/headless mode

`Ai2AiKernel` must be able to:

1. restore deferred rendezvous tickets
2. re-evaluate deferred tickets when:
   - Wi-Fi becomes available
   - device becomes idle
   - trusted route becomes available
3. submit exchange only through the existing exchange path
4. observe receiving-side receipts:
   - `peer_received`
   - `peer_validated`
   - `peer_consumed`
   - `peer_applied`
5. keep exchange truth kernel-owned before and after background release

### 6.3 Passive learning in background/headless mode

Passive kernel learning should be event-driven and batched.

Preferred sources:

1. significant location change
2. dwell clustering
3. BLE co-presence / nearby encounter evidence
4. device activity/motion transitions
5. trusted route/exchange timing

Avoid:

- continuous heavy polling
- background LLM inference loops
- high-frequency sensor work while no wake signal exists

The phone should feel like:

- "lightweight in the background"
- not "always on at full speed"

---

## 7. Platform Execution Strategy

### 7.1 Android

Recommended path:

1. BLE foreground service for mesh continuity when enabled
2. WorkManager for:
   - deferred rendezvous checks
   - segment refresh windows
   - periodic trust/custody maintenance
3. boot-completed restore path
4. connectivity callbacks for Wi-Fi-triggered release
5. significant location / activity signals where permitted

Android is the strongest candidate for "mostly autonomous background AVRAI on a phone."

### 7.2 iOS

Recommended path:

1. CoreBluetooth background modes + state restoration
2. BGTaskScheduler for deferred execution windows
3. significant-location and region-monitoring wakes
4. constrained background restore path for deferred rendezvous and passive kernel intake

iOS can support this, but under tighter OS limits.

Important constraint:

- iOS force-quit behavior is not something AVRAI can fully override
- the product promise must remain honest about platform limits

### 7.3 Strongest honest promise

**Phone-only promise:**

"After setup and permissions, AVRAI continues background mesh, deferred AI2AI exchange, and passive learning automatically within OS limits."

**Stronger future guarantee:**

"For near-always-on autonomy, AVRAI can also use a companion node, wearable, or home relay."

That second promise is where the long-run gateway/home-node direction becomes useful, but it is not required for the next phase.

---

## 8. Required Repo Workstreams

### Wave 1: Headless background execution contract

1. add `HeadlessBackgroundRuntimeCoordinator`
2. add `BackgroundWakeReason`
3. add `BackgroundCapabilitySnapshot`
4. move current rendezvous start logic behind this coordinator
5. inject real `Connectivity` into the live scheduler registration

### Wave 2: Android-first real execution path

1. bind BLE foreground service + background worker path to the coordinator
2. restore mesh and AI2AI persisted state on worker wake
3. trigger trusted custody replay and deferred rendezvous release from the coordinator
4. emit proof bundles and diagnostics for background/headless runs

### Wave 3: iOS constrained path

1. add a constrained background coordinator entry path for:
   - Bluetooth restoration
   - BGTaskScheduler windows
   - significant-location wakes
2. keep the same mesh/AI2AI kernels underneath
3. document iOS guarantee boundaries explicitly

### Wave 4: Passive kernel learning path

1. move passive learning wake signals into `PassiveKernelSignalIntakeLane`
2. convert sensing events into governed `who/what/where/when` updates
3. batch low-priority digestion instead of running heavy continuous work

### Wave 5: Full kernel-owned background AI2AI truth

1. cover all deferred exchange paths with receiving-side peer-truth receipts
2. ensure sender state only advances from real downstream observations
3. keep `trusted_route_unavailable` as the blocked reason when trust requires it

### Wave 6: Reticulum-grounded next step

After the background execution envelope is stable:

1. IFAC-style private segment policy
2. bearer-scoped trust and route eligibility
3. interface-specific segment membership rules
4. route-class policy:
   - local-only
   - trusted-relay
   - cloud-eligible

---

## 9. Acceptance Criteria

This plan is complete when all of the following are true:

1. the human does not need to open the app for deferred AI2AI release to occur after setup
2. mesh custody replay can happen from a background/headless wake source
3. passive kernel learning can ingest location/activity/encounter events without foreground UI
4. trusted announce enforcement still governs route eligibility in background execution
5. `MeshKernel` remains the sole transport writer in background mode
6. `Ai2AiKernel` remains the sole exchange writer in background mode
7. admin can inspect proof bundles and trust diagnostics for background/headless runs
8. AVRAI can explain why a release happened, why it stayed blocked, and which trusted route or wake source was involved

---

## 10. What This Is Not

This plan is **not**:

1. a widget strategy
2. a new kernel family
3. a full Phase 12 Rust extraction
4. a replacement for Signal
5. a justification for constant high-frequency background polling

It is the practical bridge between:

- today’s runtime-governed mesh + AI2AI kernels
- and the longer-run headless OS target

without breaking the current architecture or the Reticulum-grounded direction.

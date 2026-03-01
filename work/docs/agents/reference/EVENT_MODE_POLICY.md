# Event Mode Policy (AI2AI + BLE) — Drift-Safe, Low-Chatter, Battery-Bounded
**Status:** Active (policy/spec)  
**Primary risks addressed:** runaway personality drift, BLE chatter/thrash, battery drain  
**Related:**
- `docs/agents/reference/BLE_GATT_STREAMS_CONTRACT.md` (Stream 0 / Stream 1 on-wire contract)
- `docs/plans/offline_ai2ai/OFFLINE_AI2AI_TECHNICAL_SPEC.md` (baseline offline AI2AI flow)
- `docs/plans/ai2ai_system/BLE_BACKGROUND_USAGE_IMPROVEMENT_PLAN.md` (battery + background strategy)
- `lib/core/ai2ai/connection_orchestrator.dart` (current throttles/cooldowns + learning application)
- `lib/core/ai2ai/battery_adaptive_ble_scheduler.dart` (battery-tier scan policy)

---

## 1) Purpose
Event Mode exists to let the on-device model **understand an event locally** without the AI2AI system “fighting itself” in a crowded venue.

**Core idea:** During an event, AI2AI produces **bounded observations** (what’s happening in the room) and defers durable learning until the event is understood.

---

## 2) Non-negotiable invariants (safety rails)
### 2.1 No real-time personality writes from event-time AI2AI
In Event Mode:
- **MUST NOT** apply `PersonalityLearning.evolveFromAI2AILearning(...)` inline as a result of walk-by discovery or remote-node messages.
- **MUST** buffer any “learning-like” signals to an **EventLearningBuffer** (in-memory + optionally persisted).
- **MUST** run **post-event consolidation** to decide what (if anything) updates personality.

### 2.2 Drift budget caps (so crowds can’t shove you around)
Event Mode must enforce:
- **Per-event drift cap** (contextual layer only): small bounded delta.
- **Per-day drift cap** (contextual layer only): small bounded delta.
- **Core personality**: update only from **repeated evidence across multiple events**, never from a single crowded event.

### 2.3 Bounded transport (no BLE storms)
Event Mode must enforce strict budgets:
- **GATT “deep sync” connections**: rare, time-capped, byte-capped.
- **No “fan-out” learning insight gossip** during events (or heavily capped to near-zero).

---

## 3) Mode states
### 3.1 Modes
- **Normal Mode**: standard behavior (walk-by + learning throttles apply).
- **Event Mode (Broadcast-First)**: default event behavior; no GATT connections except scheduled check-ins.
- **Event Mode (Brownout)**: ultra-conservative fallback when density/battery is high.

### 3.2 Entry/exit
Event Mode can be:
- **Manual**: user toggles “Event Mode”.
- **Scheduled**: user starts an event session (start/end timestamps).
- **Auto** (optional): inferred from nearby-node density + dwell time (implementation choice).

Exit conditions:
- Event session ends, or user disables.
- Auto-exit if “no-crowd” persists for N minutes.

---

## 3.3 Walk-by vs linger (dwell threshold)
Event Mode must distinguish “passed through a crowd” from “user is actually dwelling near something”.

### Definitions
- **Walk-by**: user is exposed to high density briefly, with high churn (lots of new nodes, little overlap).
- **Linger (dwell)**: user remains near roughly the same nearby-node set long enough to justify a rare check-in.
- **Coherent linger**: linger **plus** the local “room vibe” summary stays stable (suggesting a shared context like an event, not just a static crowd).

### Dwell detector (recommended v1)
Compute these per scan window:
- `windowStartMs`, `windowEndMs`
- `seenNodeIds` (set)
- `medianRssiDbm` (optional; platform-dependent)

Maintain a rolling buffer of the last ~10 minutes of windows.

**Derived metrics:**
- `overlapRatio = |A ∩ B| / max(1, |A ∪ B|)` (Jaccard similarity between consecutive windows)
- `newNodeRate = newNodesPerWindow / windowDurationSeconds`

### Stage 1 — Linger threshold (linger=true)
- At least **3 scan windows** over **≥ 3 minutes**, and
- `uniqueNodesPer10Min >= 25` *(dense enough to matter)*, and
- median `overlapRatio >= 0.30` across those windows *(node set is “sticky”)*, and
- `newNodeRate` is not extreme *(avoid pure transit; implementation may cap e.g. `<= 10 new nodes/sec`)*

**Notes:**
- If you have motion signals available (accelerometer / step proxy), you can strengthen this: “linger=true only when low motion”.
- If you don’t, the overlapRatio approach still works well: walk-bys tend to have low overlap.

### Stage 2 — Coherence threshold (coherent_linger=true)
Coherence is how we avoid labeling “standing in Times Square” as an event.

Maintain a rolling **room vibe summary** per scan window using the same core math as Patent #1 (quantum inner-product probability + Bures distance), but computed from **collapsed, privacy-scoped broadcast values**:

#### Quantum mapping (broadcast-safe)
Treat each broadcast dimension value as a classical probability \(p \in [0,1]\), then convert to a (real-valued) quantum amplitude via the Born-rule mapping used throughout SPOTS docs:

- **Amplitude component:** \(a_k = \sqrt{p_k}\)
- **Normalize:** \(|\psi_i\rangle = \frac{a}{\|a\|}\)

> Note: this is the “phase=0”/real-only case. Deep sync can use richer quantum state/phase/entanglement (see `lib/core/ai/quantum/*`), but coherence detection must remain cheap and privacy-scoped.

#### Room state (per scan window)
Given \(N\) nearby nodes in a scan window, compute the room superposition:

- \(|\Psi\rangle = \mathrm{normalize}\left(\sum_{i=1}^{N} \sqrt{w_i}\,|\psi_i\rangle\right)\)
- Default weights: \(w_i = \frac{1}{N}\) (equal weights)

#### Coherence score (scalar; 0..1)
Use the same compatibility primitive as Patent #1:

- \(C_i = |\langle \psi_i | \Psi \rangle|^2\)
- \(\mathrm{coherenceScore} = \frac{1}{N}\sum_{i=1}^{N} C_i\)
- \(\mathrm{dispersionScore} = 1 - \mathrm{coherenceScore}\)

#### Stability across windows (Bures distance; 0..√2)
Use the patent Bures metric between room states:

- \(D_B(\Psi_t,\Psi_{t-1}) = \sqrt{2\left(1 - |\langle \Psi_t | \Psi_{t-1}\rangle|\right)}\)

#### Explicit numeric defaults (v1)
Compute coherence only when the sample is big enough:
- `minNodesForCoherence = 12`

Then set:
- `coherenceScoreMin = 0.70`
- `buresDistanceMax = 0.30` *(≈ requires \(|\langle\Psi_t|\Psi_{t-1}\rangle| \gtrsim 0.955\))*
- `coherenceDeltaMax = 0.08` *(|coherenceScore_t - coherenceScore_{t-1}|)*
- `requiredConsecutiveWindows = 3`

**Threshold (coherent_linger=true):**
- `linger=true`, and
- `uniqueNodesPer10Min >= 25`, and
- in **3 consecutive windows**:
  - `nodeCount >= minNodesForCoherence`
  - `coherenceScore >= coherenceScoreMin`
  - `D_B <= buresDistanceMax`
  - `|ΔcoherenceScore| <= coherenceDeltaMax`

**Interpretation:**
- Linger without coherence = “I’m in a sticky crowd / dense place”
- Coherent linger = “there’s a stable shared context here” (event-like door)

### What linger enables (and what it doesn’t)
- **Enables:** arming the next scheduled check-in window (one deep sync) if all other budgets allow.
- **Does NOT enable:** event-time personality updates (still buffer-only).

### What coherent linger enables (and what it doesn’t)
- **Enables:** “event-like door” hypotheses become eligible to surface (softly) and the system may spend a *bit more compute* locally to interpret what’s happening.
- **Enables:** higher priority for a scheduled check-in (still budgeted; still opt-in; still deterministic initiator).
- **Does NOT enable:** bypassing deep sync budgets, battery constraints, or drift rules.

---

## 4) BLE policy (battery + chatter)
### 4.1 Advertising (always on, small, stable)
Advertising must remain **low-power and stable**:
- Keep Stream 0 payload **small** (“a few KB” target in contract).
- Prefer **advertisement-level hints** (very small) + Stream 0 for larger data when needed.

#### 4.1.1 Make chatter limits actually effective: “connectionless first”
The biggest source of BLE “chatter” in crowded environments is **connect attempts**, not scanning.

Event Mode therefore prioritizes **connectionless compatibility**:
- **Default path:** use **advertisement payload** to compute “good enough” compatibility and room-vibe stats (no GATT reads, no connects).
- **Escalation path (rare):** only during a scheduled check-in window, do a short GATT “deep sync” if both sides opt in.

**Recommended Stream 0 optional keys (backwards compatible; readers ignore unknown keys):**
- `schema_version` (int)
- `node_id` (string; stable within a privacy window; see orchestrator’s `_localBleNodeId`)
- `event_mode` (object)
  - `enabled` (bool)
  - `level` (`"broadcast_first"` | `"brownout"`)
  - `session_epoch` (int; e.g., floor(now/5min))
- `ttl_ms` (int; receiver should discard after TTL)

**Privacy rule:** no PII, no precise location, no venue IDs, no user identifiers.

#### 4.1.2 Advertisement payload (recommended contents)
To avoid GATT reads in a crowd, the advertisement payload should contain a compact summary sufficient for:
- rough compatibility gating
- density counting
- room-vibe aggregation

Suggested fields (encoding is implementation-defined; keep tiny):
- `node_id` (rotating id; stable within a privacy window)
- `vibe_signature` (short hash / truncated hash)
- `dims_q` (quantized dimensions; e.g., 8-bit values for core dims)
- `event_mode.connect_ok` (bool; see check-in gating below)

**Note (current repo reality):** the current BLE path advertises a GATT peripheral and exposes Stream 0/1 payloads for reading (see `BlePeripheral.startPeripheral(...)` and the Stream contract). The “advertisement payload” described here is an **upgrade target** to reduce GATT connects in dense environments. Until implemented, receivers may fall back to GATT reads **only inside check-in windows**.

### 4.2 Scanning (duty-cycled, crowd-adaptive)
Event Mode scanning is for *room sensing*, not connection hunting.

**Baseline (Broadcast-First):**
- `scanWindow`: 2–4s
- `scanInterval`: 12–60s (dynamic; see density tiers below)
- `deviceTimeout`: 30–120s (shorter in crowds; avoids long “keep-alive” costs)

**Brownout:**
- `scanWindow`: 2s
- `scanInterval`: 28–120s (prefer 60–120s on low battery)
- `deviceTimeout`: 75–120s

### 4.3 Crowd density tiers (simple + robust)
Compute density from scanning samples:
- `newNodesPerWindow`: count of newly seen node_ids (or device ids) in the last scan window
- `uniqueNodesPer10Min`: approximate unique nodes over a rolling 10-min window

Then apply:
- **Low density**: scan cadence ≈ every 10–15s
- **Medium density**: scan cadence ≈ every 30–60s
- **High density**: scan cadence ≈ every 60–120s + Brownout if battery is not strong

**Important:** In crowds, do *less* work per unit time; don’t “try harder”.

### 4.3.1 Dense does not always mean “event” (ambient crowd classification)
Highly dense places (e.g., Times Square) can be crowded without being an “event”.

To avoid event false-positives, classify dense contexts:
- **Event-like dense**: density is high **and** nearby-node set is relatively stable (higher overlapRatio) **and** coherence holds, suggesting shared context (coherent linger).
- **Ambient dense**: density is high **but** churn is high (low overlapRatio) and/or coherence fails, suggesting continuous flow (tourists/transit).

**Recommended classification (v1):**
- If `uniqueNodesPer10Min >= 50` and median `overlapRatio < 0.15` → **Ambient dense**
- If `uniqueNodesPer10Min >= 25` and median `overlapRatio >= 0.30` but `coherent_linger=false` → **Sticky crowd (not event-confirmed)**
- If `coherent_linger=true` → **Event-like dense**

**Behavior in Ambient dense:**
- Prefer **Brownout** automatically (battery + chatter protection)
- Do **not** arm check-ins (no deep sync), unless user explicitly requests
- Only collect coarse room stats (density, vibe distribution) for local context

**Behavior in Sticky crowd (not event-confirmed):**
- Keep **Broadcast-First** or **Brownout** based on battery
- Allow learning from the environment as “ambient context” (see §6)
- Arm check-ins only if `linger=true` **and** budgets are healthy (optional), but treat results as observations only

### 4.4 Battery integration
Event Mode must honor (in priority order):
1) **OS power saver** (if available)  
2) **Low battery thresholds** (e.g., <30% and <20%)  
3) **Event Mode density tier**  
4) Existing battery adaptive scheduler (if running)

#### 4.5 Token-bucket budgets (global + per-node)
Even with deterministic initiation, you want hard budgets so unexpected states can’t explode.

Event Mode should implement:
- **Global token bucket:** limit total deep sync attempts per hour
- **Per-node token bucket:** prevent repeated attempts to the same remote node
- **Failure backoff:** rapidly reduce attempts when the environment is hostile (OS throttling, pairing prompts, etc.)

---

## 5) Connection policy (avoid “agents fighting”)
### 5.1 Default: no connections in Event Mode
In Event Mode (Broadcast-First and Brownout):
- **Do not** initiate GATT connections during regular scanning.
- **Do not** attempt “best-node selection” continuously.
- Nearby agents are “good” because we’re not taking heavy actions per nearby node.

### 5.2 Scheduled check-ins (the only time we connect)
**Check-in cadence:** 1 connection attempt every **5 minutes** (optionally allow 2), **armed only** (see dwell/coherence gating).

**Arming rule (prevents walk-by thrash):**
- Scheduled check-ins are **armed only when `linger=true`** (see dwell threshold), OR when user explicitly requests an event check-in.

**Critical improvement (prevents thrash): opt-in bit**
Only attempt a deep sync if the remote advertises:
- `event_mode.connect_ok = true`

Receivers should set `connect_ok=true` only during the check-in window and only if:
- not in brownout
- not low battery
- not already connected / recently connected

#### What “opt-in” means operationally (not just a flag)
Opt-in is **two-sided** and enforced at multiple layers:

1) **Advertised willingness (app-level):** `event_mode.connect_ok=true` is a public “I’m willing right now” signal.
2) **Connectability (BLE-level):** during Event Mode, devices should advertise as **non-connectable** by default and only become **connectable** during the check-in window when `connect_ok=true`. (This prevents drive-by connection attempts from even starting.)
3) **Receiver enforcement (app-level):** even if a connection happens, the receiver must immediately drop/ignore deep-sync requests when `connect_ok=false` or budgets are exhausted.
4) **User preference (policy-level):** user can disable deep sync entirely; Event Mode defaults to conservative.

If any of those are “no”, deep sync does not proceed.

**Deep sync window constraints (hard caps):**
- **Max duration**: **12 seconds** total (8 seconds in conservative profile)
- **Max bytes**: **16 KB** total transferred (8 KB in conservative profile)
- **Max attempts**: **1–2** attempts per window (including retries)

**Counterparty choice:** random from recently seen nearby nodes (or “first eligible”); avoid expensive ranking.

### 5.3 Deterministic initiator rule (prevents thrash)
To prevent “everyone initiates at once”:
- Compute `session_epoch = floor(now / 5 minutes)` (or reuse the `epoch` in §10.3).
- Each device computes `eligibility = hash(node_id + session_epoch) % 100`.
- Only devices with `eligibility < 20` may initiate in that epoch.

**Tie-break (if both eligible):** initiator is the one with smaller `hash(node_id + remote_node_id + session_epoch)`.

**Jitter:** initiator waits `jitter_ms = hash(node_id + session_epoch) % 1500` before attempting, so initiators don’t collide.

**Backoff:** if an attempt fails, do exponential backoff within the epoch (or skip the rest of the epoch).

### 5.4 Cooldowns
- **Per-node deep sync cooldown**: **60 minutes** (2 hours in conservative profile)
- **Global deep sync budget**: ≤ 8 per event session (≤ 4 in conservative profile)

### 5.6 Repeated encounter escalation (commutes / “I keep seeing this AI”)
Users should learn even while walking down the street. Most of that “learning” should be **observation learning** (safe), but repeated encounters are a meaningful signal.

Event Mode (and Normal Mode) should maintain a local-only **Familiarity Score** per remote:
- Keyed by **remote node_id** within the node-id window, and optionally by a **locally-salted stable fingerprint** (e.g., hash of `vibe_signature` with a device-local salt) to bridge across node-id rotations without enabling tracking outside the user’s device.

**Signals that increase familiarity:**
- repeated sightings of the same remote within a day
- repeated sightings at similar times (commute pattern)
- repeated *successful* deep syncs (strongest signal)

**Escalation threshold (trigger “deeper look” eligibility):**
- Example: `sightings >= 5 in 7 days` OR `deep_sync_successes >= 2 in 14 days`

**What “deeper look” means (still bounded):**
- Schedule a deep sync on the next eligible check-in epoch with:
  - the same deterministic initiator rule
  - the same opt-in bit (`connect_ok=true`)
  - the same byte/time caps
- Allocate extra *local compute* after the sync to decide whether this is:
  - a recurring “door partner” (someone you keep crossing paths with)
  - a commute/community overlap worth surfacing softly

---

## 6) Learning policy (what’s allowed during the event)
### 6.1 Allowed during event
- Maintain an **EventContextState** (temporary):
  - crowd density estimate
  - “room vibe” distribution estimate (aggregate anonymized dims)
  - local user behavior signals (dwell, interaction patterns, self-report)
- Record **EventObservations**:
  - `seen_node_count`, `peak_density_bucket`
  - “doors present” candidates (events/communities implied), as *hypotheses*

### 6.1.1 Ambient learning while walking (always-on, safe learning)
Even outside events, the system should still learn continuously without causing drift or battery issues.

In dense or moving contexts, prefer **ambient learning**:
- Learn about **contexts** (what kinds of places you pass through, density exposure, vibe exposure)
- Learn about **receptivity timing** (when you tend to slow down, linger, engage)
- Learn **recurrence** (which crowds/areas/door-types repeat)

This learning should:
- primarily update **contextual layers** and **usage pattern signals**
- avoid core personality updates unless repeated over many days
- remain mostly **post-hoc consolidated** (batch) to prevent runaway drift

### 6.2 Forbidden during event (default)
- Applying peer-derived deltas directly to personality
- Broadcasting “learning insight” fan-out packets to many peers

**Stronger rule (recommended):** disable learning-insight sends entirely in Event Mode.
If you must keep them for correctness testing, cap extremely hard:
- max 0–1 insight per check-in window
- max 1 insight per remote node per day

If anything is exchanged during check-in, it is treated as:
- **Observation** with TTL + confidence score
- Written only to **event buffer**, not to durable personality

---

## 7) Post-event consolidation (where learning happens)
At event end (or when the user leaves):
1) Summarize EventContextState → `EventSummary`
2) Validate signal quality (duration, consistency, user engagement)
3) Apply bounded updates:
   - Update **contextual layer** (e.g., “social/event context”) first
   - Only promote to **core** after repeated confirmations across events
4) Persist:
   - what was observed
   - what was updated (and how much)
   - why (auditability)

---

## 8) Defaults (recommended starting values)
| Parameter | Default |
|---|---|
| Check-in cadence | 1 per 5 min (armed only) |
| Max deep sync duration | 12s |
| Max deep sync bytes | 16KB |
| Max deep sync per event | 8 |
| Per-node deep sync cooldown | 60 min |
| Event Mode scanWindow | 2–4s |
| Event Mode scanInterval | 12–60s (density-tiered) |
| Brownout scanInterval | 60–120s |
| Event-time AI2AI learning writes | disabled (buffer only) |

**Conservative profile (low battery / OS power saver / extreme density):**
- Check-in cadence: **1 per 30 min** (armed only)
- Max deep sync duration: **8s**
- Max deep sync bytes: **8KB**
- Max deep sync per event: **4**
- Per-node deep sync cooldown: **2h**

---

## 9) Acceptance criteria (what “works” looks like)
- In a dense venue, devices do **not** create a connect/disconnect storm.
- Battery impact stays bounded (goal aligns with background plan targets).
- Personality does **not** drift noticeably after a single crowded event.
- You still get a coarse “what’s going on in the room” signal from aggregated observations + rare check-ins.

---

## 10) Broadcast coherence payload (dimension subset + quantization; cross-platform identical)
This section defines the exact broadcast-safe payload used to compute coherence and room state **without** GATT reads.

### 10.1 Canonical dimension subset for broadcast coherence
Use **exactly these 12 dimensions** (the canonical SPOTS set) in this exact order:

1. `exploration_eagerness`
2. `community_orientation`
3. `authenticity_preference`
4. `social_discovery_style`
5. `temporal_flexibility`
6. `location_adventurousness`
7. `curation_tendency`
8. `trust_network_reliance`
9. `energy_preference`
10. `novelty_seeking`
11. `value_orientation`
12. `crowd_tolerance`

**Why 12 (not 8):** coherence should capture “is this a shared context” and the last four dimensions (energy/crowd/value/novelty) materially improve event-vs-ambient discrimination.

### 10.2 Quantization (deterministic; no floats on-wire)
Each dimension value \(p \in [0,1]\) is encoded as a single byte:

- **Quantize (MUST use this rounding):** `q = floor(clamp(p, 0, 1) * 255 + 0.5)`
- **Dequantize:** `p = q / 255.0`

This is platform-identical, endian-independent, and stable across languages.

### 10.3 Payload framing (recommended; manufacturer data)
Define a compact byte frame so iOS/Android produce identical data:

**Frame v1 (little-endian where applicable):**
- `magic[4]` = ASCII `"SPTS"`
- `ver[1]` = `1`
- `flags[1]` bitfield:
  - bit0: `event_mode_enabled`
  - bit1: `connect_ok` *(opt-in for deep sync window)*
  - bit2: `brownout`
- `epoch[2]` = `floor(utcMillis / (5 * 60 * 1000))` modulo 65536
- `node_tag[4]` = first 4 bytes of `sha256(node_id_utf8)` *(stable within node-id window; not reversible; used for deterministic initiator + familiarity buckets)*
- `dims_q[12]` = 12 bytes quantized dimensions in the order in §10.1

**Total:** 4+1+1+2+4+12 = **24 bytes** (fits within legacy BLE manufacturer data budgets).

### 10.4 Quantum coherence math from the payload (exact)
Given `dims_q`, compute:
1) Dequantize to probabilities \(p_k\) (0..1)
2) Convert to amplitude components \(a_k=\sqrt{p_k}\)
3) Normalize \( |\psi\rangle = a / \|a\| \)

Then compute room state \(|\Psi\rangle\), coherenceScore, and Bures distance exactly as described in §3.3 Stage 2.

### 10.5 Compatibility rules
- Writers must keep the **dimension order** fixed for v1.
- Readers must ignore frames with unknown `ver`.
- Readers must ignore frames with stale `epoch` (optional; prevents replay).

### 10.6 Pseudocode — Encode frame v1 (exact)
This pseudocode is intentionally “boring” so implementations don’t drift.

```text
// Constants
K = 12
FRAME_LEN = 24
MAGIC = bytes("SPTS")  // 0x53 0x50 0x54 0x53
VER = 1
EPOCH_MS = 5 * 60 * 1000  // 300_000

// Canonical dimension order (MUST match §10.1)
DIM_ORDER = [
  "exploration_eagerness",
  "community_orientation",
  "authenticity_preference",
  "social_discovery_style",
  "temporal_flexibility",
  "location_adventurousness",
  "curation_tendency",
  "trust_network_reliance",
  "energy_preference",
  "novelty_seeking",
  "value_orientation",
  "crowd_tolerance",
]

function clamp01(x):
  if x < 0.0: return 0.0
  if x > 1.0: return 1.0
  return x

function quantizeByte(p):  // p is float
  // REQUIRED rounding: floor(x + 0.5)
  scaled = clamp01(p) * 255.0
  q = floor(scaled + 0.5)
  if q < 0: q = 0
  if q > 255: q = 255
  return uint8(q)

function u16le(x):  // x 0..65535
  return [ uint8(x & 0xFF), uint8((x >> 8) & 0xFF) ]

function sha256_4bytes(utf8String):
  h = sha256(utf8(utf8String))      // 32 bytes
  return [h[0], h[1], h[2], h[3]]   // first 4 bytes

// Inputs:
// - utcMillis: uint64 (UTC millis since epoch)
// - node_id: string (rotating/stable-within-window node id)
// - dims: map<string,float> with values in [0,1]
// - event_mode_enabled: bool
// - connect_ok: bool
// - brownout: bool
function encodeFrameV1(utcMillis, node_id, dims, event_mode_enabled, connect_ok, brownout):
  epoch = uint16( floor(utcMillis / EPOCH_MS) % 65536 )

  flags = 0
  if event_mode_enabled: flags |= 0b0000_0001
  if connect_ok:         flags |= 0b0000_0010
  if brownout:           flags |= 0b0000_0100

  node_tag = sha256_4bytes(node_id)  // 4 bytes

  out = new byte[FRAME_LEN]
  out[0..3] = MAGIC
  out[4] = uint8(VER)
  out[5] = uint8(flags)
  out[6..7] = u16le(epoch)
  out[8..11] = node_tag

  // dims_q (12 bytes)
  for i in 0..(K-1):
    name = DIM_ORDER[i]
    p = dims.contains(name) ? dims[name] : 0.5  // default if missing
    out[12 + i] = quantizeByte(p)

  return out  // 24 bytes
```

### 10.7 Pseudocode — Decode + compute quantum coherence (exact)
This computes the Patent #1 primitives in the broadcast-safe “real-only” form:
- compatibility \(C = |\langle\psi_i|\Psi\rangle|^2\)
- Bures distance \(D_B(\Psi_t,\Psi_{t-1})\)

```text
function dequantizeProb(q):  // q is uint8
  return float(q) / 255.0

function l2norm(vec):
  s = 0.0
  for x in vec: s += x*x
  return sqrt(s)

function normalize(vec):
  n = l2norm(vec)
  if n <= 0.0:
    // Degenerate: return uniform unit vector
    // (prevents NaNs; also makes coherence conservative)
    K = len(vec)
    u = 1.0 / sqrt(float(K))
    return [u, u, ..., u]  // length K
  return [ x / n for x in vec ]

function dot(a, b):
  // Real-only inner product
  s = 0.0
  for i in 0..(len(a)-1): s += a[i] * b[i]
  return s

// Convert a decoded dims_q[12] into a normalized quantum state |psi>
function psiFromDimsQ(dims_q[12]):
  amps = new float[12]
  for k in 0..11:
    p = dequantizeProb(dims_q[k])      // probability
    amps[k] = sqrt(p)                 // amplitude component
  return normalize(amps)

// Decode the 24-byte frame. Returns null if invalid.
function decodeFrameV1(frameBytes):
  if frameBytes == null or len(frameBytes) < 24: return null
  if frameBytes[0..3] != bytes("SPTS"): return null
  ver = frameBytes[4]
  if ver != 1: return null

  flags = frameBytes[5]
  epoch = uint16(frameBytes[6] | (frameBytes[7] << 8))  // LE
  node_tag = frameBytes[8..11]                          // 4 bytes
  dims_q = frameBytes[12..23]                           // 12 bytes

  return { "ver":1, "flags":flags, "epoch":epoch, "node_tag":node_tag, "dims_q":dims_q }

// Compute room metrics for one scan window.
// Inputs:
// - frames: list of decoded frames observed in the scan window
// - minNodesForCoherence: int (default 12)
// - prevRoomPsi: float[12] or null
// - prevCoherenceScore: float or null
function computeRoomCoherence(frames, minNodesForCoherence, prevRoomPsi, prevCoherenceScore):
  // Deduplicate by node_tag (prevents double-counting same device in a window)
  byNodeTag = map<bytes4, decodedFrame>()
  for f in frames:
    byNodeTag[f.node_tag] = f

  N = size(byNodeTag)
  if N < minNodesForCoherence:
    return { "eligible": false }

  // Build per-node psi vectors
  psis = []
  for f in byNodeTag.values():
    psis.append( psiFromDimsQ(f.dims_q) )

  // Room state |Psi> for equal weights:
  // |Psi> = normalize( sum_i sqrt(1/N)*|psi_i> ) == normalize( sum_i |psi_i> )
  sumVec = [0.0]*12
  for psi in psis:
    for k in 0..11:
      sumVec[k] += psi[k]
  roomPsi = normalize(sumVec)

  // coherenceScore = mean_i |<psi_i|Psi>|^2   (real-only => dot^2)
  acc = 0.0
  for psi in psis:
    ip = dot(psi, roomPsi)
    c = ip * ip
    // Clamp for numeric safety
    if c < 0.0: c = 0.0
    if c > 1.0: c = 1.0
    acc += c
  coherenceScore = acc / float(N)
  dispersionScore = 1.0 - coherenceScore

  // Bures distance between room states across windows (optional if no prev)
  buresDistance = null
  if prevRoomPsi != null:
    overlap = abs( dot(roomPsi, prevRoomPsi) )       // 0..1
    if overlap > 1.0: overlap = 1.0
    buresDistance = sqrt( 2.0 * (1.0 - overlap) )    // 0..sqrt(2)

  coherenceDelta = null
  if prevCoherenceScore != null:
    coherenceDelta = abs(coherenceScore - prevCoherenceScore)

  return {
    "eligible": true,
    "nodeCount": N,
    "roomPsi": roomPsi,
    "coherenceScore": coherenceScore,
    "dispersionScore": dispersionScore,
    "buresDistance": buresDistance,
    "coherenceDelta": coherenceDelta,
  }
```


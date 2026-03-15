# Reticulum Plan Impact Audit

**Date:** March 11, 2026  
**Status:** Audit  
**Purpose:** Identify what the Reticulum-inspired backlog would actually change in AVRAI, what should stay the same, and why those changes are better or more helpful in the long run.

---

## Executive Summary

The Reticulum-inspired plan is worth pursuing, but only if it is used to **simplify and consolidate** AVRAI's transport architecture.

Today, AVRAI already has many of the right ingredients:

- binary packets
- replay protection
- message ordering
- ACK handling
- route receipts
- Signal/libsignal session security
- admin telemetry and visualization shells

The problem is not the absence of transport building blocks. The problem is that those building blocks are split across:

- a deprecated packet protocol
- a stronger but partially separate Signal path
- a cloud-backed queue path
- lane-based mesh forwarding shims
- admin telemetry that does not yet express delivery truth, custody, or route state

The long-run value of the Reticulum-inspired plan is that it can turn those fragments into a single, honest, offline-first transport model.

The plan is **not** valuable if it means:

- adding more mesh logic to deprecated protocol code
- preserving insecure fallback behavior in production-sensitive paths
- making users or businesses understand mesh internals
- duplicating route concepts that already exist elsewhere in the repo

The right target is:

- Reticulum-style reachability, pathing, and store-carry-forward
- Signal-style session security and deniability
- AVRAI-style privacy, AI learning, and simple product behavior

---

## Highest-Impact Findings

### 1. The current mesh forwarding path still depends on deprecated protocol code

Current state:

- `AI2AIProtocol` is explicitly deprecated and marked as replaced for background AI sync.
- `MeshForwardingContext` still requires `AI2AIProtocol`.
- `MeshPacketForwarder` still encodes outbound mesh packets through `AI2AIProtocol`.

Affected code:

- `runtime/avrai_network/lib/network/ai2ai_protocol.dart`
- `runtime/avrai_runtime_os/lib/services/transport/mesh/mesh_forwarding_context.dart`
- `runtime/avrai_runtime_os/lib/services/transport/mesh/mesh_packet_forwarder.dart`

What the Reticulum plan should change:

- Extract packet encoding, forwarding semantics, and delivery/custody behavior into a **new canonical transport core**.
- Stop extending mesh behavior inside the deprecated protocol path.
- Migrate forwarding lanes to depend on the canonical transport core instead of `AI2AIProtocol`.

Why this is better long term:

- It prevents more investment in a path that is already marked for removal.
- It reduces the chance of transport behavior diverging across old and new code paths.
- It makes testing and telemetry more coherent because there is one transport truth instead of several partial ones.

Long-run benefit:

- simpler transport ownership
- less migration debt
- less chance of shipping old protocol assumptions into future mesh features

---

### 2. Security fallback behavior is still too loose for a stronger mesh future

Current state:

- `AI2AIProtocol.encodeMessage()` falls back to plaintext if encryption fails.
- `AES256GCMEncryptionService` generates random per-recipient keys locally and still documents that proper key exchange is missing.
- `AnonymousCommunicationProtocol` defaults to `AES256GCMEncryptionService` if no stronger service is injected.
- DI still allows `MessageEncryptionService` to fall back to AES when `SignalProtocolService` is not registered.
- `AI2AIProtocolSignalIntegration` is still a placeholder that returns `null` for Signal and expects fallback behavior.

Affected code:

- `runtime/avrai_network/lib/network/ai2ai_protocol.dart`
- `runtime/avrai_network/lib/network/message_encryption_service.dart`
- `runtime/avrai_runtime_os/lib/ai2ai/anonymous_communication.dart`
- `runtime/avrai_network/lib/network/ai2ai_protocol_signal_integration.dart`
- `apps/admin_app/lib/di/registrars/engine_service_registrar.dart`

What the Reticulum plan should change:

- Keep Signal/libsignal as the required cryptographic spine for production chat and sensitive AI2AI messaging.
- Treat weaker encryption fallback as development/test-only unless there is a deliberately scoped, lower-sensitivity payload class.
- Remove plaintext fallback from transport-sensitive paths.
- Make transport telemetry clearly distinguish:
  - no session available
  - prekey/bootstrap failure
  - bearer failure
  - queue/custody delay

Why this is better long term:

- Mesh systems are already hard to reason about. Silent crypto downgrade makes them much harder.
- If a message can move through multiple hops and intermittent custody, the system must have very strong invariants about payload protection.
- A simple product promise like "messages are delivered and read securely" is only credible if the system cannot quietly become plaintext or ad hoc AES under stress.

Long-run benefit:

- stronger security invariants
- simpler incident analysis
- fewer hidden downgrade states
- better fit for businesses that need trust without understanding protocol details

---

### 3. Delivery semantics are too coarse for honest user status and admin truth

Current state:

- `DeliveryAckService` is a boolean ACK mechanism with a short timeout.
- It distinguishes only "ACK received" vs "timeout".
- `AI2AINetworkActivityEvent` has only coarse event types like routing attempt, delivery success, and delivery failure.
- `MessageQueueService` marks queue items as `pending`, `delivered`, or `failed`.
- There is no first-class distinction between:
  - relay accepted custody
  - recipient device received message
  - recipient read message
  - AI learning was actually applied

Affected code:

- `runtime/avrai_network/lib/network/delivery_ack_service.dart`
- `runtime/avrai_runtime_os/lib/monitoring/ai2ai_network_activity_event.dart`
- `runtime/avrai_runtime_os/lib/ai2ai/message_queue_service.dart`
- `runtime/avrai_runtime_os/lib/monitoring/network_analytics.dart`

What the Reticulum plan should change:

- Introduce a formal delivery-state contract:
  - `enqueued`
  - `custody_accepted`
  - `recipient_delivered`
  - `read`
  - `learning_applied`
- Keep those states monotonic and audit-safe.
- Map every retry, expiry, custody handoff, and route change into telemetry.
- Extend queue state from simple status flags into a full transport lifecycle.

Why this is better long term:

- Users only need a few statuses, but those statuses must be true.
- Businesses need to trust delivery without understanding bearer details.
- Admin operators need to know whether a message is delayed, stored, delivered, or irrecoverable.

Long-run benefit:

- honest UX
- better troubleshooting
- better auditability
- cleaner compatibility between online relay and offline mesh behavior

---

### 4. Discovery and forwarding are still neighbor-centric, not destination/path-centric

Current state:

- `DeviceDiscoveryService` performs scan-based nearby discovery and caches current devices.
- `NetworkNodeDiscoveryService` filters and scores routing-capable nodes by proximity, reliability, and capacity.
- `AdaptiveMeshNetworkingService` mainly decides whether forwarding is allowed through hop limits.
- `MeshForwardingTargetSelector` picks from discovered IDs with exclusion rules and a small candidate count.
- `PrekeyBundleMeshForwardingLane` forwards bundles to a few nearby candidates with fixed locality assumptions.

Affected code:

- `runtime/avrai_network/lib/network/device_discovery.dart`
- `runtime/avrai_runtime_os/lib/services/transport/mesh/network_node_discovery_service.dart`
- `runtime/avrai_runtime_os/lib/services/transport/ble/adaptive_mesh_networking_service.dart`
- `runtime/avrai_runtime_os/lib/services/transport/mesh/mesh_forwarding_target_selector.dart`
- `runtime/avrai_runtime_os/lib/services/transport/mesh/prekey_bundle_mesh_forwarding_lane.dart`

What the Reticulum plan should change:

- Add destination announcements with expiration and bearer metadata.
- Maintain a path table keyed by pseudonymous destination ID.
- Track recent successful routes and per-bearer quality.
- Allow path requests and path responses for peers that are not currently visible.
- Use hop count as a guardrail, not as the main control-plane primitive.

Why this is better long term:

- Hop-based forwarding helps reach nearby peers, but it does not tell AVRAI what it knows about a destination.
- Destination/path memory improves success rate on lossy, intermittent networks.
- Reusing working paths can reduce unnecessary scans, retries, and battery cost.
- Prekey and chat delivery become more reliable when the system knows "how to reach X" instead of only "who is nearby right now".

Long-run benefit:

- better offline delivery rates
- lower battery waste
- fewer blind retries
- more predictable performance as the mesh grows

---

### 5. Queueing is fragmented and still too cloud-centric for a true offline-first mesh

Current state:

- `MessageQueueService` persists encrypted messages in Supabase for later delivery.
- It is reliable for server-backed queueing, but not the same thing as local encrypted store-carry-forward.
- Some transport receipt concepts already exist in `TransportRouteReceipt`, but they are mostly attached to route planning and workflow-level delivery decisions rather than mesh custody.

Affected code:

- `runtime/avrai_runtime_os/lib/ai2ai/message_queue_service.dart`
- `runtime/avrai_runtime_os/lib/kernel/os/functional_kernel_models.dart`
- `runtime/avrai_runtime_os/lib/services/messaging/bham_route_planner.dart`

What the Reticulum plan should change:

- Introduce a **local encrypted outbox** that can survive intermittent connectivity without requiring server access.
- Add trusted custody transfer semantics between nodes.
- Treat cloud relay as one bearer or one custody option, not the only durable queue.
- Extend `TransportRouteReceipt` instead of inventing a parallel route-receipt model.

Why this is better long term:

- AVRAI wants offline AI2AI behavior, not just delayed server delivery.
- A local outbox is the missing bridge between simple user expectations and intermittent mesh reality.
- Reusing `TransportRouteReceipt` avoids route metadata fragmentation across app workflows and transport.

Long-run benefit:

- real offline-first behavior
- easier convergence between online and offline transport
- less duplication in route/accountability models
- better support for business-private mesh deployments

---

### 6. Admin telemetry and visualization are ready for better data, but the data model is not there yet

Current state:

- `NetworkAnalytics` and `ConnectionMonitor` provide high-level health and connection streams.
- `AI2AIAdminDashboard` already consumes health, connection, metrics, communications, and active-agent streams.
- `NetworkHealthGauge` still fabricates historical sparkline data instead of using persisted history.
- The admin privacy baseline is correct: agent identity and aggregate telemetry only, no direct user PII.

Affected code:

- `runtime/avrai_runtime_os/lib/monitoring/network_analytics.dart`
- `runtime/avrai_runtime_os/lib/monitoring/connection_monitor.dart`
- `apps/admin_app/lib/ui/pages/ai2ai_admin_dashboard.dart`
- `apps/admin_app/lib/ui/widgets/network_health_gauge.dart`
- `apps/admin_app/README.md`

What the Reticulum plan should change:

- Add route-aware and custody-aware metrics:
  - path selected
  - path reused
  - route expired
  - custody accepted
  - queue depth
  - dead letter count
  - direct vs relayed vs delayed delivery
- Add replayable history for delivery failures, retries, and handoffs.
- Replace synthetic health trends with real persisted transport history.

Why this is better long term:

- Admin visualization becomes meaningful only when it is based on transport truth.
- Operators need simple answers such as:
  - Is the local mesh healthy?
  - Are messages delayed or failing?
  - Are failures caused by bearer loss, route expiry, or crypto bootstrap?
- This can be delivered without exposing user content or user identity.

Long-run benefit:

- better operations
- better support
- better business trust
- better ability to tune mesh behavior without leaking privacy

---

## Subsystem-by-Subsystem Impact

## 1. Transport Core

Current AVRAI behavior:

- packet encoding, fragmentation, replay, ordering, and ACK logic are concentrated around `AI2AIProtocol`
- mesh forwarding lanes still depend on that protocol

Recommended change:

- create a canonical transport core below the forwarding lanes
- migrate useful packet hardening features out of deprecated protocol ownership
- make the transport core responsible for:
  - packet envelope structure
  - path metadata
  - delivery/custody state transitions
  - expiry and retry policy

Why it helps:

- transport logic becomes composable and testable
- deprecation debt stops growing
- future bearers can plug into the same transport truth

---

## 2. Discovery and Control Plane

Current AVRAI behavior:

- discovery is scan-driven
- routing is candidate scoring plus exclusion
- hop limits are a major decision point

Recommended change:

- add destination reachability announcements
- add path cache freshness and invalidation
- add bearer-aware route scoring
- treat nearby scan results as one input into path knowledge, not the entire routing model

Why it helps:

- higher delivery success under intermittent visibility
- lower retry noise
- better battery discipline on dense networks

---

## 3. Store-Carry-Forward and Custody

Current AVRAI behavior:

- durable queueing exists primarily through Supabase-backed storage
- mesh forwarding is more "try nearby peers" than true custody transfer

Recommended change:

- add local encrypted outbox
- add trust-scoped custody transfer
- add expiry windows and dead-letter handling
- distinguish user-chat reliability from best-effort learning payloads

Why it helps:

- real offline-first messaging
- honest delivery states
- better handling of intermittent peers and gateway nodes

---

## 4. Signal and Session Security

Current AVRAI behavior:

- `SignalProtocolService` is the strongest security path in the repo
- session establishment, PQXDH enforcement, rekeying, and channel binding exist there
- but fallback shims remain reachable elsewhere
- `SignalSessionManager.getOrCreateSession()` does not really own session creation

Recommended change:

- keep Signal as the cryptographic anchor
- remove ambiguous ownership between session manager and service
- make prekey/bootstrap errors first-class telemetry
- make insecure fallback unreachable in production-sensitive transport flows

Why it helps:

- strong crypto remains stable while transport evolves
- easier reasoning about failures
- fewer accidental downgrade paths

---

## 5. Prekey Forwarding

Current AVRAI behavior:

- prekey forwarding is handled through a lane that reuses learning-insight style forwarding with a small candidate fanout and locality assumptions

Recommended change:

- make prekey forwarding its own transport-semantic class
- support custody, replay controls, TTL, and better path choice
- separate bootstrap telemetry from normal message telemetry

Why it helps:

- fewer failed session setups on irregular networks
- clearer diagnostics when onboarding or reconnecting peers
- stronger fit for offline-first secure messaging

---

## 6. Telemetry and Analytics

Current AVRAI behavior:

- health scoring exists
- connection monitoring exists
- route receipts exist
- but the models do not yet express the truth needed for a mesh control plane

Recommended change:

- unify transport telemetry around route receipts plus custody/delivery states
- add queue and path metrics to analytics
- preserve privacy by keeping events pseudonymous and aggregate

Why it helps:

- admin becomes operationally useful
- transport debugging gets much cheaper
- future optimization can be data-driven

---

## 7. Admin Visualization

Current AVRAI behavior:

- the admin dashboard already has the right shell
- the globe/topology and health widgets are present
- some visuals still rely on placeholder history

Recommended change:

- add a real topology/time-replay view
- show direct, relayed, delayed, and expired deliveries distinctly
- add queue depth, path churn, and failure cause trends

Why it helps:

- makes mesh behavior understandable to operators without making it visible to normal users
- helps business deployments answer "is this healthy?" quickly

---

## What Should Not Change

These are the parts of the current direction that the Reticulum-inspired plan should preserve.

### 1. Signal stays the security anchor

Reticulum should influence transport behavior, not replace AVRAI's stronger messaging security direction.

### 2. Users should not learn network vocabulary

Users should never need to choose:

- bearer
- route
- relay
- hop policy
- trust mode

The user contract should stay small:

- sending
- delivered
- read
- AI learning updated

### 3. Admin privacy baseline should remain strict

Admin surfaces should keep showing:

- agent identity
- pseudonymous node IDs
- aggregate health and transport metrics

They should not show direct user PII.

### 4. Existing route-receipt concepts should be extended, not duplicated

`TransportRouteReceipt` is already a useful cross-cutting model. It should grow mesh/custody semantics instead of being replaced by a separate transport-receipt system.

---

## Recommended Implementation Order

### 0. Security guardrail first

Before adding richer mesh behavior:

- make plaintext fallback unreachable in production-sensitive transport
- define where AES fallback is allowed, if anywhere
- separate dev/test fallback from production transport rules

Why first:

- stronger routing is not a gain if it widens downgrade behavior

### 1. Delivery-state contract and telemetry schema

Build:

- `enqueued`
- `custody_accepted`
- `recipient_delivered`
- `read`
- `learning_applied`

Why second:

- users and admins need honest truth before more transport complexity is introduced

### 2. Canonical transport core

Move packet and forwarding semantics out of deprecated protocol ownership.

Why third:

- this prevents the backlog from being implemented in the wrong place

### 3. Destination/path control plane

Add:

- destination announcements
- path cache
- route freshness
- per-bearer scoring

Why fourth:

- path intelligence is the main Reticulum-style gain

### 4. Local encrypted outbox and custody transfer

Make offline delivery durable without requiring the cloud.

Why fifth:

- pathing without local durability still leaves offline delivery weak

### 5. Prekey and session-bootstrap hardening

Make mesh-aware secure bootstrap reliable and observable.

Why sixth:

- once the transport plane is stable, bootstrap behavior becomes easier to diagnose and improve

### 6. Admin replay and topology views

Turn transport truth into operator visibility.

Why last:

- the UI should reflect the real transport model, not placeholders

---

## Long-Run Payoff

## For users

- simpler message truth
- better offline delivery
- no need to understand mesh complexity
- stronger confidence that messages and AI learning continue to work

## For businesses

- private/local deployments become easier to operate
- fewer support questions about "why didn't this deliver?"
- clearer health and failure visibility without tactical-system complexity

## For engineering

- one transport model instead of fragmented partial systems
- lower deprecation debt
- easier testing and telemetry
- better alignment between transport, crypto, queueing, and admin

## For security

- fewer downgrade paths
- stronger separation of bearer failure vs crypto failure
- better auditability of message state and custody

---

## Bottom Line

The Reticulum-inspired plan is good for AVRAI if it is treated as an **architecture cleanup and hardening effort**, not as a feature add-on.

The best long-run changes are:

- canonical transport ownership
- strict delivery truth
- destination/path intelligence
- local encrypted store-carry-forward
- Signal-first security invariants
- route/custody-aware admin observability

The worst mistake would be to add those ideas on top of deprecated protocol code and permissive crypto fallback behavior.

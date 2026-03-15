# Reticulum + Signal Simple Mesh Backlog

**Date:** March 11, 2026  
**Status:** Proposed  
**Purpose:** Strengthen AVRAI offline messaging, AI learning, and mesh resilience without exposing transport complexity to users or businesses.

---

## Overview

AVRAI should not become "Reticulum with a harder UI". The right target is:

- Reticulum-grade transport resilience and pathing
- Signal-grade session and message security
- AVRAI-grade privacy, AI learning, and simple product behavior

The user-facing contract stays small:

- messages send automatically
- messages show `sending`, `delivered`, and `read`
- AI learning continues online or offline
- users never need to choose routes, radios, relays, or protocols

Businesses should get the same simplicity:

- install
- pair
- see health
- trust delivery

They should not need mesh expertise to operate AVRAI.

---

## What To Learn From Each System

### Reticulum

Reticulum is the best reference here for transport architecture, not for end-user complexity.

Adopt these ideas:

- destination-based routing instead of socket-style endpoint thinking
- multi-bearer transport abstraction
- autonomous path discovery and path reuse
- store-carry-forward behavior for intermittently connected peers
- authenticated segmentation similar to interface access control
- delivery proofs and explicit path/liveness handling
- operation over slow, lossy, asymmetric links

Do not adopt these product behaviors:

- exposing too much network vocabulary to normal users
- requiring operators to understand pathing concepts for daily use
- building UX around manual network experimentation

### Signal Protocol

Signal remains the better reference for cryptographic messaging sessions.

Adopt these ideas:

- asynchronous session bootstrap with prekey bundles
- forward secrecy and break-in recovery via Double Ratchet
- bounded skipped-message handling and ordered recovery
- identity verification and safety/fingerprint workflows
- PQXDH / post-quantum migration path where feasible
- session lifecycle management for offline and multi-device delivery

Do not use Signal as the transport model:

- Signal assumes a more centralized mailbox/server pattern than AVRAI wants for local-first AI2AI mesh
- Signal solves cryptographic sessions well, but not local bearer selection or ad hoc mesh routing

### AVRAI

AVRAI should be the composition layer:

- privacy-preserving identifiers and admin redaction
- AI2AI learning payload design
- offline-first user and agent behavior
- consumer-simple and business-simple UX
- internal-only admin visibility with pseudonymous telemetry

---

## Product Principle

The system should be complicated. The product should not.

That means:

- complexity belongs in transport orchestration, not in the chat UI
- businesses can opt into stronger local infrastructure without retraining staff
- users only see communication truth, not implementation detail

The communication truth model should be:

1. `Sending`
2. `Delivered to recipient device or trusted store-forward custody`
3. `Read by recipient`
4. `Learning updated`

If the system cannot honestly distinguish those states, it should not display them.

---

## Target AVRAI Stack

### 1. Bearer Layer

Treat every underlying link as a bearer:

- BLE
- local Wi-Fi / LAN
- Wi-Fi Direct / Multipeer where available
- optional internet relay
- future external radios or gateway devices

Users do not pick a bearer manually. The runtime chooses.

### 2. Mesh Control Plane

This should become more Reticulum-like.

Responsibilities:

- announce reachability and capabilities
- maintain path cache and path freshness
- score routes by latency, reliability, energy cost, and trust level
- support local/private mesh segments for businesses or events
- support delayed forwarding when immediate delivery is impossible
- expose custody and reachability events upward

### 3. Security Plane

This should stay Signal-like.

Responsibilities:

- prekey bundle exchange
- session setup
- message ratcheting
- replay protection
- per-message encryption keys
- ordered recovery for skipped or delayed messages
- session rekey and expiration policies

### 4. Message Semantics Plane

AVRAI-specific behaviors:

- user chat
- AI2AI learning insight exchange
- personality exchange
- prekey forwarding
- presence and liveness
- read state
- learning receipts

### 5. UX Plane

Only surface:

- delivery/read state
- offline/online confidence
- simple sync/learning indicators
- conflict or trust warnings only when action is actually needed

---

## Concrete Backlog

### Phase 1: Simple Delivery Truth

Goal: make message state honest and understandable before adding more transport sophistication.

- Define a delivery-state contract that separates `device delivered` from `relay custody`.
- Add a `custody accepted` event type for store-forward hops.
- Keep `read` strictly end-recipient only.
- Add `learning applied` receipt type for AI insight exchanges where that distinction matters.
- Ensure all status transitions are monotonic and audit-safe.

Candidate repo targets:

- `runtime/avrai_network/lib/network/delivery_ack_service.dart`
- `runtime/avrai_runtime_os/lib/monitoring/ai2ai_network_activity_event.dart`
- `runtime/avrai_runtime_os/lib/monitoring/network_analytics.dart`
- `apps/admin_app/lib/ui/pages/ai2ai_admin_dashboard.dart`

### Phase 2: Reticulum-Inspired Reachability and Pathing

Goal: improve offline success rate without changing the user mental model.

- Introduce destination announcements with expiration and capability metadata.
- Maintain a path table keyed by pseudonymous destination ID.
- Track per-bearer quality and recent successful routes.
- Add path request / path response primitives for peers not directly visible.
- Support multiple candidate paths, not a single best path only.
- Prefer low-cost local bearers before cloud relay when available.

Candidate repo targets:

- `runtime/avrai_runtime_os/lib/services/transport/mesh/*`
- `runtime/avrai_network/lib/network/binary_packet_codec.dart`
- `runtime/avrai_network/lib/network/device_discovery_*`

### Phase 3: Store-Carry-Forward Messaging

Goal: keep conversations and AI learning moving when peers are intermittently reachable.

- Create a local encrypted outbox with retry policy and expiry windows.
- Add custody transfer semantics for trusted intermediate nodes.
- Allow AI insight packets to be delayed and replayed safely within TTL.
- Differentiate best-effort learning payloads from user-chat payloads.
- Add dead-letter handling for expired or undeliverable messages.

Candidate repo targets:

- `runtime/avrai_runtime_os/lib/services/transport/mesh/*`
- `runtime/avrai_network/lib/network/message_fragmentation.dart`
- `runtime/avrai_network/lib/network/message_ordering_buffer.dart`

### Phase 4: Signal Session Hardening for Mesh Reality

Goal: keep strong crypto even when connectivity is irregular and routes change often.

- Tighten prekey bundle forwarding semantics and anti-replay protections.
- Add bounded skipped-message storage aligned with Double Ratchet guidance.
- Separate session bootstrap failure from bearer failure in telemetry.
- Support header metadata needed for better out-of-order recovery.
- Prepare a PQXDH migration plan for long-lived high-value conversations.

Candidate repo targets:

- `runtime/avrai_runtime_os/lib/crypto/signal/*`
- `runtime/avrai_runtime_os/lib/services/transport/mesh/prekey_bundle_mesh_forwarding_lane.dart`
- `runtime/avrai_network/lib/network/replay_protection.dart`

### Phase 5: Business-Simple Private Mesh

Goal: make private/local deployments usable by non-experts.

- Create a "private mesh mode" with policy presets instead of manual tuning.
- Support one-tap enrollment of managed relay or gateway nodes.
- Provide QR-based pairing for trusted business infrastructure.
- Default to safe bearer policy and hide advanced options behind admin controls.
- Give operators a plain answer to "is the local mesh healthy?"

Candidate repo targets:

- `apps/admin_app/lib/ui/pages/ai2ai_admin_dashboard.dart`
- `apps/avrai_app/configs/runtime/*private_mesh*`
- `runtime/avrai_runtime_os/lib/services/admin/*`

### Phase 6: Admin Visualization That Fits AVRAI

Goal: take the best interaction ideas from tactical systems without importing their worldview or code.

- Add a 2D/3D topology view that distinguishes direct, relayed, and delayed paths.
- Add time-replay for delivery failures, retries, route changes, and custody handoffs.
- Visualize trust zone / segment boundaries for private mesh deployments.
- Add node health layers for battery, last-seen, bearer mix, and queue depth.
- Keep all displays pseudonymous and coarse enough to match admin privacy policy.

Candidate repo targets:

- `apps/admin_app/lib/ui/widgets/realtime_agent_globe_widget.dart`
- `apps/admin_app/lib/ui/widgets/network_3d_visualization_widget.dart`
- `apps/admin_app/lib/ui/widgets/network_health_gauge.dart`
- `apps/admin_app/lib/ui/pages/ai2ai_admin_dashboard.dart`

---

## UX Rules

These rules matter as much as the protocol work.

- Never ask the user to choose a route.
- Never ask the user to choose BLE versus Wi-Fi versus internet relay.
- Never show "mesh", "path", "bearer", or "relay" in standard chat flows unless troubleshooting is required.
- Never show a message as delivered if only local enqueue has happened.
- Never show a message as read from an intermediate hop.
- Never require fingerprint checks for normal use unless trust changed.
- Never force users to care about AI learning transport. They only need to know that learning completed or is pending.

Preferred language:

- `Sending`
- `Delivered`
- `Read`
- `Offline, will send automatically`
- `AI learning updated`

Avoid:

- `Route established`
- `Peer discovered on bearer`
- `Path request timeout`
- `Relay custody transferred`

Those belong in admin and diagnostic views only.

---

## Security Guardrails

- Keep content encryption and session security anchored in Signal/libsignal concepts.
- Treat Reticulum as transport inspiration, not as a drop-in cryptographic replacement.
- Preserve deniability and forward secrecy properties already present in the Signal-aligned path.
- Keep admin visibility content-free and pseudonymous.
- Avoid incompatible code reuse from repositories with licensing or platform constraints.

License caution:

- Sideband is useful for product ideas but not a safe default source for code transplant.
- ATAK-CIV is archived, Android-specific, and GPL-licensed. Borrow interaction ideas only unless AVRAI intentionally accepts those consequences.

---

## Success Criteria

- Two nearby devices can exchange user chat in airplane mode with no manual network setup.
- Delayed peers receive messages automatically once any valid path becomes available.
- Delivery and read states remain accurate across direct and relayed delivery.
- AI learning exchanges succeed offline with bounded delay and no user intervention.
- Businesses can deploy a private/local mesh mode without needing protocol knowledge.
- Admin operators can see path health, retry behavior, and queue pressure without seeing user PII.

---

## Immediate Next Moves

1. Formalize delivery semantics: `enqueued`, `custody accepted`, `recipient delivered`, `read`, `learning applied`.
2. Add path-table and announcement primitives to the mesh control plane.
3. Build encrypted outbox plus store-carry-forward queueing.
4. Upgrade admin telemetry to distinguish direct delivery, relay custody, and final delivery.
5. Replace synthetic health-history visualization with real path and queue history.

---

## References

- Reticulum manual: https://reticulum.network/manual/whatis.html
- Reticulum networking concepts: https://reticulum.network/manual/networks.html
- Reticulum understanding and interfaces: https://reticulum.network/manual/understanding.html
- Reticulum cryptography: https://reticulum.network/crypto.html
- Sideband repository: https://github.com/markqvist/Sideband
- Haven repository: https://github.com/buildwithparallel/haven-manet-ip-mesh-radio
- Signal X3DH: https://signal.org/docs/specifications/x3dh/x3dh.pdf
- Signal Double Ratchet: https://signal.org/docs/specifications/doubleratchet/
- Signal PQXDH: https://signal.org/docs/specifications/pqxdh/
- Signal Sesame session management: https://signal.org/docs/specifications/sesame/
- ATAK-CIV repository: https://github.com/deptofdefense/AndroidTacticalAssaultKit-CIV

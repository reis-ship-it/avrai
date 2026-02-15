# Consumer App World Planes Design Spec

Status: Canonical world planes design contract.
Last updated: February 14, 2026

## 1. Scope
Defines ambient and dedicated immersive world-plane UX for consumer app surfaces, including transitions and fallback behavior.

## 2. Modes
1. Ambient mode
- Subtle world cues embedded in regular app use.
- Must not compromise legibility or task completion.

2. Dedicated immersive mode
- Explicit route: `/world-planes`.
- Primary renderer: `Worldsheet4DWidget` when data is available.
- Includes contextual interpretation copy for non-technical users.

## 3. Data/State Contracts
- `available`: world plane payload ready.
- `limited`: partial payload; show reduced visualization.
- `unavailable`: no worldsheet yet; show explanatory empty state.
- `stale_offline`: cached visualization with timestamp.

Required behavior:
- Never block home/navigation if worldsheet is unavailable.
- Always show confidence/timestamp when data is stale.
- Transition to immersive mode must support reduced motion.

## 4. Transition + Navigation Rules
- All route transitions must use centralized transition policy.
- iOS/macOS back gesture must be finger-following interactive pop.
- No conflicting per-page custom transitions.
- Return path from immersive mode must preserve prior tab/page context.

## 5. Accessibility + Sensory
- Semantic summaries for chart/surface meaning.
- Reduced-motion crossfade fallback for immersive transitions.
- High-contrast support for overlays and labels.

## 6. Telemetry (Minimum)
- `world_planes_entry`
- `world_planes_exit`
- `world_planes_data_state` (`available|limited|unavailable|stale_offline`)
- `world_planes_fallback_rendered`

## 7. Master Plan Linkage
- Phase 4.5B: personalized quality indicators and confidence
- Phase 6.4.5: timestamped cached personalization UX
- Phase 7.1.2: coherent evolution snapshot requirement
- Phase 10.1, 10.6: feature completion and UX polish expectations

## 8. Architecture Backlog Linkage
- `MPA-P4-E3-S1`: happiness dimension integration interface
- `MPA-P6-E2-S2`: app/channel output policy contracts
- `MPA-P7-E1-S2`: capability tier negotiation
- `MPA-P10-E5-S6`: app-type UI/UX design linkage

## 9. Open Architecture Gap (Needs Backlog Story)
A dedicated architecture story for world-plane ambient+immersive contracts is not explicitly present.
Recommended addition:
- `MPA-P10-E2-S5` (proposed): Define world planes visualization contract (ambient + immersive modes, fallback semantics, telemetry).

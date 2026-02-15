# Consumer App Knot Journey Design Spec

Status: Canonical knot journey design contract.
Last updated: February 14, 2026

## 1. Scope
This spec defines the end-to-end knot experience from onboarding profile capture through knot birth, knot discovery, and post-onboarding revisit surfaces.

## 2. Journey Stages
1. `Profile/Preferences complete` -> readiness check
2. `Knot Birth` immersive step
3. `Knot Discovery` interpretation step
4. `AI Loading` transition to home
5. `Home/Profile` knot recall surfaces

## 3. State Contracts
- `preflight`: profile or runtime prerequisites not satisfied.
- `loading`: knot runtime generation in progress.
- `ready`: immersive knot birth can render.
- `completed`: user completed knot birth flow.
- `skipped`: user intentionally skipped.
- `fallback`: timeout/runtime failure; onboarding continues.

Required behavior:
- Knot experience must never block onboarding completion.
- Skip/fallback reason must be explicit and telemetry-tagged.
- Reduced-motion must disable heavy knot animation.

## 4. UX Rules
- Use portal primitives (`PortalSurface`, `GlassSlate`) for all knot steps.
- Use semantic typography and spacing tokens only.
- Keep explanatory copy plain-language first, topology details second.
- On iOS/macOS, preserve expected back-swipe behavior.
- On Android, preserve Material navigation behavior while keeping shared brand layer.

## 5. Accessibility + Sensory
- Semantic labels required for knot visuals and controls.
- Alt-text summary required for knot snapshot (Phase 10.4.5 alignment).
- `MediaQuery.disableAnimations` respected for knot motion.
- Audio sonification path available when enabled (Phase 10.4.7 alignment).

## 6. Telemetry (Minimum)
- `knot_birth_started`
- `knot_birth_completed`
- `knot_birth_skipped` (include reason)
- `knot_birth_fallback` (include reason)
- `knot_discovery_viewed`

## 7. Master Plan Linkage
- Phase 1.5A, 1.5B: onboarding and skip-onboarding paths
- Phase 6.4.5: honest offline state communication
- Phase 7.1.2: evolution cascade consistency for knot-derived displays
- Phase 10.4.5, 10.4.7, 10.4.8: accessibility and reduced-motion requirements

## 8. Architecture Backlog Linkage
- `MPA-P6-E2-S2`: app/channel output policy contracts
- `MPA-P7-E1-S2`: capability-tier negotiation by app channel
- `MPA-P10-E3`: compliance + accessibility parity
- `MPA-P10-E5-S6`: app-type UI/UX design linkage contract

## 9. Open Architecture Gap (Needs Backlog Story)
A dedicated architecture story for knot-specific UI journey contracts is not explicitly present in the backlog.
Recommended addition:
- `MPA-P10-E2-S4` (proposed): Define knot journey state machine contract and telemetry envelope for consumer onboarding.

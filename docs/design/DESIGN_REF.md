# AVRAI Design Reference (DESIGN_REF)

Status: Canonical design reference for UI/UX implementation work.
Last updated: February 15, 2026

## 1. Purpose
This document is the required entry point for UI/UX work across AVRAI applications.
It defines design architecture, source-of-truth files, and implementation contracts that must be followed for Master Plan-compliant delivery.

## 2. Canonical Sources
- Master plan: `docs/MASTER_PLAN.md`
- Canonical progress tracker: `docs/agents/status/status_tracker.md`
- Multi-app architecture blueprint: `docs/plans/architecture/MASTER_PLAN_MULTI_APP_ARCHITECTURE_BLUEPRINT.md`
- Design system architecture map: `docs/design/DESIGN_SYSTEM_ARCHITECTURE.md`
- Coverage matrix: `docs/design/DESIGN_COVERAGE_MATRIX.md`
- Master Plan linkage map: `docs/design/MASTER_PLAN_DESIGN_LINKAGE.md`
- Reality coherence test matrix: `docs/plans/architecture/REALITY_COHERENCE_TEST_MATRIX.md`
- Sensory contract: `docs/design/SENSORY_FEEDBACK_GUIDELINES.md`
- Accessibility contract: `docs/design/ACCESSIBILITY_DESIGN_CONTRACT.md`
- Brand source: `assets/brand_book/AVRAI_BRAND_BOOK_COPY.md`

## 3. Design Architecture (Code)
- Unified page layer: `lib/presentation/pages`
- Route composition: `lib/presentation/routes`
- Shared visual primitives: `lib/presentation/widgets/portal`
- Adaptive platform layer: `lib/presentation/widgets/adaptive`
- Theme + tokens:
  - `lib/core/theme/app_theme.dart`
  - `lib/core/theme/tokens/theme_tokens.dart`
  - `lib/core/theme/colors.dart`
- Central design APIs:
  - `lib/core/design/design_system.dart`
  - `lib/core/design/component_tokens.dart`
  - `lib/core/design/feedback_presenter.dart`
  - `lib/core/navigation/app_page_transitions.dart`

## 4. Multi-App Design Organization
Overarching design folder:
- `docs/design`

App-specific design folders:
- Consumer app: `docs/design/apps/consumer_app`
- Business app: `docs/design/apps/business_app`
- Admin desktop app: `docs/design/apps/admin_desktop_app`
- Research portal: `docs/design/apps/research_portal`
- Partner SDK examples: `docs/design/apps/partner_sdk_examples`

Required phase/story linkage reference:
- `docs/design/MASTER_PLAN_DESIGN_LINKAGE.md`

All app folders must inherit shared system rules from this document and may only override where actor-specific UX needs differ.

## 5. Required UI/UX Contracts
- Portal-first visual language across apps unless explicitly documented as an exception.
- Tokenized spacing/typography/radius/motion; no ad-hoc visual values in presentation code.
- Platform-adaptive interaction expectations:
  - iOS/macOS: Cupertino-native behavior where expected.
  - Android: Material-native behavior where expected.
- Navigation/transitions use centralized policy and reduced-motion compatibility.
- Reliability requirement: onboarding and home access must never be blocked by immersive/advanced visuals.
- **Access governance contract (Phase 2.6):**
  - User-facing surfaces may only render P0/P1 planes.
  - P3 Disclosure Layer is never user-facing.
  - Admin/researcher/partner experiences must enforce role+tier+purpose gating and display policy status for restricted views.
  - Any screen that exposes non-user planes must include an auditability affordance (purpose code, access scope, and timestamp context).

## 6. Definition of Design Readiness
Design is ready for implementation only when all are true:
1. Master Plan section is identified and linked.
2. App target is identified (`consumer_app`, `business_app`, etc.).
3. Page-level spec exists with states: loading, empty, error, offline, success.
4. Token usage and adaptive behavior are explicitly specified.
5. Telemetry events for key UX transitions are listed where applicable.
6. Required degraded/recovery state behavior maps to `RCM-UX-019` and `RCM-UX-020` in `docs/plans/architecture/REALITY_COHERENCE_TEST_MATRIX.md`.
7. Coherence-sensitive UI (offline/online, transport mode, weather confidence, access denial) has explicit user/admin state handling.
8. Guardrails pass:
   - `dart run tool/design_guardrails.dart`
   - `flutter analyze lib/presentation`

## 7. Implementation Checklist (Required in PR/Task Notes)
- `DESIGN_REF checked`
- `Master Plan section linked`
- `status_tracker impact recorded`
- `Portal + token contracts satisfied`
- `Adaptive behavior verified (iOS/macOS/Android)`
- `Access plane classification recorded (P0-P6)`
- `Disclosure-layer non-user-facing rule verified`
- `Reality coherence UX scenarios mapped (RCM-UX-019/020)`
- `Guardrails + analyze passed`

## 8. Change Management
Any design-system-affecting change must update:
- `docs/design/DESIGN_REF.md` (if architecture/contracts changed)
- relevant app folder docs in `docs/design/apps/*`
- `docs/agents/status/status_tracker.md` (progress impact)

This keeps design architecture, implementation, and execution status synchronized.

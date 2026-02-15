# Presentation Pages Structure

This folder is the unified page layer for AVRAI UI surfaces across app contexts.

## Structure Contract
- `lib/presentation/pages/<domain>`: domain-organized pages (`onboarding`, `home`, `business`, `admin`, etc.)
- One page class per primary file where practical.
- Shared behavior/styling belongs in `lib/presentation/widgets/*`, not duplicated in pages.

## Cohesive Page Requirements
- Use shared design system contracts (`docs/design/DESIGN_REF.md`).
- Use adaptive and portal primitives when building major surfaces.
- Keep transition/navigation behavior on centralized navigation APIs.
- Ensure core states are explicit on page-level flows: loading, empty, error, offline.

## Master Plan Compliance
Before adding/modifying pages:
1. Link affected Master Plan sections (`docs/MASTER_PLAN.md`).
2. Record dependency/progress impact in `docs/agents/status/status_tracker.md`.
3. Validate design guardrails and analyzer:
   - `dart run tool/design_guardrails.dart`
   - `flutter analyze lib/presentation`

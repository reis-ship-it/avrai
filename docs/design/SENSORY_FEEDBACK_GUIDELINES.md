# Sensory Feedback Guidelines

Last updated: February 13, 2026
Required companion: `docs/design/DESIGN_REF.md`

## 1. Purpose
Define a consistent AVRAI policy for sensory feedback:
- visual motion
- haptic feedback
- sound/sonic cues

This applies across iOS, macOS, and Android.

## 2. Principles
1. Sensory feedback should clarify state, never distract.
2. Sensory feedback must be optional/reducible for accessibility.
3. Haptics and audio should reinforce, not duplicate, visual overload.
4. Critical actions get stronger feedback than routine actions.

## 3. Motion Contract
- Source of truth: `lib/core/navigation/app_page_transitions.dart`
- Respect reduced-motion via platform accessibility settings.
- Default transitions remain tokenized and centrally editable.

## 4. Haptics Contract
- Source of truth service: `lib/core/services/device/haptics_service.dart`
- UX event mapping (baseline):
  - success confirmation: light impact
  - destructive confirmation: medium/heavy impact
  - selection toggle: selection click
  - warning/error: warning notification pattern
- All new haptic triggers must go through the shared service.

## 5. Sound Contract
- Existing implementation surfaces include knot/audio services and widgets.
- Sound must be:
  - off by default for non-critical ambient cues (unless product decision says otherwise)
  - user-controllable in settings
  - paired with non-audio fallback (visual/haptic)
- No UX state should depend solely on sound to be understood.

## 6. Accessibility Rules
- Reduced motion disables non-essential animation choreography.
- Haptics respect global enable/disable setting.
- Audio cues must have equivalent visual semantics.
- Do not encode meaning via sound-only or color-only cues.

## 7. Validation for Sensory Changes
For any PR touching motion/haptics/audio:
1. Link `docs/design/DESIGN_REF.md`
2. State sensory event mapping in PR notes
3. Verify reduced-motion behavior
4. Verify fallback behavior when haptics/audio unavailable

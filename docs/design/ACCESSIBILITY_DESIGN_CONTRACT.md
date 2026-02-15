# Accessibility Design Contract

Last updated: February 13, 2026
Required companion: `docs/design/DESIGN_REF.md`

## 1. Scope
Defines mandatory accessibility behavior for all AVRAI UI surfaces.

## 2. Mandatory UX Accessibility States
Every major flow/page should account for:
- loading
- empty
- error
- offline
- success

## 3. Semantics and Screen Reader
- Interactive controls require meaningful semantic labels.
- Critical state changes should be discoverable via semantics and text.

## 4. Typography and Scaling
- Support dynamic text scaling without clipping primary actions/content.
- Avoid fixed-height containers for text-heavy critical surfaces.

## 5. Motion
- Respect reduced-motion settings.
- Avoid essential information only conveyed by animation timing.

## 6. Contrast and Color
- Do not rely on color-only meaning.
- Ensure adequate contrast for text and controls.

## 7. Input and Focus
- Support keyboard/focusable interactions where platform-applicable (notably macOS).
- Ensure predictable focus order in complex forms/dialogs.

## 8. Verification
For accessibility-impacting PRs:
1. mention accessibility checks performed
2. validate reduced motion behavior
3. validate semantic labels on new interactive controls
4. validate dynamic text scaling on modified screens

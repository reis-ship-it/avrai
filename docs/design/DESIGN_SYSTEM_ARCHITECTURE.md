# AVRAI Design System Architecture

This is the single map for visual and UX consistency across iOS, macOS, and Android.
For required UI/UX execution workflow and master-plan alignment, also see `docs/design/DESIGN_REF.md`.

## 1) Global Theme and Tokens
- Theme entrypoint: `lib/core/theme/app_theme.dart`
- Token definitions: `lib/core/theme/tokens/theme_tokens.dart`
- Colors: `lib/core/theme/colors.dart`
- Design facade: `lib/core/design/design_system.dart`
- Semantic component tokens: `lib/core/design/component_tokens.dart`
- Motion presets: `lib/core/design/motion_presets.dart`
- Feedback presenter: `lib/core/design/feedback_presenter.dart`
- Component wrappers: `lib/core/design/widgets/avrai_components.dart`

Edit these files to change typography, spacing, radius, motion tokens, and global component defaults.
`AppTypography` in `theme_tokens.dart` centralizes semantic type scale values.

## 2) Navigation Motion and Swipe Behavior
- Central transition policy: `lib/core/navigation/app_page_transitions.dart`
- Central navigation helper: `lib/core/navigation/app_navigator.dart`
- Legacy transition wrapper (delegates to central policy): `lib/presentation/widgets/common/page_transitions.dart`
- Portal content transition wrapper (delegates to central policy): `lib/presentation/widgets/portal/glass_content_transition.dart`

Rules:
- Use `AppPageTransitions` for route transitions.
- Use `AppNavigator` for new push/replace calls.
- Avoid creating new ad-hoc `PageRouteBuilder` transitions.
- Reduced-motion behavior is enforced in transition builders via `MediaQuery.disableAnimations`.

## 3) Portal Design Primitives
- Portal layout shell: `lib/presentation/widgets/portal/avrai_portal_layout.dart`
- Primary portal surface primitive: `lib/presentation/widgets/portal/portal_surface.dart`
- Glass slate: `lib/presentation/widgets/portal/glass_slate.dart`
- Recessed map: `lib/presentation/widgets/portal/recessed_map_container.dart`

Rules:
- Build page sections with `PortalSurface` instead of ad-hoc container decoration.
- Keep blur/radius/shadow values token-driven through `PortalTokens`.

## 4) Platform-Adaptive UI Contracts
- Adaptive scaffold/layout: `lib/presentation/widgets/adaptive/adaptive_layout.dart`
- Adaptive controls: `lib/presentation/widgets/adaptive/adaptive_widgets.dart`

Rules:
- iOS/macOS: preserve native interaction expectations.
- Android: preserve Material interaction expectations.
- Brand layer should remain visually consistent across platforms.

## 5) Current Convergence Status
- `lib/presentation` typography uses tokenized theme styles (no raw `TextStyle(` / `fontSize:` literals).
- Presentation-layer transitions are centralized.
- Direct `MaterialPageRoute(...)` usage in `lib/presentation` has been migrated to centralized transition policy.
- Central app-side navigation helper exists in `AppNavigator`.
- Design playground is available at route `/design/playground`.
- `feedback_presenter.dart` exposes `BuildContext` feedback helpers: `showInfo`, `showSuccess`, `showWarning`, `showError`.

## 6) Component Catalog
- Route: `/design/playground`
- Page: `lib/presentation/pages/design/design_playground_page.dart`

Use this page to quickly inspect token values, component states, feedback colors, and motion behavior while developing.
`AvraiText`/`AvraiTextRole` are included in the playground for semantic typography checks.

## 7) Router Modularization
- Module: `lib/presentation/routes/modules/design_debug_routes.dart`
- Root router composes this module from `lib/presentation/routes/app_router.dart`

## 8) Guardrails (CI / Local)
- Script: `tool/design_guardrails.dart`
- Run: `dart run tool/design_guardrails.dart`
- CI integration: `.github/workflows/quick-tests.yml`

Guardrails currently enforce:
- No raw `TextStyle(` / `fontSize:` in `lib/presentation` without explicit allow marker.
- No direct `MaterialPageRoute(...)` in `lib/presentation`.
- No ad-hoc `PageRouteBuilder(...)` in `lib/presentation` outside approved centralized wrappers.
## 9) Recommended Next Refactors
1. Break `lib/presentation/routes/app_router.dart` into route modules by feature.
2. Add golden tests for key routes on iOS/Android/macOS to lock parity.
3. Expand design playground sections for page shells and empty/loading/error states.

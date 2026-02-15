# Portal Visual QA Audit (Onboarding -> Home -> World Planes -> Settings)

Date: 2026-02-12
Scope: `lib/presentation/pages/onboarding`, `lib/presentation/pages/home`, `lib/presentation/pages/world_planes`, `lib/presentation/pages/settings`

## Overall Status
- Portal shell parity: PASS
- Component shell parity (`Card`/`BoxDecoration` page-level shell usage): PASS
- Design-token spacing/typography discipline: PARTIAL
- Platform-adaptive interaction parity (iOS/macOS/Android): PARTIAL

## Hard Metrics (Current)
- `Card` usage in pages: `0`
- Page-level `BoxDecoration` usage in pages: `0`
- `PortalSurface` usage in pages: `411`
- Static drift signals in journey scope (`EdgeInsets`, fixed `SizedBox`, inline `TextStyle/fontSize`):
  - Onboarding: `410`
  - Home: `66`
  - World Planes: `10`
  - Settings: `531`

## Journey Checklist
1. Onboarding (`welcome -> permissions/legal -> profile/preferences -> knot birth/discovery -> AI loading`)
- Portal surface consistency: PASS
- Tokenized spacing/typography consistency: PARTIAL
- Key drift: high inline style density in `lib/presentation/pages/onboarding/onboarding_step.dart:893`, `lib/presentation/pages/onboarding/onboarding_step.dart:921`, `lib/presentation/pages/onboarding/onboarding_step.dart:958`

2. Home (tabs + entry points)
- Portal surface consistency: PASS
- Platform-native nav parity: PARTIAL
- Key drift: hardcoded Material nav bar is always used in `lib/presentation/pages/home/home_page.dart:145`
- Key drift: iOS/macOS likely should branch to Cupertino tab semantics for strict parity in `lib/presentation/pages/home/home_page.dart:145`

3. World Planes
- Portal framing and fallback behavior: PASS
- Token use consistency: PASS (minor)
- Key note: low drift count (`10`) and no structural parity blockers

4. Settings
- Portal surface consistency: PASS
- Tokenized spacing/typography consistency: PARTIAL
- Key drift concentration:
  - `lib/presentation/pages/settings/cross_app_settings_page.dart:74`
  - `lib/presentation/pages/settings/about_page.dart:17`
  - `lib/presentation/pages/settings/privacy_settings_page.dart:291`

## Priority Findings
1. High: Home tab navigation is Material-only, reducing strict iOS/macOS parity
- Evidence: `lib/presentation/pages/home/home_page.dart:145`
- Impact: iOS/macOS interaction language diverges from Cupertino expectations.

2. High: Onboarding step renderer contains dense hardcoded sizes/styles
- Evidence: `lib/presentation/pages/onboarding/onboarding_step.dart:893`, `lib/presentation/pages/onboarding/onboarding_step.dart:921`, `lib/presentation/pages/onboarding/onboarding_step.dart:958`
- Impact: inconsistent rhythm/type scale across devices and dynamic type settings.

3. Medium: Settings information pages still use many fixed paddings and direct `TextStyle`
- Evidence: `lib/presentation/pages/settings/about_page.dart:17`, `lib/presentation/pages/settings/about_page.dart:66`, `lib/presentation/pages/settings/about_page.dart:77`
- Impact: maintainability and parity risk when adjusting portal tokens globally.

4. Medium: Cross-app settings page has repeated fixed spacing blocks
- Evidence: `lib/presentation/pages/settings/cross_app_settings_page.dart:74`, `lib/presentation/pages/settings/cross_app_settings_page.dart:123`, `lib/presentation/pages/settings/cross_app_settings_page.dart:134`
- Impact: harder to keep layout cadence identical across form factors.

5. Medium: Privacy settings retains inline typography tuning
- Evidence: `lib/presentation/pages/settings/privacy_settings_page.dart:291`, `lib/presentation/pages/settings/privacy_settings_page.dart:307`, `lib/presentation/pages/settings/privacy_settings_page.dart:547`
- Impact: fragmented text hierarchy and less controllable global refinement.

## Recommended Next Pass (Implementation Order)
1. Home nav abstraction
- Add adaptive bottom navigation wrapper (Cupertino on iOS/macOS, Material on Android) and migrate `home_page` tab bar to it.

2. Onboarding step tokenization pass
- Replace fixed `TextStyle(fontSize: ...)` and `EdgeInsets` in `onboarding_step.dart` with `Theme.of(context).textTheme` + `context.spacing` / `context.radius` tokens.

3. Settings content tokenization pass
- Start with `about_page.dart`, `cross_app_settings_page.dart`, `privacy_settings_page.dart`.
- Use shared section/header/content helper widgets to remove repeated fixed layout literals.

4. Visual QA rerun
- Re-run this same audit after each batch and track counts to converge toward low/controlled literal usage.

## Verification Used
- `scripts/check_portal_uniformity.sh`
- `flutter analyze`
- Static code audit via `rg` for token drift signals

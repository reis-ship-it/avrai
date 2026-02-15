# Portal Uniformity Audit
Date: February 12, 2026

## Scope
- UI layer: `lib/presentation/pages`
- Goal: enforce portal surface consistency and centralize visual tuning.

## Current Status
- `Card(` usage in pages: **0**
- `PortalSurface(` usage in pages: **242**
- `BoxDecoration(` usage in pages: **299**

## Interpretation
- Structural migration is complete for page-level card shells (`Card` -> `PortalSurface`).
- Remaining `BoxDecoration` usages are mostly badges, chips, map overlays, progress/status pills, and non-card visual elements.
- Visual consistency risk now is primarily from custom decorated containers that may look card-like.

## Top Files To Visually Review Next
1. `lib/presentation/pages/events/event_success_dashboard.dart`
2. `lib/presentation/pages/clubs/club_page.dart`
3. `lib/presentation/pages/onboarding/combined_permissions_page.dart`
4. `lib/presentation/pages/events/quick_event_builder_page.dart`
5. `lib/presentation/pages/disputes/dispute_status_page.dart`
6. `lib/presentation/pages/admin/review_fraud_review_page.dart`
7. `lib/presentation/pages/admin/fraud_review_page.dart`
8. `lib/presentation/pages/verification/identity_verification_page.dart`
9. `lib/presentation/pages/tax/tax_documents_page.dart`
10. `lib/presentation/pages/settings/cross_app_settings_page.dart`

## Guardrail
- Added `scripts/check_portal_uniformity.sh`
- Checks:
  - Fails if any `Card(` exists in `lib/presentation/pages`
  - Reports `PortalSurface` and `BoxDecoration` counts
  - Prints top files with `BoxDecoration` for manual review

## Recommended CI Follow-Up
- Add `scripts/check_portal_uniformity.sh` as a required CI step for UI changes.
- Keep `BoxDecoration` review as non-blocking until false positives are categorized.

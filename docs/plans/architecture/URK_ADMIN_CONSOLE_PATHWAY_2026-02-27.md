# URK Admin Console Pathway

**Date:** February 27, 2026  
**Status:** Active  
**Purpose:** Define the canonical in-app route and placement for URK kernel governance UI.

## Canonical UI Path

1. `Profile`
2. `Admin`
3. `URK Kernel Console`

Direct route: `/admin/urk-kernels`

## Route Governance

Route is guarded in `lib/presentation/routes/app_router.dart` with:

1. authenticated session required
2. `UserRole.admin` required
3. fallback redirects:
   - unauthenticated -> `/login`
   - non-admin -> `/home`

## UI Integration Points

1. Admin entry from Profile page:
   - `lib/presentation/pages/profile/profile_page.dart`
   - Admin section item: `URK Kernel Console`
2. Admin entry from AI2AI dashboard:
   - `lib/presentation/pages/admin/ai2ai_admin_dashboard.dart`
   - top card action routes to `/admin/urk-kernels`
3. Console page:
   - `lib/presentation/pages/admin/urk_kernel_console_page.dart`
   - data source: `UrkKernelControlPlaneService` (live state + health + lineage)
4. Registry reader service:
   - `lib/core/services/admin/urk_kernel_registry_service.dart`
5. Control-plane service:
   - `lib/core/services/admin/urk_kernel_control_plane_service.dart`

## Placement Rule

All kernel-governance UI must be placed under `/admin/*` routes and must not be added under user settings routes outside admin gating.

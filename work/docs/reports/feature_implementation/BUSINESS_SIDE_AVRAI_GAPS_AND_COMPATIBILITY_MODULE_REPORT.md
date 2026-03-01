# Business Side AVRAI Gaps & Compatibility Module Report

**Date:** February 3, 2026  
**Status:** ✅ Complete  
**Reference Plan:** `.cursor/plans/business_side_avrai_gaps_8eb26f51.plan.md`

---

## Executive Summary

This report documents two bodies of work completed in a single session:

1. **Business Side AVRAI Gaps Implementation** – Filling the remaining gaps from the original Business Side AVRAI plan: wiring user-place attraction into group matching, claim-flow place search, device knot seeding for claimed places, place-level attraction override, attraction profile in business onboarding, and UX enhancements.

2. **Compatibility Module Extraction** – Extracting `Attraction12DResolver` and `VibeCompatibilityService` from the payment module into a dedicated compatibility module, so compatibility logic has no payment-specific dependencies.

---

## Part 1: Business Side AVRAI Gaps Implementation

### Phase 1: Wire User-Place Attraction Compatibility (High)

**Goal:** Callers that score user↔place or group↔place compatibility use attraction 12D.

**Changes:**
- **GroupMatchingService** – Injected optional `PlaceClaimService`, `BusinessAccountService`, and `Attraction12DResolver`.
- **`_resolveSpotAttraction12D`** – New helper that resolves attraction 12D for each spot:
  - Claimed places: uses per-place `attractionOverride` when set, else business attraction
  - Unclaimed places: uses `Attraction12DResolver.resolveForPlace(spot, businessAttraction12D: null)`
  - Fallback: `reflectDimensionsForAttraction(spotVibe.vibeDimensions)` when services unavailable
- **`_createSpotQuantumState`** – Now accepts `spotAttraction12D` and uses it for `personalityState` and `quantumVibeAnalysis` instead of raw inferred dimensions.
- **DI** – `injection_container_quantum.dart` updated to pass the new optional dependencies.

**Files:** `lib/core/services/group_matching_service.dart`, `lib/injection_container_quantum.dart`

---

### Phase 2: Claim Flow Place Search (High)

**Goal:** Claim flow supports search by address/name → select place → resolve to `google_place_id`.

**Changes:**
- **ClaimPlacePage** – Added search field that calls `HybridSearchUseCase.searchSpots` with debounced input (400ms).
- Results shown as selectable list; only spots with `googlePlaceId` are displayed.
- On selection, `google_place_id` is populated from the spot.
- Manual Place ID entry retained as fallback.

**Files:** `lib/presentation/pages/business/claim_place_page.dart`

---

### Phase 3: Device-First Knot/String for Claimed Places (Medium)

**Goal:** On successful place claim, seed device-first knot for `(businessId, googlePlaceId)`.

**Changes:**
- **KnotStorageService** – Added `saveBusinessPlaceKnot`, `loadBusinessPlaceKnot` with keys `business_place_knot:{businessId}:{googlePlaceId}`.
- **BusinessPlaceKnotService** (new) – Seeds knot after claim: fetches business, resolves attraction 12D, generates knot via EntityKnotService, stores via KnotStorageService.
- **ClaimPlacePage** – After successful claim, calls `BusinessPlaceKnotService.seedKnotForClaimedPlace` when registered.
- **DI** – `BusinessPlaceKnotService` registered in main container after Payment (requires Attraction12DResolver).

**Files:** `packages/avrai_knot/lib/services/knot/knot_storage_service.dart`, `lib/core/services/business_place_knot_service.dart`, `lib/presentation/pages/business/claim_place_page.dart`, `lib/injection_container.dart`

---

### Phase 4: Place-Level Attraction Override (Medium)

**Goal:** For claimed places, allow per-place override of attraction 12D instead of always using business default.

**Changes:**
- **Migration** – `088_claimed_places_attraction_override.sql` adds `attraction_override JSONB` column.
- **ClaimedPlace** – Added `attractionOverride` field and JSON (de)serialization.
- **PlaceClaimService** – Added `updateAttractionOverride(businessId, googlePlaceId, attractionOverride?)`.
- **GroupMatchingService** – Uses `getClaimByPlaceId`; when claim has `attractionOverride`, passes it to resolution instead of business attraction.
- **Dashboard** – Per-place "Edit attraction" (tune icon) opens bottom sheet with 12 sliders; "Use business default" clears override; "Save" persists.

**Files:** `supabase/migrations/088_claimed_places_attraction_override.sql`, `lib/core/models/claimed_place.dart`, `lib/core/services/place_claim_service.dart`, `lib/core/services/group_matching_service.dart`, `lib/presentation/pages/business/business_dashboard_page.dart`

---

### Phase 5: Attraction Profile in Business Onboarding (Medium)

**Goal:** "Who do you want to attract?" step in business onboarding with 12 sliders.

**Changes:**
- **BusinessOnboardingData** – Added `attractionDimensions`.
- **BusinessOnboardingController** – Passes `attractionDimensions` to `updateBusinessAccount`.
- **BusinessOnboardingPage** – New "Attraction Profile" step between Customer Preferences and Team Setup; sliders for all 12 dimensions; values passed into completion data.

**Files:** `lib/core/controllers/business_onboarding_controller.dart`, `lib/presentation/pages/business/business_onboarding_page.dart`

---

### Phase 7: UX Enhancements (Lower)

**Changes:**
- **Strong match labels** – Dashboard attraction profile card shows "Strong match for: [top 5 dimension labels]" when custom profile is set.
- **Post-claim feedback** – Success message updated to: "Place claimed successfully. This place's compatibility profile is now active."

**Files:** `lib/presentation/pages/business/business_dashboard_page.dart`, `lib/presentation/pages/business/claim_place_page.dart`

---

### Phase 6: Unclaimed Place Snapshot Cap (Lower)

**Status:** Deferred – No current writer for unclaimed place snapshots; scope requires defining where snapshots are written (e.g., during discovery/sync). Implement when that flow exists.

---

## Part 2: Compatibility Module Extraction

**Goal:** Separate non-payment compatibility services from the payment module so compatibility logic has no payment-specific dependencies.

### Created: `lib/injection_container_compatibility.dart`

**Services registered:**
- **Attraction12DResolver** – Entity → attraction 12D for user–business/event/place (with `patronPrefsTo12D`).
- **VibeCompatibilityService** (QuantumKnotVibeCompatibilityService) – Quantum + knot compatibility scoring.

**Dependencies:** PersonalityLearning, PersonalityKnotService, EntityKnotService. Optional: MultiScaleQuantumStateService (when available from Quantum module).

**Consumers:** PartnershipService, SponsorshipService, EventRecommendationService, GroupMatchingService, BusinessPlaceKnotService.

### Updated: `lib/injection_container_payment.dart`

- Removed registration of Attraction12DResolver and VibeCompatibilityService.
- Removed imports for `attraction_12d_resolver`, `patron_prefs_to_12d_mapper`, and knot/quantum services.
- PartnershipService and SponsorshipService continue to use `sl<VibeCompatibilityService>()`; the instance is now provided by the Compatibility module.

### Updated: `lib/injection_container.dart`

- Added import for `injection_container_compatibility.dart`.
- Calls `registerCompatibilityServices(sl)` after Knot and Community, before Payment.
- Registration order: Knot → Community → **Compatibility** → Payment → Quantum → AI.

---

## Verification

- `flutter analyze lib/injection_container_compatibility.dart lib/injection_container_payment.dart lib/injection_container.dart` – No issues.
- User-side flows (group matching, event recommendations) remain functional; GroupMatchingService changes are backward-compatible with fallbacks when services are unavailable.

---

## Files Changed Summary

| File | Change |
|------|--------|
| `lib/core/services/group_matching_service.dart` | Attraction 12D resolution, place override support |
| `lib/injection_container_quantum.dart` | Optional compatibility deps for GroupMatchingService |
| `lib/presentation/pages/business/claim_place_page.dart` | Place search, knot seeding, post-claim message |
| `packages/avrai_knot/lib/services/knot/knot_storage_service.dart` | Business place knot save/load |
| `lib/core/services/business_place_knot_service.dart` | **New** – Knot seeding for claimed places |
| `lib/core/models/claimed_place.dart` | `attractionOverride` field |
| `lib/core/services/place_claim_service.dart` | `updateAttractionOverride` |
| `lib/core/controllers/business_onboarding_controller.dart` | `attractionDimensions` in data and update |
| `lib/presentation/pages/business/business_onboarding_page.dart` | Attraction Profile step |
| `lib/presentation/pages/business/business_dashboard_page.dart` | Strong match labels, place override UI |
| `supabase/migrations/088_claimed_places_attraction_override.sql` | **New** – `attraction_override` column |
| `lib/injection_container_compatibility.dart` | **New** – Compatibility module |
| `lib/injection_container_payment.dart` | Removed compatibility services |
| `lib/injection_container.dart` | Compatibility module registration |

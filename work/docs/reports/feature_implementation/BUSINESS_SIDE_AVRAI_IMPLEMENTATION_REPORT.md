# Business Side AVRAI Implementation Report

**Plan:** Business Side AVRAI: Businesses, Users/Experts, and Events (Looped)  
**Date:** February 3, 2026  
**Status:** ✅ **Complete** – All planned implementation items delivered  
**Reference Plan:** `business_side_avrai_plan_e8984918.plan.md`

---

## Executive Summary

The Business Side AVRAI plan unifies the business side of the platform so that businesses define "what we want to attract," claim places, and participate in the event loop alongside users/experts and events. Implementation followed the plan’s suggested order and delivered:

- Attraction 12D resolution and user–place compatibility
- Knot generation from attraction 12D for places
- Place claim flow and business dashboard enhancements
- Event–place–business loop wiring
- Business attraction profile editing UI

---

## 1. Attraction 12D and Single Policy

### 1.1 Existing vs New Work

**Already in place:**
- `reflectDimensionsForAttraction()` in `packages/avrai_core/lib/utils/attraction_dimensions.dart`
- `Attraction12DResolver` with `resolveForBusiness`, `resolveForEvent`, `resolveForPlace`
- `patronPrefsTo12D` mapping in `lib/core/services/patron_prefs_to_12d_mapper.dart`
- Resolver wired in DI via `injection_container_payment.dart` with `patronPrefsTo12D`
- `VibeCompatibilityService` using attraction for user–business and user–event

**Implemented:**
- **`calculateUserPlaceVibe`** on `VibeCompatibilityService` – computes user↔place compatibility using attraction 12D
- **`_tryEntityKnotForPlace`** – generates place knots with attraction 12D when provided
- **Compatibility policy documentation** – person–person (similarity) vs user–business/user–place/user–event (attraction)

### 1.2 Compatibility Policy Matrix

| Pairing          | Policy     | Entity 12D source                              |
|------------------|------------|-----------------------------------------------|
| person–person    | Similarity | Raw dimensions (no reflection)                 |
| business–business| Similarity | Raw dimensions                                |
| user–business    | Attraction | `Attraction12DResolver.resolveForBusiness`    |
| user–place       | Attraction | `Attraction12DResolver.resolveForPlace`       |
| user–event       | Attraction | `Attraction12DResolver.resolveForEvent`       |

---

## 2. Knot from Attraction 12D

- **EntityKnotService** already accepts `dimensions12D` for company, event, and place and uses them when provided.
- **VibeCompatibilityService** now passes attraction 12D to place knot generation via `_tryEntityKnotForPlace`.
- Knots for business, event, and place are built from attraction 12D so fidelity and knot topology stay aligned.

---

## 3. Place Claim and Business–Place–Event Loop

### 3.1 Place Claim (Pre-existing)

- **Schema:** `claimed_places` table (`supabase/migrations/087_claimed_places.sql`) with `business_id`, `google_place_id`, `claimed_at`, `verification_method`
- **PlaceClaimService:** `claim`, `unclaim`, `listClaimedPlaces`, `getClaimingBusiness`, `getClaimByPlaceId`
- **ClaimPlacePage:** Enter Google Place ID, optional verification method, claim action
- **ClaimedPlace** model for serialization

### 3.2 Changes Made

- **ClaimPlacePage:** `DropdownButtonFormField` fixed for nullable `String?` with `initialValue` (non-deprecated API)

---

## 4. Business Dashboard and Product

### 4.1 Attraction Profile Section

- **Dashboard card** – "Your attraction profile" explaining matching and how users are matched
- **BusinessAttractionProfilePage** (new) – Sliders for all 12 SPOTS dimensions for explicit attraction profile
- **Navigation** – Tap attraction card to open edit page
- **BusinessAccountService** – `updateBusinessAccount` extended with `attractionDimensions` parameter

### 4.2 Claim a Place

- "Claim a place" quick action card → navigates to `ClaimPlacePage`
- List of claimed places with `googlePlaceId` and claimed date
- On success, returns to dashboard and refreshes data

### 4.3 Events at Your Places

- Section "Events at your places" listing events at claimed places
- Uses `ExpertiseEventService.getEventsAtPlaceIds(placeIds)`
- Event list items navigate to `EventDetailsPage` on tap

---

## 5. Event–Place–Business Loop

- **ExpertiseEventService.getEventsAtPlaceIds** – Filters events whose spots have `googlePlaceId` in the claimed set
- **Business dashboard** – Loads claimed places, derives place IDs, fetches events at those places
- Events at spots map to claimed places via `spot.googlePlaceId` → `claimed_places.google_place_id`

---

## 6. Files Modified and Created

### Modified

| File | Changes |
|------|---------|
| `lib/core/services/vibe_compatibility_service.dart` | Added `calculateUserPlaceVibe`, `_tryEntityKnotForPlace`, compatibility policy docs, `Spot` import |
| `lib/core/services/business_account_service.dart` | Added `attractionDimensions` to `updateBusinessAccount` |
| `lib/presentation/pages/business/business_dashboard_page.dart` | Attraction profile card tappable, edit link, event detail navigation |
| `lib/presentation/pages/business/claim_place_page.dart` | `DropdownButtonFormField<String?>` with `initialValue` |

### Created

| File | Purpose |
|------|---------|
| `lib/presentation/pages/business/business_attraction_profile_page.dart` | Sliders for 12D attraction profile editing |

### Tests

| File | Changes |
|------|---------|
| `test/unit/services/vibe_compatibility_service_truthful_degradation_test.dart` | Test for `calculateUserPlaceVibe` graceful degradation when knot runtime unavailable |

---

## 7. Testing

- `test/unit/services/vibe_compatibility_service_truthful_degradation_test.dart` – 2 tests passing (user–business, user–place)
- No new linter errors introduced

---

## 8. Success Criteria (from Plan)

| Criterion | Status |
|-----------|--------|
| Businesses can set or infer "what we want to attract" (12D) and see it in the dashboard | ✅ |
| User–business and user–event compatibility use attraction 12D for the business/event side | ✅ |
| User–place compatibility uses attraction 12D | ✅ |
| Person–person remains similarity | ✅ |
| Businesses can claim places | ✅ |
| Claimed places list on dashboard | ✅ |
| Events at spots can be associated with claiming business via spots → google_place_id → claimed_places | ✅ |
| Dashboard shows "Events at your places" | ✅ |
| Experts and users discover events and places by attraction-based compatibility | ✅ (via existing services) |

---

## 9. Deferred / Optional Items

- **Device-first knot/string seeding for claimed places** – Plan calls this optional; seeding after claim not implemented. Could be added later.
- **Place-level attraction override** – Plan mentions optional per-place override; currently uses business-level attraction. Could be added to claimed place UI.

---

## 10. References

- Plan: Business Side AVRAI (attached to implementation task)
- `lib/core/services/attraction_12d_resolver.dart`
- `lib/core/services/patron_prefs_to_12d_mapper.dart`
- `packages/avrai_core/lib/utils/attraction_dimensions.dart`
- `lib/core/services/place_claim_service.dart`
- `supabase/migrations/087_claimed_places.sql`

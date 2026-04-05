# Agent 2: Addendum — Community Discovery + True Compatibility

**Date:** January 1, 2026  
**Phase:** Phase 6 - Local Expert System Redesign (Communities/Clubs surface)  
**Status:** ✅ **COMPLETE**

---

## 🎯 Summary

This addendum makes **community recommendations user-visible** and makes the underlying scoring **non-neutral in production** by introducing a privacy-safe 12D community centroid, plus lightweight caching for ranking.

---

## 🚪 Doors (Philosophy Alignment)

- **Door opened:** “Discover communities” becomes a real surface (not just internal logic)
- **Good key:** True compatibility is explainable (quantum + topology + weave fit), and does not require fetching every member profile
- **Learning:** Joining a community updates an aggregated centroid (privacy-safe) used to improve future ranking

---

## ✅ What Changed (Implementation)

### **UI**
- Added `CommunitiesDiscoverPage`:
  - **Route:** `/communities/discover`
  - Shows a ranked list of communities for the signed-in user using combined true compatibility
- Added a “Discover” CTA inside `EventsBrowsePage` when the user selects the Clubs/Communities scope

### **Community Discovery Candidates (Persistence)**
- `CommunityService` now hydrates/persists the community list via `StorageService`
  - **Storage key:** `communities:all_v1`
  - Prevents “no candidates” when communities exist outside the current runtime session

### **Non-Neutral Quantum Term (Privacy-Safe)**
- Added to `Community`:
  - `vibeCentroidDimensions` (12D, privacy-safe / aggregated)
  - `vibeCentroidContributors` (count)
- `CommunityService` updates a running centroid on join (best-effort) using anonymized dimensions
- Quantum compatibility prefers the stored centroid when present (fallback remains centroid-from-member-profiles)

### **Performance**
- Added short TTL caching for `calculateUserCommunityTrueCompatibility` during ranking

---

## 🧪 Verification

- ✅ `flutter test test/unit/services/community_service_test.dart`
- ✅ `flutter test test/unit/models/community_test.dart`
- ✅ `flutter test test/integration/knot_onboarding_integration_test.dart`

---

## 📁 Files Touched (High Signal)

- `lib/presentation/pages/communities/communities_discover_page.dart`
- `lib/presentation/routes/app_router.dart`
- `lib/presentation/pages/events/events_browse_page.dart`
- `lib/core/services/community_service.dart`
- `lib/core/models/community.dart`
- `packages/spots_knot/lib/services/knot/knot_community_service.dart`
- `test/unit/services/community_service_test.dart`


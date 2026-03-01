# SPOTS Manual Testing Checklist

## 1. Onboarding Flow
- [ ] Launch app as a new user
- [ ] Complete Homebase selection (map-based)
- [ ] Complete Favorite Places selection
- [ ] Complete Preference Survey (categories per area)
- [ ] Add friends & Respect a list
- [ ] Verify baseline lists (Chill, Fun, Classic) are auto-created
- [ ] Skip each onboarding step and verify app behavior
- [ ] Edit onboarding selections before completion
- [ ] Complete onboarding and land on main app

## 2. Spot Creation
- [ ] Create a spot from the main entry point
- [ ] Create a spot from the Lists tab
- [ ] Add spot details (name, location, category, description)
- [ ] Use current location for spot
- [ ] Search for a location when creating a spot
- [ ] View created spot in Spots tab

## 3. List Management
- [ ] Create a new list
- [ ] Edit a list (title, description)
- [ ] Delete a list
- [ ] Add a spot to a list
- [ ] Remove a spot from a list
- [ ] Verify baseline lists are present after onboarding
- [ ] Attempt to delete a baseline list (should not be possible)

## 4. Map Features
- [ ] Map loads on Map tab
- [ ] User location is shown (with permission prompt)
- [ ] Spot markers display on map
- [ ] Tap marker to view spot details
- [ ] Map theme selector works
- [ ] Map navigation (zoom, pan) is smooth

## 5. Offline Mode
- [ ] Disable network and launch app
- [ ] View spots and lists offline
- [ ] Create/edit spots and lists offline
- [ ] Offline indicator displays
- [ ] Re-enable network and verify sync

## 6. Privacy & Permissions
- [ ] Location permission prompt appears on first use
- [ ] Deny location permission and verify app behavior
- [ ] No sensitive data leaves device (verify logs, network activity)

## 7. Navigation & UI
- [ ] All tabs, pages, and modals work
- [ ] Navigation is smooth and matches design
- [ ] No UI overflow or layout bugs
- [ ] App works in both light and dark mode

## 8. Device Testing
- [ ] Test on iOS simulator
- [ ] Test on real iOS device (if possible)
- [ ] Test on Android emulator
- [ ] Test on real Android device (if possible)

### 8.1 Phase 19.15: Quantum Matching A/B Testing (Device Testing)
**Purpose:** Validate quantum entanglement matching vs. classical matching on real devices

#### **A/B Testing Workflow:**
1. **Enable Feature Flags Gradually:**
   - [ ] Enable `phase19_quantum_matching_enabled` for 5% of users
   - [ ] Monitor metrics for 24-48 hours
   - [ ] Increase to 10% if metrics are positive
   - [ ] Continue gradual rollout (25%, 50%, 75%, 100%)
   - [ ] Enable service-specific flags:
     - [ ] `phase19_quantum_event_matching`
     - [ ] `phase19_quantum_partnership_matching`
     - [ ] `phase19_quantum_brand_discovery`
     - [ ] `phase19_quantum_business_expert_matching`
   - [ ] Enable `phase19_knot_integration_enabled` when quantum matching is stable

2. **Monitor Metrics Using QuantumMatchingMetricsService:**
   - [ ] Track matching operations (method, compatibility, execution time)
   - [ ] Monitor per-service metrics:
     - [ ] EventMatchingService metrics
     - [ ] PartnershipMatchingService metrics
     - [ ] BrandDiscoveryService metrics
     - [ ] BusinessExpertMatchingService metrics
   - [ ] Check metrics daily during rollout
   - [ ] Verify metrics are being collected correctly

3. **Compare Quantum vs. Classical Performance:**
   - [ ] Use `QuantumMatchingMetricsService.compareMethods()` for each service
   - [ ] Compare compatibility scores (quantum vs. classical)
   - [ ] Compare execution times (quantum vs. classical)
   - [ ] Check for compatibility improvements (>0% improvement target)
   - [ ] Check for acceptable performance impact (<50ms additional time acceptable)
   - [ ] Document comparison results

4. **Adjust Hybrid Weights Based on Results:**
   - [ ] Review metrics after each rollout phase
   - [ ] If quantum performs better: Increase quantum weight (e.g., 70% → 80%)
   - [ ] If quantum performs worse: Decrease quantum weight (e.g., 70% → 60%)
   - [ ] If execution time is too high: Optimize quantum matching or reduce weight
   - [ ] Update hybrid weights in services:
     - [ ] EventMatchingService (currently 60% quantum, 40% classical)
     - [ ] PartnershipMatchingService (currently 70% quantum, 30% classical)
     - [ ] BrandDiscoveryService (currently 70% quantum, 30% classical)
     - [ ] BusinessExpertMatchingService (currently 70% quantum, 30% classical)

5. **Roll Out to 100% When Validated:**
   - [ ] Verify quantum matching improves compatibility scores
   - [ ] Verify execution time is acceptable (<100ms additional time)
   - [ ] Verify no regressions in matching quality
   - [ ] Verify knot integration bonus works correctly
   - [ ] Enable for 100% of users
   - [ ] Monitor for 1 week after full rollout
   - [ ] Document final metrics and performance

#### **Device-Specific Testing:**
- [ ] Test quantum matching on iOS devices (iPhone, iPad)
- [ ] Test quantum matching on Android devices (various manufacturers)
- [ ] Test on low-end devices (performance impact)
- [ ] Test on high-end devices (baseline performance)
- [ ] Test with poor network conditions (fallback to classical)
- [ ] Test with no network (offline mode, classical only)
- [ ] Test feature flag toggling (enable/disable quantum matching)
- [ ] Verify graceful degradation when quantum matching fails

#### **Metrics to Monitor:**
- [ ] Average compatibility score (quantum vs. classical)
- [ ] Average execution time (quantum vs. classical)
- [ ] Compatibility improvement percentage
- [ ] Execution time difference percentage
- [ ] Number of quantum matching operations
- [ ] Number of classical fallbacks
- [ ] Error rate (quantum matching failures)
- [ ] User satisfaction (if available via feedback)

## 9. Bug/Issue Documentation
- [ ] Document any bugs, UI issues, or platform-specific problems found during testing

---

*Check off each item as you complete it. Add notes or screenshots for any issues found.* 
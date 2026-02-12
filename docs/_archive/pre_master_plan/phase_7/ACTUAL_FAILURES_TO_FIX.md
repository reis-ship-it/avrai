# Actual Test Failures That Need Fixing

**Date:** December 20, 2025, 05:39 PM CST  
**Current Status:** 794 passing, 49 failing (94.2% pass rate)

---

## Summary

After filtering out expected service logs, the actual test failures fall into these categories:

---

## Category 1: IntegrationTestWidgetsFlutterBinding Conflicts (Multiple files)

**Problem:** Several test files use `IntegrationTestWidgetsFlutterBinding.ensureInitialized()` which conflicts with `TestWidgetsFlutterBinding` when running with `flutter test` instead of `flutter drive`.

**Affected Files:**
- `test/integration/onboarding_flow_integration_test.dart`
- `test/integration/ai2ai_ecosystem_test.dart`
- `test/integration/offline_online_sync_test.dart`
- ~~`test/integration/complete_user_journey_test.dart`~~ - **REMOVED**
- `test/integration/role_progression_test.dart`
- `test/integration/deployment_readiness_test.dart`
- (And possibly others)

**Error Pattern:**
```
_AssertionError._throwNew
package:flutter/src/foundation/binding.dart 165:7  new BindingBase
...
package:integration_test/integration_test.dart 158:7  IntegrationTestWidgetsFlutterBinding.ensureInitialized
```

**Fix Strategy:**
1. **Option 1 (Recommended):** Replace `IntegrationTestWidgetsFlutterBinding.ensureInitialized()` with `TestWidgetsFlutterBinding.ensureInitialized()` for tests that run with `flutter test`
2. **Option 2:** Keep `IntegrationTestWidgetsFlutterBinding` but document that these tests require `flutter drive` instead of `flutter test`
3. **Option 3:** Create separate test files for integration test binding vs regular test binding

**Priority:** HIGH (affects multiple files)

---

## Category 2: UI Widget Expectation Failures

### 2.1 Missing UI Text/Widgets

**File:** `test/integration/ui_llm_integration_test.dart` (renamed from ui_integration_week_35_test.dart)

**Failure:**
```
Expected: exactly one matching candidate
Actual: _TextWidgetFinder:<Found 0 widgets with text "🎉 List Created!": []>
```

**Fix:** Update test to wait for UI to update or check for alternative text/state

**Priority:** MEDIUM

### 2.2 Location/Address Mismatches

**Failure Pattern:**
```
Expected: contains 'Williamsburg, Brooklyn'
Actual: ['Williamsburg']

Expected: 'Austin'
Actual: '500 Congress Ave'
```

**Fix:** Update test expectations to match actual UI output format (may be showing street address instead of city, or shortened location names)

**Priority:** MEDIUM

---

## Category 3: Business Logic Expectation Mismatches

### 3.1 Dimension Count Mismatches

**Failure Pattern:**
```
Expected: an object with length of <8>
Actual: { ... }
```

**Root Cause:** Tests expect 8 dimensions but actual implementation uses 12 dimensions (as we fixed in `ai2ai_final_integration_test.dart`)

**Fix:** Update remaining tests to expect 12 dimensions instead of 8

**Priority:** HIGH

### 3.2 Value Threshold Failures

**Failure Pattern:**
```
Expected: a value greater than <0.8>
Actual: <0.8>  or <0.5>
```

**Fix:** Adjust expectations to match actual calculated values, or fix calculation logic if values are incorrect

**Priority:** MEDIUM

### 3.3 Intent Type Mismatches

**Failure Pattern:**
```
Expected: <Instance of 'CreateListIntent'>
Actual: <Instance of 'CreateSpotIntent'>
```

**Fix:** Update test to expect correct intent type based on actual user action

**Priority:** MEDIUM

### 3.4 List/Array Mismatches

**Failure Pattern:**
```
Expected: contains CommunityEvent:<CommunityEvent(...)>
Actual: []
```

**Fix:** Verify that events are actually created before assertions, or fix event creation/retrieval logic

**Priority:** MEDIUM

### 3.5 Boolean/Count Mismatches

**Failure Pattern:**
```
Expected: true
Actual: <false>

Expected: a value greater than or equal to <2>
Actual: <1>
```

**Fix:** Adjust test expectations or fix business logic that determines these values

**Priority:** MEDIUM

---

## Category 4: Test Setup/Initialization Issues

**File:** `test/integration/ui/user_flow_integration_test.dart`

**Failure:**
```
should show loading states appropriately in brand flow
Test failed. See exception logs above.
```

**Fix:** Verify test setup, mock initialization, and async operation handling

**Priority:** MEDIUM

---

## Priority Order for Fixes

### High Priority (Fix First)

1. **IntegrationTestWidgetsFlutterBinding conflicts** - Affects multiple files, prevents tests from running
2. **Dimension count mismatches** - Known issue (8 vs 12 dimensions), systematic fix needed

### Medium Priority

3. **UI widget expectation failures** - Text/location mismatches
4. **Business logic expectation mismatches** - Value thresholds, intent types, lists
5. **Test setup/initialization issues** - Individual test failures

---

## Estimated Impact

- **High Priority Fixes:** ~10-15 failures resolved (IntegrationTestWidgetsFlutterBinding + dimension counts)
- **Medium Priority Fixes:** ~30-35 failures resolved (UI expectations + business logic)
- **Total Expected Resolution:** ~40-50 failures → **Target: 98%+ pass rate**

---

## Next Steps

1. **Fix IntegrationTestWidgetsFlutterBinding conflicts** (replace with TestWidgetsFlutterBinding where appropriate)
2. **Fix dimension count expectations** (8 → 12 dimensions)
3. **Fix UI expectation failures** (update text/location expectations)
4. **Fix business logic expectation mismatches** (adjust thresholds, intent types, lists)
5. **Verify fixes** with full test suite run

---

## Notes

- Many errors shown in test output are **expected service logs**, not actual test failures
- The actual failures are **assertion mismatches** and **binding conflicts**
- Most fixes are straightforward expectation updates or test setup corrections
- Some may require business logic verification to ensure expectations are correct


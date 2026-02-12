# Mock Setup Error Analysis - 12 Remaining Errors

**Date:** December 8, 2025  
**Status:** Investigation Complete - Root Cause Identified

## Executive Summary

All 12 remaining errors are caused by **library conflict between Mocktail and Mockito**. When Mocktail's `when()` is called, it triggers Mockito's internal state tracking, causing subsequent Mockito `when()` calls to fail with "Cannot call `when` within a stub response".

## Error Pattern Analysis

### Universal Pattern (100% of errors)

```
Line X:   mocktail.when(() => mockConnectivity.checkConnectivity())  ✅ WORKS
Line X+2: mockito.when(mockLocalDataSource.method(...))              ❌ FAILS
```

**Every single error** follows this exact pattern.

### Specific Error Locations

| Line | Test Name | Mocktail Call | Mockito Call That Fails |
|------|-----------|---------------|-------------------------|
| 103 | should prioritize community data over external sources | Line 101 | `mockLocalDataSource.searchSpots('cafe')` |
| 147 | should return only community data when includeExternal is false | Line 145 | `mockLocalDataSource.searchSpots('restaurant')` |
| 188 | should use cached Google Places data when offline | Line 186 | `mockLocalDataSource.searchSpots('coffee')` |
| 225 | should return cached result when available | Line 223 | `mockLocalDataSource.searchSpots('cafe')` |
| 249 | should cache results with proper expiration | Line 247 | `mockLocalDataSource.searchSpots('restaurant')` |
| 271 | should apply filters when provided | Line 269 | `mockLocalDataSource.searchSpots('cafe')` |
| 297 | should respect maxResults limit | Line 295 | `mockLocalDataSource.searchSpots('restaurant')` |
| 323 | should return empty result on error | Line 321 | `mockLocalDataSource.searchSpots('cafe')` |
| 344 | should handle external data source errors gracefully | Line 342 | `mockLocalDataSource.searchSpots('cafe')` |
| 373 | should search nearby spots with location | Line 372 | `mockLocalDataSource.searchSpots('')` |
| 397 | should respect radius parameter | Line 396 | `mockLocalDataSource.searchSpots('')` |
| 471 | should prioritize community data over external sources (OUR_GUTS.md) | Line 470 | `mockLocalDataSource.searchSpots('cafe')` |
| 500 | should maintain privacy-preserving search analytics | Line 499 | `mockLocalDataSource.searchSpots('cafe')` |

**Note:** One test also shows "type 'Null' is not a subtype" error, likely a secondary effect of the mock setup failure.

### Tests That Pass (Control Group)

3 tests in the `HybridSearchResult` group pass successfully:
- `should create empty result correctly`
- `should calculate community ratio correctly`
- `should return false for isPrimarilyCommunityDriven when external dominates`

**Why they pass:** These tests don't use any mocks - they only test pure data model logic.

## Root Cause Analysis

### Hypothesis: Library State Conflict

**Evidence:**
1. 100% of errors occur when Mocktail `when()` is followed by Mockito `when()`
2. Mocktail calls succeed, Mockito calls fail immediately after
3. Error occurs at the very first Mockito `when()` after any Mocktail `when()`
4. Tests without mocks pass fine
5. Error is consistent across all failing tests

**Mechanism:**
Both Mocktail and Mockito use `noSuchMethod` interception to track mock behavior. When Mocktail sets up a stub:
1. Mocktail's stub setup triggers `noSuchMethod` interception
2. This interception mechanism is shared or conflicts with Mockito's tracking
3. Mockito detects the `noSuchMethod` call and thinks we're "inside a stub response"
4. Mockito blocks new `when()` calls thinking we're mid-execution
5. Error: "Cannot call `when` within a stub response"

### Technical Details

**Mocktail Implementation:**
- Uses `noSuchMethod` for all method calls
- Tracks stub responses globally
- Async stubs handled with `thenAnswer`

**Mockito Implementation:**
- Also uses `noSuchMethod` interception
- Maintains internal state about "active stub responses"
- Detects when `noSuchMethod` is called during stub execution

**Conflict Point:**
When Mocktail's `when()` creates a stub, Mockito's state tracking sees the `noSuchMethod` call and marks the context as "inside stub response". Subsequent Mockito calls then fail.

## Individual Error Breakdown

### Error Category 1: Mock Setup Sequence (12 errors)
- **Pattern:** Mocktail `when()` → Mockito `when()` 
- **Frequency:** 12/12 (100%)
- **Fix Required:** Change order or use single library

### Error Category 2: Null Subtype (1 error)
- **Pattern:** Mock not configured when called
- **Frequency:** 1 test
- **Likely Cause:** Secondary effect of mock setup failure
- **Fix:** Resolve primary mock setup issue

## Solution Analysis

### Option 1: Use Mocktail for ALL mocks ⭐ RECOMMENDED
**Pros:**
- Eliminates library conflict completely
- Better async stub handling
- Consistent syntax throughout
- Already proven to work for Connectivity

**Cons:**
- Requires converting all Mockito mocks
- Need to change all `mockito.when()` to `mocktail.when(() => ...)`
- Need to change all `mockito.verify()` to `mocktail.verify(() => ...)`
- Need to update mock class definitions

**Effort:** Medium (~30-40 `when()` calls to update)

**Expected Outcome:** ✅ All 12 errors resolved

### Option 2: Use Mockito for ALL mocks
**Pros:**
- Minimal changes (just revert Connectivity)
- Most mocks already use Mockito

**Cons:**
- Connectivity mock will have async issues again
- Back to original problem (18-19 errors)
- Mockito's async handling is problematic for `checkConnectivity()`

**Effort:** Low (just revert Connectivity changes)

**Expected Outcome:** ❌ Returns to 18-19 errors

### Option 3: Reorder Mock Setup
**Hypothesis:** Set up Mockito mocks first, then Mocktail

**Analysis:**
- Unlikely to work - conflict is state-based, not order-based
- Mockito would still see Mocktail's `noSuchMethod` calls
- Conflict occurs when both libraries are active

**Effort:** Low (reorder calls)

**Expected Outcome:** ❌ Likely won't work

### Option 4: Separate Test Groups by Library
**Pros:**
- No mixing in same test

**Cons:**
- Major restructuring required
- Tests share same setup/tearDown
- Connectivity needed in most tests

**Effort:** High

**Expected Outcome:** ⚠️ Possible but complex

## Recommendation

**Convert all mocks to Mocktail** for the following reasons:

1. **Proven Solution:** Mocktail already resolves Connectivity async issues
2. **Complete Fix:** Eliminates all 12 errors by removing conflict
3. **Better Foundation:** Mocktail handles async better for future tests
4. **Consistency:** Single library = simpler maintenance
5. **Future-Proof:** Avoids library conflicts in new tests

## Implementation Plan

1. Convert all mock class definitions from `mockito.Mock` to `mocktail.Mock`
2. Replace all `mockito.when(mock.method(...))` with `mocktail.when(() => mock.method(...))`
3. Replace all `mockito.verify(mock.method(...))` with `mocktail.verify(() => mock.method(...))`
4. Replace `mockito.verifyNever()` with `mocktail.verifyNever()`
5. Replace `mockito.anyNamed()` with `mocktail.any()` or appropriate matcher
6. Remove `mockito` import prefix (keep `mocktail` prefix or remove both)
7. Test and verify all errors resolved

## Expected Results

- ✅ All 12 "Cannot call when within stub" errors eliminated
- ✅ All mock setup issues resolved
- ✅ Consistent mocking library throughout test file
- ✅ Better async stub handling for all mocks

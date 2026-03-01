# Mock Setup Conversion Complete

**Date:** December 8, 2025  
**Status:** ✅ All 12 Errors Resolved

## Summary

Successfully converted all mocks from Mockito to Mocktail in `test/unit/repositories/hybrid_search_repository_test.dart`, eliminating all 12 "Cannot call `when` within a stub response" errors.

## Conversion Details

### 1. Mock Class Definitions
- ✅ Converted all 5 mock classes from `mockito.Mock` to `mocktail.Mock`
  - `MockSpotsLocalDataSource`
  - `MockSpotsRemoteDataSource`
  - `MockGooglePlacesDataSource`
  - `MockOpenStreetMapDataSource`
  - `MockGooglePlacesCacheService`
  - `MockConnectivity` (already using Mocktail)

### 2. Import Changes
- ✅ Removed `import 'package:mockito/mockito.dart' as mockito;`
- ✅ Changed to `import 'package:mocktail/mocktail.dart';` (no prefix needed)
- ✅ Removed all `mockito.` prefixes

### 3. Syntax Conversions

#### `when()` Calls
- **Before:** `mockito.when(mockLocalDataSource.searchSpots('cafe'))`
- **After:** `when(() => mockLocalDataSource.searchSpots('cafe'))`
- **Count:** ~25 conversions

#### `verify()` Calls
- **Before:** `mockito.verify(mockLocalDataSource.searchSpots('cafe')).called(1)`
- **After:** `verify(() => mockLocalDataSource.searchSpots('cafe')).called(1)`
- **Count:** ~5 conversions

#### `verifyNever()` Calls
- **Before:** `mockito.verifyNever(mockGooglePlacesDataSource.searchPlaces(...))`
- **After:** `verifyNever(() => mockGooglePlacesDataSource.searchPlaces(...))`
- **Count:** ~4 conversions

#### Named Parameters
- **Before:** `mockito.anyNamed('latitude')`
- **After:** `any(named: 'latitude')`
- **Count:** ~6 conversions

## Test Results

### Before Conversion
- **Tests Passing:** 4/16 (12 failures)
- **Error:** "Bad state: Cannot call `when` within a stub response"
- **Root Cause:** Library conflict between Mockito and Mocktail

### After Conversion
- **Tests Passing:** 16/16 (100% pass rate)
- **Errors:** 0
- **Status:** ✅ All tests passing

## Key Insights

1. **Library Conflict Confirmed:** Mixing Mockito and Mocktail in the same test file causes fundamental state conflicts
2. **Mocktail Superiority:** Mocktail handles async stubs more reliably, especially for `Connectivity.checkConnectivity()`
3. **Consistent Syntax:** Using a single mocking library provides consistency and eliminates conflicts

## Files Modified

- `test/unit/repositories/hybrid_search_repository_test.dart`
  - Converted all mocks to Mocktail
  - Updated all `when()`, `verify()`, and `verifyNever()` calls
  - Converted all `anyNamed()` to `any(named: ...)`
  - Removed Mockito import

## Impact

✅ **All 12 "Cannot call `when` within a stub response" errors eliminated**  
✅ **All 16 tests now passing**  
✅ **No linter errors**  
✅ **Improved async stub reliability**

## Next Steps

This conversion demonstrates that Mocktail is the preferred mocking library for this project, especially when dealing with async operations. Consider:

1. Converting other test files that mix Mockito and Mocktail
2. Standardizing on Mocktail across the entire test suite
3. Updating test helpers and mock factories to use Mocktail consistently

## References

- Original issue analysis: `docs/MOCK_SETUP_ERROR_ANALYSIS.md`
- Solution options: `docs/MOCK_SETUP_SOLUTION_OPTIONS.md`
- Mocktail documentation: [pub.dev/packages/mocktail](https://pub.dev/packages/mocktail)


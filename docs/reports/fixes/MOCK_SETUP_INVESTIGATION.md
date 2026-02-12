# Mock Setup Issues Investigation

**Date:** December 8, 2025  
**Status:** In Progress

## Problem Summary

**Error:** "Cannot call `when` within a stub response"  
**Location:** `test/unit/repositories/hybrid_search_repository_test.dart`  
**Count:** 13 failing tests

## Root Cause Analysis

### Findings

1. **Repository Constructor:** Does NOT call `checkConnectivity()` - it only stores the reference
2. **Mock Setup Pattern:** All `when()` calls happen BEFORE repository creation
3. **Test Isolation:** Fresh mocks created in `setUp()`, reset in `tearDown()`
4. **Sequential Execution:** Issue persists even with `--concurrency=1`

### Key Observations

- Tests that DON'T use connectivity mocks pass (3 tests in HybridSearchResult group)
- Error occurs when setting up connectivity mock: `when(mockConnectivity.checkConnectivity())`
- Error happens even on first `when()` call in some tests
- Two different error types:
  1. "type 'Null' is not a subtype" - Mock not set up when called
  2. "Cannot call `when` within a stub response" - Setting up mock during stub execution

### Hypothesis

The error occurs because:
1. Mockito tracks when you're inside a stub response execution
2. If any async operation from a previous test (or even within the same test setup) is still pending, Mockito thinks we're in a stub context
3. When we call `when()` to set up a new stub, Mockito throws the error

### Attempted Fixes

1. ✅ Moved repository creation out of `setUp()` to individual tests
2. ✅ Ensured all `when()` calls happen before repository creation
3. ✅ Changed `clearInteractions()` to `reset()` in tearDown
4. ✅ Increased delay in tearDown to ensure async completion
5. ✅ Tested with sequential execution (`--concurrency=1`)

### Remaining Issues

- Error still occurs even with all above fixes
- Suggests the problem might be deeper in Mockito's async handling
- May require a different mocking strategy or library

## Next Steps

1. Try using `Mocktail` instead of `Mockito` for connectivity mocks
2. Investigate if there's a global Mockito state that needs clearing
3. Consider if the repository's async initialization pattern needs changing
4. Check if other test files have similar patterns that work

## References

- Mockito documentation on async stubbing
- Flutter testing best practices
- Alternative mocking libraries (Mocktail)


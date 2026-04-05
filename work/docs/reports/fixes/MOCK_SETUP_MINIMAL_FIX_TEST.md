# Minimal Fix Test Plan

**Date:** December 8, 2025  
**Purpose:** Test if removing redundant Mocktail calls fixes the issue

## Hypothesis

If we remove the 12 redundant `mocktail.when()` calls from tests (since setUp() already sets them), Mockito `when()` calls might work because:
- Mocktail setup happens in setUp() (before test execution)
- Tests skip redundant Mocktail calls
- Mockito `when()` calls happen without active Mocktail context

## Test Plan

1. Remove redundant `mocktail.when(() => mockConnectivity.checkConnectivity())` calls from all tests
2. Keep Mocktail call in setUp() (line 63)
3. Keep offline test's Mocktail call (line 186 - uses new mock instance)
4. Test if Mockito `when()` calls succeed

## Expected Outcomes

**If it works:** Minimal change solution - no library conversion needed  
**If it doesn't work:** Confirms mixing libraries is incompatible - need full conversion


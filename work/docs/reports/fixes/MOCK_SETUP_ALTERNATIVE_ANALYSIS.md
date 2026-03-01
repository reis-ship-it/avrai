# Alternative Solutions - Avoiding Full Library Conversion

**Date:** December 8, 2025  
**Status:** Analysis

## Question

**Can we fix the 12 errors without converting everything to Mocktail or Mockito?**

## Current Situation

### Setup in `setUp()`
- Line 63: `mocktail.when(() => mockConnectivity.checkConnectivity())` sets default to **online** (wifi)

### Tests That Override (Redundantly)
Most tests call `mocktail.when()` again with the SAME value (online/wifi):
- Line 101: Sets to wifi (same as setUp)
- Line 145: Sets to wifi (same as setUp)  
- Line 223: Sets to wifi (same as setUp)
- Line 247: Sets to wifi (same as setUp)
- Line 269: Sets to wifi (same as setUp)
- Line 295: Sets to wifi (same as setUp)
- Line 321: Sets to wifi (same as setUp)
- Line 342: Sets to wifi (same as setUp)
- Line 372: Sets to wifi (same as setUp)
- Line 396: Sets to wifi (same as setUp)
- Line 470: Sets to wifi (same as setUp)
- Line 499: Sets to wifi (same as setUp)

### Tests That Actually Need Override
- Line 186: Sets to **offline** (none) - Uses a NEW mock instance, different approach

## Alternative Solution: Remove Redundant Calls

### Hypothesis

If we **remove the redundant `mocktail.when()` calls** in tests (since setUp() already sets them to online), we might avoid the conflict because:

1. Mocktail `when()` in setUp() happens BEFORE tests run
2. Tests skip Mocktail `when()` (default is already correct)
3. Tests call Mockito `when()` directly - no Mocktail interference

### Potential Issues

1. **State Persistence:** Even though Mocktail `when()` is in setUp(), Mockito might still see the state
2. **Test Isolation:** Tests might interfere with each other if we don't override
3. **Offline Test:** The offline test creates a new mock, so it's already handled differently

### Testing Strategy

Try removing redundant Mocktail `when()` calls from tests that match the setUp() default and see if Mockito `when()` calls succeed.

## Alternative Solution 2: Set Up Mockito Mocks in setUp()

### Hypothesis

If we set up ALL Mockito mocks in setUp() with default values, tests might not need to call Mockito `when()` at all, or only for overrides.

### Challenges

- Tests need different mock responses (different queries, different return values)
- Would require parameterized mocks or very generic defaults
- Not practical given test diversity

## Alternative Solution 3: Use Mocktail Only for Connectivity, Accept Limitations

### Current Approach (Not Working)

- Mocktail for Connectivity only
- Mockito for all other mocks
- **Problem:** Mocktail in setUp() interferes with Mockito in tests

### Potential Workaround

What if we:
1. Keep Mocktail only for Connectivity
2. Set up Connectivity in setUp() (no override in tests unless needed)
3. Use a delay/await between Mocktail setup and Mockito setup?

**Unlikely to work:** The conflict is state-based, not timing-based.

## Recommendation

**Remove redundant Mocktail `when()` calls** and test:

1. Remove all `mocktail.when(() => mockConnectivity.checkConnectivity())` calls from tests where the value matches setUp() default (wifi)
2. Keep Mocktail `when()` only when actually overriding (offline test already uses new mock)
3. See if Mockito `when()` calls then succeed

**If this works:** Minimal change, no library conversion needed.  
**If this doesn't work:** Confirms that mixing libraries is fundamentally incompatible, and conversion is required.


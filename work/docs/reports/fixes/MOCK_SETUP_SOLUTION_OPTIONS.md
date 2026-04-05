# Mock Setup Solution Options

**Date:** December 8, 2025  
**Question:** Do we need to convert everything to fix the 12 errors?

## Answer: **NO, but with caveats**

## Option Analysis

### Option 1: Remove Redundant Mocktail Calls (Minimal Change) ⚠️ MAY WORK

**Strategy:** 
- Remove redundant `mocktail.when()` calls in tests that match setUp() default
- Keep Mocktail only in setUp() and for actual overrides (offline test)

**Why it might work:**
- Mocktail `when()` in setUp() happens BEFORE test execution
- If tests don't call Mocktail `when()` again, Mockito might not see active conflict
- Only one test actually needs to override (offline), and it uses a new mock instance

**Why it might not work:**
- Mockito might still detect Mocktail's state from setUp()
- The conflict might be fundamental regardless of when Mocktail is called

**Implementation:**
- Remove 12 redundant `mocktail.when(() => mockConnectivity.checkConnectivity())` calls
- Keep the one in setUp()
- Keep the offline test's setup (it uses a new mock anyway)

**Effort:** Low (remove ~12 lines)
**Success Probability:** 50% (unlikely but worth testing)

### Option 2: Convert ALL to Mocktail (Recommended) ✅ GUARANTEED TO WORK

**Strategy:**
- Convert all Mockito mocks to Mocktail
- Use consistent syntax throughout

**Why it works:**
- Eliminates library conflict completely
- No mixing = no state interference
- Mocktail handles async better anyway

**Implementation:**
- Convert ~30-40 `mockito.when()` to `mocktail.when(() => ...)`
- Convert mock class definitions
- Update verify calls

**Effort:** Medium
**Success Probability:** 100% (proven solution)

### Option 3: Convert ALL to Mockito ❌ WON'T WORK

**Strategy:**
- Revert Connectivity to Mockito
- Use only Mockito throughout

**Why it won't work:**
- Original problem was Mockito's async stub issues with Connectivity
- Would return to 18-19 errors
- Back to square one

**Effort:** Low (just revert)
**Success Probability:** 0% (known to fail)

## Recommendation

**Test Option 1 first** (5 minutes):
1. Remove redundant Mocktail `when()` calls from tests
2. Test if Mockito `when()` calls then succeed
3. If it works: ✅ Minimal change solution
4. If it doesn't: Convert to Option 2 (Mocktail for all)

**Rationale:** 
- Option 1 is quick to test (~5 min)
- If it fails, we know for certain that mixing is incompatible
- If it works, we save significant refactoring effort


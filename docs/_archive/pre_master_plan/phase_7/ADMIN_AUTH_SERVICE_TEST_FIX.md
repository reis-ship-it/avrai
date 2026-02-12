# AdminAuthService Test Fix Requirements

**Date:** December 18, 2025  
**File:** `test/unit/services/admin_auth_service_test.dart`  
**Status:** 🔍 Analysis Complete

---

## Problem Summary

The `admin_auth_service_test.dart` has 1 failing test in the `authenticate` group. The test expects `result2.lockedOut` to be `true` when there are 4 previous login attempts, but it's returning `false`.

**Failing Test:** Line 47-51
```dart
final result2 = await service.authenticate(
  username: 'admin',
  password: 'wrong-password',
);
expect(result2.lockedOut, isTrue);  // ❌ Fails: Expected true, Actual false
```

---

## Root Cause Analysis

### Service Architecture

The `AdminAuthService.authenticate()` method:

1. **Checks local lockout** (lines 32-36)
   - Reads `_adminLockoutKey` from SharedPreferences
   - Returns locked out if lockout timestamp is in the future

2. **Calls `_verifyCredentials()`** (line 39)
   - Creates new `SupabaseService()` instance (line 87) - **NOT injectable**
   - Checks if Supabase is available (line 90)
   - If not available, returns failure with error message
   - If available, calls `client.functions.invoke('admin-auth', ...)` (line 105)

3. **Handles verification result** (lines 41-58)
   - If `verifyResult.lockedOut == true`, sets local lockout and returns locked out
   - If `verifyResult.remainingAttempts != null`, returns failed with attempts
   - Otherwise returns generic failure

### The Issue

The test sets up mocks for:
- `mockPrefs.getInt('admin_lockout_until')` → `null` (not locked locally)
- `mockPrefs.getInt('admin_login_attempts')` → `4` (4 previous attempts)

But the service:
1. Checks local lockout → `null` (passes)
2. Calls `_verifyCredentials()` → Creates `SupabaseService()` singleton
3. `SupabaseService.isAvailable` → Likely returns `false` (not mocked)
4. Returns `_VerifyResult(success: false, error: 'Backend service unavailable...')`
5. `verifyResult.lockedOut` → `false` (not set because Supabase unavailable)
6. `verifyResult.remainingAttempts` → `null` (not set)
7. Returns `AdminAuthResult.failed(error: ...)` → `lockedOut: false` ❌

**The test expects lockout behavior, but the service can't lockout because Supabase is unavailable.**

---

## Solution Options

### Option 1: Mock SupabaseService Singleton (RECOMMENDED)

Use `SupabaseService.useClientForTests()` to inject a mock client, then mock the edge function response.

**Steps:**
1. Import mockito and generate mocks for `SupabaseClient`, `FunctionsClient`
2. In `setUp`, create mock client and use `SupabaseService.useClientForTests(mockClient)`
3. Mock `mockClient.functions.invoke()` to return appropriate responses:
   - For test with 4 attempts: Return response with `lockedOut: true`
   - For other tests: Return appropriate responses
4. In `tearDown`, call `SupabaseService.resetClientForTests()`

**Pros:**
- Works with existing singleton pattern
- No code changes needed
- Follows pattern used in `supabase_service_test.dart`

**Cons:**
- Requires mocking Supabase client chain (client → functions → invoke)
- More complex mock setup

**Estimated Time:** 15-20 minutes

### Option 2: Refactor Service to Accept SupabaseService (NOT RECOMMENDED)

Change `AdminAuthService` constructor to accept `SupabaseService` as dependency.

**Steps:**
1. Add `SupabaseService? supabaseService` parameter to constructor
2. Use `supabaseService ?? SupabaseService()` in `_verifyCredentials`
3. In test, inject mock `SupabaseService`

**Pros:**
- Cleaner test setup
- Better dependency injection

**Cons:**
- Requires code changes to production service
- Breaks existing API
- More invasive change

**Estimated Time:** 30-40 minutes (including refactoring)

### Option 3: Test Local Lockout Logic Only (ALTERNATIVE)

Modify test to focus on local lockout behavior, not server-side lockout.

**Steps:**
1. Set `mockPrefs.getInt('admin_lockout_until')` to future timestamp
2. Verify service returns locked out without calling Supabase
3. Remove tests that require Supabase interaction

**Pros:**
- Simplest fix
- No mocking needed

**Cons:**
- Doesn't test full authentication flow
- Less comprehensive test coverage

**Estimated Time:** 5-10 minutes

---

## Recommended Solution: Option 1

### Implementation Steps

1. **Add imports and mocks:**
```dart
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:spots/core/services/supabase_service.dart';

import 'admin_auth_service_test.mocks.dart';

@GenerateMocks([SupabaseClient, FunctionsClient])
```

2. **Set up mocks in setUp:**
```dart
setUp(() {
  mockPrefs = MockSharedPreferencesCompat();
  
  // Create mock Supabase client
  final mockClient = MockSupabaseClient();
  final mockFunctions = MockFunctionsClient();
  
  when(() => mockClient.functions).thenReturn(mockFunctions);
  
  // Inject mock client into SupabaseService singleton
  SupabaseService.useClientForTests(mockClient);
  
  service = AdminAuthService(mockPrefs);
});
```

3. **Mock edge function responses:**
```dart
// For test with 4 attempts (should lockout)
when(() => mockFunctions.invoke(
  'admin-auth',
  body: anyNamed('body'),
)).thenAnswer((_) async => FunctionsResponse(
  data: {
    'success': false,
    'lockedOut': true,
    'lockoutRemaining': Duration(minutes: 15).inMilliseconds,
  },
  status: 429, // Too Many Requests
));
```

4. **Reset in tearDown:**
```dart
tearDown(() {
  SupabaseService.resetClientForTests();
});
```

5. **Generate mocks:**
```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## Test Cases to Fix

### Test 1: Invalid Credentials (Line 34-40)
**Current:** Fails because Supabase unavailable  
**Fix:** Mock `functions.invoke` to return `success: false, remainingAttempts: 4`

### Test 2: Lockout After Max Attempts (Line 42-48) ⚠️ **FAILING**
**Current:** Expects `lockedOut: true` but gets `false`  
**Fix:** Mock `functions.invoke` to return `success: false, lockedOut: true, lockoutRemaining: ...`

### Test 3: Already Locked Out (Line 50-59)
**Current:** Sets local lockout timestamp  
**Fix:** Should work, but may need Supabase mock for consistency

### Test 4: Successful Authentication (Line 61-75)
**Current:** Expects failure due to no credentials  
**Fix:** Mock `functions.invoke` to return `success: true` OR keep as-is (tests error handling)

---

## Files to Modify

1. **test/unit/services/admin_auth_service_test.dart**
   - Add mockito imports
   - Add `@GenerateMocks` annotation
   - Set up Supabase mocks in `setUp`
   - Mock edge function responses for each test case
   - Reset Supabase in `tearDown`

2. **Run build_runner:**
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
   This generates `admin_auth_service_test.mocks.dart`

---

## Verification

After fix:
- [ ] All 6 tests in `admin_auth_service_test.dart` pass
- [ ] No compilation errors
- [ ] Mocks properly isolate Supabase dependency
- [ ] Test covers both local and server-side lockout scenarios

---

## Alternative: Skip Supabase-Dependent Tests

If mocking Supabase is too complex, we can:
1. Mark tests that require Supabase as `skip: true` with explanation
2. Add integration tests that use real Supabase connection
3. Focus on testing local lockout logic only

**This would reduce test coverage but unblock progress.**

---

## Estimated Time

- **Option 1 (Recommended):** 15-20 minutes
- **Option 2 (Refactor):** 30-40 minutes  
- **Option 3 (Skip):** 5-10 minutes

**Recommendation:** Proceed with Option 1 for comprehensive test coverage.


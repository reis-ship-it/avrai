# Test Runtime Errors Analysis
**Date:** Current Session  
**Status:** Tests compile successfully, but runtime issues prevent full execution  
**Progress:** ✅ Compilation fixed → ⚠️ Runtime issues remain

---

## 📊 Executive Summary

**Good News:**
- ✅ All compilation errors fixed
- ✅ 20 tests passed successfully
- ✅ Tests are loading and running

**Remaining Issues:**
- ⚠️ 2 test failures (fixable)
- ⚠️ 8 tests "did not complete" (native library crashes)
- ⚠️ Test framework stream errors (cascading from crashes)

**Root Causes:**
1. **MissingPluginException** - FlutterSecureStorage requires platform channels in tests
2. **SIGABRT crashes** - Native libraries not available or incompatible
3. **Test expectations** - Tests expect specific exceptions but get different ones

---

## ✅ Success Metrics

- **20 tests passed** - Core functionality works
- **Tests compile** - No syntax or type errors
- **Test framework loads** - Infrastructure is working

---

## 🔴 Issue #1: MissingPluginException (Test Environment)

**File:** `test/core/crypto/signal/signal_protocol_service_test.dart`  
**Line:** 58-61  
**Test:** `initialize() throws when FFI bindings not implemented`  
**Status:** Test failure (expected exception mismatch)

### Problem:
```dart
test('initialize() throws when FFI bindings not implemented', () async {
  expect(
    () => service.initialize(),  // ← Calls service.initialize()
    throwsA(isA<SignalProtocolException>()),
  );
});
```

**What Happens:**
1. Test calls `service.initialize()`
2. Service calls `_keyManager.getOrGenerateIdentityKeyPair()`
3. KeyManager tries to read from `FlutterSecureStorage`
4. **FlutterSecureStorage throws `MissingPluginException`** (no platform channels in test)
5. Exception bubbles up before `SignalProtocolException` can be thrown
6. Test fails: Expected `SignalProtocolException`, got `MissingPluginException`

### Error Output:
```
Expected: throws <Instance of 'SignalProtocolException'>
  Actual: <Closure: () => Future<void>>
   Which: threw MissingPluginException:<MissingPluginException(No implementation found for method read on channel plugins.it_nomads.com/flutter_secure_storage)>
```

### Root Cause:
- `FlutterSecureStorage` requires platform channels (native code)
- Unit tests don't have platform channels available
- Service tries to use secure storage before it can throw the expected exception

### Solution Pattern (From Other Tests):
Other tests in the codebase use **mocked FlutterSecureStorage**:

```dart
// From test/integration/security_integration_test.dart
class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

setUp(() {
  mockSecureStorage = MockFlutterSecureStorage();
  
  // Mock read/write/delete operations
  when(() => mockSecureStorage.read(key: any(named: 'key')))
      .thenAnswer((invocation) async {
    final key = invocation.namedArguments[#key] as String;
    return keyStorage[key];
  });
  
  // Use mock instead of real FlutterSecureStorage
  keyManager = SignalKeyManager(
    secureStorage: mockSecureStorage,  // ← Use mock
    ffiBindings: ffiBindings,
  );
});
```

### Fix Required:
1. Add `mocktail` dependency (if not already present)
2. Create `MockFlutterSecureStorage` in test file
3. Mock `read()`, `write()`, `delete()` methods
4. Use mock instead of `const FlutterSecureStorage()` in `setUp()`

---

## 🔴 Issue #2: SIGABRT Crashes (Native Library Issues)

**Files Affected:**
- `signal_ffi_bindings_test.dart` (4 tests)
- `signal_ffi_prekey_bundle_test.dart` (1 test)
- `signal_protocol_integration_test.dart` (5 tests)

**Error:** `TestDeviceException(Shell subprocess crashed with SIGABRT (-6))`

### What is SIGABRT?
- **SIGABRT** = Signal Abort
- Native code (C/Rust) crashed
- Usually means:
  - Library not found
  - Library incompatible
  - Library loaded but function missing
  - Memory corruption

### Tests Affected:
1. `should generate identity key pair` - Tries to call native function
2. `should generate different identity key pairs on each call` - Tries to call native function
3. `should throw if not initialized` - May trigger library load
4. `generatePreKeyBundle should throw NOT_IMPLEMENTED` - Tries to call native function
5. `Identity key generation works when libraries available` - Tries to call native function
6. `Key manager can generate identity keys` - Tries to call native function
7. `Graceful degradation when libraries unavailable` - May trigger library load
8. `Operations throw when not initialized` - May trigger library load

### Root Cause Analysis:

**Scenario A: Library Not Found**
- Tests try to `initialize()` FFI bindings
- `DynamicLibrary.open()` fails (library doesn't exist)
- Should throw `SignalProtocolException` (expected)
- But if library partially loads, then crashes → SIGABRT

**Scenario B: Library Incompatible**
- Library exists but wrong architecture (arm64 vs x86_64)
- Library loads but functions missing
- Calling missing function → SIGABRT

**Scenario C: Library Loaded But Broken**
- Library loads successfully
- Function pointer obtained
- Calling function with wrong parameters → SIGABRT

### Current Test Behavior:
Tests are designed to handle missing libraries gracefully:
```dart
try {
  await ffiBindings.initialize();
} catch (e) {
  // Expected if libraries not available - skip test
  return;
}
```

**But:** If library loads but is broken, tests continue and crash when calling functions.

### Expected vs Actual:
- **Expected:** Library missing → `SignalProtocolException` → Test skips gracefully
- **Actual:** Library partially loads → Test continues → Calls function → SIGABRT crash

### Solution Options:

**Option A: Better Error Detection (Recommended)**
Add checks before calling native functions:
```dart
test('should generate identity key pair', () async {
  try {
    await ffiBindings.initialize();
    if (!ffiBindings.isInitialized) {
      return; // Skip if not initialized
    }
    
    // Add safety check: verify function pointer exists
    // (This would require exposing function pointer getters)
    
    final identityKeyPair = await ffiBindings.generateIdentityKeyPair();
    // ...
  } catch (e) {
    if (e is SignalProtocolException) {
      return; // Expected - skip test
    }
    // Unexpected error - rethrow
    rethrow;
  }
});
```

**Option B: Skip Tests If Libraries Not Built**
Add test group skip if libraries don't exist:
```dart
group('SignalFFIBindings - Identity Key Generation', () {
  setUpAll(() {
    // Check if library exists
    final libPath = 'native/signal_ffi/macos/libsignal_ffi.dylib';
    final libFile = File(libPath);
    if (!libFile.existsSync()) {
      // Skip all tests in this group
      skip('Native libraries not built. Run: ./scripts/build_signal_ffi_macos.sh');
    }
  });
  // ...
});
```

**Option C: Mock FFI Bindings for Unit Tests**
Create mock implementations for testing without native libraries:
```dart
class MockSignalFFIBindings extends Mock implements SignalFFIBindings {}
```

---

## ⚠️ Issue #3: Stream Channel Errors (Cascading)

**Error:** `Bad state: Cannot add event while adding stream.`

**Files Affected:**
- `signal_ffi_bindings_test.dart`
- `signal_ffi_prekey_bundle_test.dart`

### What's Happening:
1. Test starts running
2. Native library crash (SIGABRT) occurs
3. Test framework tries to report error
4. Stream channel is in bad state (already processing)
5. Framework can't add error event → "Cannot add event while adding stream"

### Root Cause:
- **Cascading error** from Issue #2 (SIGABRT crashes)
- Test framework can't handle crash gracefully
- Stream channel gets into invalid state

### Impact:
- Tests that crash also generate stream errors
- Makes error messages harder to read
- Doesn't prevent other tests from running

### Solution:
- **Fix Issue #2 first** (SIGABRT crashes)
- Stream errors will disappear once crashes are handled gracefully
- No direct fix needed - it's a symptom, not the cause

---

## 📋 Summary of Issues

| Issue | Severity | Tests Affected | Fix Complexity |
|-------|----------|----------------|----------------|
| MissingPluginException | Medium | 1 test | Easy (use mock) |
| SIGABRT Crashes | High | 8 tests | Medium (better error handling) |
| Stream Channel Errors | Low | 2 tests | None (cascading, will fix with #2) |

---

## ✅ Recommended Fix Order

### Priority 1: Fix MissingPluginException (Quick Win)
**Time:** 5-10 minutes  
**Impact:** 1 test fixed

1. Add mocktail import (if needed)
2. Create `MockFlutterSecureStorage` class
3. Mock `read()`, `write()`, `delete()` methods
4. Use mock in `setUp()` instead of real `FlutterSecureStorage`

### Priority 2: Handle SIGABRT Crashes Gracefully
**Time:** 20-30 minutes  
**Impact:** 8 tests fixed

**Option A (Recommended):** Add library existence checks
1. Check if library file exists before initializing
2. Skip tests if library not found
3. Add clear skip messages

**Option B:** Improve error handling
1. Wrap native function calls in try-catch
2. Catch `SignalProtocolException` and skip gracefully
3. Re-throw unexpected errors

**Option C:** Mock FFI bindings
1. Create mock implementations
2. Use mocks for unit tests
3. Keep real bindings for integration tests

### Priority 3: Stream Errors (Automatic)
**Time:** 0 minutes  
**Impact:** Will fix automatically when SIGABRT crashes are handled

---

## 🎯 Expected Outcome After Fixes

- **21 tests passing** (currently 20, +1 from MissingPluginException fix)
- **8 tests skipped gracefully** (instead of crashing)
- **0 crashes** (SIGABRT handled)
- **0 stream errors** (cascading issue resolved)

---

## 📝 Files to Modify

1. **`test/core/crypto/signal/signal_protocol_service_test.dart`**
   - Add `MockFlutterSecureStorage`
   - Use mock in `setUp()`

2. **`test/core/crypto/signal/signal_ffi_bindings_test.dart`**
   - Add library existence check in `setUpAll()`
   - Improve error handling in tests

3. **`test/core/crypto/signal/signal_ffi_prekey_bundle_test.dart`**
   - Add library existence check in `setUpAll()`
   - Improve error handling in tests

4. **`test/core/crypto/signal/signal_protocol_integration_test.dart`**
   - Add library existence check in `setUpAll()`
   - Improve error handling in tests

---

## 🔍 Verification Steps

After fixes:
1. Run: `flutter test test/core/crypto/signal/`
2. Verify: No SIGABRT crashes
3. Verify: Tests skip gracefully with clear messages
4. Verify: MissingPluginException test passes
5. Verify: Stream errors are gone

---

## 💡 Key Insights

1. **Tests are working** - 20 passing is great progress!
2. **Compilation fixed** - Major blocker resolved
3. **Runtime issues are expected** - Native libraries need to be built
4. **Graceful degradation needed** - Tests should skip, not crash
5. **Mocking pattern exists** - Other tests show the way forward

---

## 🚀 Next Steps

1. **Quick fix:** Add mock for FlutterSecureStorage (5 min)
2. **Medium fix:** Add library checks to skip tests gracefully (20 min)
3. **Verify:** Run tests and confirm graceful skipping
4. **Document:** Update test documentation with skip requirements

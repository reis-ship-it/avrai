# Tests That Cannot Run - Detailed Report

**Date:** November 20, 2025, 3:20 PM CST  
**Purpose:** Comprehensive analysis of tests that cannot run and why

---

## Executive Summary

**Total Tests That Cannot Run:** **93 tests** across 5 test files

**Breakdown:**
- **Onboarding Integration Test:** **5 tests** (code compilation errors)
- **Repository Tests:** **84 tests** (missing mock files)
  - `auth_repository_impl_test.dart`: 35 tests
  - `lists_repository_impl_test.dart`: 27 tests
  - `spots_repository_impl_test.dart`: 22 tests
- **Personality Advertising Service Test:** **4 tests** (platform channel limitation)

---

## Detailed Analysis

### 1. Onboarding Integration Test ⚠️ **CODE COMPILATION ERRORS**

**File:** `test/integration/onboarding_flow_integration_test.dart`  
**Tests Affected:** **5 tests** (all tests in file)

**Why They Cannot Run:**
The test file itself is correct, but the **codebase has compilation errors** that prevent the test from even loading:

1. **Missing Type: `InteractionType`**
   - **Location:** `lib/presentation/pages/admin/connection_communication_detail_page.dart:526`
   - **Error:** `Type 'InteractionType' not found`
   - **Impact:** Code cannot compile, so tests cannot load

2. **Missing Type: `InteractionEvent`**
   - **Location:** `lib/presentation/pages/admin/connection_communication_detail_page.dart:459`
   - **Error:** `Type 'InteractionEvent' not found`
   - **Impact:** Code cannot compile, so tests cannot load

3. **Missing Constructor: `SPOTSApp`**
   - **Location:** `test/integration/onboarding_flow_integration_test.dart` (multiple lines)
   - **Error:** `Couldn't find constructor 'SPOTSApp'`
   - **Impact:** Test cannot instantiate the app widget

**Root Cause:** Codebase has incomplete or missing type definitions and constructors. These are **code issues, not test issues**.

**Status:** Test file is correct. Codebase needs fixes before tests can run.

**Fix Required:** 
- Define `InteractionType` enum/class
- Define `InteractionEvent` class
- Fix `SPOTSApp` constructor or import

---

### 2. Repository Tests ⏳ **MISSING MOCK FILES**

**Files:**
- `test/unit/repositories/auth_repository_impl_test.dart` - **35 tests**
- `test/unit/repositories/lists_repository_impl_test.dart` - **27 tests**
- `test/unit/repositories/spots_repository_impl_test.dart` - **22 tests**

**Total Tests Affected:** **84 tests**

**Why They Cannot Run:**
Tests cannot compile because they depend on generated mock files that don't exist:

1. **Missing Mock File:**
   - **File:** `test/mocks/mock_dependencies.dart.mocks.dart`
   - **Error:** `Error when reading 'test/mocks/mock_dependencies.dart.mocks.dart': No such file or directory`
   - **Impact:** Tests cannot import required mock classes

2. **Missing Mock Classes:**
   - `MockAuthLocalDataSource`
   - `MockAuthRemoteDataSource`
   - `MockConnectivity`
   - And other mocks from `mock_dependencies.dart`

3. **Additional Compilation Errors:**
   - `ModelFactories.createUserWithRole` method not found
   - Type mismatches (`UnifiedUser` vs `User`)
   - Missing named parameters

**Root Cause:** 
- `build_runner` cannot generate mock files because template files (`test/templates/*.dart`) contain placeholder syntax (`[ServiceName]`, `[Component]`) that breaks the build process
- Build_runner scans all Dart files and fails when encountering invalid syntax in templates

**Status:** ⏳ **DEFERRED** - Low priority, blocked by template syntax issue

**Fix Options:**
1. Create `build.yaml` to exclude `test/templates/` directory from build_runner
2. Move templates outside test directory
3. Rename templates to non-Dart extension (e.g., `.template.dart`)
4. Use manual mocks instead of generated mocks

**Estimated Effort:** 30 minutes (once template issue resolved)

---

### 3. Personality Advertising Service Test ⚠️ **PLATFORM CHANNEL LIMITATION**

**File:** `test/unit/network/personality_advertising_service_test.dart`  
**Tests Affected:** **4 tests**

**Why They Cannot Run:**
Tests fail at runtime due to platform channel requirements:

1. **GetStorage Initialization Failure:**
   - **Error:** `LateInitializationError: Local 'compatPrefs' has not been initialized`
   - **Root Cause:** `GetStorage.init()` requires platform channels (`path_provider`) which are not available in unit test environments
   - **Impact:** Tests fail during setup/initialization

2. **Platform Channel Dependency:**
   - `SharedPreferencesCompat.getInstance()` calls `StorageService.instance.init()`
   - Which calls `GetStorage.init()`
   - Which requires `path_provider` platform channel
   - Platform channels are only available in integration tests or on actual devices/emulators

**Status:** ⚠️ **DOCUMENTED LIMITATION** - Expected behavior for unit tests

**Fix Options:**
1. Run as integration test: `flutter test --platform=chrome` or on device/emulator
2. Mock GetStorage: Create test-friendly mock that doesn't require platform channels
3. Dependency Injection: Allow injecting test-friendly storage implementation
4. Test Helper: Create helper that initializes storage differently for tests

**Estimated Effort:** 4-6 hours (to create proper test infrastructure)

**Current Status:** Documented as known limitation. Test requires integration test environment.

---

## Summary Table

| Test File | Tests Affected | Reason | Type | Fix Required |
|-----------|---------------|--------|------|--------------|
| `onboarding_flow_integration_test.dart` | **5** | Code compilation errors | Code Issue | Fix `InteractionType`, `InteractionEvent`, `SPOTSApp` |
| `auth_repository_impl_test.dart` | **35** | Missing mock files | Build Issue | Fix template syntax or use manual mocks |
| `lists_repository_impl_test.dart` | **27** | Missing mock files | Build Issue | Fix template syntax or use manual mocks |
| `spots_repository_impl_test.dart` | **22** | Missing mock files | Build Issue | Fix template syntax or use manual mocks |
| `personality_advertising_service_test.dart` | **4** | Platform channel limitation | Test Environment | Run as integration test or mock GetStorage |

**Total:** **93 tests cannot run**

---

## Impact Assessment

### High Impact (Blocks Tests)
1. **Repository Tests (84 tests)** - Missing mock files prevent compilation
   - **Priority:** Medium (largest number of blocked tests)
   - **Effort:** Low (30 minutes once template issue resolved)
   - **Workaround:** Can use manual mocks instead of generated mocks

2. **Onboarding Integration Test (5 tests)** - Code compilation errors prevent all tests from running
   - **Priority:** High (code issue needs fixing)
   - **Effort:** Medium (need to define missing types/constructors)

### Low Impact (Documented Limitation)
3. **Personality Advertising Service Test (4 tests)** - Platform channel limitation
   - **Priority:** Low (documented limitation, expected behavior)
   - **Effort:** Medium (4-6 hours for proper test infrastructure)
   - **Workaround:** Run as integration test (`flutter test --platform=chrome`)

---

## Recommendations

### Immediate Actions
1. **Fix Template Syntax Issue** (Repository Tests - 84 tests)
   - Create `build.yaml` to exclude templates from build_runner
   - Or move/rename template files
   - **Impact:** Unblocks **84 tests** (largest impact)

2. **Fix Code Compilation Errors** (Onboarding Test - 5 tests)
   - Define `InteractionType` enum/class
   - Define `InteractionEvent` class  
   - Fix `SPOTSApp` constructor
   - **Impact:** Unblocks **5 tests**

### Long-term Actions
3. **Create Test Infrastructure** (Personality Advertising Test)
   - Mock GetStorage or use dependency injection
   - **Impact:** Enables ~3-5 tests to run in unit test environment

---

## Conclusion

**Total Tests That Cannot Run:** ~50+ tests

**Breakdown by Issue Type:**
- **Code Compilation Errors:** **5 tests** (need code fixes)
- **Missing Mock Files:** **84 tests** (need build_runner fix)
- **Platform Channel Limitation:** **4 tests** (documented limitation)

**All issues are fixable**, but require different approaches:
- Code issues need code fixes
- Build issues need build configuration fixes
- Platform limitations need test infrastructure improvements

---

**Last Updated:** November 20, 2025, 3:20 PM CST


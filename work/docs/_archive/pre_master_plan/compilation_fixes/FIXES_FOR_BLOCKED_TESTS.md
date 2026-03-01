# Fixes for All Blocked Tests

**Date:** November 20, 2025, 3:25 PM CST  
**Purpose:** Step-by-step fixes for all 93 blocked tests

---

## Quick Summary

| Issue | Tests | Fix Time | Priority |
|-------|-------|----------|----------|
| Missing Mock Files | 84 | 5 minutes | High |
| Code Compilation Errors | 5 | 10 minutes | High |
| Platform Channel Limitation | 4 | 30 minutes | Medium |

---

## Fix 1: Repository Tests (84 tests) - Missing Mock Files

### Problem
`build_runner` cannot generate mock files because template files contain placeholder syntax that breaks the build.

### Solution: Exclude Templates from build_runner

**Step 1:** Create `build.yaml` in project root:

```yaml
targets:
  $default:
    sources:
      exclude:
        - test/templates/**
```

**Step 2:** Generate mock files:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

**Step 3:** Verify tests compile:

```bash
flutter test test/unit/repositories/ --no-pub
```

**Alternative Solution:** If `build.yaml` doesn't work, rename template files:

```bash
cd test/templates
mv service_test_template.dart service_test_template.dart.txt
mv unit_test_template.dart unit_test_template.dart.txt
mv widget_test_template.dart widget_test_template.dart.txt
mv integration_test_template.dart integration_test_template.dart.txt
```

Then run `build_runner` again.

**Impact:** ✅ Unblocks **84 tests**

---

## Fix 2: Onboarding Integration Test (5 tests) - Code Compilation Errors

### Problem
Missing imports and incorrect class name in test file.

### Solution: Fix Imports and Class Name

**Step 1:** Fix `test/integration/onboarding_flow_integration_test.dart`:

```dart
// Add these imports at the top
import 'package:spots/app.dart';  // For SpotsApp (not SPOTSApp)
import 'package:spots/core/models/connection_metrics.dart';  // For InteractionType, InteractionEvent
```

**Step 2:** Replace all instances of `SPOTSApp` with `SpotsApp`:

```dart
// Change this:
await tester.pumpWidget(const SPOTSApp());

// To this:
await tester.pumpWidget(const SpotsApp());
```

**Step 3:** Fix `lib/presentation/pages/admin/connection_communication_detail_page.dart`:

Add import at the top:

```dart
import 'package:spots/core/models/connection_metrics.dart';
```

**Step 4:** Verify the file compiles:

```bash
flutter analyze lib/presentation/pages/admin/connection_communication_detail_page.dart
```

**Step 5:** Run the test:

```bash
flutter test test/integration/onboarding_flow_integration_test.dart --no-pub
```

**Impact:** ✅ Unblocks **5 tests**

---

## Fix 3: Personality Advertising Service Test (4 tests) - Platform Channel Limitation

### Problem
`GetStorage.init()` requires platform channels not available in unit tests.

### Solution: Mock GetStorage

**Option A: Run as Integration Test (Quick Fix)**

```bash
flutter test test/unit/network/personality_advertising_service_test.dart --platform=chrome
```

**Option B: Create Mock Storage (Better Fix)**

**Step 1:** Create `test/mocks/mock_storage_service.dart`:

```dart
import 'package:get_storage/get_storage.dart';

class MockGetStorage extends GetStorage {
  static final Map<String, dynamic> _storage = {};
  
  @override
  Future<void> write(String key, dynamic value) async {
    _storage[key] = value;
  }
  
  @override
  T? read<T>(String key) {
    return _storage[key] as T?;
  }
  
  @override
  Future<void> remove(String key) async {
    _storage.remove(key);
  }
  
  @override
  Future<void> erase() async {
    _storage.clear();
  }
  
  static void reset() {
    _storage.clear();
  }
}
```

**Step 2:** Update `test/unit/network/personality_advertising_service_test.dart`:

```dart
import 'test/mocks/mock_storage_service.dart';

setUpAll(() async {
  // Use mock storage instead of real GetStorage
  GetStorage.init = () async => MockGetStorage();
  compatPrefs = await SharedPreferencesCompat.getInstance();
});
```

**Option C: Use Dependency Injection (Best Fix)**

Modify `SharedPreferencesCompat` to accept a storage instance:

```dart
// In lib/core/services/storage_service.dart
class SharedPreferencesCompat {
  static GetStorage? _storageInstance;
  
  static Future<SharedPreferencesCompat> getInstance({GetStorage? storage}) async {
    if (storage != null) {
      _storageInstance = storage;
    } else {
      await GetStorage.init();
      _storageInstance = GetStorage();
    }
    return SharedPreferencesCompat._(_storageInstance!);
  }
}
```

Then in test:

```dart
setUpAll(() async {
  final mockStorage = MockGetStorage();
  compatPrefs = await SharedPreferencesCompat.getInstance(storage: mockStorage);
});
```

**Impact:** ✅ Unblocks **4 tests**

---

## Complete Fix Script

Run all fixes in sequence:

```bash
#!/bin/bash

echo "Fix 1: Creating build.yaml to exclude templates..."
cat > build.yaml << 'EOF'
targets:
  $default:
    sources:
      exclude:
        - test/templates/**
EOF

echo "Fix 2: Generating mock files..."
flutter pub run build_runner build --delete-conflicting-outputs

echo "Fix 3: Fixing onboarding test imports..."
# This would need manual editing - see Fix 2 above

echo "Fix 4: Running tests..."
flutter test test/unit/repositories/ --no-pub
flutter test test/integration/onboarding_flow_integration_test.dart --no-pub
flutter test test/unit/network/personality_advertising_service_test.dart --platform=chrome

echo "Done!"
```

---

## Verification

After applying fixes, verify all tests can run:

```bash
# Repository tests
flutter test test/unit/repositories/ --no-pub

# Onboarding test
flutter test test/integration/onboarding_flow_integration_test.dart --no-pub

# Personality advertising test (as integration test)
flutter test test/unit/network/personality_advertising_service_test.dart --platform=chrome
```

---

## Expected Results

After fixes:
- ✅ **84 repository tests** should compile and run
- ✅ **5 onboarding tests** should compile and run
- ✅ **4 personality advertising tests** should run (as integration tests or with mocks)

**Total:** **93 tests** should be unblocked

---

**Last Updated:** November 20, 2025, 3:25 PM CST


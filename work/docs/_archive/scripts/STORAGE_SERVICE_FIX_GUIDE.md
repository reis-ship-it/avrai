# StorageService Mock Setup Fix Guide

**Date:** December 7, 2025  
**Purpose:** Guide for automatically fixing StorageService initialization in test files  
**Impact:** Fixes ~100+ test failures related to "StorageService not initialized"

---

## Quick Start

### 1. Run Analysis (Dry Run)

```bash
# See what files need fixing
python3 scripts/fix_storage_service_setup.py --dry-run
```

### 2. Apply Fixes

```bash
# Fix all files automatically
python3 scripts/fix_storage_service_setup.py

# Fix specific files
python3 scripts/fix_storage_service_setup.py --files test/unit/services/neighborhood_boundary_service_test.dart
```

---

## What the Script Does

### Automatically Adds:

1. **Required Import:**
   ```dart
   import '../../helpers/platform_channel_helper.dart';
   ```

2. **Setup Code:**
   ```dart
   setUpAll(() async {
     await setupTestStorage();
   });
   ```

### Files It Fixes:

- Test files that use `StorageService.instance`
- Test files that test services using StorageService internally:
  - `NeighborhoodBoundaryService`
  - `ActionHistoryService`
  - `UserAnonymizationService`

---

## How It Works

### Detection

The script finds test files that:
1. Use `StorageService.instance` directly
2. Test services known to use StorageService internally
3. Have methods that call storage (e.g., `saveBoundary`, `_saveBoundaryToStorage`)

### Fix Pattern

For each file that needs fixing:

1. **Adds import** (if missing):
   ```dart
   import '../../helpers/platform_channel_helper.dart';
   ```

2. **Adds setUpAll** (if missing):
   ```dart
   setUpAll(() async {
     await setupTestStorage();
   });
   ```

3. **Preserves existing code** - doesn't modify test logic

---

## Example: Before and After

### Before (Fails with "StorageService not initialized")

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/services/neighborhood_boundary_service.dart';

void main() {
  group('NeighborhoodBoundaryService Tests', () {
    late NeighborhoodBoundaryService service;
    
    setUp(() {
      service = NeighborhoodBoundaryService();
    });
    
    test('should save boundary', () async {
      // This will fail: StorageService not initialized
      await service.saveBoundary(...);
    });
  });
}
```

### After (Fixed)

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/services/neighborhood_boundary_service.dart';
import '../../helpers/platform_channel_helper.dart';  // ← Added

void main() {
  setUpAll(() async {  // ← Added
    await setupTestStorage();
  });
  
  group('NeighborhoodBoundaryService Tests', () {
    late NeighborhoodBoundaryService service;
    
    setUp(() {
      service = NeighborhoodBoundaryService();
    });
    
    test('should save boundary', () async {
      // Now works: StorageService is initialized
      await service.saveBoundary(...);
    });
  });
}
```

---

## Manual Fixes (If Script Doesn't Work)

### Option 1: Use setupTestStorage()

```dart
import '../../helpers/platform_channel_helper.dart';

void main() {
  setUpAll(() async {
    await setupTestStorage();
  });
  
  // ... tests
}
```

### Option 2: Use Mock Storage Directly (For Services with Dependency Injection)

```dart
import '../../mocks/mock_storage_service.dart';

void main() {
  setUp(() {
    final mockStorage = MockGetStorage.getInstance();
    MockGetStorage.reset();
    
    // If service accepts storage as dependency:
    service = MyService(storage: mockStorage);
  });
}
```

### Option 3: Wrap Tests (For Services That Can't Be Mocked)

```dart
import '../../helpers/platform_channel_helper.dart';

void main() {
  test('my test', () async {
    await runTestWithPlatformChannelHandling(() async {
      // Test code that uses StorageService
    });
  });
}
```

---

## Troubleshooting

### Script Says "Already Fixed" But Tests Still Fail

1. Check if `setUpAll` is actually being called
2. Verify the import path is correct for your test location
3. Try running tests to see the actual error

### Import Path Issues

The script calculates relative paths automatically:
- `test/unit/...` → `../../helpers/platform_channel_helper.dart`
- `test/integration/...` → `../helpers/platform_channel_helper.dart`
- `test/...` → `helpers/platform_channel_helper.dart`

### setUpAll vs setUp

- **setUpAll**: Runs once before all tests (use for storage initialization)
- **setUp**: Runs before each test (use for test-specific setup)

The script uses `setUpAll` for storage initialization.

---

## Expected Results

### After Running Script:

- **Files Fixed:** ~7-10 test files
- **Failures Resolved:** ~100+ test failures
- **Pass Rate Improvement:** +3-5 percentage points

### Verification:

```bash
# Check progress
./scripts/fix_test_pass_rate.sh --progress

# Should show fewer failures
```

---

## Related Files

- `scripts/fix_storage_service_setup.py` - The fix script
- `test/helpers/platform_channel_helper.dart` - Helper functions
- `test/mocks/mock_storage_service.dart` - Mock storage implementation
- `lib/core/services/storage_service.dart` - StorageService implementation

---

**Last Updated:** December 7, 2025


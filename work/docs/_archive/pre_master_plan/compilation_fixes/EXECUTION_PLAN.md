# Execution Plan: Fix Compilation Errors

**Date:** November 19, 2025  
**Total Errors:** ~1,333  
**Strategy:** Systematic root cause fixes  
**Time:** 8-10 hours

---

## 🎯 **PHASE 1: QUICK WINS** (1 hour) - **~75 errors**

### **1.1 Fix ExpertiseLevel Method Access** (30 min)
**Root Cause:** Methods exist but compiler doesn't see them (likely import or extension issue)

**Files to Check:**
- `lib/core/services/expert_search_service.dart`
- `lib/core/services/expertise_matching_service.dart`
- `lib/core/services/expertise_network_service.dart`
- `lib/core/services/mentorship_service.dart`

**Fix:**
1. Ensure `ExpertiseLevel` is imported: `import 'package:spots/core/models/expertise_level.dart';`
2. Methods `isHigherThan` and `isLowerThan` exist in enum - verify they're accessible
3. If extension needed, ensure it's imported

**Expected:** ~8 errors fixed

---

### **1.2 Fix ExpertiseLevel Static Access** (20 min)
**Root Cause:** `displayName` accessed as static but it's instance getter

**Files:**
- `lib/core/models/expertise_pin.dart:78` - Already correct (instance access)
- `lib/core/models/expertise_progress.dart:40, 43, 48` - Already correct (instance access)

**Fix:** These are already correct! The issue might be elsewhere. Check if `nextLevel` is null.

**Expected:** ~3 errors fixed (if any)

---

### **1.3 Fix Spot Import** (10 min)
**File:** `lib/core/services/community_validation_service.dart:32`

**Fix:**
```dart
import 'package:spots/core/models/spot.dart';  // Add this import
```

**Expected:** ~1 error fixed

---

### **1.4 Fix UnifiedList Import** (5 min)
**File:** `lib/core/services/community_validation_service.dart:78`

**Fix:**
```dart
import 'package:spots/core/models/unified_list.dart';  // Add this import
```

**Expected:** ~1 error fixed

---

### **1.5 Fix Spot Ambiguous Import** (15 min)
**File:** `lib/data/datasources/remote/google_places_datasource_new_impl.dart`

**Fix:**
```dart
// Use selective import to avoid ambiguity
import 'package:spots/core/models/spot.dart' show Spot;
// OR
import 'package:spots_core/spots_core.dart' hide Spot;
import 'package:spots/core/models/spot.dart' show Spot;
```

**Expected:** ~10 errors fixed

---

## 🔧 **PHASE 2: MISSING CLASSES** (2 hours) - **~200 errors**

### **2.1 Fix SpotValidationSummary Constructor** (15 min)
**File:** `lib/core/models/community_validation.dart:172`

**Issue:** Constructor `_unvalidated` doesn't exist

**Fix Options:**
1. Add named constructor `SpotValidationSummary._unvalidated()`
2. Or change usage to use existing constructor

**Check:** Read `SpotValidationSummary` class definition

---

### **2.2 Create Test Mock Classes** (1.5 hours)

**Mocks Needed:**
- `MockAuthLocalDataSource`
- `MockAuthRemoteDataSource`
- `MockAuthRepository`
- `MockConnectivity`
- `MockCreateListUseCase`
- `MockCreateSpotUseCase`
- `MockListsLocalDataSource`
- `MockListsRemoteDataSource`
- `MockListsRepository`
- `MockSpotsLocalDataSource`
- `MockSpotsRemoteDataSource`
- `MockSpotsRepository`

**Strategy:**
1. Check if `@GenerateMocks` annotation exists
2. If yes, run code generation: `flutter pub run build_runner build`
3. If no, create manual mocks or add annotations

---

### **2.3 Fix Other Undefined Classes** (15 min)

**Classes to Check:**
- `AI2AIChatAnalyzer` - Check if exists, fix import
- `AIPersonalityNode` - Check if exists, fix import
- `AndroidDeviceDiscovery` - Exists, check import
- `IOSDeviceDiscovery` - Exists, check import
- `BlocTest` - Test helper, check import
- `ConnectionMetrics` - Exists, check import
- `ListType` - Enum, check import

**Fix:** Add correct imports or create stubs

---

## 🔨 **PHASE 3: CONSTRUCTOR FIXES** (3 hours) - **~300 errors**

### **3.1 Identify Patterns** (30 min)
Run analysis to find most common constructor errors:
```bash
flutter analyze --no-fatal-infos 2>&1 | grep "undefined_named_parameter" | awk -F"'" '{print $2}' | sort | uniq -c | sort -rn | head -20
```

### **3.2 Fix Systematically** (2.5 hours)
Fix classes with most errors first, working down the list.

---

## 📦 **PHASE 4: IMPORT FIXES** (2 hours) - **~400 errors**

### **4.1 Batch Fix Wrong Paths** (1 hour)
Use find/replace for common wrong paths:
- `package:spots/core/services/business/ai/*` → `package:spots/core/ai/*`
- `package:spots/core/services/business/ml/*` → `package:spots/core/ml/*`

### **4.2 Fix Ambiguous Imports** (30 min)
Add `show` clauses to resolve ambiguities

### **4.3 Add Missing Imports** (30 min)
Use IDE or manual fixes

---

## 🧹 **PHASE 5: REMAINING** (2 hours) - **~300 errors**

Fix remaining issues systematically.

---

## ⚡ **IMMEDIATE ACTION ITEMS**

1. **Fix ExpertiseLevel imports** - Check all files using ExpertiseLevel
2. **Fix Spot/UnifiedList imports** - Add missing imports
3. **Fix Spot ambiguity** - Use selective imports
4. **Fix SpotValidationSummary** - Add constructor or fix usage
5. **Generate test mocks** - Run build_runner or create manually

---

**Start with Phase 1 - highest ROI!**


# Phase 3.3.3: Move Core Utilities to spots_core Package

**Date:** January 2025  
**Status:** 🟡 **IN PROGRESS**  
**Phase:** 3.3.3 - Core Utilities Migration

---

## 🎯 **GOAL**

Move core utility services and models from `lib/core/services/` and `lib/core/models/` to `packages/spots_core/` to improve code organization and package structure.

---

## 📋 **FILES TO MOVE**

### **Services:**
1. `lib/core/services/atomic_clock_service.dart` → `packages/spots_core/lib/services/atomic_clock_service.dart`

### **Models (required dependency):**
2. `lib/core/models/atomic_timestamp.dart` → `packages/spots_core/lib/models/atomic_timestamp.dart`
   - **Reason:** `atomic_clock_service` depends on this model, so both should move together

---

## 📊 **DEPENDENCY ANALYSIS**

### **atomic_clock_service.dart Dependencies:**
- ✅ `dart:developer` - Standard library (no change needed)
- ✅ `dart:async` - Standard library (no change needed)
- ⚠️ `package:spots/core/models/atomic_timestamp.dart` - **MUST MOVE** (see above)
- ⚠️ `package:timezone/timezone.dart` - External package (needs to be added to spots_core pubspec.yaml)

### **atomic_timestamp.dart Dependencies:**
- ✅ No external dependencies (uses only Dart standard library)

### **Usage Analysis:**
- **atomic_clock_service:** Used by 31 production files + many test files
- **atomic_timestamp:** Used by 18 production files + many test files
- **Import pattern:** `package:spots/core/services/atomic_clock_service.dart` → `package:spots_core/services/atomic_clock_service.dart`

---

## 🔄 **MIGRATION STEPS**

### **Step 1: Update spots_core Package Dependencies**
- [ ] Add `timezone: ^0.9.2` to `packages/spots_core/pubspec.yaml`

### **Step 2: Create Directory Structure**
- [ ] Create `packages/spots_core/lib/services/` directory (if doesn't exist)
- [ ] Models directory already exists: `packages/spots_core/lib/models/`

### **Step 3: Move atomic_timestamp Model First**
- [ ] Copy `lib/core/models/atomic_timestamp.dart` → `packages/spots_core/lib/models/atomic_timestamp.dart`
- [ ] Update imports in moved file (none needed - no dependencies)
- [ ] Update `packages/spots_core/lib/spots_core.dart` to export the model

### **Step 4: Move atomic_clock_service**
- [ ] Copy `lib/core/services/atomic_clock_service.dart` → `packages/spots_core/lib/services/atomic_clock_service.dart`
- [ ] Update import in service file: `package:spots/core/models/atomic_timestamp.dart` → `package:spots_core/models/atomic_timestamp.dart`
- [ ] Update `packages/spots_core/lib/spots_core.dart` to export the service

### **Step 5: Update All Imports Across Codebase**
- [ ] Update imports in production files (31 files for atomic_clock_service)
- [ ] Update imports in test files
- [ ] Update imports in injection containers (injection_container.dart, injection_container_core.dart, injection_container_ai.dart, injection_container_knot.dart, injection_container_quantum.dart)
- [ ] Update imports in package files (spots_quantum, spots_knot packages that import atomic_clock_service)

**Import changes:**
- `package:spots/core/services/atomic_clock_service.dart` → `package:spots_core/services/atomic_clock_service.dart`
- `package:spots/core/models/atomic_timestamp.dart` → `package:spots_core/models/atomic_timestamp.dart`

### **Step 6: Verify Compilation**
- [ ] Run `flutter pub get` in spots_core package
- [ ] Run `dart analyze packages/spots_core` to check for errors
- [ ] Run `dart analyze lib` to check for errors
- [ ] Fix any import issues

### **Step 7: Delete Old Files**
- [ ] Delete `lib/core/services/atomic_clock_service.dart`
- [ ] Delete `lib/core/models/atomic_timestamp.dart`
- [ ] Verify no remaining references to old locations

### **Step 8: Final Verification**
- [ ] Verify no old import paths remain (grep check)
- [ ] Run full test suite (if applicable)
- [ ] Document completion

---

## ⚠️ **CRITICAL NOTES**

1. **Atomic Timestamp Must Move First:** Since `atomic_clock_service` depends on `atomic_timestamp`, the model must be moved and exported before the service.

2. **Timezone Package:** Must be added to `spots_core/pubspec.yaml` as a dependency.

3. **Package Exports:** Both files must be exported in `packages/spots_core/lib/spots_core.dart` for easy importing.

4. **Wide Usage:** This service is used across many packages (spots_quantum, spots_knot) - all imports need updating.

---

## 📊 **ESTIMATED EFFORT**

- **Analysis & Planning:** 30 minutes ✅
- **Move Files:** 15 minutes
- **Update Package Config:** 15 minutes
- **Update Imports:** 1-2 hours (31+ production files + tests + packages)
- **Verification:** 30 minutes
- **Total:** 2.5-3.5 hours

---

**Reference:** `CODEBASE_REFACTORING_AUDIT_2025-01.md` Section 3.3

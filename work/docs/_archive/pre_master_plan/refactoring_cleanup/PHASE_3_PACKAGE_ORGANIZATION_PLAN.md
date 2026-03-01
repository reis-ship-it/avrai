# Phase 3: Package Organization - Implementation Plan

**Date:** January 2025  
**Status:** 🟡 In Progress  
**Phase:** 3.1 - Moving Knot Models  
**Estimated Effort:** 4-6 hours (from audit)

---

## 🎯 **GOAL**

Move knot models from `lib/core/models/` to `packages/spots_knot/lib/models/` to improve code organization and package structure.

---

## 📋 **FILES TO MOVE**

### **Main Knot Models (3 files):**
1. `lib/core/models/personality_knot.dart` → `packages/spots_knot/lib/models/personality_knot.dart`
2. `lib/core/models/entity_knot.dart` → `packages/spots_knot/lib/models/entity_knot.dart`
3. `lib/core/models/dynamic_knot.dart` → `packages/spots_knot/lib/models/dynamic_knot.dart`

### **Knot Subdirectory Models (20 files in `knot/` subdirectory):**
All files from `lib/core/models/knot/` → `packages/spots_knot/lib/models/knot/`

---

## 🔄 **MIGRATION STEPS**

### **Step 1: Move Files**
1. Move main knot models to package
2. Move knot/ subdirectory to package
3. Maintain directory structure

### **Step 2: Update Imports in Moved Files**
1. Update imports from `package:spots/core/models/...` to relative imports or package imports
2. Check for dependencies on other models that might need updating

### **Step 3: Update Imports Across Codebase**
1. Find all files importing knot models (72 imports across 49 files)
2. Update imports from `package:spots/core/models/...` to `package:spots_knot/...`
3. Update spots_knot.dart to export models

### **Step 4: Update Package Exports**
1. Update `packages/spots_knot/lib/spots_knot.dart` to export all models
2. Verify package dependencies

### **Step 5: Verify Compilation**
1. Run `flutter pub get` in package
2. Run `dart analyze` to check for errors
3. Fix any import issues
4. Run tests

---

## ⚠️ **DEPENDENCIES TO CHECK**

### **Models that knot models depend on:**
- `mood_state.dart` - used by `dynamic_knot.dart` (stays in core/models)
- Other core models that knot models reference

### **Models that depend on knot models:**
- Need to update imports in all files that use knot models

---

## 📊 **PROGRESS TRACKING**

### **Phase 3.1: Knot Models** ✅ **COMPLETE**
- [x] Step 1: Move files (23 files moved)
- [x] Step 2: Update imports in moved files
- [x] Step 3: Update imports across codebase (49+ files)
- [x] Step 4: Update package exports
- [x] Step 5: Verify compilation

**See:** `PHASE_3_1_KNOT_MODELS_COMPLETE.md` for details

### **Phase 3.2: AI Models** ✅ **COMPLETE**
- [x] Identify AI models to move (5 files identified)
- [x] Move AI models to spots_ai package
- [x] Update imports (59+ files)
- [x] Update package exports
- [x] Add spots_ai to main pubspec.yaml
- [x] Verify compilation

**See:** `PHASE_3_2_AI_MODELS_COMPLETE.md` for details

### **Phase 3.3: Core Services** ✅ **MOSTLY COMPLETE**

#### **Phase 3.3.2: AI Services** ✅ **COMPLETE (100%)**
- [x] Create services directory structure
- [x] Complete full dependency analysis
- [x] Wave 1: Low complexity services (4/4 services) ✅
  - [x] `contextual_personality_service.dart` ✅
  - [x] `personality_sync_service.dart` ✅
  - [x] `ai2ai_realtime_service.dart` ✅
  - [x] `locality_personality_service.dart` ✅
- [x] Wave 2: Medium complexity services (2/2 services) ✅
  - [x] `language_pattern_learning_service.dart` ✅ (CRITICAL dependency resolved)
  - [x] `ai2ai_learning_service.dart` ✅
- [x] Wave 3: High complexity services (3/3 services) ✅
  - [x] `personality_agent_chat_service.dart` ✅
  - [x] `business_business_chat_service_ai2ai.dart` ✅
  - [x] `business_expert_chat_service_ai2ai.dart` ✅

**See:** `PHASE_3_3_2_FULL_DEPENDENCY_ANALYSIS.md` for detailed analysis  
**See:** `PHASE_3_3_2_WAVE_1_COMPLETE.md` for Wave 1 completion details  
**See:** `PHASE_3_3_2_WAVE_2_COMPLETE.md` for Wave 2 completion details  
**See:** `PHASE_3_3_2_WAVE_3_COMPLETE.md` for Wave 3 completion details

---

**Reference:** `CODEBASE_REFACTORING_AUDIT_2025-01.md` Section 3.1

# Phase 3.3: Move Core Services to Packages - Implementation Plan

**Date:** January 2025  
**Status:** 🟡 **PLANNING**  
**Phase:** 3.3 - Core Services Migration

---

## 🎯 **GOAL**

Move services from `lib/core/services/` to appropriate packages to improve code organization and reduce duplication.

---

## 📋 **SCOPE ANALYSIS**

### **Current Situation:**

1. **Knot Services:**
   - ✅ Services exist in `packages/spots_knot/lib/services/` (correct location)
   - ⚠️ **Duplicate services** also exist in `lib/core/services/knot/` (old location)
   - Need to: Verify if old location is still used, remove if duplicates

2. **Quantum Services:**
   - ✅ Services exist in `packages/spots_quantum/lib/services/` (correct location)
   - ⚠️ **Duplicate services** also exist in `lib/core/services/quantum/` (old location)
   - Need to: Verify if old location is still used, remove if duplicates

3. **AI/Personality Services:**
   - ❌ Currently only in `lib/core/services/` (need to move to package)
   - Services to move to `packages/spots_ai/lib/services/`:
     - `personality_agent_chat_service.dart`
     - `personality_sync_service.dart`
     - `personality_analysis_service.dart`
     - `contextual_personality_service.dart`
     - `ai2ai_learning_service.dart`
     - `ai2ai_realtime_service.dart`
     - `language_pattern_learning_service.dart`
     - `locality_personality_service.dart`
     - `online_learning_service.dart`
     - `user_preference_learning_service.dart`
     - `business_business_chat_service_ai2ai.dart`
     - `business_expert_chat_service_ai2ai.dart`

4. **Core Utilities:**
   - `atomic_clock_service.dart` → Move to `packages/spots_core/lib/services/`

---

## 🔄 **MIGRATION STRATEGY**

### **Phase 3.3.1: Clean Up Duplicates** ⏳
1. Identify which services in `lib/core/services/knot/` and `lib/core/services/quantum/` are duplicates
2. Check if any code imports from old locations
3. Update imports to use package locations
4. Remove duplicate services from `lib/core/services/`

### **Phase 3.3.2: Move AI Services** ⏳
1. Create `packages/spots_ai/lib/services/` directory structure
2. Move AI/personality services to package
3. Update imports in moved services
4. Update package exports (`spots_ai.dart`)
5. Update imports across codebase
6. Update package dependencies if needed

### **Phase 3.3.3: Move Core Utilities** ⏳
1. Move `atomic_clock_service.dart` to `spots_core`
2. Update imports across codebase
3. Verify compilation

---

## ⚠️ **DEPENDENCIES & CONSIDERATIONS**

### **Service Dependencies:**
- AI services may depend on models (already moved to `spots_ai`)
- AI services may depend on core services (storage, database, etc.)
- Need to check dependency chains before moving

### **Import Updates:**
- Services in packages need to import from other packages
- Main app needs to import from packages
- Test files need import updates

---

## 📊 **ESTIMATED EFFORT**

- Phase 3.3.1 (Clean duplicates): 2-3 hours
- Phase 3.3.2 (Move AI services): 6-8 hours
- Phase 3.3.3 (Move core utilities): 1-2 hours
- **Total:** 9-13 hours

---

## ✅ **SUCCESS CRITERIA**

- [ ] No duplicate services in `lib/core/services/knot/` or `lib/core/services/quantum/`
- [ ] All AI services moved to `packages/spots_ai/lib/services/`
- [ ] All imports updated across codebase
- [ ] Package exports updated
- [ ] Zero compilation errors
- [ ] All tests pass

---

**Reference:** `CODEBASE_REFACTORING_AUDIT_2025-01.md` Section 3.2

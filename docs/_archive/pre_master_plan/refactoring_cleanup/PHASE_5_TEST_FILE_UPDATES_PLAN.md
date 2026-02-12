# Phase 5: Update Test File Imports

**Date:** January 2025  
**Status:** 🟡 **IN PROGRESS**  
**Phase:** 5 - Test File Import Updates  
**Estimated Effort:** 4-6 hours

---

## 🎯 **GOAL**

Update test file imports to match the production code migrations from Phases 3 and 4, ensuring test files use the new package paths and maintain test suite consistency.

**Goal Status:** 🟡 **IN PROGRESS**

---

## 📋 **SCOPE**

### **Import Updates Needed:**

#### **1. Phase 3.1: Knot Models** (23 models moved)
**Old Path:** `package:spots/core/models/knot/...` or `package:spots/core/models/personality_knot.dart`  
**New Path:** `package:spots_knot/models/...`

**Test Files Affected:** ~20+ test files

#### **2. Phase 3.2: AI Models** (5 models moved)
**Old Path:** `package:spots/core/models/personality_profile.dart`, etc.  
**New Path:** `package:spots_ai/models/...`

**Test Files Affected:** ~30+ test files

#### **3. Phase 3.3.2: AI Services** (9 services moved)
**Old Path:** `package:spots/core/services/personality_agent_chat_service.dart`, etc.  
**New Path:** `package:spots_ai/services/...`

**Test Files Affected:** ~20+ test files

#### **4. Phase 3.3.3: Core Utilities** (atomic_clock_service moved)
**Old Path:** `package:spots/core/services/atomic_clock_service.dart`  
**New Path:** `package:spots_core/services/atomic_clock_service.dart`

**Old Path:** `package:spots/core/models/atomic_timestamp.dart`  
**New Path:** `package:spots_core/models/atomic_timestamp.dart`

**Test Files Affected:** ~30+ test files

#### **5. Phase 3.3.4: Network Services** (12 services moved)
**Old Path:** `package:spots/core/network/device_discovery.dart`, etc.  
**New Path:** `package:spots_network/network/...`

**Test Files Affected:** ~10+ test files

---

## 📊 **IMPLEMENTATION PLAN**

### **Step 1: Audit Test Files** (1 hour)

#### **1.1 Identify All Test Files Needing Updates**
- Scan `test/` directory for old import paths
- Categorize by migration phase
- Count affected files per category
- Prioritize by test importance

#### **1.2 Create Update Checklist**
- List all files needing updates
- Document old → new import paths
- Note any special cases or dependencies

---

### **Step 2: Update Knot Model Imports** (1 hour)

#### **2.1 Update Test Files**
- Update all `package:spots/core/models/knot/...` imports
- Update all `package:spots/core/models/personality_knot.dart` imports
- Change to `package:spots_knot/models/...`

#### **2.2 Verify**
- Run tests related to knot models
- Ensure compilation succeeds
- Fix any import errors

---

### **Step 3: Update AI Model Imports** (1 hour)

#### **3.1 Update Test Files**
- Update all `package:spots/core/models/personality_profile.dart` imports
- Update other AI model imports
- Change to `package:spots_ai/models/...`

#### **3.2 Verify**
- Run tests related to AI models
- Ensure compilation succeeds

---

### **Step 4: Update AI Service Imports** (1 hour)

#### **4.1 Update Test Files**
- Update all AI service imports from `package:spots/core/services/...`
- Change to `package:spots_ai/services/...`

#### **4.2 Verify**
- Run tests related to AI services
- Ensure compilation succeeds

---

### **Step 5: Update Core Utility Imports** (1 hour)

#### **5.1 Update atomic_clock_service Imports**
- Update all `package:spots/core/services/atomic_clock_service.dart` imports
- Change to `package:spots_core/services/atomic_clock_service.dart`

#### **5.2 Update atomic_timestamp Imports**
- Update all `package:spots/core/models/atomic_timestamp.dart` imports
- Change to `package:spots_core/models/atomic_timestamp.dart`

#### **5.3 Verify**
- Run tests related to atomic clock/timestamp
- Ensure compilation succeeds

---

### **Step 6: Update Network Service Imports** (30 minutes)

#### **6.1 Update Test Files**
- Update all `package:spots/core/network/...` imports
- Change to `package:spots_network/network/...`

#### **6.2 Verify**
- Run network-related tests
- Ensure compilation succeeds

---

### **Step 7: Final Verification** (30 minutes)

#### **7.1 Compilation Check**
- Run `flutter test` to verify all tests compile
- Fix any remaining import errors
- Ensure no old import paths remain

#### **7.2 Test Execution**
- Run test suite
- Verify tests still pass after import updates
- Document any test failures (should be minimal)

---

## ✅ **SUCCESS CRITERIA**

1. ✅ All test file imports updated to match production code
2. ✅ No old import paths remain in test files
3. ✅ All tests compile without errors
4. ✅ Test execution succeeds (tests still pass)
5. ✅ Import consistency between production and test code

---

## 📚 **IMPORT MAPPING REFERENCE**

| Old Import | New Import | Phase |
|------------|------------|-------|
| `package:spots/core/models/knot/...` | `package:spots_knot/models/...` | 3.1 |
| `package:spots/core/models/personality_profile.dart` | `package:spots_ai/models/personality_profile.dart` | 3.2 |
| `package:spots/core/services/personality_agent_chat_service.dart` | `package:spots_ai/services/personality_agent_chat_service.dart` | 3.3.2 |
| `package:spots/core/services/atomic_clock_service.dart` | `package:spots_core/services/atomic_clock_service.dart` | 3.3.3 |
| `package:spots/core/models/atomic_timestamp.dart` | `package:spots_core/models/atomic_timestamp.dart` | 3.3.3 |
| `package:spots/core/network/device_discovery.dart` | `package:spots_network/network/device_discovery.dart` | 3.3.4 |

---

## ⚠️ **CONSIDERATIONS**

1. **Test Mock Files:** May need updating if they import moved services/models
2. **Test Utilities:** Check if test helpers/utilities need updates
3. **Integration Tests:** Verify integration tests work with new imports
4. **Test Fixtures:** Check if test data files reference moved models

---

## 🔄 **MIGRATION STRATEGY**

1. **Batch by Phase:** Update imports phase by phase for easier tracking
2. **Verify Incrementally:** Verify compilation after each phase batch
3. **Run Tests:** Execute tests after each batch to catch issues early

---

**References:**
- `PHASE_3_1_KNOT_MODELS_COMPLETE.md` - Knot models migration
- `PHASE_3_2_AI_MODELS_COMPLETE.md` - AI models migration
- `PHASE_3_3_2_COMPLETE.md` - AI services migration
- `PHASE_3_3_3_CORE_UTILITIES_COMPLETE.md` - Core utilities migration
- `PHASE_3_3_4_NETWORK_SERVICES_COMPLETE.md` - Network services migration

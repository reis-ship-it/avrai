# Phase 3.3.4: Move Network Services to spots_network Package

**Date:** January 2025  
**Status:** 🟡 **PLANNING**  
**Phase:** 3.3.4 - Network Services Migration

---

## 🎯 **GOAL**

Move network discovery services and protocol services from `lib/core/network/` to `packages/spots_network/` to improve code organization and package structure.

---

## 📋 **FILES TO MOVE**

### **Device Discovery Services (7 files):**
1. `lib/core/network/device_discovery.dart` → `packages/spots_network/lib/network/device_discovery.dart`
2. `lib/core/network/device_discovery_factory.dart` → `packages/spots_network/lib/network/device_discovery_factory.dart`
3. `lib/core/network/device_discovery_android.dart` → `packages/spots_network/lib/network/device_discovery_android.dart`
4. `lib/core/network/device_discovery_ios.dart` → `packages/spots_network/lib/network/device_discovery_ios.dart`
5. `lib/core/network/device_discovery_web.dart` → `packages/spots_network/lib/network/device_discovery_web.dart`
6. `lib/core/network/device_discovery_stub.dart` → `packages/spots_network/lib/network/device_discovery_stub.dart`
7. `lib/core/network/device_discovery_io.dart` → `packages/spots_network/lib/network/device_discovery_io.dart` (verify if needed)

### **Personality Advertising Services (2 files):**
8. `lib/core/network/personality_advertising_service.dart` → `packages/spots_network/lib/network/personality_advertising_service.dart`
9. `lib/core/network/personality_data_codec.dart` → `packages/spots_network/lib/network/personality_data_codec.dart`

### **Protocol Services (2 files):**
10. `lib/core/network/ai2ai_protocol.dart` → `packages/spots_network/lib/network/ai2ai_protocol.dart`
11. `lib/core/network/ai2ai_protocol_signal_integration.dart` → `packages/spots_network/lib/network/ai2ai_protocol_signal_integration.dart`

### **Configuration (1 file):**
12. `lib/core/network/webrtc_signaling_config.dart` → `packages/spots_network/lib/network/webrtc_signaling_config.dart` (used by device_discovery_web)

**Total: 11-12 files**

---

## 📊 **DEPENDENCY ANALYSIS (Preliminary)**

### **Device Discovery Services Dependencies:**
- ✅ `dart:developer` - Standard library
- ✅ `dart:async` - Standard library
- ⚠️ `package:spots/core/ai/privacy_protection.dart` - **Complex dependency** (AI layer)
- ⚠️ `package:spots/core/network/device_discovery_factory.dart` - **Internal dependency** (will move together)

### **Personality Advertising Service Dependencies:**
- ✅ `dart:developer` - Standard library
- ✅ `dart:async` - Standard library
- ⚠️ `package:spots/core/ai/privacy_protection.dart` - **Complex dependency**
- ⚠️ `package:spots/core/ai/vibe_analysis_engine.dart` - **Complex dependency**
- ⚠️ `package:spots_ai/models/personality_profile.dart` - **AI models** (already in spots_ai package ✅)
- ⚠️ `package:spots/core/models/unified_user.dart` - **Core models** (NOT in spots_core yet - use temporary spots package dependency)
- ⚠️ `package:spots/core/models/anonymous_user.dart` - **Core models** (NOT in spots_core yet - use temporary spots package dependency)
- ⚠️ `package:spots/core/services/user_anonymization_service.dart` - **Service dependency**
- ✅ `flutter_blue_plus` - External package (needs to be added to spots_network pubspec.yaml)
- ✅ `flutter_nsd` - External package (needs to be added to spots_network pubspec.yaml)

### **AI2AI Protocol Dependencies:**
- ✅ `dart:developer` - Standard library
- ✅ `dart:convert` - Standard library
- ✅ `dart:typed_data` - Standard library
- ✅ `dart:math` - Standard library
- ✅ `crypto` - External package (needs to be added)
- ✅ `pointycastle` - External package (needs to be added)
- ⚠️ `package:spots_ai/models/personality_profile.dart` - **AI models** (already in spots_ai package ✅)
- ⚠️ `package:spots/core/models/unified_user.dart` - **Core models**
- ⚠️ `package:spots/core/models/anonymous_user.dart` - **Core models**
- ⚠️ `package:spots/core/ai/privacy_protection.dart` - **Complex dependency**
- ⚠️ `package:spots/core/ai/vibe_analysis_engine.dart` - **Complex dependency**
- ⚠️ `package:spots/core/ai/personality_learning.dart` - **Complex dependency**
- ⚠️ `package:spots/core/services/user_anonymization_service.dart` - **Service dependency**
- ⚠️ `package:spots/core/services/message_encryption_service.dart` - **Service dependency**

---

## ⚠️ **CHALLENGES**

### **Complex Dependencies:**
Many network services depend on AI layer services that are still in the main app:
- `privacy_protection.dart` - AI privacy layer
- `vibe_analysis_engine.dart` - AI vibe analysis
- `personality_learning.dart` - AI personality learning
- `user_anonymization_service.dart` - User anonymization service

### **Temporary Dependency Strategy:**
- Services will temporarily depend on main `spots` package for AI layer services (`package:spots/core/ai/...`)
- Services will temporarily depend on main `spots` package for core models (`package:spots/core/models/unified_user.dart`, `package:spots/core/models/anonymous_user.dart`)
- Services will temporarily depend on main `spots` package for core services (`package:spots/core/services/user_anonymization_service.dart`, `package:spots/core/services/message_encryption_service.dart`)
- All temporary dependencies will be resolved after Phase 3.3.2 (AI services migration) and future core model migrations

### **Package Dependencies:**
- Need to add `flutter_blue_plus`, `flutter_nsd`, `crypto`, `pointycastle` to `spots_network/pubspec.yaml`
- Need to add `spots_ai` as dependency (for personality_profile)
- Need to add `spots_core` as dependency (for unified_user, anonymous_user - if moved)
- Need to add `spots` as temporary dependency (for AI layer services)

---

## 🔄 **MIGRATION STRATEGY**

### **Option A: Full Migration (Recommended if dependencies allow)**
1. Move all files to `packages/spots_network/lib/network/`
2. Update imports to use temporary `spots` package for AI layer dependencies
3. Update all imports across codebase
4. Update package exports

### **Option B: Partial Migration (If dependencies are too complex)**
1. Move only device discovery services (fewer dependencies)
2. Keep personality_advertising and ai2ai_protocol in main app for now
3. Revisit after AI services migration is complete

**Recommendation:** Start with **Option A** - migrate all services but use temporary `spots` package dependency for AI layer services.

---

## 🔄 **MIGRATION STEPS**

### **Step 1: Update spots_network Package Dependencies**
- [x] Add `flutter_blue_plus: ^1.30.7` to `packages/spots_network/pubspec.yaml` ✅
- [x] Add `flutter_nsd: ^1.6.0` to `packages/spots_network/pubspec.yaml` ✅
- [x] Add `crypto: ^3.0.3` to `packages/spots_network/pubspec.yaml` ✅
- [x] Add `pointycastle: ^3.7.3` to `packages/spots_network/pubspec.yaml` ✅
- [x] Add `spots_ai` as dependency (for personality_profile) ✅
- [x] Add `spots` as temporary dependency (for AI layer services) ✅
- [ ] Add `shared_preferences` if needed (for webrtc_signaling_config)
- [ ] Add `web` package if needed (for device_discovery_web - web platform support)

### **Step 2: Create Directory Structure**
- [ ] Create `packages/spots_network/lib/network/` directory

### **Step 3: Move Device Discovery Services**
- [ ] Move all device discovery files (7 files)
- [ ] Update imports in moved files (privacy_protection → package:spots/core/ai/...)
- [ ] Update internal references (device_discovery_factory path)

### **Step 4: Move Personality Advertising Services**
- [ ] Move personality_advertising_service.dart and personality_data_codec.dart
- [ ] Update imports in moved files (use temporary spots package for AI dependencies)

### **Step 5: Move Protocol Services**
- [ ] Move ai2ai_protocol.dart and ai2ai_protocol_signal_integration.dart
- [ ] Update imports in moved files (use temporary spots package for AI dependencies)

### **Step 6: Update Package Exports**
- [ ] Update `packages/spots_network/lib/spots_network.dart` to export network services

### **Step 7: Update All Imports Across Codebase**
- [ ] Find all files importing network services (15+ files)
- [ ] Update imports from `package:spots/core/network/...` → `package:spots_network/network/...`
- [ ] Update injection container imports

### **Step 8: Verify Compilation**
- [ ] Run `flutter pub get` in spots_network package
- [ ] Run `dart analyze packages/spots_network` to check for errors
- [ ] Run `dart analyze lib` to check for errors
- [ ] Fix any import issues

### **Step 9: Delete Old Files**
- [ ] Delete old files from `lib/core/network/`
- [ ] Verify no remaining references to old locations

### **Step 10: Final Verification**
- [ ] Verify no old import paths remain (grep check)
- [ ] Run full test suite (if applicable)
- [ ] Document completion

---

## 📊 **ESTIMATED EFFORT**

- **Analysis & Planning:** 30 minutes ✅
- **Move Files:** 30 minutes
- **Update Package Config:** 15 minutes
- **Update Imports:** 2-3 hours (15+ production files + packages)
- **Verification:** 30 minutes
- **Total:** 3.5-4.5 hours

---

## ⚠️ **RISKS & MITIGATION**

### **Risk 1: Complex AI Dependencies**
- **Mitigation:** Use temporary `spots` package dependency for AI layer services
- **Future Work:** After AI services migration (Phase 3.3.2), these can be refactored

### **Risk 2: Circular Dependencies**
- **Mitigation:** Carefully analyze dependency graph before migration
- **Solution:** Temporary `spots` dependency avoids circular dependency issues

### **Risk 3: Platform-Specific Code**
- **Mitigation:** All platform-specific code is already separated (android, ios, web)
- **Solution:** No additional changes needed

---

**Reference:** `CODEBASE_REFACTORING_AUDIT_2025-01.md` Section 3.3 (Other Services)

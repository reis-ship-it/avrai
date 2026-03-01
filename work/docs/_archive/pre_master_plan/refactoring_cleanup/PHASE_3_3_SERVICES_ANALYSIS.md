# Phase 3.3: Core Services Migration - Analysis

**Date:** January 2025  
**Status:** 🔍 **ANALYSIS IN PROGRESS**  
**Phase:** 3.3 - Move Core Services to Packages

---

## 🎯 **GOAL**

Move services from `lib/core/services/` to appropriate packages to improve code organization.

---

## 📋 **ANALYSIS**

### **Current State**

#### **Knot Services:**
- ✅ Already in `packages/spots_knot/lib/services/` (moved previously)
- ⚠️ Some services still in `lib/core/services/knot/` - Need to check if duplicates or old locations

#### **Quantum Services:**
- ✅ Already in `packages/spots_quantum/lib/services/` (moved previously)
- ⚠️ Some services still in `lib/core/services/quantum/` - Need to check if duplicates or old locations

#### **AI/Personality Services:**
- ❌ Currently in `lib/core/services/` - Need to move to `packages/spots_ai/lib/services/`
- Services to consider:
  - `personality_agent_chat_service.dart`
  - `personality_sync_service.dart`
  - `ai2ai_learning_service.dart`
  - `contextual_personality_service.dart`
  - Other AI-related services

#### **Core Services:**
- ⚠️ Some core services should stay in main app (shared dependencies)
- Some could move to `packages/spots_core/lib/services/`
- Services to consider:
  - `atomic_clock_service.dart` → `spots_core`

---

## 🔄 **NEXT STEPS**

1. **Verify Package Locations:**
   - Check if knot services in `lib/core/services/knot/` are duplicates
   - Check if quantum services in `lib/core/services/quantum/` are duplicates
   - Identify which services are actually in packages vs. main app

2. **Identify AI Services to Move:**
   - List all AI/personality services in `lib/core/services/`
   - Determine dependencies
   - Plan migration to `spots_ai` package

3. **Create Migration Plan:**
   - Prioritize services to move
   - Identify dependency chains
   - Plan import updates

---

**Reference:** `CODEBASE_REFACTORING_AUDIT_2025-01.md` Section 3.2

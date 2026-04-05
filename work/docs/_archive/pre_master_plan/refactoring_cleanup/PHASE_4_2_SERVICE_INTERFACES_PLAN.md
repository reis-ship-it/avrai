# Phase 4.2: Create Service Interfaces

**Date:** January 2025  
**Status:** 🟡 **IN PROGRESS**  
**Phase:** 4.2 - Service Interfaces  
**Estimated Effort:** 6-10 hours

---

## 🎯 **GOAL**

Create service interfaces for high-dependency services to reduce coupling and improve testability.

**Target Services:**
- `StorageService` - Used by 30+ services
- `ExpertiseService` - Used by 15+ services

---

## 📋 **IMPLEMENTATION PLAN**

### **Step 1: Create Interface Files** (2-3 hours)

#### **1.1 Create IStorageService Interface**
- Extract public API from `StorageService`
- Include all public methods (get/set operations, storage accessors)
- Place in `lib/core/services/interfaces/storage_service_interface.dart`
- Exclude private implementation details (GetStorage access, initialization logic)

#### **1.2 Create IExpertiseService Interface**
- Extract public API from `ExpertiseService`
- Include all public methods (calculateExpertiseLevel, getUserPins, calculateProgress, etc.)
- Place in `lib/core/services/interfaces/expertise_service_interface.dart`
- Exclude private helper methods

### **Step 2: Update Implementations** (2-3 hours)

#### **2.1 Update StorageService**
- Make `StorageService` implement `IStorageService`
- Keep all existing functionality
- Verify all public methods match interface

#### **2.2 Update ExpertiseService**
- Make `ExpertiseService` implement `IExpertiseService`
- Keep all existing functionality
- Verify all public methods match interface

### **Step 3: Update Dependency Injection** (1-2 hours)

#### **3.1 Update DI Registration**
- Register interfaces in dependency injection container
- Services can be accessed via interface type
- Maintain backward compatibility (can still register implementations)

**Strategy:** Register both interface and implementation for backward compatibility during transition period.

### **Step 4: Update Dependent Services (Optional)** (1-2 hours)

#### **4.1 Update High-Impact Services**
- Update services that depend on StorageService/ExpertiseService to use interfaces
- Start with services that would benefit most from interface usage
- Can be done incrementally

**Note:** This step is optional - services can continue using concrete types, but interfaces are now available for future refactoring.

---

## ✅ **SUCCESS CRITERIA**

1. ✅ Interface files created for StorageService and ExpertiseService
2. ✅ Implementations updated to implement interfaces
3. ✅ All existing functionality preserved
4. ✅ No compilation errors
5. ✅ Interfaces registered in DI container
6. ✅ Documentation updated

---

## 📚 **INTERFACE LOCATION**

Create interfaces in: `lib/core/services/interfaces/`

This follows the pattern seen in `packages/spots_network/lib/interfaces/` and keeps interfaces close to service implementations.

---

## ⚠️ **CONSIDERATIONS**

1. **Backward Compatibility:** Services can continue using concrete types - interfaces are additive
2. **Incremental Adoption:** Services can migrate to interfaces over time
3. **Testing:** Interfaces enable easier mocking in tests
4. **Future Refactoring:** Interfaces make it easier to swap implementations

---

## 🔄 **MIGRATION STRATEGY**

1. **Phase 1:** Create interfaces and update implementations (this phase)
2. **Phase 2 (Future):** Gradually update dependent services to use interfaces
3. **Phase 3 (Future):** Consider creating interfaces for other high-dependency services

---

**References:**
- `CODEBASE_REFACTORING_AUDIT_2025-01.md` Section 4.1 - Service Dependency Complexity
- `lib/core/services/storage_service.dart` - StorageService implementation
- `lib/core/services/expertise_service.dart` - ExpertiseService implementation

---

## 🔄 **FUTURE ENHANCEMENT: Migrate Services to Use Interfaces**

**Status:** ⏳ **Optional Enhancement** (Not Required for App Functionality)

### **Note:**
After completing Phase 4.2 (creating interfaces), consider migrating services to use interfaces instead of concrete types. This is an **optional enhancement** that improves testability and reduces coupling, but is not required for the app to function.

**See:** `PHASE_4_2_COMPLETE.md` for detailed migration strategy and examples.

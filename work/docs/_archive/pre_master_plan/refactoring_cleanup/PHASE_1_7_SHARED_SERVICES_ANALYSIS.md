# Phase 1.7: Shared Services Analysis

**Date:** January 2025  
**Status:** ✅ Analysis Complete

---

## 🎯 **PURPOSE**

Identify services that are used by multiple domain modules and determine where they should be registered to ensure proper dependency resolution.

---

## 📊 **SHARED SERVICES IDENTIFIED**

### **1. PartnershipService**
**Used by:**
- ✅ Payment module (RevenueSplitService, SponsorshipService)
- ✅ AI module (BusinessExpertOutreachService, BusinessBusinessOutreachService)

**Current Location:** Payment module (lines 75-78 in injection_container_payment.dart)

**Decision:** ✅ **Keep in Payment module**

**Rationale:** 
- Partnership is primarily a payment/revenue domain concept
- AI module's business outreach services use partnerships for revenue sharing
- AI module can depend on Payment module being registered first
- This maintains clear domain boundaries

---

### **2. BusinessService**
**Used by:**
- ✅ Payment module (PartnershipService dependency - line 77)
- ✅ AI module (BusinessBusinessOutreachService - line 539)

**Current Location:** Payment module (lines 68-72 in injection_container_payment.dart) with `if (!sl.isRegistered<BusinessService>())` check

**Decision:** ✅ **Register in main container before domain modules**

**Rationale:**
- Foundational business service used across Payment and AI domains
- BusinessService depends on BusinessAccountService
- Should be available before both Payment and AI modules register
- The conditional check indicates it was already recognized as potentially shared

---

### **3. BusinessAccountService**
**Used by:**
- ✅ Admin module (AdminGodModeService - line 58)
- ✅ Payment module (BusinessService dependency - line 70)
- ✅ AI module (Multiple services: BusinessExpertChatServiceAI2AI, BusinessBusinessChatServiceAI2AI, BusinessMemberService, BusinessSharedAgentService)

**Current Location:** Admin module (line 57 in injection_container_admin.dart)

**Decision:** ✅ **Register in main container before domain modules**

**Rationale:**
- Core business account management - foundational service
- Used across Admin, Payment, and AI domains
- BusinessService depends on it, so must be registered before BusinessService
- Should be registered early as it's a core domain concept

---

### **4. ExpertiseEventService**
**Used by:**
- ✅ Payment module (PaymentService, PaymentEventService, SalesTaxService, PartnershipService, BrandDiscoveryService)
- ✅ AI module (EventRecommendationService, EventMatchingService, LegalDocumentService)

**Current Location:** Payment module (lines 44-47 in injection_container_payment.dart) with `if (!sl.isRegistered<ExpertiseEventService>())` check

**Decision:** ✅ **Register in main container before domain modules**

**Rationale:**
- Core event service - foundational domain concept
- Used by both Payment (payments for events) and AI (event recommendations/matching)
- The conditional check indicates it was already recognized as potentially shared
- Events are a core concept, not payment-specific

---

### **5. GooglePlacesDataSource**
**Used by:**
- ✅ AI module (OnboardingPlaceListGenerator - line 567)

**Current Location:** Currently in main container (lines 347-354 in injection_container.dart)

**Decision:** ✅ **Keep in main container (data sources section)**

**Rationale:**
- Data sources are foundational infrastructure
- Should be registered with other data sources (Google Places, OpenStreetMap)
- Already in correct location in main container
- No need to move

---

### **6. MessageEncryptionService**
**Used by:**
- ✅ AI module (Multiple chat services, AI2AIProtocol, AnonymousCommunicationProtocol)

**Current Location:** Currently in main container (lines 1095-1123 in injection_container.dart)

**Decision:** ✅ **Keep in main container**

**Rationale:**
- Core security infrastructure
- Has complex initialization (depends on SignalProtocolService, which is conditionally registered after Supabase initialization)
- Used extensively in AI module but initialization is too complex for domain module
- Already in correct location

---

### **7. CommunityService**
**Used by:**
- ✅ Knot module (KnotCommunityService - line 158 in injection_container_knot.dart)
- ✅ AI module (CommunityChatService setup - line 500 in injection_container_ai.dart)

**Current Location:** Currently in main container (lines 1143-1147 in injection_container.dart)

**Decision:** ✅ **Keep in main container**

**Rationale:**
- Foundational community service
- Used by both Knot (community integration) and AI (community chat)
- Already in correct location
- Should be registered before Knot and AI modules

---

### **8. EventSuccessAnalysisService**
**Used by:**
- ✅ Quantum module (QuantumOutcomeLearningService - line 159 in injection_container_quantum.dart)

**Current Location:** Currently NOT explicitly registered in injection_container.dart (only referenced in QuantumOutcomeLearningService registration at line 1023)

**Decision:** ✅ **Register in main container before domain modules**

**Rationale:**
- Used by Quantum module's outcome learning service
- Needs dependencies: ExpertiseEventService, PostEventFeedbackService, PaymentService (optional)
- Should be registered before Quantum module
- Currently missing explicit registration - needs to be added

**Note:** EventSuccessAnalysisService constructor requires:
- ExpertiseEventService (will be registered in main container)
- PostEventFeedbackService (need to check if registered)
- PaymentService (optional, but will be available from Payment module)

**Recommendation:** Register EventSuccessAnalysisService after ExpertiseEventService and PaymentService, but before Quantum module.

---

### **9. GeographicExpansionService**
**Used by:**
- ✅ AI module (CommunityService constructor - line 501, instantiated inline)

**Current Location:** Instantiated inline in CommunityService registration (not registered separately)

**Decision:** ✅ **No action needed**

**Rationale:**
- Instantiated inline, not registered as singleton
- No shared dependency issue
- Current approach is fine

---

## 📋 **RECOMMENDED REGISTRATION ORDER**

### **Phase 1: Core Services**
Already handled by `injection_container_core.dart`:
- StorageService, Database, Connectivity
- AtomicClockService, UserVibeAnalyzer
- Geographic services, Security services
- Search services, Feature flags
- SupabaseService, AgentIdService

### **Phase 2: Data Sources (in main container)**
- GooglePlacesDataSource ✅ (already in main container)
- OpenStreetMapDataSource ✅ (already in main container)
- Other data sources ✅ (already in main container)

### **Phase 3: Shared Foundational Services (in main container, before domain modules)**
Register in this order:

1. **BusinessAccountService** (foundational)
2. **BusinessService** (depends on BusinessAccountService)
3. **ExpertiseEventService** (foundational event service)
4. **CommunityService** (foundational community service)
5. **GooglePlacesDataSource** ✅ (already registered in Phase 2)
6. **MessageEncryptionService** ✅ (keep in main container with complex initialization)

**After Payment module registers:**
7. **EventSuccessAnalysisService** (depends on ExpertiseEventService, PostEventFeedbackService, optional PaymentService)

**Note:** PostEventFeedbackService needs to be checked - if not registered, it should be registered before EventSuccessAnalysisService.

### **Phase 4: Domain Modules (in dependency order)**
1. **Knot services** (no domain dependencies)
2. **Payment services** (depends on BusinessService, ExpertiseEventService)
3. **Quantum services** (depends on Knot services, EventSuccessAnalysisService)
4. **AI services** (depends on Knot, Quantum, and Payment services via PartnershipService)
5. **Admin services** (depends on BusinessAccountService, may depend on AI services)

### **Phase 5: Use Cases, Controllers, BLoCs**
Already in main container ✅

---

## 🔧 **IMPLEMENTATION DECISIONS**

### **Decision: Register Shared Services in Main Container**
**Approach:** Register shared foundational services in main container before calling domain modules.

**Rationale:**
- ✅ Simple and explicit
- ✅ Clear dependency order
- ✅ Main container is already the orchestrator - shared services belong there
- ✅ Domain modules stay focused on their domain
- ✅ Easy to see what's shared vs domain-specific

**Alternative Considered:** Create `injection_container_shared.dart`
- ❌ Rejected: Adds complexity without clear benefit
- ❌ Main container is already the orchestrator
- ❌ Shared services are foundational - they belong in the main orchestrator

---

## 📝 **SERVICES TO MOVE**

### **From Payment Module → Main Container:**
1. BusinessAccountService (currently in Admin module, but should be in main)
2. BusinessService (currently in Payment module with conditional check)
3. ExpertiseEventService (currently in Payment module with conditional check)

### **From Admin Module → Main Container:**
1. BusinessAccountService (move to main container)

### **From Quantum Module → Main Container:**
1. EventSuccessAnalysisService (currently not explicitly registered - needs to be added)

### **Keep in Domain Modules:**
- ✅ PartnershipService (stays in Payment - payment domain concept)
- ✅ All other domain-specific services

---

## ✅ **ACTION ITEMS**

1. ✅ Identify all shared services (this document)
2. ⏳ Update Phase 1.7 plan with shared services approach
3. ⏳ Register shared services in main container (in correct order):
   - BusinessAccountService
   - BusinessService
   - ExpertiseEventService
   - CommunityService
   - EventSuccessAnalysisService (after Payment module)
4. ⏳ Remove shared service registrations from domain modules:
   - Remove BusinessAccountService from Admin module
   - Remove BusinessService from Payment module
   - Remove ExpertiseEventService from Payment module
5. ⏳ Update domain modules to use shared services (they already do via `sl<>()`)
6. ⏳ Verify all dependencies resolve correctly
7. ⏳ Test app initialization

---

## 🎯 **FINAL ARCHITECTURE**

```
injection_container.dart (main orchestrator)
├── Core Services (injection_container_core.dart)
├── Data Sources (Google Places, OpenStreetMap, etc.)
├── Shared Foundational Services:
│   ├── BusinessAccountService
│   ├── BusinessService
│   ├── ExpertiseEventService
│   ├── CommunityService
│   └── EventSuccessAnalysisService (after Payment)
├── Domain Modules (in order):
│   ├── registerKnotServices()
│   ├── registerPaymentServices()
│   ├── registerQuantumServices()
│   ├── registerAIServices()
│   └── registerAdminServices()
├── Use Cases
├── Controllers
└── BLoCs
```

---

**Last Updated:** January 2025

# Next Steps - Prioritized Action Plan

**Date:** December 7, 2025  
**Status:** 46 errors fixed ✅, 9 compilation errors remaining ⏳

---

## 🎯 IMMEDIATE NEXT STEPS (Do These First)

### Priority 1: Fix Script-Generated Duplicates (15 minutes)

The automation script added `category` parameters, but some files already had them!

**Files to Fix:**

1. **dispute_resolution_service_test.dart** (Line 48)
   - ❌ Duplicated named argument 'category'
   - **Fix:** Remove one of the duplicate `category:` lines

2. **legal_document_service_test.dart** (Line 36)
   - ❌ Duplicated named argument 'category'
   - **Fix:** Remove one of the duplicate `category:` lines

3. **community_event_upgrade_service_test.dart** (Line 281)
   - ❌ Duplicated named argument 'category'
   - **Fix:** Remove one of the duplicate `category:` lines

### Priority 2: Fix Remaining Compilation Errors (1-2 hours)

4. **cancellation_service_test.dart** (Line 177)
   - ❌ Type mismatch: Future<Payment> vs Payment?
   - **Fix:** Change `thenAnswer((_) async => ...)` to return `Payment?` not `Future<Payment>`

5. **cross_locality_connection_service_test.dart** (Line 11)
   - ❌ Missing mock file
   - **Fix:** Generate mocks: `dart run build_runner build --delete-conflicting-outputs`

6. **identity_verification_service_test.dart** (Line 69)
   - ❌ Import conflict: VerificationStatus
   - **Fix:** Use import alias:
     ```dart
     import 'package:spots/core/models/verification_status.dart' as status;
     // Then use: status.VerificationStatus.pending
     ```

7. **payment_service_partnership_test.dart** (Line 351)
   - ❌ No named parameter 'amountInCents'
   - **Fix:** Check Payment model for correct parameter name

8. **rate_limiting_test.dart** (Line 2)
   - ❌ Missing file: rate_limiting_service.dart
   - **Fix:** Create service file or remove/update test

9. **storage_health_checker_test.dart** (Line 46)
   - ❌ Type mismatch: MockStorageFileApi
   - **Fix:** Use proper mock type or cast

---

## 📋 Detailed Fix Instructions

### Fix 1-3: Remove Duplicate Category Parameters

**Quick Fix Script:**
```bash
# Find files with duplicate category
grep -n "category:" test/unit/services/dispute_resolution_service_test.dart | head -5
grep -n "category:" test/unit/services/legal_document_service_test.dart | head -5
grep -n "category:" test/unit/services/community_event_upgrade_service_test.dart | head -5
```

**Manual Fix:**
- Open each file
- Find the duplicate `category:` line (the one added by script)
- Remove it (keep the original)

### Fix 4: Cancellation Service Type Mismatch

**File:** `test/unit/services/cancellation_service_test.dart:177`

**Current (wrong):**
```dart
when(mockPaymentService.someMethod(...))
    .thenAnswer((_) async => payment);  // Returns Future<Payment>
```

**Should be:**
```dart
when(mockPaymentService.someMethod(...))
    .thenAnswer((_) => payment);  // Returns Payment? directly
```

Or check what the method actually returns.

### Fix 5: Generate Missing Mocks

```bash
dart run build_runner build --delete-conflicting-outputs
```

### Fix 6: Import Conflict Resolution

**File:** `test/unit/services/identity_verification_service_test.dart`

**Add alias:**
```dart
import 'package:spots/core/models/verification_status.dart' as status;
```

**Update usage:**
```dart
expect(session.status, equals(status.VerificationStatus.pending));
```

### Fix 7: Payment Parameter Name

Check the Payment model to find the correct parameter name:
```bash
grep -n "amount" lib/core/models/payment.dart | head -10
```

### Fix 8: Rate Limiting Service

Either:
- Create the missing service file
- Or comment out/remove the test if service doesn't exist

### Fix 9: Storage Mock Type

Check the mock type and fix the assignment.

---

## 🚀 Quick Win: Fix Duplicates First (15 min)

Let's fix the 3 duplicate category issues right now - they're easy wins!

---

## After Compilation Errors Are Fixed

### Next Priority: Runtime Errors (~542 failures)

Most are `MissingPluginException` from platform channels. Options:

1. **Quick Fix (2-3 hours):** Test helpers to catch exceptions
2. **Proper Fix (4-6 hours):** Mock storage infrastructure
3. **Long-term (8-12 hours):** Dependency injection refactor

### Then: Test Logic Errors (~9 failures)

Manual review and fixes needed.

---

## 📊 Progress Tracking

**Before Automation:**
- Compilation errors: ~55
- Files needing fixes: ~20+

**After Automation:**
- ✅ Fixed: 46 errors automatically
- ⏳ Remaining: 9 compilation errors

**Remaining Work:**
- ⏳ 9 compilation errors (1-2 hours)
- ⏳ 542 runtime errors (4-6 hours)
- ⏳ 9 test logic errors (2-4 hours)

**Total Estimated:** 7-12 hours to 99% pass rate

---

## ✅ Success Criteria

**Phase 7 Requirements:**
- ✅ Design Token Compliance: 100% COMPLETE
- ⏳ Test Pass Rate: 99%+ (Current: 93.8%)
- ⏳ Test Coverage: 90%+ (Need to verify)

**Current Status:**
- 1128 passing, 75 failing
- Need: 1150+ passing, <10 failing

---

## 🎯 Recommended Next Action

**Start with the 3 duplicate category fixes** - they're quick wins (15 minutes) and will get us from 9 errors to 6 errors immediately!

Then tackle the remaining 6 compilation errors systematically.


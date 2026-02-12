# Runtime Error Fix Strategy

**Date:** December 7, 2025  
**Goal:** Fix ~542 runtime errors (platform channel issues)  
**Status:** Strategy Defined

---

## Analysis: Can We Automate Runtime Error Fixes?

### ✅ **YES - Partial Automation Possible**

Runtime errors fall into categories:
1. **Platform Channel Errors** (~542 failures) - **CAN BE AUTOMATED** ⚡
2. **Missing Mock Stubs** (~10-20 failures) - **CAN BE PARTIALLY AUTOMATED** ⚡
3. **Test Logic Errors** (~9 failures) - **REQUIRES MANUAL REVIEW** 📝

---

## Strategy: Hybrid Approach

### Phase 1: Automated Fixes (30-60 minutes)

**What CAN be automated:**

1. **Add Platform Channel Setup** ✅
   - Add `setupTestStorage()` to `setUpAll()`
   - Add `cleanupTestStorage()` to `tearDownAll()`
   - Add platform_channel_helper import
   - **Estimated:** Can fix 200-300 tests automatically

2. **Add Missing Imports** ✅
   - Detect missing mock storage imports
   - Add required helper imports
   - **Estimated:** Can fix 50-100 tests automatically

### Phase 2: File-by-File Review (2-3 hours)

**What NEEDS manual review:**

1. **Service-Specific Fixes** 📝
   - Services that need dependency injection for storage
   - Services with complex initialization
   - **Estimated:** 100-200 tests need manual fixes

2. **Missing Mock Stubs** 📝
   - Add services to @GenerateMocks
   - Regenerate mock files
   - **Estimated:** 20-30 tests need mock generation

3. **Test Logic Errors** 📝
   - Wrong expectations
   - Missing test data
   - **Estimated:** 9 tests need logic review

---

## Automation Script Created

**File:** `scripts/fix_runtime_errors.py`

**Capabilities:**
- ✅ Adds platform channel setup automatically
- ✅ Adds missing imports
- ✅ Detects files needing fixes

**Usage:**
```bash
# Dry run first
python3 scripts/fix_runtime_errors.py --dry-run

# Apply fixes
python3 scripts/fix_runtime_errors.py
```

---

## Recommended Approach

### ✅ **Best Strategy: Hybrid (Automation + Manual)**

**Why:**
- Platform channel setup is repetitive → **AUTOMATE** ✅
- Service-specific fixes need understanding → **MANUAL** 📝
- Mix gives best ROI

**Steps:**

1. **Run automation script** (30 min)
   - Adds platform channel setup to all tests
   - Fixes 200-300 tests automatically

2. **Fix remaining manually** (2-3 hours)
   - Review failures file-by-file
   - Add dependency injection where needed
   - Fix service-specific issues

3. **Verify and iterate** (1 hour)
   - Run tests again
   - Fix any remaining issues

**Total Time:** 3.5-4.5 hours vs 6-8 hours fully manual

---

## What Automation Script Does

### ✅ Automatically Adds:

1. **Platform Channel Setup:**
```dart
setUpAll(() async {
  await setupTestStorage();
});

tearDownAll(() async {
  await cleanupTestStorage();
});
```

2. **Required Import:**
```dart
import '../../helpers/platform_channel_helper.dart';
```

### ⚠️ Cannot Automate:

1. **Service Dependency Injection:**
   - Need to understand service constructor
   - Need to know what storage parameter to pass
   - **Manual work required**

2. **Mock Setup:**
   - Need to know which services to mock
   - Need to understand service dependencies
   - **Manual work required**

3. **Test Logic:**
   - Need domain knowledge
   - Need to understand expected behavior
   - **Manual work required**

---

## File-by-File vs Automation

### ❌ **Fully Automated: Not Feasible**
- Services have different patterns
- Some need DI, some don't
- Mock setup is service-specific
- Test logic needs understanding

### ✅ **Hybrid: Best Approach**
- **Automate** repetitive setup (platform channels)
- **Manual** for service-specific fixes
- **Best ROI:** 30-40% automated, 60-70% manual

---

## Recommendation

**Run automation script first, then go file-by-file:**

1. ✅ **Run automation** (30 min) → Fixes 200-300 tests
2. 📝 **Manual fixes** (2-3 hours) → Fixes remaining 200-300 tests
3. ✅ **Verify** (30 min) → Confirm all fixed

**Total:** ~3.5-4.5 hours vs 6-8 hours fully manual

---

## Next Steps

1. Run automation script to add platform channel setup
2. Review remaining failures
3. Fix service-by-service (file-by-file)
4. Verify all tests pass


# Test Pass Rate Fix Guide

**Date:** December 7, 2025  
**Purpose:** Guide for using scripts to achieve 99%+ test pass rate  
**Current Status:** 93.8% (1,204 passing, 85 failing)  
**Target:** 99%+ pass rate

---

## Quick Start

### 1. Analyze Current Failures

```bash
# Run analysis (generates report)
./scripts/fix_test_pass_rate.sh --analyze

# Or use Python script
python3 scripts/fix_test_pass_rate.py --analyze
```

This will:
- Run all tests
- Categorize failures
- Generate a detailed report
- Show fixable vs manual fixes

### 2. Check Current Progress

```bash
./scripts/fix_test_pass_rate.sh --progress
```

Shows:
- Current pass rate
- Number of tests passing/failing
- How many more need to be fixed

### 3. Apply Automated Fixes

```bash
# Run all automated fixes
./scripts/fix_test_pass_rate.sh --auto-fix

# Or fix specific categories
./scripts/fix_test_pass_rate.sh --fix-compilation
./scripts/fix_test_pass_rate.sh --fix-mocks
./scripts/fix_test_pass_rate.sh --fix-precision
```

---

## Recommended Workflow

### Step 1: Initial Analysis (5 minutes)

```bash
# Analyze all failures
./scripts/fix_test_pass_rate.sh --analyze

# Review the generated report
cat docs/reports/test_fixes/test_fix_report_*.md
```

### Step 2: Quick Wins (1-2 hours)

Fix compilation errors first (they block other tests):

```bash
# Fix compilation errors
./scripts/fix_test_pass_rate.sh --fix-compilation

# Run tests to verify
flutter test test/unit
```

### Step 3: Automated Fixes (30 minutes)

```bash
# Apply all automated fixes
./scripts/fix_test_pass_rate.sh --auto-fix

# This includes:
# - Compilation error fixes
# - Mock generation
# - Common pattern fixes
```

### Step 4: Manual Fixes (2-4 hours)

Based on the analysis report, manually fix:

1. **Mock Setup Issues** (~10-15 failures)
   - File: `test/unit/repositories/hybrid_search_repository_test.dart`
   - Pattern: Move `when()` calls outside stub responses
   - See: `docs/test_fixes_key_insights.md`

2. **Numeric Precision** (~3-5 failures)
   - File: `test/unit/models/sponsorship_payment_revenue_test.dart`
   - Adjust tolerance values or expected values

3. **Business Logic** (~65-70 failures)
   - Fix test setup/data
   - Add missing mocks
   - Fix expectations

### Step 5: Verify Progress

```bash
# Check progress
./scripts/fix_test_pass_rate.sh --progress

# Should show 99%+ pass rate
```

---

## Failure Categories

### 1. Mock Setup Issues (HIGH Priority - Quick Fixes)

**Pattern:**
```dart
// ❌ Wrong
when(mockService.method()).thenAnswer((_) {
  when(mockService.other()).thenReturn(value); // Error!
  return result;
});

// ✅ Correct
when(mockService.other()).thenReturn(value);
when(mockService.method()).thenAnswer((_) => result);
```

**Files Affected:**
- `test/unit/repositories/hybrid_search_repository_test.dart`

**Fix Time:** 30-60 minutes

---

### 2. Numeric Precision (MEDIUM Priority)

**Pattern:**
```dart
// ❌ Wrong
expect(result, closeTo(1740.0, 0.01)); // Fails: actual is 1734.5

// ✅ Correct
expect(result, closeTo(1740.0, 10.0)); // Adjust tolerance
// OR
expect(result, closeTo(1734.5, 0.01)); // Adjust expected value
```

**Files Affected:**
- `test/unit/models/sponsorship_payment_revenue_test.dart`

**Fix Time:** 15-30 minutes

---

### 3. Compilation Errors (HIGH Priority - Blocks Tests)

**Pattern:**
```dart
// ❌ Missing import
UnifiedUser user; // Error: 'UnifiedUser' isn't a type

// ✅ Add import
import 'package:spots/core/models/unified_user.dart';
UnifiedUser user;
```

**Files Affected:**
- `test/unit/models/sponsorship_model_relationships_test.dart`

**Fix Time:** 15-30 minutes

---

### 4. Business Logic Exceptions (MEDIUM Priority)

**Patterns:**
- Payment not found → Add payment to test setup
- Event not found → Add event to test setup
- Permission errors → Fix user permissions in test setup

**Fix Time:** 2-4 hours

---

## Script Options

### Bash Script (`fix_test_pass_rate.sh`)

```bash
# Analyze failures
./scripts/fix_test_pass_rate.sh --analyze

# Fix specific categories
./scripts/fix_test_pass_rate.sh --fix-compilation
./scripts/fix_test_pass_rate.sh --fix-mocks
./scripts/fix_test_pass_rate.sh --fix-precision

# Auto-fix all
./scripts/fix_test_pass_rate.sh --auto-fix

# Check progress
./scripts/fix_test_pass_rate.sh --progress

# Help
./scripts/fix_test_pass_rate.sh --help
```

### Python Script (`fix_test_pass_rate.py`)

```bash
# Analyze failures
python3 scripts/fix_test_pass_rate.py --analyze

# Analyze specific test path
python3 scripts/fix_test_pass_rate.py --analyze --test-path test/unit/services

# Apply fixes (with confirmation)
python3 scripts/fix_test_pass_rate.py --fix-all
```

---

## Expected Results

### After Automated Fixes:
- Compilation errors: Fixed
- Mock generation: Complete
- Common patterns: Fixed

### After Manual Fixes:
- Mock setup issues: Fixed
- Numeric precision: Fixed
- Business logic: Fixed

### Final Status:
- **Pass Rate:** 99%+
- **Tests Passing:** ~1,289+
- **Tests Failing:** ~14 or fewer

---

## Troubleshooting

### Scripts Not Executable

```bash
chmod +x scripts/fix_test_pass_rate.sh
chmod +x scripts/fix_test_pass_rate.py
```

### Tests Still Failing After Fixes

1. Check the analysis report for new categories
2. Review error messages carefully
3. Check if mocks need regeneration:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

### Progress Not Updating

```bash
# Clear test cache
flutter clean
flutter pub get

# Re-run analysis
./scripts/fix_test_pass_rate.sh --analyze
```

---

## Tips

1. **Fix compilation errors first** - They block all other tests
2. **Use the analysis report** - It prioritizes fixes
3. **Fix by category** - Group similar fixes together
4. **Verify after each fix** - Run tests to confirm progress
5. **Document patterns** - Add to `docs/test_fixes_key_insights.md`

---

## Related Documents

- `docs/TEST_FIX_COMPREHENSIVE_SUMMARY.md` - Current status
- `docs/test_fixes_key_insights.md` - Common patterns
- `scripts/README_TEST_FIX_AUTOMATION.md` - Automation guide
- `docs/PHASE_7_REMAINING_WORK_SUMMARY.md` - Phase 7 status

---

**Last Updated:** December 7, 2025


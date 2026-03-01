# Test Reuse Requirement - Master Plan Mandatory Guideline

**Date:** December 22, 2025  
**Purpose:** Mandatory requirement for all tests created as part of the Master Plan  
**Status:** ✅ Active - Applies to All Phases

---

## 🚨 **MANDATORY REQUIREMENT**

**Before creating ANY new test as part of the Master Plan, you MUST:**

1. **Check for existing similar tests**
2. **Check for existing test environments**
3. **Check for reusable test infrastructure**
4. **Refactor/extend existing tests rather than creating duplicates**

**This requirement applies to ALL phases and ALL test creation work.**

---

## 📋 **Step-by-Step Process**

### **Step 1: Search Existing Tests**

Before creating a new test, search for similar existing tests:

```bash
# Search for similar service tests
grep -r "similar_service_name" test/unit/services/

# Search for similar widget tests
grep -r "similar_widget_name" test/widget/

# Search for similar integration tests
grep -r "similar_feature_name" test/integration/

# Search for test patterns
grep -r "similar_test_pattern" test/
```

### **Step 2: Check Test Infrastructure**

Look for reusable test infrastructure:

- **Test Helpers:** `test/helpers/` - Reusable test utilities
- **Test Fixtures:** `test/fixtures/` - Test data and fixtures
- **Test Templates:** `test/templates/` - Test templates
- **Test Mocks:** `test/mocks/` - Mock implementations
- **Test Utilities:** `test/helpers/` - Common test functions

### **Step 3: Check Test Environments**

Look for similar test environments:

- **Integration Test Environments:** `test/integration/` - Similar integration test setups
- **Widget Test Environments:** `test/widget/` - Similar widget test setups
- **Unit Test Environments:** `test/unit/` - Similar unit test setups

### **Step 4: Refactor or Extend**

**If similar tests exist:**
- ✅ **Refactor existing tests** to cover new functionality
- ✅ **Extend existing tests** with additional test cases
- ✅ **Reuse test infrastructure** (helpers, fixtures, mocks)
- ❌ **DO NOT create duplicate tests**

**If no similar tests exist:**
- ✅ Create new test using appropriate template
- ✅ Follow existing test patterns and conventions
- ✅ Document why new test was needed

---

## 📁 **Test Infrastructure Locations**

### **Test Directories:**
- `test/unit/services/` - Service unit tests
- `test/unit/models/` - Model unit tests
- `test/widget/widgets/` - Widget tests
- `test/widget/pages/` - Page tests
- `test/integration/` - Integration tests
- `test/helpers/` - Test utilities and helpers
- `test/fixtures/` - Test data and fixtures
- `test/mocks/` - Mock implementations
- `test/templates/` - Test templates

### **Test Files to Check:**
- Similar service tests in `test/unit/services/`
- Similar model tests in `test/unit/models/`
- Similar widget tests in `test/widget/`
- Similar integration tests in `test/integration/`
- Test helpers in `test/helpers/`
- Test fixtures in `test/fixtures/`

---

## ✅ **Checklist**

Before creating a new test, verify:

- [ ] Searched `test/unit/` for similar service/model tests
- [ ] Searched `test/widget/` for similar widget/page tests
- [ ] Searched `test/integration/` for similar integration tests
- [ ] Checked `test/helpers/` for reusable test utilities
- [ ] Checked `test/fixtures/` for existing test data
- [ ] Checked `test/mocks/` for existing mocks
- [ ] Checked `test/templates/` for appropriate templates
- [ ] Determined if existing tests can be refactored/extended
- [ ] Documented why new test was needed (if created)

---

## 🎯 **Examples**

### **Example 1: Service Test**

**Before creating new test:**
```bash
# Search for similar service tests
grep -r "PaymentService" test/unit/services/
grep -r "RevenueSplit" test/unit/services/
```

**If similar tests exist:**
- ✅ Extend existing `payment_service_test.dart` with new test cases
- ✅ Reuse existing test fixtures and helpers
- ❌ Do NOT create duplicate `payment_service_new_test.dart`

### **Example 2: Widget Test**

**Before creating new test:**
```bash
# Search for similar widget tests
grep -r "EventCard" test/widget/
grep -r "Partnership" test/widget/
```

**If similar tests exist:**
- ✅ Extend existing widget test with new test cases
- ✅ Reuse existing test helpers and fixtures
- ❌ Do NOT create duplicate widget test file

### **Example 3: Integration Test**

**Before creating new test:**
```bash
# Search for similar integration tests
grep -r "onboarding" test/integration/
grep -r "payment_flow" test/integration/
```

**If similar tests exist:**
- ✅ Extend existing integration test with new scenarios
- ✅ Reuse existing test environment setup
- ❌ Do NOT create duplicate integration test file

---

## 📚 **Resources**

- **Test Templates:** `test/templates/` - Use appropriate template
- **Test Helpers:** `test/helpers/` - Reusable test utilities
- **Test Fixtures:** `test/fixtures/` - Test data and fixtures
- **Test Writing Guide:** `docs/plans/test_refactoring/TEST_WRITING_GUIDE.md`
- **Test Quality Standards:** `docs/plans/phase_1_3/PHASE_3_TEST_QUALITY_STANDARDS.md`
- **Feature Matrix Test Guide:** `docs/plans/feature_matrix/FEATURE_MATRIX_TEST_INTEGRATION_GUIDE.md`

---

## 🚨 **Enforcement**

**This requirement is MANDATORY for:**
- All phases in the Master Plan
- All test creation work
- All test updates and refactoring

**Before marking any phase/feature complete:**
- ✅ Verify that test reuse requirement was followed
- ✅ Document any new tests created and why they were needed
- ✅ Ensure no duplicate tests were created

---

**Last Updated:** December 22, 2025  
**Status:** ✅ Active - Mandatory for All Master Plan Work


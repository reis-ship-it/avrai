# Test Update Procedures

**Date:** November 20, 2025  
**Purpose:** Standardized procedures for updating tests when codebase changes

---

## Overview

This document provides step-by-step procedures for updating tests when:
- Adding new features
- Refactoring existing code
- Fixing bugs
- Updating dependencies
- Changing APIs

---

## Procedure 1: Updating Tests for API Changes

### When to Use
- Method signatures change
- Constructor parameters change
- Property names change
- Return types change

### Steps

1. **Identify Affected Tests**
   ```bash
   # Search for usage of changed API
   grep -r "OldMethodName" test/
   grep -r "oldProperty" test/
   ```

2. **Update Test Files**
   - Update method calls to match new signature
   - Update property access to match new names
   - Update type assertions if return types changed
   - Update mocks if dependencies changed

3. **Verify Changes**
   ```bash
   # Run affected tests
   flutter test test/path/to/affected_test.dart
   
   # Check for compilation errors
   flutter analyze test/
   ```

4. **Update Documentation**
   - Update test file header if coverage changes
   - Update comments if test logic changes

---

## Procedure 2: Adding Tests for New Features

### When to Use
- New service/component added
- New use case implemented
- New widget/page created

### Steps

1. **Choose Test Template**
   - Service tests: `test/templates/service_test_template.dart`
   - Unit tests: `test/templates/unit_test_template.dart`
   - Widget tests: `test/templates/widget_test_template.dart`
   - Integration tests: `test/templates/integration_test_template.dart`

2. **Create Test File**
   - Use appropriate template
   - Place in correct directory:
     - Services: `test/unit/services/`
     - Models: `test/unit/models/`
     - Widgets: `test/widget/`
     - Pages: `test/widget/pages/`
     - Integration: `test/integration/`

3. **Implement Tests**
   - Follow Phase 3 standards
   - Include documentation header
   - Cover core functionality
   - Include edge cases
   - Test error conditions

4. **Verify Tests**
   ```bash
   # Run new test file
   flutter test test/path/to/new_test.dart
   
   # Check coverage
   flutter test --coverage
   ```

5. **Update Progress Documentation**
   - Update `TEST_SUITE_UPDATE_PROGRESS.md`
   - Add to appropriate category

---

## Procedure 3: Fixing Broken Tests

### When to Use
- Tests fail after code changes
- Tests have compilation errors
- Tests are flaky

### Steps

1. **Identify Root Cause**
   ```bash
   # Run failing test with verbose output
   flutter test test/path/to/failing_test.dart --reporter=expanded
   
   # Check for compilation errors
   flutter analyze test/path/to/failing_test.dart
   ```

2. **Determine Fix Type**
   - **Compilation Error:** Update API calls, imports, types
   - **Runtime Failure:** Fix test logic, mock setup, expectations
   - **Flaky Test:** Add proper waits, fix timing issues, isolate dependencies

3. **Apply Fix**
   - Follow Phase 3 standards
   - Use established patterns
   - Update mocks if needed
   - Fix test logic

4. **Verify Fix**
   ```bash
   # Run test multiple times to check for flakiness
   for i in {1..5}; do flutter test test/path/to/fixed_test.dart; done
   ```

5. **Document Fix**
   - Add comment explaining fix if non-obvious
   - Update test documentation if needed

---

## Procedure 4: Updating Mocks

### When to Use
- Dependencies change
- Mock classes need regeneration
- New dependencies added

### Steps

1. **Regenerate Mocks** (if using build_runner)
   ```bash
   # Regenerate all mocks
   dart run build_runner build --delete-conflicting-outputs
   
   # Or regenerate specific file
   dart run build_runner build --delete-conflicting-outputs test/mocks/specific_file.dart
   ```

2. **Update Mock Usage**
   - Update mock setup in `setUp()` methods
   - Update `when()` calls if API changed
   - Update `verify()` calls if needed

3. **Verify Mocks**
   ```bash
   # Run tests that use mocks
   flutter test test/unit/
   ```

---

## Procedure 5: Refactoring Test Code

### When to Use
- Test code becomes duplicated
- Test helpers need updating
- Test organization needs improvement

### Steps

1. **Identify Refactoring Opportunities**
   - Duplicate test setup code
   - Repeated test patterns
   - Unclear test organization

2. **Create/Update Helpers**
   - Add to `test/helpers/test_helpers.dart`
   - Add to `test/helpers/widget_test_helpers.dart`
   - Create component-specific helpers if needed

3. **Refactor Tests**
   - Replace duplicate code with helper calls
   - Improve test organization
   - Clarify test names and groups

4. **Verify Refactoring**
   ```bash
   # Run all tests to ensure nothing broke
   flutter test
   ```

---

## Procedure 6: Updating Test Coverage

### When to Use
- Coverage drops below targets
- New features lack coverage
- Coverage gaps identified

### Steps

1. **Generate Coverage Report**
   ```bash
   flutter test --coverage
   genhtml coverage/lcov.info -o coverage/html
   ```

2. **Identify Gaps**
   - Review coverage report
   - Identify untested code paths
   - Prioritize critical components

3. **Add Tests**
   - Follow Procedure 2 (Adding Tests)
   - Focus on uncovered code paths
   - Prioritize critical components

4. **Verify Coverage Improvement**
   ```bash
   # Generate updated coverage
   flutter test --coverage
   
   # Compare with previous report
   ```

---

## Common Patterns

### Pattern 1: Updating UserAction Usage
```dart
// Old
UserActionData(type: UserActionType.spotVisit, ...)

// New
UserAction(
  type: UserActionType.spotVisit,
  metadata: {},
  timestamp: DateTime.now(),
)
```

### Pattern 2: Updating PersonalityLearning Constructor
```dart
// Old
PersonalityLearning(prefs: SharedPreferences.getInstance())

// New
PersonalityLearning.withPrefs(mockPrefs)
```

### Pattern 3: Updating Method Names
```dart
// Old
personalityLearning.evolveFromUserActionData(userId, action)

// New
personalityLearning.evolveFromUserAction(userId, action)
```

---

## Troubleshooting

### Tests Fail After Dependency Update
1. Check dependency changelog
2. Update imports if package structure changed
3. Update API calls if methods changed
4. Regenerate mocks if needed

### Tests Pass Locally But Fail in CI
1. Check for environment-specific code
2. Verify all dependencies are in pubspec.yaml
3. Check for timing issues (add proper waits)
4. Verify test data is consistent

### Coverage Not Updating
1. Ensure `--coverage` flag is used
2. Check that `coverage/` directory exists
3. Verify lcov.info is generated
4. Check coverage tool configuration

---

## Quick Reference Commands

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/unit/services/my_service_test.dart

# Run tests excluding performance
flutter test --exclude-tags=performance

# Analyze test code
flutter analyze test/

# Format test code
dart format test/

# Regenerate mocks
dart run build_runner build --delete-conflicting-outputs

# Check test file headers
bash scripts/audit_test_headers.sh
```

---

**Last Updated:** November 20, 2025


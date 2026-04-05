# Test Maintenance Checklist

**Date:** November 20, 2025  
**Purpose:** Standardized checklist for maintaining test suite quality as codebase evolves

---

## Pre-Commit Checklist

Before committing test changes:

- [ ] All tests compile without errors
- [ ] All tests pass locally
- [ ] Test follows Phase 3 naming conventions
- [ ] Test includes proper documentation header
- [ ] Test uses appropriate mocking patterns
- [ ] Test covers edge cases and error conditions
- [ ] Test validates privacy requirements (where applicable)
- [ ] No hardcoded test data that should use factories
- [ ] Test is properly organized in correct directory

---

## When Adding New Features

- [ ] Create corresponding test file(s) if new components added
- [ ] Update existing tests if API changes affect them
- [ ] Add integration tests for critical user flows
- [ ] Update test coverage documentation
- [ ] Verify tests pass in CI/CD pipeline

---

## When Refactoring Code

- [ ] Update all affected test files
- [ ] Verify test coverage maintained or improved
- [ ] Check for deprecated test patterns
- [ ] Update mocks if dependencies change
- [ ] Run full test suite before merging

---

## When Fixing Bugs

- [ ] Add regression test for the bug
- [ ] Verify fix doesn't break existing tests
- [ ] Update test documentation if needed
- [ ] Ensure test clearly demonstrates the fix

---

## Monthly Maintenance Tasks

- [ ] Run full test suite
- [ ] Review test coverage reports
- [ ] Check for flaky tests
- [ ] Update test documentation headers (use `scripts/audit_test_headers.sh`)
- [ ] Review and update test templates if patterns change
- [ ] Check for deprecated test dependencies
- [ ] Review performance test baselines

---

## Quarterly Maintenance Tasks

- [ ] Comprehensive test suite review
- [ ] Update coverage targets if needed
- [ ] Review and update test standards
- [ ] Audit test organization structure
- [ ] Review CI/CD test execution performance
- [ ] Update test maintenance procedures

---

## Test Quality Standards (Phase 3)

### Documentation
- [ ] File header with purpose, date, test coverage list
- [ ] Group comments explaining what each group tests
- [ ] Complex test logic documented
- [ ] OUR_GUTS.md references where applicable

### Organization
- [ ] Tests organized in correct directory structure
- [ ] Test file naming follows conventions (`*_test.dart`)
- [ ] Related tests grouped logically

### Coverage
- [ ] Critical components: 90%+ coverage
- [ ] High priority: 85%+ coverage
- [ ] Medium priority: 75%+ coverage
- [ ] Low priority: 60%+ coverage

### Patterns
- [ ] Uses proper mocking (mockito/mocktail)
- [ ] Uses test helpers and factories
- [ ] Follows established test patterns
- [ ] No duplicate test logic

---

## Common Issues to Watch For

### Compilation Errors
- [ ] Outdated API calls
- [ ] Missing imports
- [ ] Incorrect property names
- [ ] Type mismatches

### Runtime Failures
- [ ] Null pointer exceptions
- [ ] Missing mock setup
- [ ] Incorrect test expectations
- [ ] Environment-dependent failures

### Test Quality
- [ ] Tests that are too slow
- [ ] Flaky tests
- [ ] Tests with unclear assertions
- [ ] Missing edge case coverage

---

## Quick Reference

### Test File Structure
```dart
/// SPOTS [Component] Tests
/// Date: [Current Date]
/// Purpose: Test [Component] functionality
/// 
/// Test Coverage:
/// - [Feature 1]: [Description]
/// - [Feature 2]: [Description]
/// 
/// OUR_GUTS.md: [Relevant principle]

import 'package:flutter_test/flutter_test.dart';
// ... imports

void main() {
  group('[Component]', () {
    // Setup
    setUp(() {});
    
    // Tests
    group('[Feature Group]', () {
      test('should [expected behavior]', () {
        // Test implementation
      });
    });
  });
}
```

### Running Tests
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/unit/services/my_service_test.dart

# Run with coverage
flutter test --coverage

# Run excluding performance tests
flutter test --exclude-tags=performance

# Run only performance tests
flutter test --tags=performance
```

### Generating Coverage Report
```bash
# Generate coverage
flutter test --coverage

# View coverage (requires lcov)
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

---

**Last Updated:** November 20, 2025


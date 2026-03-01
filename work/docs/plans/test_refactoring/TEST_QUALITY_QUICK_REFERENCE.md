# Test Quality Quick Reference

**One-page checklist for writing high-quality tests**

---

## ✅ DO: Test These

| Category | What to Test | Example |
|----------|-------------|---------|
| **Models** | Validation, business rules, round-trip JSON | `expect(() => Spot(lat: 200), throwsArgumentError)` |
| **Services** | Business logic, error handling, async ops | `expect(result.isSuccess, isTrue)` |
| **Widgets** | User interactions, state changes, validation | `await tester.tap(button); expect(find.text('Success'), findsOneWidget)` |
| **Integration** | Complete workflows, system interactions | `await workflow.execute(); expect(result, isSuccess)` |

---

## ❌ DON'T: Test These

| Anti-Pattern | Why It's Bad | Better Alternative |
|-------------|--------------|-------------------|
| **Property assignment** | Tests language, not behavior | Test behavior that uses properties |
| **Constructor-only** | Tests Dart works, not your code | Test service can perform its function |
| **Field-by-field JSON** | Doesn't verify deserialization | Use round-trip JSON test |
| **Trivial null checks** | Tests language features | Test behavior with null inputs |
| **Over-granular UI** | Too many tests for simple rendering | Consolidate into comprehensive test |

---

## 🎯 Quick Examples

### ❌ BAD: Property Assignment
```dart
test('should create model', () {
  final model = Model(id: '1', name: 'Test');
  expect(model.id, equals('1'));
  expect(model.name, equals('Test'));
});
```

### ✅ GOOD: Behavior Test
```dart
test('should validate and process data', () {
  final model = Model(id: '1', name: 'Test');
  expect(() => model.process(), returnsNormally);
  expect(model.process().isValid, isTrue);
});
```

### ❌ BAD: Constructor-Only
```dart
test('should instantiate', () {
  expect(Service(), isNotNull);
});
```

### ✅ GOOD: Functional Test
```dart
test('should initialize and process requests', () {
  final service = Service();
  expect(() => service.process(Request()), returnsNormally);
});
```

### ❌ BAD: Field-by-Field JSON
```dart
test('should serialize', () {
  final json = model.toJson();
  expect(json['id'], equals('1'));
  expect(json['name'], equals('Test'));
  // ... 10 more fields
});
```

### ✅ GOOD: Round-Trip JSON
```dart
test('should serialize and deserialize (round-trip)', () {
  final original = Model(id: '1', name: 'Test');
  final restored = Model.fromJson(original.toJson());
  expect(restored, equals(original));
});
```

---

## 📋 Pre-Commit Checklist

Before committing test changes:

- [ ] Tests focus on **behavior**, not properties
- [ ] No constructor-only tests (`test('should create', ...)`)
- [ ] JSON tests use **round-trip** pattern
- [ ] Related checks are **consolidated** into single tests
- [ ] Tests include **error handling** cases
- [ ] Test names are **descriptive** and behavior-focused
- [ ] File has **documentation header** with purpose

---

## 🔍 Quality Checks

### Automatic Checks (Pre-Commit Hook)
- ✅ Runs automatically on `git commit`
- ✅ Flags property-assignment tests
- ✅ Flags constructor-only tests
- ✅ Flags field-by-field JSON tests

### Manual Check
```bash
# Check specific file
dart run scripts/check_test_quality.dart test/unit/models/spot_test.dart

# Check directory
dart run scripts/check_test_quality.dart test/unit/models/

# Check all tests
dart run scripts/check_test_quality.dart
```

---

## 📚 Resources

- **Full Guide:** `docs/plans/test_refactoring/TEST_WRITING_GUIDE.md`
- **Refactoring Plan:** `docs/plans/test_refactoring/TEST_REFACTORING_PLAN.md`
- **Templates:** `test/templates/`

---

## 💡 Key Principle

> **Test what the code DOES, not what it IS**

Focus on:
- ✅ **Behavior** - What happens when you call a method?
- ✅ **Business Logic** - Does it calculate/validate correctly?
- ✅ **Error Handling** - How does it handle failures?
- ✅ **User Interactions** - What happens when user taps/inputs?

Avoid:
- ❌ **Properties** - What values are stored?
- ❌ **Structure** - What fields exist?
- ❌ **Language Features** - Does null checking work?

---

**Last Updated:** December 8, 2025

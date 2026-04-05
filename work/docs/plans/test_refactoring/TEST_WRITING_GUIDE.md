# SPOTS Test Writing Guide

**Date:** December 8, 2025  
**Purpose:** Comprehensive guide for writing high-quality tests in SPOTS  
**Status:** ✅ Active

---

## Table of Contents

1. [Core Principles](#core-principles)
2. [What to Test](#what-to-test)
3. [What NOT to Test](#what-not-to-test)
4. [Test Patterns](#test-patterns)
5. [Examples: Good vs Bad](#examples-good-vs-bad)
6. [Common Anti-Patterns](#common-anti-patterns)
7. [Best Practices](#best-practices)
8. [Resources](#resources)

---

## Core Principles

### 1. Test Behavior, Not Implementation
✅ **DO:** Test what the code does, not how it's structured  
❌ **DON'T:** Test property values, getters, or internal structure

### 2. Focus on Business Logic
✅ **DO:** Test critical business rules, validation, and workflows  
❌ **DON'T:** Test language features (null checks, type checks)

### 3. Consolidate Related Tests
✅ **DO:** Combine related checks into comprehensive test blocks  
❌ **DON'T:** Create separate tests for each property or UI element

### 4. Test Edge Cases and Errors
✅ **DO:** Test error handling, boundary conditions, invalid inputs  
❌ **DON'T:** Only test the happy path

---

## What to Test

### ✅ Model Tests

**Test:**
- **Validation logic** - Invalid inputs, boundary conditions
- **Business rules** - Calculations, transformations, constraints
- **JSON round-trip** - Serialization and deserialization together
- **Immutability** - `copyWith` creates new instances correctly
- **Equality** - When objects should be equal/unequal

**Example:**
```dart
test('should validate coordinates and throw ArgumentError for invalid latitude', () {
  expect(() => Spot(latitude: 200, longitude: 0), throwsArgumentError);
  expect(() => Spot(latitude: -100, longitude: 0), throwsArgumentError);
});

test('should serialize and deserialize correctly (round-trip)', () {
  final spot = Spot(id: '1', name: 'Test', latitude: 40.0, longitude: -74.0);
  final json = spot.toJson();
  final restored = Spot.fromJson(json);
  expect(restored, equals(spot));
});
```

### ✅ Service Tests

**Test:**
- **Business logic** - Service methods perform correct operations
- **Error handling** - How service handles failures
- **Dependency interactions** - Correct calls to dependencies
- **Async operations** - Futures, streams work correctly
- **Side effects** - State changes, external calls

**Example:**
```dart
test('should calculate distance accurately between two spots', () async {
  final spot1 = Spot(latitude: 40.7128, longitude: -74.0060); // NYC
  final spot2 = Spot(latitude: 34.0522, longitude: -118.2437); // LA
  final distance = await distanceService.calculateDistance(spot1, spot2);
  expect(distance, closeTo(3944.0, 10.0)); // ~3944 km
});

test('should handle network errors gracefully', () async {
  when(() => mockNetworkService.fetch()).thenThrow(NetworkException());
  final result = await service.fetchData();
  expect(result.isFailure, isTrue);
  expect(result.error, isA<NetworkException>());
});
```

### ✅ Widget Tests

**Test:**
- **User interactions** - Taps, text input, gestures
- **State changes** - UI updates based on state
- **Business logic in UI** - Form validation, calculations
- **Edge cases** - Empty states, error states, loading states
- **Accessibility** - Semantic labels, keyboard navigation

**Example:**
```dart
testWidgets('should validate form and show error for invalid email, submit when valid, clear errors on input change, and disable submit button when form is invalid', (tester) async {
  await tester.pumpWidget(createTestableWidget(child: SignupForm()));
  
  // Invalid email
  await tester.enterText(find.byKey(Key('email')), 'invalid');
  await tester.tap(find.byKey(Key('submit')));
  await tester.pump();
  expect(find.text('Invalid email'), findsOneWidget);
  
  // Valid email
  await tester.enterText(find.byKey(Key('email')), 'test@example.com');
  await tester.pump();
  expect(find.text('Invalid email'), findsNothing);
  
  // Submit
  await tester.tap(find.byKey(Key('submit')));
  await tester.pumpAndSettle();
  verify(() => mockAuthBloc.add(SignupRequested(email: 'test@example.com'))).called(1);
});
```

---

## What NOT to Test

### ❌ Property Assignment Tests

**BAD:**
```dart
test('should create model with properties', () {
  final model = Model(id: '1', name: 'Test');
  expect(model.id, equals('1'));
  expect(model.name, equals('Test'));
});
```

**Why it's bad:** Tests language features (constructor parameters), not behavior.

**Better:** Test behavior that uses those properties:
```dart
test('should validate and process data correctly', () {
  final model = Model(id: '1', name: 'Test');
  final result = model.process();
  expect(result.isValid, isTrue);
});
```

### ❌ Constructor-Only Tests

**BAD:**
```dart
test('should instantiate correctly', () {
  final service = Service();
  expect(service, isNotNull);
});
```

**Why it's bad:** Tests that Dart constructors work, not your code.

**Better:** Test that the service can perform its function:
```dart
test('should initialize and be ready to process requests', () {
  final service = Service();
  expect(() => service.processRequest(Request()), returnsNormally);
});
```

### ❌ Field-by-Field JSON Tests

**BAD:**
```dart
test('should serialize to JSON', () {
  final model = Model(id: '1', name: 'Test');
  final json = model.toJson();
  expect(json['id'], equals('1'));
  expect(json['name'], equals('Test'));
  expect(json['createdAt'], isNotNull);
  // ... 10 more field checks
});
```

**Why it's bad:** Tests each field individually, doesn't verify deserialization works.

**Better:** Use round-trip test:
```dart
test('should serialize and deserialize correctly (round-trip)', () {
  final original = Model(id: '1', name: 'Test');
  final json = original.toJson();
  final restored = Model.fromJson(json);
  expect(restored, equals(original));
});
```

### ❌ Trivial Null/Empty Checks

**BAD:**
```dart
test('should handle null input', () {
  final result = service.process(null);
  expect(result, isNull);
});

test('should handle empty input', () {
  final result = service.process('');
  expect(result, isEmpty);
});
```

**Why it's bad:** Tests language features, not business logic.

**Better:** Test actual behavior with null/empty:
```dart
test('should return error result for null or empty input', () {
  expect(service.process(null).isError, isTrue);
  expect(service.process('').isError, isTrue);
  expect(service.process('valid').isSuccess, isTrue);
});
```

### ❌ Over-Granular UI Tests

**BAD:**
```dart
testWidgets('should display title', (tester) async {
  expect(find.text('Title'), findsOneWidget);
});

testWidgets('should display subtitle', (tester) async {
  expect(find.text('Subtitle'), findsOneWidget);
});

testWidgets('should display button', (tester) async {
  expect(find.byType(ElevatedButton), findsOneWidget);
});
```

**Why it's bad:** Creates many tests for simple UI rendering.

**Better:** Consolidate into comprehensive test:
```dart
testWidgets('should display all UI elements correctly', (tester) async {
  await tester.pumpWidget(createTestableWidget(child: MyWidget()));
  expect(find.text('Title'), findsOneWidget);
  expect(find.text('Subtitle'), findsOneWidget);
  expect(find.byType(ElevatedButton), findsOneWidget);
});
```

---

## Test Patterns

### Pattern 1: Comprehensive Test Blocks

Instead of multiple small tests, combine related checks:

```dart
test('should validate input, process data, and return correct result', () {
  // Arrange
  final input = ValidInput();
  
  // Act
  final result = service.process(input);
  
  // Assert - multiple related checks
  expect(result.isValid, isTrue);
  expect(result.data, isNotNull);
  expect(result.timestamp, isNotNull);
  expect(result.processedBy, equals('service'));
});
```

### Pattern 2: Round-Trip Tests

For serialization, test both directions:

```dart
test('should serialize and deserialize correctly (round-trip)', () {
  final original = Model(/* ... */);
  final json = original.toJson();
  final restored = Model.fromJson(json);
  expect(restored, equals(original));
});
```

### Pattern 3: Behavior-Driven Tests

Focus on what the code does, not how:

```dart
test('should calculate total price including tax and discounts', () {
  final cart = Cart(items: [Item(price: 100)]);
  final total = cart.calculateTotal(taxRate: 0.1, discount: 0.05);
  expect(total, closeTo(104.5, 0.01)); // 100 * 1.1 * 0.95
});
```

### Pattern 4: Error Handling Tests

Test how code handles failures:

```dart
test('should handle network errors and return failure result', () async {
  when(() => mockNetwork.fetch()).thenThrow(NetworkException());
  final result = await service.fetchData();
  expect(result.isFailure, isTrue);
  expect(result.error, isA<NetworkException>());
});
```

---

## Examples: Good vs Bad

### Example 1: Model Test

**❌ BAD:**
```dart
test('should create spot with properties', () {
  final spot = Spot(id: '1', name: 'Test', latitude: 40.0, longitude: -74.0);
  expect(spot.id, equals('1'));
  expect(spot.name, equals('Test'));
  expect(spot.latitude, equals(40.0));
  expect(spot.longitude, equals(-74.0));
});
```

**✅ GOOD:**
```dart
test('should validate coordinates and throw ArgumentError for invalid values', () {
  expect(() => Spot(latitude: 200, longitude: 0), throwsArgumentError);
  expect(() => Spot(latitude: 0, longitude: 200), throwsArgumentError);
  expect(() => Spot(latitude: 40.0, longitude: -74.0), returnsNormally);
});

test('should serialize and deserialize correctly (round-trip)', () {
  final spot = Spot(id: '1', name: 'Test', latitude: 40.0, longitude: -74.0);
  final json = spot.toJson();
  final restored = Spot.fromJson(json);
  expect(restored, equals(spot));
});
```

### Example 2: Service Test

**❌ BAD:**
```dart
test('should create service', () {
  final service = DataService();
  expect(service, isNotNull);
});

test('should have repository', () {
  final service = DataService();
  expect(service.repository, isNotNull);
});
```

**✅ GOOD:**
```dart
test('should fetch data and handle errors gracefully', () async {
  when(() => mockRepository.fetch()).thenAnswer((_) async => Data(id: '1'));
  final result = await service.fetchData();
  expect(result.isSuccess, isTrue);
  expect(result.data?.id, equals('1'));
  
  when(() => mockRepository.fetch()).thenThrow(Exception('Error'));
  final errorResult = await service.fetchData();
  expect(errorResult.isFailure, isTrue);
});
```

### Example 3: Widget Test

**❌ BAD:**
```dart
testWidgets('should display title', (tester) async {
  expect(find.text('Title'), findsOneWidget);
});

testWidgets('should display button', (tester) async {
  expect(find.byType(ElevatedButton), findsOneWidget);
});

testWidgets('should display input field', (tester) async {
  expect(find.byType(TextField), findsOneWidget);
});
```

**✅ GOOD:**
```dart
testWidgets('should display form, validate input, and submit when valid', (tester) async {
  await tester.pumpWidget(createTestableWidget(child: SignupForm()));
  
  // Display
  expect(find.text('Sign Up'), findsOneWidget);
  expect(find.byType(TextField), findsOneWidget);
  expect(find.byType(ElevatedButton), findsOneWidget);
  
  // Validation
  await tester.enterText(find.byKey(Key('email')), 'invalid');
  await tester.tap(find.byKey(Key('submit')));
  await tester.pump();
  expect(find.text('Invalid email'), findsOneWidget);
  
  // Submit
  await tester.enterText(find.byKey(Key('email')), 'test@example.com');
  await tester.tap(find.byKey(Key('submit')));
  await tester.pumpAndSettle();
  verify(() => mockAuthBloc.add(SignupRequested(email: 'test@example.com'))).called(1);
});
```

---

## Common Anti-Patterns

### 1. Testing Getters
```dart
// ❌ BAD
test('should return name', () {
  expect(model.name, equals('Test'));
});

// ✅ GOOD - Test behavior that uses the name
test('should format display name correctly', () {
  expect(model.displayName, equals('Test (ID: 1)'));
});
```

### 2. Testing Enum Values
```dart
// ❌ BAD
test('should have status', () {
  expect(model.status, equals(Status.active));
});

// ✅ GOOD - Test behavior based on status
test('should allow editing when status is active', () {
  final model = Model(status: Status.active);
  expect(model.canEdit, isTrue);
});
```

### 3. Testing List Length Only
```dart
// ❌ BAD
test('should have items', () {
  expect(list.items.length, equals(3));
});

// ✅ GOOD - Test behavior with the list
test('should filter items correctly', () {
  final filtered = list.filter((item) => item.isActive);
  expect(filtered.length, equals(2));
  expect(filtered.every((item) => item.isActive), isTrue);
});
```

---

## Best Practices

### 1. Use Descriptive Test Names
- ✅ `test('should validate email format and reject invalid addresses')`
- ❌ `test('email test')`

### 2. Follow Arrange-Act-Assert Pattern
```dart
test('should calculate total correctly', () {
  // Arrange
  final items = [Item(price: 10), Item(price: 20)];
  
  // Act
  final total = cart.calculateTotal(items);
  
  // Assert
  expect(total, equals(30));
});
```

### 3. Test One Thing Per Test (But Consolidate Related Checks)
- ✅ One test with multiple related assertions
- ❌ Multiple tests for the same behavior

### 4. Use Test Helpers and Factories
```dart
// ✅ GOOD
final spot = TestDataFactory.createSpot();

// ❌ BAD
final spot = Spot(id: '1', name: 'Test', latitude: 40.0, longitude: -74.0, /* ... 10 more params */);
```

### 5. Mock External Dependencies
```dart
// ✅ GOOD
when(() => mockRepository.fetch()).thenAnswer((_) async => data);

// ❌ BAD
final repository = RealRepository(); // Uses real network
```

### 6. Test Error Cases
```dart
// ✅ GOOD
test('should handle network errors gracefully', () async {
  when(() => mockNetwork.fetch()).thenThrow(NetworkException());
  final result = await service.fetchData();
  expect(result.isFailure, isTrue);
});
```

### 7. Document Complex Tests
```dart
test('should calculate distance using Haversine formula', () {
  // Haversine formula: a = sin²(Δφ/2) + cos φ1 ⋅ cos φ2 ⋅ sin²(Δλ/2)
  // Expected distance: ~3944 km between NYC and LA
  final distance = calculateDistance(nyc, la);
  expect(distance, closeTo(3944.0, 10.0));
});
```

---

## Resources

### Documentation
- **Test Refactoring Plan:** `docs/plans/test_refactoring/TEST_REFACTORING_PLAN.md`
- **Quick Reference:** `docs/plans/test_refactoring/TEST_QUALITY_QUICK_REFERENCE.md`
- **Phase 6 Plan:** `docs/plans/test_refactoring/PHASE_6_CONTINUOUS_IMPROVEMENT_PLAN.md`

### Templates
- **Unit Test Template:** `test/templates/unit_test_template.dart`
- **Widget Test Template:** `test/templates/widget_test_template.dart`
- **Service Test Template:** `test/templates/service_test_template.dart`
- **Integration Test Template:** `test/templates/integration_test_template.dart`

### Tools
- **Quality Checker:** `dart run scripts/check_test_quality.dart [file]`
- **Pre-Commit Hook:** `.git/hooks/pre-commit` (runs automatically)

### Examples
- **Good Model Tests:** `test/unit/models/spot_test.dart`
- **Good Service Tests:** `test/unit/services/*_test.dart`
- **Good Widget Tests:** `test/widget/**/*_test.dart`

---

**Last Updated:** December 8, 2025  
**Status:** ✅ Active - Use this guide when writing new tests

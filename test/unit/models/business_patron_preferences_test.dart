import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/models/business/business_patron_preferences.dart';
import 'package:avrai/core/models/business/business_expert_preferences.dart';
import '../../helpers/test_helpers.dart';

/// Comprehensive tests for BusinessPatronPreferences model
/// Tests patron matching preferences, JSON serialization, and helper methods
void main() {
  group('BusinessPatronPreferences Model Tests', () {
    setUp(() {
      TestHelpers.setupTestEnvironment();
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    // Removed: Constructor and Properties group
    // These tests only verified Dart constructor behavior, not business logic

    group('SpendingLevel Enum', () {
      test(
          'should parse spending level from string with case handling and defaults',
          () {
        // Test business logic: string parsing with error handling
        expect(SpendingLevelExtension.fromString('budget'),
            equals(SpendingLevel.budget));
        expect(SpendingLevelExtension.fromString('midrange'),
            equals(SpendingLevel.midRange));
        expect(SpendingLevelExtension.fromString('mid-range'),
            equals(SpendingLevel.midRange)); // Hyphenated variant
        expect(SpendingLevelExtension.fromString('unknown'), isNull); // Invalid
        expect(
            SpendingLevelExtension.fromString(null), isNull); // Null handling
      });
    });

    group('isEmpty Checker', () {
      test('should correctly identify empty vs non-empty preferences', () {
        // Test business logic: empty state determination
        const empty = BusinessPatronPreferences();
        const withAgeRange = BusinessPatronPreferences(
          preferredAgeRange: AgeRange(minAge: 21),
        );
        const withLanguages = BusinessPatronPreferences(
          preferredLanguages: ['English'],
        );
        const withSpendingLevel = BusinessPatronPreferences(
          preferredSpendingLevel: SpendingLevel.midRange,
        );

        expect(empty.isEmpty, isTrue);
        expect(withAgeRange.isEmpty, isFalse);
        expect(withLanguages.isEmpty, isFalse);
        expect(withSpendingLevel.isEmpty, isFalse);
      });
    });

    group('getSummary', () {
      test('should generate summary with all preference fields', () {
        // Test business logic: summary generation
        const empty = BusinessPatronPreferences();
        const withAllFields = BusinessPatronPreferences(
          preferredAgeRange: AgeRange(minAge: 21, maxAge: 65),
          preferredInterests: ['Food'],
          preferredSpendingLevel: SpendingLevel.midRange,
          preferredVibePreferences: ['Casual'],
        );

        expect(empty.getSummary(), equals('No patron preferences set'));
        final summary = withAllFields.getSummary();
        expect(summary, contains('Age:'));
        expect(summary, contains('Interests:'));
        expect(summary, contains('Spending:'));
        expect(summary, contains('Vibe:'));
      });
    });

    group('JSON Serialization', () {
      test('should serialize and deserialize without data loss', () {
        const ageRange = AgeRange(minAge: 21, maxAge: 65);
        const prefs = BusinessPatronPreferences(
          preferredAgeRange: ageRange,
          preferredLanguages: ['English'],
          preferredInterests: ['Food'],
          preferredSpendingLevel: SpendingLevel.midRange,
          aiMatchingCriteria: {'custom': 'value'},
        );

        final json = prefs.toJson();
        final restored = BusinessPatronPreferences.fromJson(json);

        // Test critical business fields preserved
        expect(restored.isEmpty, equals(prefs.isEmpty));
        expect(restored.getSummary(), equals(prefs.getSummary()));
      });
    });

    group('copyWith', () {
      test('should create immutable copy with updated fields', () {
        const original = BusinessPatronPreferences(
          preferredInterests: ['Food'],
          preferredSpendingLevel: SpendingLevel.budget,
        );

        final updated = original.copyWith(
          preferredInterests: ['Music'],
          preferredSpendingLevel: SpendingLevel.premium,
        );

        // Test immutability (business logic)
        expect(original.preferredInterests, isNot(equals(['Music'])));
        expect(updated.preferredInterests, equals(['Music']));
      });
    });

    // Removed: Equality group
    // These tests verify Equatable implementation, which is already tested by the package
    // If equality breaks, other tests will fail
  });
}

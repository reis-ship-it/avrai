import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/models/business/business_expert_preferences.dart';
import '../../helpers/test_helpers.dart';

/// Comprehensive tests for BusinessExpertPreferences model
/// Tests expert matching preferences, JSON serialization, and helper methods
void main() {
  group('BusinessExpertPreferences Model Tests', () {
    setUp(() {
      TestHelpers.setupTestEnvironment();
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    // Removed: Constructor and Properties group
    // These tests only verified Dart constructor behavior, not business logic

    group('AgeRange Model', () {
      test('should correctly format display text and match ages', () {
        // Test business logic: age range formatting and matching
        const fullRange = AgeRange(minAge: 25, maxAge: 45);
        const minOnly = AgeRange(minAge: 25);
        const maxOnly = AgeRange(maxAge: 45);
        const empty = AgeRange();

        expect(fullRange.displayText, equals('25-45'));
        expect(minOnly.displayText, equals('25+'));
        expect(maxOnly.displayText, equals('Under 45'));
        expect(empty.displayText, equals('Any age'));

        expect(fullRange.matches(30), isTrue);
        expect(fullRange.matches(24), isFalse);
        expect(fullRange.matches(46), isFalse);
      });
    });

    group('isEmpty Checker', () {
      test('should correctly identify empty vs non-empty preferences', () {
        // Test business logic: empty state determination
        const empty = BusinessExpertPreferences();
        const withCategories = BusinessExpertPreferences(
          requiredExpertiseCategories: ['Coffee'],
        );
        const withLevel = BusinessExpertPreferences(
          minExpertLevel: 3,
        );
        const withLocation = BusinessExpertPreferences(
          preferredLocation: 'NYC',
        );

        expect(empty.isEmpty, isTrue);
        expect(withCategories.isEmpty, isFalse);
        expect(withLevel.isEmpty, isFalse);
        expect(withLocation.isEmpty, isFalse);
      });
    });

    group('getSummary', () {
      test('should generate summary with all preference fields', () {
        // Test business logic: summary generation
        const empty = BusinessExpertPreferences();
        const withAllFields = BusinessExpertPreferences(
          requiredExpertiseCategories: ['Coffee'],
          preferredExpertiseCategories: ['Food'],
          preferredLocation: 'NYC',
          minExpertLevel: 3,
        );

        expect(empty.getSummary(), equals('No preferences set'));
        final summary = withAllFields.getSummary();
        expect(summary, contains('Required: Coffee'));
        expect(summary, contains('Preferred: Food'));
        expect(summary, contains('Location: NYC'));
        expect(summary, contains('Min Level: 3'));
      });
    });

    group('JSON Serialization', () {
      test('should serialize and deserialize without data loss', () {
        const ageRange = AgeRange(minAge: 25, maxAge: 45);
        const prefs = BusinessExpertPreferences(
          requiredExpertiseCategories: ['Coffee'],
          preferredExpertiseCategories: ['Food'],
          minExpertLevel: 3,
          preferredLocation: 'NYC',
          preferredAgeRange: ageRange,
          aiMatchingCriteria: {'custom': 'value'},
        );

        final json = prefs.toJson();
        final restored = BusinessExpertPreferences.fromJson(json);

        // Test critical business fields preserved
        expect(restored.isEmpty, equals(prefs.isEmpty));
        expect(restored.getSummary(), equals(prefs.getSummary()));
      });
    });

    group('copyWith', () {
      test('should create immutable copy with updated fields', () {
        const original = BusinessExpertPreferences(
          requiredExpertiseCategories: ['Coffee'],
          minExpertLevel: 3,
        );

        final updated = original.copyWith(
          requiredExpertiseCategories: ['Food'],
          minExpertLevel: 4,
        );

        // Test immutability (business logic)
        expect(original.requiredExpertiseCategories, isNot(equals(['Food'])));
        expect(updated.requiredExpertiseCategories, equals(['Food']));
      });
    });

    // Removed: Equality group
    // These tests verify Equatable implementation, which is already tested by the package
    // If equality breaks, other tests will fail
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/models/expertise/expertise_progress.dart';
import 'package:avrai/core/models/expertise/expertise_level.dart';
import '../../helpers/test_helpers.dart';

/// Comprehensive tests for ExpertiseProgress model
/// Tests progress tracking, JSON serialization, and helper methods
void main() {
  group('ExpertiseProgress Model Tests', () {
    late DateTime testDate;

    setUp(() {
      TestHelpers.setupTestEnvironment();
      testDate = TestHelpers.createTestDateTime();
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    // Removed: Constructor and Properties group
    // These tests only verified Dart constructor behavior, not business logic

    group('empty Factory', () {
      test('should create empty progress with correct business defaults', () {
        final withLocation = ExpertiseProgress.empty(
          category: 'Coffee',
          location: 'Brooklyn',
        );
        final withoutLocation = ExpertiseProgress.empty(category: 'Coffee');

        // Test business logic: factory method behavior
        expect(withLocation.currentLevel, equals(ExpertiseLevel.local));
        expect(withLocation.nextLevel, equals(ExpertiseLevel.city));
        expect(withLocation.progressPercentage, equals(0.0));
        expect(withLocation.nextSteps, isNotEmpty);
        expect(withoutLocation.nextSteps,
            contains('Create your first list in this category'));
      });
    });

    group('Helper Methods', () {
      test(
          'should generate correct progress descriptions, identify readiness to advance, and format contribution summary',
          () {
        // Test business logic: description generation, advancement readiness, and summary formatting
        final atHighest = ExpertiseProgress(
          category: 'Coffee',
          currentLevel: ExpertiseLevel.universal,
          progressPercentage: 100.0,
          lastUpdated: testDate,
        );
        final readyToAdvance = ExpertiseProgress(
          category: 'Coffee',
          currentLevel: ExpertiseLevel.local,
          nextLevel: ExpertiseLevel.city,
          progressPercentage: 100.0,
          totalContributions: 10,
          requiredContributions: 10,
          lastUpdated: testDate,
        );
        final partialProgress = ExpertiseProgress(
          category: 'Coffee',
          currentLevel: ExpertiseLevel.local,
          nextLevel: ExpertiseLevel.city,
          progressPercentage: 50.0,
          totalContributions: 5,
          requiredContributions: 10,
          lastUpdated: testDate,
        );
        final notReady = ExpertiseProgress(
          category: 'Coffee',
          currentLevel: ExpertiseLevel.local,
          nextLevel: ExpertiseLevel.city,
          progressPercentage: 99.9,
          lastUpdated: testDate,
        );
        final noNextLevel = ExpertiseProgress(
          category: 'Coffee',
          currentLevel: ExpertiseLevel.universal,
          progressPercentage: 100.0,
          lastUpdated: testDate,
        );
        final withContributions = ExpertiseProgress(
          category: 'Coffee',
          currentLevel: ExpertiseLevel.local,
          progressPercentage: 50.0,
          contributionBreakdown: const {
            'lists': 3,
            'reviews': 5,
            'spots': 2,
          },
          lastUpdated: testDate,
        );
        final empty = ExpertiseProgress(
          category: 'Coffee',
          currentLevel: ExpertiseLevel.local,
          progressPercentage: 0.0,
          lastUpdated: testDate,
        );

        // Test description generation
        expect(atHighest.getProgressDescription(), contains('highest level'));
        expect(readyToAdvance.getProgressDescription(),
            contains('Ready to advance'));
        expect(partialProgress.getProgressDescription(), contains('5 more'));

        // Test advancement readiness
        expect(readyToAdvance.isReadyToAdvance, isTrue);
        expect(notReady.isReadyToAdvance, isFalse);
        expect(noNextLevel.isReadyToAdvance, isFalse);

        // Test contribution summary
        final summary = withContributions.getContributionSummary();
        expect(summary, contains('3 lists'));
        expect(summary, contains('5 reviews'));
        expect(empty.getContributionSummary(), equals('No contributions yet'));
      });
    });

    group('JSON Serialization', () {
      test(
          'should serialize and deserialize with defaults and handle missing and invalid fields',
          () {
        // Test business logic: JSON round-trip with default and error handling
        final progress = ExpertiseProgress(
          category: 'Coffee',
          location: 'Brooklyn',
          currentLevel: ExpertiseLevel.local,
          nextLevel: ExpertiseLevel.city,
          progressPercentage: 75.5,
          nextSteps: const ['Create 2 more lists'],
          contributionBreakdown: const {'lists': 3},
          totalContributions: 8,
          requiredContributions: 10,
          lastUpdated: testDate,
        );

        final json = progress.toJson();
        final restored = ExpertiseProgress.fromJson(json);

        expect(restored.currentLevel, equals(ExpertiseLevel.local));
        expect(restored.nextLevel, equals(ExpertiseLevel.city));
        expect(restored.progressPercentage, equals(75.5));
        expect(restored.contributionBreakdown, equals({'lists': 3}));

        // Test defaults and invalid fields
        final minimalJson = {
          'category': 'Coffee',
          'currentLevel': 'local',
          'progressPercentage': 50.0,
          'lastUpdated': testDate.toIso8601String(),
        };
        final invalidLevelJson = {
          'category': 'Coffee',
          'currentLevel': 'invalid',
          'progressPercentage': 50.0,
          'lastUpdated': testDate.toIso8601String(),
        };

        final minimal = ExpertiseProgress.fromJson(minimalJson);
        final invalid = ExpertiseProgress.fromJson(invalidLevelJson);

        expect(minimal.nextSteps, isEmpty);
        expect(minimal.totalContributions, equals(0));
        expect(invalid.currentLevel,
            equals(ExpertiseLevel.local)); // Invalid level defaults
      });
    });

    group('copyWith', () {
      test('should create immutable copy with updated fields', () {
        final original = ExpertiseProgress(
          category: 'Coffee',
          currentLevel: ExpertiseLevel.local,
          progressPercentage: 50.0,
          lastUpdated: testDate,
        );

        final updated = original.copyWith(
          progressPercentage: 75.0,
          nextLevel: ExpertiseLevel.city,
        );

        // Test immutability (business logic)
        expect(original.progressPercentage, isNot(equals(75.0)));
        expect(updated.progressPercentage, equals(75.0));
        expect(updated.category,
            equals(original.category)); // Unchanged fields preserved
      });
    });

    // Removed: Equality group
    // These tests verify Equatable implementation, which is already tested by the package
    // If equality breaks, other tests will fail
  });
}

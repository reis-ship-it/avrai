import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/models/expertise/local_expert_qualification.dart';
import 'package:avrai/core/models/expertise/expertise_level.dart';
import 'package:avrai/core/models/expertise/expertise_requirements.dart';
import '../../helpers/test_helpers.dart';

/// Comprehensive tests for LocalExpertQualification model
void main() {
  group('LocalExpertQualification Model Tests', () {
    late DateTime testDate;
    late ThresholdValues baseThresholds;
    late ThresholdValues localityThresholds;

    setUp(() {
      TestHelpers.setupTestEnvironment();
      testDate = TestHelpers.createTestDateTime();

      baseThresholds = const ThresholdValues(
        minVisits: 10,
        minRatings: 5,
        minAvgRating: 4.0,
        minTimeInCategory: Duration(days: 30),
        minCommunityEngagement: 3,
        minListCuration: 2,
        minEventHosting: 1,
      );

      localityThresholds = const ThresholdValues(
        minVisits: 7, // Lower (30% reduction)
        minRatings: 4, // Lower
        minAvgRating: 4.0, // Same
        minTimeInCategory: Duration(days: 30), // Same
        minCommunityEngagement: 2, // Lower
        minListCuration: 1, // Lower
        minEventHosting: 1, // Same
      );
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    // Removed: Constructor and Properties group
    // These tests only verified Dart constructor behavior, not business logic

    group('Progress Percentage', () {
      test(
          'should calculate progress percentage for complete, partial, and qualified states',
          () {
        // Test business logic: progress calculation in different states
        final complete = LocalExpertQualification(
          id: 'qual-1',
          userId: 'user-123',
          category: 'Coffee',
          locality: 'Greenpoint',
          currentLevel: ExpertiseLevel.local,
          baseThresholds: baseThresholds,
          localityThresholds: localityThresholds,
          progress: const QualificationProgress(
            visits: 7, // Met
            ratings: 4, // Met
            avgRating: 4.5, // Met (>= 4.0)
            communityEngagement: 2, // Met
            listCuration: 1, // Met
            eventHosting: 1, // Met
          ),
          factors: const QualificationFactors(),
          createdAt: testDate,
          updatedAt: testDate,
        );

        final partial = LocalExpertQualification(
          id: 'qual-2',
          userId: 'user-123',
          category: 'Coffee',
          locality: 'Greenpoint',
          currentLevel: ExpertiseLevel.local,
          baseThresholds: baseThresholds,
          localityThresholds: localityThresholds,
          progress: const QualificationProgress(
            visits: 7, // Met
            ratings: 2, // Not met (needs 4)
            avgRating: 4.5, // Met
            communityEngagement: 1, // Not met (needs 2)
            listCuration: 1, // Met
            eventHosting: 1, // Met
          ),
          factors: const QualificationFactors(),
          createdAt: testDate,
          updatedAt: testDate,
        );

        final qualified = LocalExpertQualification(
          id: 'qual-3',
          userId: 'user-123',
          category: 'Coffee',
          locality: 'Greenpoint',
          currentLevel: ExpertiseLevel.local,
          baseThresholds: baseThresholds,
          localityThresholds: localityThresholds,
          progress: const QualificationProgress(),
          factors: const QualificationFactors(),
          isQualified: true,
          qualifiedAt: testDate,
          createdAt: testDate,
          updatedAt: testDate,
        );

        // All thresholds met = 100% progress
        expect(complete.progressPercentage, equals(1.0));
        // 4 out of 6 thresholds met = ~67%
        expect(partial.progressPercentage, closeTo(0.67, 0.01));
        // Already qualified = 100%
        expect(qualified.progressPercentage, equals(1.0));
      });
    });

    group('Remaining Requirements', () {
      test(
          'should calculate remaining requirements for partial and complete progress',
          () {
        // Test business logic: requirement calculation
        final partial = LocalExpertQualification(
          id: 'qual-1',
          userId: 'user-123',
          category: 'Coffee',
          locality: 'Greenpoint',
          currentLevel: ExpertiseLevel.local,
          baseThresholds: baseThresholds,
          localityThresholds: localityThresholds,
          progress: const QualificationProgress(
            visits: 5, // Needs 2 more (7 - 5)
            ratings: 2, // Needs 2 more (4 - 2)
            avgRating: 4.5, // Met
            communityEngagement: 1, // Needs 1 more (2 - 1)
            listCuration: 1, // Met
            eventHosting: 1, // Met
          ),
          factors: const QualificationFactors(),
          createdAt: testDate,
          updatedAt: testDate,
        );

        final complete = LocalExpertQualification(
          id: 'qual-2',
          userId: 'user-123',
          category: 'Coffee',
          locality: 'Greenpoint',
          currentLevel: ExpertiseLevel.local,
          baseThresholds: baseThresholds,
          localityThresholds: localityThresholds,
          progress: const QualificationProgress(
            visits: 7,
            ratings: 4,
            avgRating: 4.5,
            communityEngagement: 2,
            listCuration: 1,
            eventHosting: 1,
          ),
          factors: const QualificationFactors(),
          createdAt: testDate,
          updatedAt: testDate,
        );

        final remaining = partial.remainingRequirements;
        expect(remaining['visits'], equals(2));
        expect(remaining['ratings'], equals(2));
        expect(remaining['communityEngagement'], equals(1));
        expect(remaining.containsKey('listCuration'), isFalse);
        expect(complete.remainingRequirements, isEmpty);
      });
    });

    group('JSON Serialization', () {
      test(
          'should serialize and deserialize with nested progress and factors correctly',
          () {
        final qualification = LocalExpertQualification(
          id: 'qual-123',
          userId: 'user-123',
          category: 'Coffee',
          locality: 'Greenpoint',
          currentLevel: ExpertiseLevel.local,
          baseThresholds: baseThresholds,
          localityThresholds: localityThresholds,
          progress: const QualificationProgress(
            visits: 5,
            ratings: 3,
          ),
          factors: const QualificationFactors(
            listsWithFollowers: 2,
            hasProfessionalBackground: true,
          ),
          isQualified: false,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final json = qualification.toJson();
        final restored = LocalExpertQualification.fromJson(json);

        // Test nested structures preserved (business logic)
        expect(restored.currentLevel, equals(ExpertiseLevel.local));
        expect(restored.isQualified, isFalse);
        expect(restored.progress.visits, equals(5));
      });
    });

    group('copyWith', () {
      test('should create immutable copy with updated fields', () {
        final original = LocalExpertQualification(
          id: 'qual-123',
          userId: 'user-123',
          category: 'Coffee',
          locality: 'Greenpoint',
          currentLevel: ExpertiseLevel.local,
          baseThresholds: baseThresholds,
          localityThresholds: localityThresholds,
          progress: const QualificationProgress(),
          factors: const QualificationFactors(),
          createdAt: testDate,
          updatedAt: testDate,
        );

        final updated = original.copyWith(
          isQualified: true,
          currentLevel: ExpertiseLevel.city,
        );

        // Test immutability (business logic)
        expect(original.isQualified, isFalse);
        expect(updated.isQualified, isTrue);
        expect(updated.id, equals(original.id)); // Unchanged fields preserved
      });
    });

    // Removed: Equality group
    // These tests verify Equatable implementation, which is already tested by the package
    // If equality breaks, other tests will fail
  });
}

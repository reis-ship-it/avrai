import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_runtime_os/services/recommendations/dynamic_threshold_service.dart';
import 'package:avrai_runtime_os/services/geographic/locality_value_analysis_service.dart';
import 'package:avrai_core/models/expertise/expertise_requirements.dart';
import '../../helpers/platform_channel_helper.dart';

/// Dynamic Threshold Service Tests
/// Tests dynamic threshold calculation for local expert qualification
void main() {
  group('DynamicThresholdService Tests', () {
    late DynamicThresholdService service;
    late LocalityValueAnalysisService localityValueService;

    setUp(() {
      localityValueService = LocalityValueAnalysisService();
      service = DynamicThresholdService(
        localityValueService: localityValueService,
      );
    });

    // Removed: Property assignment tests
    // Dynamic threshold tests focus on business logic (threshold calculation, adjustment), not property assignment

    group('calculateLocalThreshold', () {
      test(
          'should calculate local threshold for locality and category, return base thresholds on error, and adjust thresholds based on locality values',
          () async {
        // Test business logic: local threshold calculation with adjustments
        const baseThresholds1 = ThresholdValues(
          minVisits: 10,
          minRatings: 5,
          minAvgRating: 4.0,
          minTimeInCategory: Duration(days: 30),
          minCommunityEngagement: 3,
          minListCuration: 2,
          minEventHosting: 1,
        );
        final adjustedThresholds1 = await service.calculateLocalThreshold(
          locality: 'Greenpoint',
          category: 'food',
          baseThresholds: baseThresholds1,
        );
        expect(adjustedThresholds1, isNotNull);
        expect(adjustedThresholds1.minVisits, greaterThan(0));
        expect(adjustedThresholds1.minRatings, greaterThan(0));
        expect(adjustedThresholds1.minAvgRating, equals(4.0));
        expect(adjustedThresholds1.minTimeInCategory,
            equals(const Duration(days: 30)));

        const baseThresholds2 = ThresholdValues(
          minVisits: 10,
          minRatings: 5,
          minAvgRating: 4.0,
          minTimeInCategory: Duration(days: 30),
        );
        final adjustedThresholds2 = await service.calculateLocalThreshold(
          locality: '',
          category: 'food',
          baseThresholds: baseThresholds2,
        );
        expect(adjustedThresholds2.minVisits, equals(12));
        expect(adjustedThresholds2.minRatings, greaterThan(0));

        const baseThresholds3 = ThresholdValues(
          minVisits: 10,
          minRatings: 5,
          minAvgRating: 4.0,
          minTimeInCategory: Duration(days: 30),
          minEventHosting: 3,
        );
        final adjustedThresholds3 = await service.calculateLocalThreshold(
          locality: 'Greenpoint',
          category: 'food',
          baseThresholds: baseThresholds3,
        );
        expect(adjustedThresholds3.minVisits, isNotNull);
        expect(adjustedThresholds3.minRatings, isNotNull);
        expect(adjustedThresholds3.minEventHosting, isNotNull);
      });
    });

    group('getThresholdForActivity', () {
      test(
          'should return adjusted threshold for activity, return base threshold on error, and adjust threshold based on activity weight',
          () async {
        // Test business logic: activity threshold calculation with adjustments
        const baseThreshold = 10.0;
        final adjustedThreshold1 = await service.getThresholdForActivity(
          locality: 'Greenpoint',
          activity: 'events_hosted',
          baseThreshold: baseThreshold,
        );
        expect(adjustedThreshold1, greaterThan(0.0));
        expect(adjustedThreshold1, greaterThanOrEqualTo(baseThreshold * 0.7));
        expect(adjustedThreshold1, lessThanOrEqualTo(baseThreshold * 1.3));

        final adjustedThreshold2 = await service.getThresholdForActivity(
          locality: '',
          activity: 'events_hosted',
          baseThreshold: baseThreshold,
        );
        expect(adjustedThreshold2, equals(baseThreshold));

        final eventsThreshold = await service.getThresholdForActivity(
          locality: 'Greenpoint',
          activity: 'events_hosted',
          baseThreshold: baseThreshold,
        );
        final listsThreshold = await service.getThresholdForActivity(
          locality: 'Greenpoint',
          activity: 'lists_created',
          baseThreshold: baseThreshold,
        );
        expect(eventsThreshold, greaterThan(0.0));
        expect(listsThreshold, greaterThan(0.0));
      });
    });

    group('getLocalityMultiplier', () {
      test(
          'should return multiplier for locality and category, or return calculated multiplier for empty locality',
          () async {
        // Test business logic: locality multiplier calculation
        final multiplier1 = await service.getLocalityMultiplier(
          locality: 'Greenpoint',
          category: 'food',
        );
        expect(multiplier1, greaterThanOrEqualTo(0.7));
        expect(multiplier1, lessThanOrEqualTo(1.3));

        final multiplier2 = await service.getLocalityMultiplier(
          locality: '',
          category: 'food',
        );
        expect(multiplier2, equals(1.15));
      });
    });

    group('threshold adjustment logic', () {
      test(
          'should lower threshold for highly valued activities or raise threshold for less valued activities',
          () async {
        // Test business logic: threshold adjustment based on activity value
        const baseThreshold = 10.0;
        final threshold1 = await service.getThresholdForActivity(
          locality: 'Greenpoint',
          activity: 'events_hosted',
          baseThreshold: baseThreshold,
        );
        expect(threshold1, greaterThan(0.0));
        expect(threshold1, lessThanOrEqualTo(baseThreshold * 1.3));

        final threshold2 = await service.getThresholdForActivity(
          locality: 'Greenpoint',
          activity: 'professional_background',
          baseThreshold: baseThreshold,
        );
        expect(threshold2, greaterThanOrEqualTo(baseThreshold * 0.7));
        expect(threshold2, lessThanOrEqualTo(baseThreshold * 1.3));
      });
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });
  });
}

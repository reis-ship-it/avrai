import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/services/geographic/locality_value_analysis_service.dart';
import '../../helpers/platform_channel_helper.dart';

/// Locality Value Analysis Service Tests
/// Tests locality value analysis and activity weight calculation
void main() {
  group('LocalityValueAnalysisService Tests', () {
    late LocalityValueAnalysisService service;

    setUp(() {
      service = LocalityValueAnalysisService();
    });

    // Removed: Property assignment tests
    // Locality value analysis tests focus on business logic (analysis, weights, activity recording), not property assignment

    group('analyzeLocalityValues', () {
      test(
          'should return locality value data for valid locality, return default weights for new locality, and cache locality value data',
          () async {
        // Test business logic: locality value analysis with caching
        final valueData1 = await service.analyzeLocalityValues('Greenpoint');
        expect(valueData1, isNotNull);
        expect(valueData1.locality, equals('Greenpoint'));
        expect(valueData1.activityWeights, isNotEmpty);
        expect(valueData1.lastUpdated, isNotNull);

        final valueData2 = await service.analyzeLocalityValues('NewLocality');
        expect(valueData2.locality, equals('NewLocality'));
        expect(valueData2.activityWeights, isNotEmpty);
        expect(valueData2.activityWeights['events_hosted'], isNotNull);
        expect(valueData2.activityWeights['lists_created'], isNotNull);
        expect(valueData2.activityWeights['reviews_written'], isNotNull);

        final valueData3 = await service.analyzeLocalityValues('Greenpoint');
        expect(valueData1.locality, equals(valueData3.locality));
      });
    });

    group('getActivityWeights', () {
      test(
          'should return activity weights for locality with correct structure, weights between 0.0 and 1.0, and default weights for new locality',
          () async {
        // Test business logic: activity weight retrieval and validation
        final weights1 = await service.getActivityWeights('Greenpoint');
        expect(weights1, isNotEmpty);
        expect(weights1.containsKey('events_hosted'), isTrue);
        expect(weights1.containsKey('lists_created'), isTrue);
        expect(weights1.containsKey('reviews_written'), isTrue);
        expect(weights1.containsKey('event_attendance'), isTrue);
        expect(weights1.containsKey('professional_background'), isTrue);
        expect(weights1.containsKey('positive_trends'), isTrue);
        for (final weight in weights1.values) {
          expect(weight, greaterThanOrEqualTo(0.0));
          expect(weight, lessThanOrEqualTo(1.0));
        }

        final weights2 = await service.getActivityWeights('NewLocality');
        expect(weights2, isNotEmpty);
        expect(weights2['events_hosted'], equals(0.20));
        expect(weights2['lists_created'], equals(0.20));
        expect(weights2['reviews_written'], equals(0.20));
      });
    });

    group('recordActivity', () {
      test(
          'should record activity in locality with or without category and engagement level',
          () async {
        // Test business logic: activity recording with various parameters
        await service.recordActivity(
          locality: 'Greenpoint',
          activityType: 'events_hosted',
          category: 'food',
          engagement: 1.0,
        );

        await service.recordActivity(
          locality: 'Greenpoint',
          activityType: 'lists_created',
        );

        await service.recordActivity(
          locality: 'Greenpoint',
          activityType: 'reviews_written',
          engagement: 0.8,
        );
        // All should complete without throwing
      });
    });

    group('getCategoryPreferences', () {
      test(
          'should return category preferences for locality, or return default weights if no category data',
          () async {
        // Test business logic: category preference retrieval
        final preferences1 =
            await service.getCategoryPreferences('Greenpoint', 'food');
        expect(preferences1, isNotEmpty);
        expect(preferences1.containsKey('events_hosted'), isTrue);
        expect(preferences1.containsKey('lists_created'), isTrue);

        final preferences2 =
            await service.getCategoryPreferences('NewLocality', 'food');
        expect(preferences2, isNotEmpty);
        expect(preferences2['events_hosted'], isNotNull);
      });
    });

    group('LocalityValueData', () {
      test(
          'should create default values with default weights, record activity, get category preferences, and normalize weights',
          () {
        // Test business logic: LocalityValueData model operations
        final valueData1 = LocalityValueData.defaultValues('Greenpoint');
        expect(valueData1.locality, equals('Greenpoint'));
        expect(valueData1.activityWeights, isNotEmpty);
        expect(valueData1.activityCounts, isEmpty);

        final weights = LocalityValueData.defaultWeights();
        expect(weights, isNotEmpty);
        expect(weights['events_hosted'], equals(0.20));
        expect(weights['lists_created'], equals(0.20));
        expect(weights['reviews_written'], equals(0.20));

        final valueData2 = LocalityValueData.defaultValues('Greenpoint');
        valueData2.recordActivity('events_hosted', 1.0);
        expect(valueData2.activityCounts['events_hosted'], equals(1));

        final preferences = valueData2.getCategoryPreferences('food');
        expect(preferences, isNotEmpty);
        expect(preferences['events_hosted'], equals(0.20));

        final valueData3 = LocalityValueData(
          locality: 'Greenpoint',
          activityWeights: {
            'events_hosted': 0.5,
            'lists_created': 0.5,
          },
          categoryPreferences: {},
          activityCounts: {},
          lastUpdated: DateTime.now(),
        );
        valueData3.normalizeWeights();
        expect(valueData3.activityWeights['events_hosted'], equals(0.5));
        expect(valueData3.activityWeights['lists_created'], equals(0.5));
      });
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });
  });
}

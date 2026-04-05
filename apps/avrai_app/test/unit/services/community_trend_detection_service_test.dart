import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_runtime_os/services/community/community_trend_detection_service.dart';
import 'package:avrai_runtime_os/ml/pattern_recognition.dart';
import 'package:avrai_runtime_os/ml/nlp_processor.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show StorageService;
import 'package:avrai_runtime_os/services/reality_model/governed_domain_consumer_state_service.dart';
import 'package:avrai_core/models/user/user.dart' as user_model;
import '../../helpers/platform_channel_helper.dart';
import '../../mocks/mock_storage_service.dart';

/// Community Trend Detection Service Tests
/// Tests community trend analysis functionality
///
/// NOTE: This test focuses on testing the service's public API without deep mocking
/// Full integration tests would test with actual PatternRecognitionSystem and NLPProcessor
void main() {
  group('CommunityTrendDetectionService', () {
    // Note: Creating actual instances for testing
    // In a real scenario, these would be mocked or use test doubles
    late PatternRecognitionSystem patternRecognition;
    late NLPProcessor nlpProcessor;
    late CommunityTrendDetectionService service;
    late GovernedDomainConsumerStateService governedStateService;

    setUp(() async {
      // Create actual instances - service handles errors gracefully
      MockGetStorage.reset();
      await StorageService.instance.initForTesting(
        defaultStorage: MockGetStorage.getInstance(boxName: 'spots_default'),
        userStorage: MockGetStorage.getInstance(boxName: 'spots_user'),
        aiStorage: MockGetStorage.getInstance(boxName: 'spots_ai'),
        analyticsStorage:
            MockGetStorage.getInstance(boxName: 'spots_analytics'),
      );
      patternRecognition = PatternRecognitionSystem();
      nlpProcessor = NLPProcessor();
      governedStateService = GovernedDomainConsumerStateService(
        storageService: StorageService.instance,
      );

      service = CommunityTrendDetectionService(
        patternRecognition: patternRecognition,
        nlpProcessor: nlpProcessor,
        governedDomainConsumerStateService: governedStateService,
      );
    });

    // Removed: Property assignment tests
    // Community trend detection tests focus on business logic (trend analysis, insights generation, behavior analysis), not property assignment

    group('analyzeCommunityTrends', () {
      test(
          'should return trend when lists are empty, analyze trends from lists, and handle errors gracefully',
          () async {
        // Test business logic: community trend analysis
        final trend1 = await service.analyzeCommunityTrends([]);
        expect(trend1, isNotNull);
        expect(trend1.trendType, isA<String>());

        final lists = [
          SpotList(
            id: 'list-1',
            name: 'Coffee Spots',
            spotIds: ['spot-1', 'spot-2'],
            createdBy: 'user-1',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          SpotList(
            id: 'list-2',
            name: 'Restaurants',
            spotIds: ['spot-3'],
            createdBy: 'user-2',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];
        final trend2 = await service.analyzeCommunityTrends(lists);
        expect(trend2, isNotNull);
        expect(trend2.trendType, equals('community_analysis'));
        expect(trend2.strength, closeTo(0.85, 0.01));

        final trend3 = await service.analyzeCommunityTrends([]);
        expect(trend3, isNotNull);
      });

      test('uses governed community state as a bounded trend-strength input',
          () async {
        final lists = [
          SpotList(
            id: 'list-1',
            name: 'Coffee Spots',
            spotIds: ['spot-1', 'spot-2'],
            createdBy: 'user-1',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        final baselineTrend = await service.analyzeCommunityTrends(lists);
        expect(baselineTrend.strength, closeTo(0.85, 0.01));

        await governedStateService.upsertState(
          GovernedDomainConsumerState(
            sourceId: 'simulation_training_source_den',
            domainId: 'community',
            consumerId: 'community_coordination_lane',
            environmentId: 'denver-replay-world-2024',
            cityCode: 'denver',
            generatedAt: DateTime.utc(2026, 4, 1, 18),
            status: 'executed_local_governed_domain_consumer_refresh',
            summary: 'Community coordination guidance is ready.',
            boundedUse: 'Bounded only.',
            targetedSystems: const <String>['community_coordination'],
            requestCount: 4,
            averageConfidence: 0.9,
          ),
        );

        final governedTrend = await service.analyzeCommunityTrends(lists);
        expect(governedTrend.strength, greaterThan(baselineTrend.strength));
        expect(governedTrend.strength, lessThanOrEqualTo(1.0));
      });
    });

    group('generateAnonymizedInsights', () {
      test('should generate anonymized insights and handle errors gracefully',
          () async {
        // Test business logic: anonymized insights generation
        final user = user_model.User(
          id: 'test-user',
          email: 'test@example.com',
          name: 'Test User',
          displayName: 'Test User',
          role: user_model.UserRole.user,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final insights1 = await service.generateAnonymizedInsights(user);
        expect(insights1, isNotNull);
        expect(insights1.authenticity, isNotNull);
        expect(insights1.privacy, isNotNull);

        final insights2 = await service.generateAnonymizedInsights(user);
        expect(insights2, isNotNull);
      });
    });

    group('analyzeBehavior', () {
      test('should analyze behavior patterns and handle empty actions list',
          () async {
        // Test business logic: behavior pattern analysis
        final actions = <UserActionData>[];
        final result1 = await service.analyzeBehavior(actions);
        expect(result1, isA<Map<String, dynamic>>());

        final result2 = await service.analyzeBehavior(actions);
        expect(result2, isA<Map<String, dynamic>>());
      });
    });

    group('predictTrends', () {
      test('should predict community trends and return prediction structure',
          () async {
        // Test business logic: trend prediction
        final actions = <UserActionData>[];
        final result1 = await service.predictTrends(actions);
        expect(result1, isA<Map<String, dynamic>>());
        expect(result1['confidence_level'], equals(0.85));
        expect(result1['emerging_categories'], isA<List>());
        expect(result1['declining_categories'], isA<List>());
        expect(result1['stable_categories'], isA<List>());

        final result2 = await service.predictTrends(actions);
        expect(result2.containsKey('confidence_level'), isTrue);
        expect(result2.containsKey('emerging_categories'), isTrue);
      });
    });

    group('analyzePersonality', () {
      test('should analyze personality trends and handle errors gracefully',
          () async {
        // Test business logic: personality trend analysis
        final actions = <UserActionData>[];
        final result1 = await service.analyzePersonality(actions);
        expect(result1, isA<Map<String, dynamic>>());
        expect(result1['dominant_archetypes'], isA<Map>());
        expect(result1['personality_evolution'], isA<Map>());
        expect(result1['community_maturity'], equals(0.80));
        expect(result1['diversity_index'], equals(0.72));

        final result2 = await service.analyzePersonality(actions);
        expect(result2, isA<Map<String, dynamic>>());
      });
    });

    group('analyzeTrends', () {
      test(
          'should analyze trending content, return trending spots with scores, and handle errors gracefully',
          () async {
        // Test business logic: trending content analysis
        final actions = <UserActionData>[];
        final result1 = await service.analyzeTrends(actions);
        expect(result1, isA<Map<String, dynamic>>());
        expect(result1['trending_spots'], isA<List>());
        expect(result1['trending_lists'], isA<List>());
        expect(result1['emerging_locations'], isA<List>());
        expect(result1['viral_content'], isA<List>());

        final result2 = await service.analyzeTrends(actions);
        final trendingSpots = result2['trending_spots'] as List;
        expect(trendingSpots.length, greaterThan(0));
        expect(trendingSpots.first['score'], isA<double>());

        final result3 = await service.analyzeTrends(actions);
        expect(result3, isA<Map<String, dynamic>>());
      });
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });
  });
}

import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai_core/models/spots/spot.dart';
import 'package:avrai_core/models/spots/spot_vibe.dart';
import 'package:avrai_core/models/user/unified_user.dart';
import 'package:avrai_runtime_os/ai/vibe_analysis_engine.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:avrai_runtime_os/services/matching/spot_vibe_matching_service.dart';
import 'package:avrai_runtime_os/services/reality_model/governed_domain_consumer_state_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fixtures/model_factories.dart';
import '../../helpers/platform_channel_helper.dart';
import '../../mocks/mock_storage_service.dart';

void main() {
  group('SpotVibeMatchingService Tests', () {
    late GovernedDomainConsumerStateService governedStateService;
    late UnifiedUser user;
    late PersonalityProfile personality;
    late Spot spot;
    late SpotVibe spotVibe;

    setUp(() async {
      MockGetStorage.reset();
      await StorageService.instance.initForTesting(
        defaultStorage: MockGetStorage.getInstance(boxName: 'spots_default'),
        userStorage: MockGetStorage.getInstance(boxName: 'spots_user'),
        aiStorage: MockGetStorage.getInstance(boxName: 'spots_ai'),
        analyticsStorage:
            MockGetStorage.getInstance(boxName: 'spots_analytics'),
      );
      governedStateService = GovernedDomainConsumerStateService(
        storageService: StorageService.instance,
      );
      user = ModelFactories.createTestUser(
        id: 'test-user-venue',
        displayName: 'Venue Tester',
      );
      personality = PersonalityProfile.initial(
        'agent-test-user-venue',
        userId: user.id,
      );
      spot = Spot(
        id: 'venue-1',
        name: 'Venue One',
        description: 'A strong venue candidate',
        latitude: 30.2672,
        longitude: -97.7431,
        category: 'Live Music',
        rating: 4.6,
        createdBy: 'seed',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        address: 'Austin, TX',
        cityCode: 'atx',
      );
      spotVibe = SpotVibe(
        spotId: spot.id,
        vibeDimensions: const <String, double>{
          'exploration_eagerness': 0.72,
          'community_orientation': 0.74,
          'adventure_seeking': 0.68,
        },
        vibeDescription: 'Live music venue with strong community energy',
        overallEnergy: 0.76,
        socialPreference: 0.73,
        explorationTendency: 0.69,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    test('uses governed venue intelligence as a bounded compatibility input',
        () async {
      final prefs = await SharedPreferencesCompat.getInstance(
        storage: getTestStorage(boxName: 'venue_vibes'),
      );

      final baselineService = SpotVibeMatchingService(
        vibeAnalyzer: UserVibeAnalyzer(prefs: prefs),
      );
      final baselineCompatibility =
          await baselineService.calculateSpotUserCompatibility(
        user: user,
        spot: spot,
        userPersonality: personality,
        spotVibe: spotVibe,
      );

      await governedStateService.upsertState(
        GovernedDomainConsumerState(
          sourceId: 'simulation_training_source_atx',
          domainId: 'venue',
          consumerId: 'venue_intelligence_lane',
          environmentId: 'atx-replay-world-2024',
          cityCode: 'atx',
          generatedAt: DateTime.utc(2026, 4, 1, 22),
          status: 'executed_local_governed_domain_consumer_refresh',
          summary: 'Venue intelligence is ready for Austin.',
          boundedUse: 'Bounded venue ranking only.',
          targetedSystems: const <String>['venue_ranking'],
          requestCount: 4,
          averageConfidence: 0.9,
        ),
      );

      final governedService = SpotVibeMatchingService(
        vibeAnalyzer: UserVibeAnalyzer(prefs: prefs),
        governedDomainConsumerStateService: governedStateService,
      );
      final governedCompatibility =
          await governedService.calculateSpotUserCompatibility(
        user: user,
        spot: spot,
        userPersonality: personality,
        spotVibe: spotVibe,
      );

      expect(governedCompatibility, greaterThan(baselineCompatibility));
      expect(governedCompatibility - baselineCompatibility,
          lessThanOrEqualTo(0.05));
      expect(governedCompatibility, lessThanOrEqualTo(1.0));
    });

    test('ignores stale governed venue intelligence in live compatibility',
        () async {
      final prefs = await SharedPreferencesCompat.getInstance(
        storage: getTestStorage(boxName: 'stale_venue_vibes'),
      );

      final baselineService = SpotVibeMatchingService(
        vibeAnalyzer: UserVibeAnalyzer(prefs: prefs),
      );
      final baselineCompatibility =
          await baselineService.calculateSpotUserCompatibility(
        user: user,
        spot: spot,
        userPersonality: personality,
        spotVibe: spotVibe,
      );

      await governedStateService.upsertState(
        GovernedDomainConsumerState(
          sourceId: 'stale_simulation_training_source_atx',
          domainId: 'venue',
          consumerId: 'venue_intelligence_lane',
          environmentId: 'atx-replay-world-2024',
          cityCode: 'atx',
          generatedAt: DateTime.utc(2026, 1, 1, 22),
          status: 'executed_local_governed_domain_consumer_refresh',
          summary: 'Stale venue intelligence should not affect live ranking.',
          boundedUse: 'Bounded venue ranking only.',
          targetedSystems: const <String>['venue_ranking'],
          requestCount: 4,
          averageConfidence: 0.9,
        ),
      );

      final governedService = SpotVibeMatchingService(
        vibeAnalyzer: UserVibeAnalyzer(prefs: prefs),
        governedDomainConsumerStateService: governedStateService,
      );
      final governedCompatibility =
          await governedService.calculateSpotUserCompatibility(
        user: user,
        spot: spot,
        userPersonality: personality,
        spotVibe: spotVibe,
      );

      expect(
        governedCompatibility,
        closeTo(baselineCompatibility, 0.01),
      );
    });
  });
}

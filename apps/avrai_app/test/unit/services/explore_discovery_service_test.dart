import 'package:avrai_core/models/community.dart';
import 'package:avrai_core/models/community/club.dart';
import 'package:avrai_core/models/discovery/discovery_models.dart';
import 'package:avrai_core/models/expertise/expertise_event.dart';
import 'package:avrai_core/models/misc/list.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai_core/models/reality/governed_learning_adoption_receipt.dart';
import 'package:avrai_core/models/reality/governed_learning_chat_observation_receipt.dart';
import 'package:avrai_core/models/spots/spot.dart';
import 'package:avrai_core/models/user/unified_user.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_runtime_os/ai/personality_learning.dart';
import 'package:avrai_runtime_os/data/repositories/hybrid_search_repository.dart';
import 'package:avrai_runtime_os/domain/repositories/lists_repository.dart';
import 'package:avrai_runtime_os/services/community/club_service.dart';
import 'package:avrai_runtime_os/services/community/community_service.dart';
import 'package:avrai_runtime_os/services/events/event_recommendation_service.dart';
import 'package:avrai_runtime_os/services/expertise/expertise_event_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:avrai_runtime_os/services/intake/universal_intake_repository.dart';
import 'package:avrai_runtime_os/services/intake/upward_air_gap_service.dart';
import 'package:avrai_runtime_os/services/matching/spot_vibe_matching_service.dart';
import 'package:avrai_runtime_os/services/reality_model/governed_domain_consumer_state_service.dart';
import 'package:avrai_runtime_os/services/reality_model/governed_upward_learning_intake_service.dart';
import 'package:avrai_runtime_os/services/recommendations/explore_discovery_service.dart';
import 'package:avrai_runtime_os/services/recommendations/saved_discovery_service.dart';
import 'package:avrai_runtime_os/services/user/user_governed_learning_projection_service.dart';
import 'package:avrai_runtime_os/services/user/user_governed_learning_adoption_service.dart';
import 'package:avrai_runtime_os/services/user/user_governed_learning_chat_observation_service.dart';
import 'package:avrai_runtime_os/services/user/user_governed_learning_usage_service.dart';
import 'package:avrai_runtime_os/services/vibe/canonical_vibe_projection_service.dart';
import 'package:avrai_runtime_os/ai/vibe_analysis_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fixtures/model_factories.dart';
import '../../helpers/platform_channel_helper.dart';
import '../../mocks/mock_storage_service.dart';

class _FakeHybridSearchRepository extends HybridSearchRepository {
  _FakeHybridSearchRepository({
    List<Spot> searchSpots = const <Spot>[],
    List<Spot> nearbySpots = const <Spot>[],
  })  : _searchSpots = searchSpots,
        _nearbySpots = nearbySpots;

  final List<Spot> _searchSpots;
  final List<Spot> _nearbySpots;

  @override
  Future<HybridSearchResult> searchSpots({
    required String query,
    double? latitude,
    double? longitude,
    String? userId,
    int maxResults = 50,
    bool includeExternal = true,
    SearchFilters? filters,
    SearchSortOption sortOption = SearchSortOption.relevance,
  }) async {
    return HybridSearchResult(
      spots: _searchSpots,
      communityCount: _searchSpots.length,
      externalCount: 0,
      totalCount: _searchSpots.length,
      searchDuration: Duration.zero,
      sources: const <String, int>{'community': 1},
      metadata: const <SpotWithMetadata>[],
    );
  }

  @override
  Future<HybridSearchResult> searchNearbySpots({
    required double latitude,
    required double longitude,
    String? userId,
    int radius = 5000,
    int maxResults = 50,
    bool includeExternal = true,
  }) async {
    return HybridSearchResult(
      spots: _nearbySpots,
      communityCount: _nearbySpots.length,
      externalCount: 0,
      totalCount: _nearbySpots.length,
      searchDuration: Duration.zero,
      sources: const <String, int>{'community': 1},
      metadata: const <SpotWithMetadata>[],
    );
  }
}

class _FakeListsRepository implements ListsRepository {
  _FakeListsRepository(this._lists);

  final List<SpotList> _lists;

  @override
  Future<List<SpotList>> getLists() async => _lists;

  @override
  Future<List<SpotList>> getPublicLists() async => _lists;

  @override
  Future<SpotList> createList(SpotList list) async => list;

  @override
  Future<bool> canUserAddSpotToList(String userId, String listId) async => true;

  @override
  Future<bool> canUserCreateList(String userId) async => true;

  @override
  Future<bool> canUserDeleteList(String userId, String listId) async => true;

  @override
  Future<bool> canUserManageCollaborators(
    String userId,
    String listId,
  ) async =>
      true;

  @override
  Future<void> deleteList(String listId) async {}

  @override
  Future<void> createPersonalizedListsForUser({
    required String userId,
    required Map<String, dynamic> userPreferences,
  }) async {}

  @override
  Future<void> createStarterListsForUser({
    required String userId,
  }) async {}

  @override
  Future<SpotList> updateList(SpotList list) async => list;
}

class _FakeCommunityService extends CommunityService {
  _FakeCommunityService({
    required this.communities,
    required this.scoresByCommunityId,
  });

  final List<Community> communities;
  final Map<String, double> scoresByCommunityId;

  @override
  Future<List<Community>> getAllCommunities({int maxResults = 200}) async {
    return communities.take(maxResults).toList();
  }

  @override
  Future<CommunityTrueCompatibilityBreakdown>
      calculateUserCommunityTrueCompatibilityBreakdown({
    required String communityId,
    int memberSampleSize = 50,
    required String userId,
  }) async {
    final score = scoresByCommunityId[communityId] ?? 0.5;
    return CommunityTrueCompatibilityBreakdown(
      combined: score,
      quantum: score,
      topological: score,
      weaveFit: score,
    );
  }
}

class _FakeClubService extends ClubService {
  _FakeClubService(this.clubs);

  final List<Club> clubs;

  @override
  Future<List<Club>> getAllClubs({int maxResults = 100}) async {
    return clubs.take(maxResults).toList();
  }
}

class _FakeEventRecommendationService extends EventRecommendationService {
  _FakeEventRecommendationService({
    this.recommendations = const <EventRecommendation>[],
  });

  final List<EventRecommendation> recommendations;
  final List<String> requestedSurfaces = <String>[];

  @override
  Future<List<EventRecommendation>> getPersonalizedRecommendations({
    required UnifiedUser user,
    String? category,
    String? location,
    int maxResults = 20,
    double explorationRatio = 0.3,
    String surface = 'events_personalized',
  }) async {
    requestedSurfaces.add(surface);
    return recommendations;
  }
}

class _FakeEventService extends ExpertiseEventService {
  _FakeEventService(this.eventsById);

  final Map<String, ExpertiseEvent> eventsById;

  @override
  Future<ExpertiseEvent?> getEventById(String eventId) async {
    return eventsById[eventId];
  }
}

class _FakeCanonicalVibeProjectionService
    extends CanonicalVibeProjectionService {
  _FakeCanonicalVibeProjectionService(this.profile);

  final PersonalityProfile profile;

  @override
  Future<PersonalityProfile> getOrCreateProjectedProfile({
    required String userId,
    required Future<PersonalityProfile?> Function(String userId) loadFallback,
    required Future<PersonalityProfile> Function(String userId) createFallback,
  }) async {
    return profile;
  }
}

class _FakePersonalityLearning extends PersonalityLearning {
  _FakePersonalityLearning(this.profile);

  final PersonalityProfile profile;

  @override
  Future<PersonalityProfile?> getCurrentPersonality(String userId) async {
    return profile;
  }

  @override
  Future<PersonalityProfile> initializePersonality(
    String userId, {
    String? password,
  }) async {
    return profile;
  }
}

void main() {
  group('ExploreDiscoveryService Tests', () {
    late GovernedDomainConsumerStateService governedStateService;
    late UnifiedUser user;
    late PersonalityProfile personalityProfile;
    late Spot governedSpot;
    late Spot baselineSpot;
    late SpotList governedList;
    late SpotList baselineList;
    late Community governedCommunity;
    late Community baselineCommunity;
    late Club governedClub;
    late Club baselineClub;
    late ExpertiseEvent governedEvent;
    late ExpertiseEvent baselineEvent;

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
        id: 'discovery-user',
        displayName: 'Discovery User',
      );
      personalityProfile = PersonalityProfile.initial(
        'agent-discovery-user',
        userId: user.id,
      );

      final now = DateTime.utc(2026, 4, 1, 12);
      governedSpot = Spot(
        id: 'spot-sf',
        name: 'Governed Place',
        description: 'Governed place',
        latitude: 37.7749,
        longitude: -122.4194,
        category: 'Cafe',
        rating: 4.7,
        createdBy: 'seed',
        createdAt: now,
        updatedAt: now,
        address: 'San Francisco, CA',
        cityCode: 'sf',
        localityCode: 'mission',
      );
      baselineSpot = Spot(
        id: 'spot-nyc',
        name: 'Baseline Place',
        description: 'Baseline place',
        latitude: 40.7128,
        longitude: -74.0060,
        category: 'Cafe',
        rating: 4.7,
        createdBy: 'seed',
        createdAt: now,
        updatedAt: now,
        address: 'New York, NY',
        cityCode: 'nyc',
        localityCode: 'soho',
      );
      governedList = SpotList(
        id: 'list-governed',
        title: 'Governed List',
        description: 'A city-aware list',
        spots: <Spot>[governedSpot],
        createdAt: now,
        updatedAt: now,
        isPublic: true,
        respectCount: 4,
      );
      baselineList = SpotList(
        id: 'list-baseline',
        title: 'Baseline List',
        description: 'A baseline list',
        spots: <Spot>[baselineSpot],
        createdAt: now,
        updatedAt: now,
        isPublic: true,
        respectCount: 4,
      );

      governedCommunity = Community(
        id: 'community-governed',
        name: 'Governed Community',
        category: 'Arts',
        originatingEventId: 'event-governed',
        originatingEventType: OriginatingEventType.expertiseEvent,
        founderId: 'founder-1',
        createdAt: now,
        updatedAt: now,
        originalLocality: 'Mission',
        cityCode: 'sf',
        localityCode: 'mission',
        activityLevel: ActivityLevel.growing,
      );
      baselineCommunity = Community(
        id: 'community-baseline',
        name: 'Baseline Community',
        category: 'Arts',
        originatingEventId: 'event-baseline',
        originatingEventType: OriginatingEventType.expertiseEvent,
        founderId: 'founder-2',
        createdAt: now,
        updatedAt: now,
        originalLocality: 'SoHo',
        cityCode: 'nyc',
        localityCode: 'soho',
        activityLevel: ActivityLevel.growing,
      );

      governedClub = Club(
        id: 'club-governed',
        name: 'Governed Club',
        category: 'Music',
        originatingEventId: 'event-governed',
        originatingEventType: OriginatingEventType.communityEvent,
        founderId: 'founder-1',
        createdAt: now,
        updatedAt: now,
        originalLocality: 'Mission',
        cityCode: 'sf',
        localityCode: 'mission',
        memberCount: 12,
        organizationalMaturity: 0.6,
        leadershipStability: 0.7,
        activityLevel: ActivityLevel.growing,
      );
      baselineClub = Club(
        id: 'club-baseline',
        name: 'Baseline Club',
        category: 'Music',
        originatingEventId: 'event-baseline',
        originatingEventType: OriginatingEventType.communityEvent,
        founderId: 'founder-2',
        createdAt: now,
        updatedAt: now,
        originalLocality: 'SoHo',
        cityCode: 'nyc',
        localityCode: 'soho',
        memberCount: 12,
        organizationalMaturity: 0.6,
        leadershipStability: 0.7,
        activityLevel: ActivityLevel.growing,
      );

      final host = ModelFactories.createTestUser(
        id: 'host-user',
        displayName: 'Host User',
      );
      governedEvent = ExpertiseEvent(
        id: 'event-governed',
        title: 'Governed Event',
        description: 'Community coordinates',
        category: 'Arts',
        eventType: ExpertiseEventType.meetup,
        host: host,
        startTime: now,
        endTime: now.add(const Duration(hours: 2)),
        latitude: 37.7749,
        longitude: -122.4194,
        location: 'Mission',
        cityCode: 'sf',
        localityCode: 'mission',
        createdAt: now,
        updatedAt: now,
      );
      baselineEvent = ExpertiseEvent(
        id: 'event-baseline',
        title: 'Baseline Event',
        description: 'Community coordinates',
        category: 'Arts',
        eventType: ExpertiseEventType.meetup,
        host: host,
        startTime: now,
        endTime: now.add(const Duration(hours: 2)),
        latitude: 40.7128,
        longitude: -74.0060,
        location: 'SoHo',
        cityCode: 'nyc',
        localityCode: 'soho',
        createdAt: now,
        updatedAt: now,
      );
    });

    test('uses governed list, community, and club signals in discovery ranking',
        () async {
      await governedStateService.upsertState(
        GovernedDomainConsumerState(
          sourceId: 'simulation_training_source_sf',
          domainId: 'list',
          consumerId: 'list_curation_lane',
          environmentId: 'sf-replay-world-2024',
          cityCode: 'sf',
          generatedAt: DateTime.utc(2026, 4, 2, 1),
          status: 'executed_local_governed_domain_consumer_refresh',
          summary: 'List curation is ready.',
          boundedUse: 'Bounded list ranking only.',
          targetedSystems: const <String>['list_curation'],
          requestCount: 5,
          recommendationCount: 3,
          averageConfidence: 0.92,
        ),
      );
      await governedStateService.upsertState(
        GovernedDomainConsumerState(
          sourceId: 'simulation_training_source_sf',
          domainId: 'place',
          consumerId: 'place_intelligence_lane',
          environmentId: 'sf-replay-world-2024',
          cityCode: 'sf',
          generatedAt: DateTime.utc(2026, 4, 2, 1),
          status: 'executed_local_governed_domain_consumer_refresh',
          summary: 'Place intelligence is ready.',
          boundedUse: 'Bounded place ranking only.',
          targetedSystems: const <String>['place_discovery'],
          requestCount: 4,
          recommendationCount: 3,
          averageConfidence: 0.88,
        ),
      );
      await governedStateService.upsertState(
        GovernedDomainConsumerState(
          sourceId: 'simulation_training_source_sf',
          domainId: 'community',
          consumerId: 'community_coordination_lane',
          environmentId: 'sf-replay-world-2024',
          cityCode: 'sf',
          generatedAt: DateTime.utc(2026, 4, 2, 1),
          status: 'executed_local_governed_domain_consumer_refresh',
          summary: 'Community coordination is ready.',
          boundedUse: 'Bounded community ranking only.',
          targetedSystems: const <String>['community_discovery'],
          requestCount: 4,
          recommendationCount: 2,
          averageConfidence: 0.9,
        ),
      );
      await governedStateService.upsertState(
        GovernedDomainConsumerState(
          sourceId: 'simulation_training_source_sf',
          domainId: 'locality',
          consumerId: 'locality_intelligence_lane',
          environmentId: 'sf-replay-world-2024',
          cityCode: 'sf',
          generatedAt: DateTime.utc(2026, 4, 2, 1),
          status: 'executed_local_governed_domain_consumer_refresh',
          summary: 'Locality intelligence is ready.',
          boundedUse: 'Bounded locality ranking only.',
          targetedSystems: const <String>['locality_discovery'],
          requestCount: 4,
          recommendationCount: 2,
          averageConfidence: 0.86,
        ),
      );

      final service = ExploreDiscoveryService(
        searchRepository: _FakeHybridSearchRepository(),
        listsRepository: _FakeListsRepository(
          <SpotList>[baselineList, governedList],
        ),
        communityService: _FakeCommunityService(
          communities: <Community>[baselineCommunity, governedCommunity],
          scoresByCommunityId: const <String, double>{
            'community-baseline': 0.55,
            'community-governed': 0.55,
          },
        ),
        clubService: _FakeClubService(<Club>[baselineClub, governedClub]),
        eventRecommendationService: _FakeEventRecommendationService(),
        eventService: _FakeEventService(
          <String, ExpertiseEvent>{
            governedEvent.id: governedEvent,
            baselineEvent.id: baselineEvent,
          },
        ),
        spotVibeMatchingService: SpotVibeMatchingService(
          vibeAnalyzer: UserVibeAnalyzer(
            prefs: await SharedPreferencesCompat.getInstance(
              storage: getTestStorage(boxName: 'explore_discovery_service'),
            ),
          ),
        ),
        personalityLearning: _FakePersonalityLearning(personalityProfile),
        canonicalVibeProjectionService:
            _FakeCanonicalVibeProjectionService(personalityProfile),
        savedDiscoveryService: SavedDiscoveryService(),
        governedDomainConsumerStateService: governedStateService,
      );

      final result = await service.load(user: user);

      final lists = result.itemsFor(DiscoveryEntityType.list);
      final communities = result.itemsFor(DiscoveryEntityType.community);
      final clubs = result.itemsFor(DiscoveryEntityType.club);

      expect(lists, isNotEmpty);
      expect(communities, isNotEmpty);
      expect(clubs, isNotEmpty);

      expect(lists.first.list?.id, 'list-governed');
      expect(communities.first.community?.id, 'community-governed');
      expect(clubs.first.club?.id, 'club-governed');
      expect(lists.first.attribution.why, isNot(contains('Birmingham')));
      expect(lists.first.attribution.whyDetails, contains('governed'));
      expect(communities.first.attribution.why, isNot(contains('Birmingham')));
    });

    test(
        'records governed learning usage receipts when a learning record boosts a surfaced spot recommendation',
        () async {
      final repository = UniversalIntakeRepository();
      final adoptionService = UserGovernedLearningAdoptionService(
        storageService: StorageService.instance,
      );
      final observationService = UserGovernedLearningChatObservationService(
        storageService: StorageService.instance,
      );
      final usageService = UserGovernedLearningUsageService(
        storageService: StorageService.instance,
      );
      final projectionService = UserGovernedLearningProjectionService(
        intakeRepository: repository,
        adoptionService: adoptionService,
        observationService: observationService,
        usageService: usageService,
      );
      final upwardService = GovernedUpwardLearningIntakeService(
        intakeRepository: repository,
        atomicClockService: AtomicClockService(),
      );

      final coffeeSpot = Spot(
        id: 'spot-coffee-1',
        name: 'Quiet Coffee House',
        description: 'Espresso and natural light.',
        latitude: 37.781,
        longitude: -122.41,
        category: 'Cafe',
        rating: 4.8,
        createdBy: 'seed',
        createdAt: DateTime.utc(2026, 4, 1, 12),
        updatedAt: DateTime.utc(2026, 4, 1, 12),
        address: 'Mission, San Francisco, CA',
        cityCode: 'sf',
        localityCode: 'mission',
      );
      final baselineSpotForReceipts = Spot(
        id: 'spot-nightlife-1',
        name: 'Downtown After Hours',
        description: 'Late-night music and crowds.',
        latitude: 37.79,
        longitude: -122.42,
        category: 'Nightlife',
        rating: 4.6,
        createdBy: 'seed',
        createdAt: DateTime.utc(2026, 4, 1, 12),
        updatedAt: DateTime.utc(2026, 4, 1, 12),
        address: 'Downtown, San Francisco, CA',
        cityCode: 'sf',
        localityCode: 'downtown',
      );

      final intakeResult = await upwardService.stagePersonalAgentHumanIntake(
        ownerUserId: user.id,
        actorAgentId: 'agent-discovery-user',
        chatId: 'chat_coffee_1',
        messageId: 'msg_coffee_1',
        occurredAtUtc: DateTime.utc(2026, 4, 4, 7),
        airGapArtifact: const UpwardAirGapService().issueArtifact(
          originPlane: 'personal_device',
          sourceKind: 'personal_agent_human_intake',
          sourceScope: 'human',
          destinationCeiling: 'reality_model_agent',
          issuedAtUtc: DateTime.now().toUtc(),
          sanitizedPayload: <String, dynamic>{
            'chatId': 'chat_coffee_1',
            'messageId': 'msg_coffee_1',
            'sourceOccurredAtUtc': '2026-04-04T07:00:00.000Z',
          },
          pseudonymousActorRef: 'anon_user',
        ),
        boundaryMetadata: const <String, dynamic>{
          'summary':
              'The user likes coffee shops with espresso and natural light.',
          'sanitized_summary':
              'The user likes coffee shops with espresso and natural light.',
          'referenced_entities': <String>['Quiet Coffee House', 'coffee'],
          'accepted': true,
          'learning_allowed': true,
        },
        cityCode: 'sf',
        localityCode: 'mission',
      );
      await observationService.recordReceipts([
        GovernedLearningChatObservationReceipt(
          id: 'obs:${intakeResult.envelope.id}',
          ownerUserId: user.id,
          envelopeId: intakeResult.envelope.id,
          sourceId: intakeResult.sourceId,
          kind: GovernedLearningChatObservationKind.explanation,
          outcome: GovernedLearningChatObservationOutcome.acknowledged,
          recordedAtUtc: DateTime.utc(2026, 4, 4, 7, 30),
          chatId: 'chat_coffee_1',
          userMessageId: 'user_msg_obs',
        ),
      ]);

      final service = ExploreDiscoveryService(
        searchRepository: _FakeHybridSearchRepository(
          searchSpots: <Spot>[coffeeSpot, baselineSpotForReceipts],
        ),
        listsRepository: _FakeListsRepository(const <SpotList>[]),
        communityService: _FakeCommunityService(
          communities: const <Community>[],
          scoresByCommunityId: const <String, double>{},
        ),
        clubService: _FakeClubService(const <Club>[]),
        eventRecommendationService: _FakeEventRecommendationService(),
        eventService: _FakeEventService(const <String, ExpertiseEvent>{}),
        spotVibeMatchingService: SpotVibeMatchingService(
          vibeAnalyzer: UserVibeAnalyzer(
            prefs: await SharedPreferencesCompat.getInstance(
              storage: getTestStorage(
                boxName: 'explore_discovery_usage_receipts',
              ),
            ),
          ),
        ),
        personalityLearning: _FakePersonalityLearning(personalityProfile),
        canonicalVibeProjectionService:
            _FakeCanonicalVibeProjectionService(personalityProfile),
        savedDiscoveryService: SavedDiscoveryService(),
        governedDomainConsumerStateService: governedStateService,
        userGovernedLearningProjectionService: projectionService,
        userGovernedLearningAdoptionService: adoptionService,
        userGovernedLearningChatObservationService: observationService,
        userGovernedLearningUsageService: usageService,
      );

      final result = await service.load(user: user);
      final receipts = await usageService.listReceiptsForUser(
        ownerUserId: user.id,
      );
      final adoptionReceipts = await adoptionService.listReceiptsForUser(
        ownerUserId: user.id,
      );
      final observationReceipts = await observationService.listReceiptsForUser(
        ownerUserId: user.id,
      );
      final coffeeItem = result.itemsFor(DiscoveryEntityType.spot).firstWhere(
            (item) => item.spot?.id == coffeeSpot.id,
          );

      expect(result.itemsFor(DiscoveryEntityType.spot), isNotEmpty);
      expect(receipts, isNotEmpty);
      expect(
        coffeeItem.attribution.why,
        contains('you liked coffee shops with espresso and natural light'),
      );
      expect(
        coffeeItem.attribution.whyDetails,
        contains('bounded coffee learning signal added extra lift'),
      );
      expect(
        receipts
            .where((receipt) => receipt.envelopeId == intakeResult.envelope.id),
        isNotEmpty,
      );
      final coffeeReceipt = receipts.firstWhere(
        (receipt) => receipt.targetEntityId == coffeeSpot.id,
      );
      expect(coffeeReceipt.targetEntityType, 'spot');
      expect(coffeeReceipt.decisionFamily, 'spot_recommendation');
      expect(coffeeReceipt.surface, 'explore_spots');
      expect(coffeeReceipt.domainId, 'coffee');
      expect(coffeeReceipt.targetEntityTitle, 'Quiet Coffee House');
      expect(
        coffeeReceipt.influenceReason,
        contains('helped boost this spot recommendation'),
      );
      final surfacedReceipt = adoptionReceipts.singleWhere(
        (receipt) =>
            receipt.envelopeId == intakeResult.envelope.id &&
            receipt.status ==
                GovernedLearningAdoptionStatus.firstSurfacedOnSurface,
      );
      expect(surfacedReceipt.surface, 'explore_spots');
      expect(surfacedReceipt.targetEntityType, 'spot');
      expect(surfacedReceipt.targetEntityTitle, 'Quiet Coffee House');
      expect(
        observationReceipts.single.validationStatus,
        GovernedLearningChatObservationValidationStatus
            .validatedBySurfacedAdoption,
      );
      expect(observationReceipts.single.validatedSurface, 'explore_spots');
      expect(
        observationReceipts.single.validatedTargetEntityTitle,
        'Quiet Coffee House',
      );

      await service.load(user: user);
      final adoptionReceiptsAfterRepeat =
          await adoptionService.listReceiptsForEnvelope(
        ownerUserId: user.id,
        envelopeId: intakeResult.envelope.id,
      );
      expect(
        adoptionReceiptsAfterRepeat
            .where(
              (receipt) =>
                  receipt.status ==
                  GovernedLearningAdoptionStatus.firstSurfacedOnSurface,
            )
            .length,
        1,
      );
    });

    test('requests explore event recommendations through the explore surface',
        () async {
      final eventService = _FakeEventRecommendationService(
        recommendations: <EventRecommendation>[
          EventRecommendation(
            event: governedEvent,
            relevanceScore: 0.82,
            recommendationReason: 'Strong event fit from explore.',
          ),
        ],
      );

      final service = ExploreDiscoveryService(
        searchRepository: _FakeHybridSearchRepository(),
        listsRepository: _FakeListsRepository(const <SpotList>[]),
        communityService: _FakeCommunityService(
          communities: const <Community>[],
          scoresByCommunityId: const <String, double>{},
        ),
        clubService: _FakeClubService(const <Club>[]),
        eventRecommendationService: eventService,
        eventService: _FakeEventService(
          <String, ExpertiseEvent>{
            governedEvent.id: governedEvent,
          },
        ),
        spotVibeMatchingService: SpotVibeMatchingService(
          vibeAnalyzer: UserVibeAnalyzer(
            prefs: await SharedPreferencesCompat.getInstance(
              storage: getTestStorage(
                boxName: 'explore_discovery_events_surface',
              ),
            ),
          ),
        ),
        personalityLearning: _FakePersonalityLearning(personalityProfile),
        canonicalVibeProjectionService:
            _FakeCanonicalVibeProjectionService(personalityProfile),
        savedDiscoveryService: SavedDiscoveryService(),
        governedDomainConsumerStateService: governedStateService,
      );

      final result = await service.load(user: user);

      expect(result.itemsFor(DiscoveryEntityType.event), isNotEmpty);
      expect(eventService.requestedSurfaces, contains('explore_events'));
      expect(
        result.itemsFor(DiscoveryEntityType.event).first.entity.id,
        governedEvent.id,
      );
    });
  });
}

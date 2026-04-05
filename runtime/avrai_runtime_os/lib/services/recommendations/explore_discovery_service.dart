import 'package:avrai_core/models/community/club.dart';
import 'package:avrai_core/models/community/community.dart';
import 'package:avrai_core/models/discovery/discovery_models.dart';
import 'package:avrai_core/models/expertise/expertise_event.dart';
import 'package:avrai_core/models/misc/list.dart';
import 'package:avrai_core/models/reality/governed_learning_adoption_receipt.dart';
import 'package:avrai_core/models/reality/governed_learning_usage_receipt.dart';
import 'package:avrai_core/models/reality/user_visible_governed_learning.dart';
import 'package:avrai_core/models/spots/spot.dart';
import 'package:avrai_core/models/user/unified_user.dart';
import 'package:avrai_runtime_os/ai/personality_learning.dart';
import 'package:avrai_runtime_os/data/repositories/hybrid_search_repository.dart';
import 'package:avrai_runtime_os/domain/repositories/lists_repository.dart';
import 'package:avrai_runtime_os/services/community/club_service.dart';
import 'package:avrai_runtime_os/services/community/community_service.dart';
import 'package:avrai_runtime_os/services/events/event_recommendation_service.dart';
import 'package:avrai_runtime_os/services/expertise/expertise_event_service.dart';
import 'package:avrai_runtime_os/services/matching/spot_vibe_matching_service.dart';
import 'package:avrai_runtime_os/services/reality_model/governed_domain_consumer_state_service.dart';
import 'package:avrai_runtime_os/services/recommendations/saved_discovery_service.dart';
import 'package:avrai_runtime_os/services/user/user_governed_learning_projection_service.dart';
import 'package:avrai_runtime_os/services/user/user_governed_learning_adoption_service.dart';
import 'package:avrai_runtime_os/services/user/user_governed_learning_chat_observation_service.dart';
import 'package:avrai_runtime_os/services/user/user_governed_learning_usage_service.dart';
import 'package:avrai_runtime_os/services/vibe/canonical_vibe_projection_service.dart';
import 'package:get_it/get_it.dart';

class ExploreDiscoveryItem {
  final DiscoveryEntityReference entity;
  final RecommendationAttribution attribution;
  final String title;
  final String subtitle;
  final String scoreLabel;
  final double score;
  final bool isLiveNow;
  final String? secondaryMeta;
  final bool isSaved;
  final bool canRenderOnMap;
  final Spot? spot;
  final SpotList? list;
  final ExpertiseEvent? event;
  final Club? club;
  final Community? community;

  const ExploreDiscoveryItem({
    required this.entity,
    required this.attribution,
    required this.title,
    required this.subtitle,
    required this.scoreLabel,
    required this.score,
    required this.isLiveNow,
    required this.isSaved,
    required this.canRenderOnMap,
    this.secondaryMeta,
    this.spot,
    this.list,
    this.event,
    this.club,
    this.community,
  });
}

class ExploreDiscoveryResult {
  final Map<DiscoveryEntityType, List<ExploreDiscoveryItem>> byType;

  const ExploreDiscoveryResult({
    required this.byType,
  });

  List<ExploreDiscoveryItem> itemsFor(DiscoveryEntityType type) {
    return byType[type] ?? const <ExploreDiscoveryItem>[];
  }
}

class ExploreDiscoveryService {
  final HybridSearchRepository _searchRepository;
  final ListsRepository _listsRepository;
  final CommunityService _communityService;
  final ClubService _clubService;
  final EventRecommendationService _eventRecommendationService;
  final SpotVibeMatchingService _spotVibeMatchingService;
  final PersonalityLearning _personalityLearning;
  final CanonicalVibeProjectionService _canonicalVibeProjectionService;
  final ExpertiseEventService _eventService;
  final SavedDiscoveryService _savedDiscoveryService;
  final GovernedDomainConsumerStateService? _governedStateService;
  final UserGovernedLearningProjectionService?
      _userGovernedLearningProjectionService;
  final UserGovernedLearningAdoptionService?
      _userGovernedLearningAdoptionService;
  final UserGovernedLearningChatObservationService?
      _userGovernedLearningChatObservationService;
  final UserGovernedLearningUsageService? _userGovernedLearningUsageService;

  ExploreDiscoveryService({
    HybridSearchRepository? searchRepository,
    ListsRepository? listsRepository,
    CommunityService? communityService,
    ClubService? clubService,
    EventRecommendationService? eventRecommendationService,
    SpotVibeMatchingService? spotVibeMatchingService,
    PersonalityLearning? personalityLearning,
    CanonicalVibeProjectionService? canonicalVibeProjectionService,
    ExpertiseEventService? eventService,
    SavedDiscoveryService? savedDiscoveryService,
    GovernedDomainConsumerStateService? governedDomainConsumerStateService,
    UserGovernedLearningProjectionService?
        userGovernedLearningProjectionService,
    UserGovernedLearningAdoptionService? userGovernedLearningAdoptionService,
    UserGovernedLearningChatObservationService?
        userGovernedLearningChatObservationService,
    UserGovernedLearningUsageService? userGovernedLearningUsageService,
  })  : _searchRepository =
            searchRepository ?? GetIt.instance<HybridSearchRepository>(),
        _listsRepository = listsRepository ?? GetIt.instance<ListsRepository>(),
        _communityService =
            communityService ?? GetIt.instance<CommunityService>(),
        _clubService = clubService ?? GetIt.instance<ClubService>(),
        _eventRecommendationService = eventRecommendationService ??
            GetIt.instance<EventRecommendationService>(),
        _spotVibeMatchingService = spotVibeMatchingService ??
            GetIt.instance<SpotVibeMatchingService>(),
        _personalityLearning =
            personalityLearning ?? GetIt.instance<PersonalityLearning>(),
        _canonicalVibeProjectionService = canonicalVibeProjectionService ??
            (GetIt.instance.isRegistered<CanonicalVibeProjectionService>()
                ? GetIt.instance<CanonicalVibeProjectionService>()
                : CanonicalVibeProjectionService()),
        _eventService = eventService ?? GetIt.instance<ExpertiseEventService>(),
        _savedDiscoveryService =
            savedDiscoveryService ?? SavedDiscoveryService(),
        _governedStateService = governedDomainConsumerStateService ??
            (GetIt.instance.isRegistered<GovernedDomainConsumerStateService>()
                ? GetIt.instance<GovernedDomainConsumerStateService>()
                : null),
        _userGovernedLearningProjectionService =
            userGovernedLearningProjectionService ??
                (GetIt.instance
                        .isRegistered<UserGovernedLearningProjectionService>()
                    ? GetIt.instance<UserGovernedLearningProjectionService>()
                    : null),
        _userGovernedLearningAdoptionService =
            userGovernedLearningAdoptionService ??
                (GetIt.instance
                        .isRegistered<UserGovernedLearningAdoptionService>()
                    ? GetIt.instance<UserGovernedLearningAdoptionService>()
                    : null),
        _userGovernedLearningChatObservationService =
            userGovernedLearningChatObservationService ??
                (GetIt.instance.isRegistered<
                        UserGovernedLearningChatObservationService>()
                    ? GetIt.instance<
                        UserGovernedLearningChatObservationService>()
                    : null),
        _userGovernedLearningUsageService = userGovernedLearningUsageService ??
            (GetIt.instance.isRegistered<UserGovernedLearningUsageService>()
                ? GetIt.instance<UserGovernedLearningUsageService>()
                : null);

  Future<ExploreDiscoveryResult> load({
    required UnifiedUser user,
    double? latitude,
    double? longitude,
  }) async {
    final savedItems = await _savedDiscoveryService.listAll(user.id);
    final savedKeys = savedItems
        .map((item) => '${item.entity.type.name}:${item.entity.id}')
        .toSet();
    final userPersonality =
        await _canonicalVibeProjectionService.getOrCreateProjectedProfile(
      userId: user.id,
      loadFallback: _personalityLearning.getCurrentPersonality,
      createFallback: _personalityLearning.initializePersonality,
    );
    final visibleGovernedLearningRecords =
        await _loadVisibleGovernedLearningRecords(user.id);

    final spots = await _loadSpots(
      user: user,
      userPersonality: userPersonality,
      latitude: latitude,
      longitude: longitude,
      savedKeys: savedKeys,
      visibleGovernedLearningRecords: visibleGovernedLearningRecords,
    );
    final lists = await _loadLists(
      savedKeys: savedKeys,
    );
    final events = await _loadEvents(
      user: user,
      savedKeys: savedKeys,
    );
    final communities = await _loadCommunities(
      userId: user.id,
      savedKeys: savedKeys,
    );
    final clubs = await _loadClubs(
      userId: user.id,
      savedKeys: savedKeys,
    );

    return ExploreDiscoveryResult(
      byType: <DiscoveryEntityType, List<ExploreDiscoveryItem>>{
        DiscoveryEntityType.spot: spots,
        DiscoveryEntityType.list: lists,
        DiscoveryEntityType.event: events,
        DiscoveryEntityType.club: clubs,
        DiscoveryEntityType.community: communities,
      },
    );
  }

  Future<List<ExploreDiscoveryItem>> _loadSpots({
    required UnifiedUser user,
    required dynamic userPersonality,
    required double? latitude,
    required double? longitude,
    required Set<String> savedKeys,
    required List<UserVisibleGovernedLearningRecord>
        visibleGovernedLearningRecords,
  }) async {
    final results = latitude != null && longitude != null
        ? await _searchRepository.searchNearbySpots(
            latitude: latitude,
            longitude: longitude,
            maxResults: 16,
            includeExternal: true,
          )
        : await _searchRepository.searchSpots(
            query: '',
            maxResults: 16,
            includeExternal: true,
          );

    final items = <ExploreDiscoveryItem>[];
    final influencesBySpotId = <String, _GovernedLearningSpotInfluence>{};
    for (var index = 0; index < results.spots.length; index++) {
      final spot = results.spots[index];
      final compatibility =
          await _spotVibeMatchingService.calculateSpotUserCompatibilityResult(
        user: user,
        spot: spot,
        userPersonality: userPersonality,
      );
      final governedLearningInfluence = _calculateGovernedLearningInfluence(
        spot: spot,
        visibleRecords: visibleGovernedLearningRecords,
      );
      final attributionCopy = _buildSpotAttributionCopy(
        compatibilitySummary: compatibility.summary,
        governedLearningInfluence: governedLearningInfluence,
        spot: spot,
      );
      influencesBySpotId[spot.id] = governedLearningInfluence;
      final score =
          (compatibility.finalScore + governedLearningInfluence.totalScoreDelta)
              .clamp(0.0, 1.0);
      final entity = DiscoveryEntityReference(
        type: DiscoveryEntityType.spot,
        id: spot.id,
        title: spot.name,
        routePath: '/spot/${spot.id}',
        latitude: spot.latitude,
        longitude: spot.longitude,
        localityLabel: spot.localityCode ?? spot.address,
      );
      items.add(
        ExploreDiscoveryItem(
          entity: entity,
          attribution: RecommendationAttribution(
            why: attributionCopy.why,
            whyDetails: attributionCopy.whyDetails,
            projectedEnjoyabilityPercent: (score * 100).round(),
            recommendationSource: 'spot_matching',
            confidence: compatibility.confidence.clamp(0.0, 1.0),
          ),
          title: spot.name,
          subtitle: spot.category,
          scoreLabel: '${(score * 100).round()}% fit',
          score: score,
          isLiveNow: true,
          secondaryMeta: spot.address,
          isSaved: savedKeys.contains('spot:${spot.id}'),
          canRenderOnMap: entity.hasCoordinates,
          spot: spot,
        ),
      );
    }
    items.sort((a, b) => b.score.compareTo(a.score));
    await _recordGovernedLearningUsageReceiptsForSpots(
      user: user,
      items: items,
      influencesBySpotId: influencesBySpotId,
      decisionFamily: 'spot_recommendation',
      surface: 'explore_spots',
    );
    return items;
  }

  Future<List<ExploreDiscoveryItem>> _loadLists({
    required Set<String> savedKeys,
  }) async {
    final lists = await _listsRepository.getPublicLists();
    final items = lists.take(16).map((list) {
      final centroid = _deriveListCentroid(list);
      final governedBoost = _calculateListGovernedBoost(list);
      final score = (((list.respectCount / 20).clamp(0.0, 0.35) +
                  (list.spots.isNotEmpty ? 0.42 : 0.18) +
                  (list.isPublic ? 0.15 : 0.0)) +
              governedBoost)
          .clamp(0.0, 1.0);
      final entity = DiscoveryEntityReference(
        type: DiscoveryEntityType.list,
        id: list.id,
        title: list.title,
        routePath: '/list/${list.id}',
        latitude: centroid?.$1,
        longitude: centroid?.$2,
        localityLabel: list.category,
      );
      return ExploreDiscoveryItem(
        entity: entity,
        attribution: RecommendationAttribution(
          why: list.spots.isEmpty
              ? 'This public list is ready for stronger place intelligence.'
              : 'This list already clusters places that fit the current city pattern.',
          whyDetails:
              'List recommendations favor public collections with useful local shape and governed curation signals.',
          projectedEnjoyabilityPercent: (score * 100).round(),
          recommendationSource: 'public_lists',
          confidence: (0.62 + governedBoost).clamp(0.0, 0.9),
        ),
        title: list.title,
        subtitle: list.category ?? 'List',
        scoreLabel: '${(score * 100).round()}% fit',
        score: score,
        isLiveNow: list.updatedAt.isAfter(
          DateTime.now().subtract(const Duration(days: 14)),
        ),
        secondaryMeta: '${list.spots.length} spots',
        isSaved: savedKeys.contains('list:${list.id}'),
        canRenderOnMap: centroid != null,
        list: list,
      );
    }).toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    return items;
  }

  Future<List<ExploreDiscoveryItem>> _loadEvents({
    required UnifiedUser user,
    required Set<String> savedKeys,
  }) async {
    final recommendations =
        await _eventRecommendationService.getPersonalizedRecommendations(
      user: user,
      maxResults: 16,
      surface: 'explore_events',
    );
    final now = DateTime.now();
    return recommendations.map((recommendation) {
      final event = recommendation.event;
      final score = recommendation.relevanceScore.clamp(0.0, 1.0);
      final entity = DiscoveryEntityReference(
        type: DiscoveryEntityType.event,
        id: event.id,
        title: event.title,
        routePath: '/event/${event.id}',
        latitude: event.latitude,
        longitude: event.longitude,
        localityLabel: event.localityCode ?? event.location,
      );
      return ExploreDiscoveryItem(
        entity: entity,
        attribution: RecommendationAttribution(
          why: recommendation.recommendationReason,
          whyDetails:
              'Event recommendations come from your current knot and live event timing.',
          projectedEnjoyabilityPercent: (score * 100).round(),
          recommendationSource: 'event_recommendation',
          confidence: score,
        ),
        title: event.title,
        subtitle: event.category,
        scoreLabel: '${(score * 100).round()}% fit',
        score: score,
        isLiveNow: event.status == EventStatus.ongoing ||
            event.startTime.isAfter(now) &&
                event.startTime.difference(now) <= const Duration(hours: 6),
        secondaryMeta: event.location,
        isSaved: savedKeys.contains('event:${event.id}'),
        canRenderOnMap: entity.hasCoordinates,
        event: event,
      );
    }).toList()
      ..sort((a, b) => b.score.compareTo(a.score));
  }

  Future<List<ExploreDiscoveryItem>> _loadCommunities({
    required String userId,
    required Set<String> savedKeys,
  }) async {
    final communities =
        await _communityService.getAllCommunities(maxResults: 32);
    final items = <ExploreDiscoveryItem>[];
    for (final community
        in communities.where((item) => !item.isMember(userId)).take(16)) {
      final scoreBreakdown = await _communityService
          .calculateUserCommunityTrueCompatibilityBreakdown(
        communityId: community.id,
        userId: userId,
      );
      final coords =
          await _resolveCommunityCoordinates(community.originatingEventId);
      final governedBoost = _calculateCommunityGovernedBoost(community);
      final score = (scoreBreakdown.combined + governedBoost).clamp(0.0, 1.0);
      final entity = DiscoveryEntityReference(
        type: DiscoveryEntityType.community,
        id: community.id,
        title: community.name,
        routePath: '/community/${community.id}',
        latitude: coords?.$1,
        longitude: coords?.$2,
        localityLabel: community.localityCode ?? community.originalLocality,
      );
      items.add(
        ExploreDiscoveryItem(
          entity: entity,
          attribution: RecommendationAttribution(
            why: 'This community lines up with your current social shape.',
            whyDetails:
                'Community ranking blends locality, activity, compatibility, and governed coordination signals.',
            projectedEnjoyabilityPercent: (score * 100).round(),
            recommendationSource: 'community_matching',
            confidence: (0.68 + governedBoost).clamp(0.0, 0.92),
          ),
          title: community.name,
          subtitle: community.category,
          scoreLabel: '${(score * 100).round()}% fit',
          score: score,
          isLiveNow: community.lastEventAt != null &&
              DateTime.now().difference(community.lastEventAt!) <
                  const Duration(days: 7),
          secondaryMeta: community.originalLocality,
          isSaved: savedKeys.contains('community:${community.id}'),
          canRenderOnMap: entity.hasCoordinates,
          community: community,
        ),
      );
    }
    items.sort((a, b) => b.score.compareTo(a.score));
    return items;
  }

  Future<List<ExploreDiscoveryItem>> _loadClubs({
    required String userId,
    required Set<String> savedKeys,
  }) async {
    final clubs = await _clubService.getAllClubs(maxResults: 24);
    return clubs.where((club) => !club.isMember(userId)).take(16).map((club) {
      final governedBoost = _calculateClubGovernedBoost(club);
      final score = (((club.memberCount / 30).clamp(0.0, 0.35) +
                  club.organizationalMaturity.clamp(0.0, 0.3) +
                  club.leadershipStability.clamp(0.0, 0.25) +
                  (club.activityLevel == ActivityLevel.growing ? 0.1 : 0.0)) +
              governedBoost)
          .clamp(0.0, 1.0);
      final entity = DiscoveryEntityReference(
        type: DiscoveryEntityType.club,
        id: club.id,
        title: club.name,
        routePath: '/club/${club.id}',
        localityLabel: club.localityCode ?? club.originalLocality,
      );
      return ExploreDiscoveryItem(
        entity: entity,
        attribution: RecommendationAttribution(
          why:
              'This club has enough structure to be useful without overformalizing.',
          whyDetails:
              'Club ranking favors local leadership stability, active membership, and governed community signals.',
          projectedEnjoyabilityPercent: (score * 100).round(),
          recommendationSource: 'club_discovery',
          confidence: (0.64 + governedBoost).clamp(0.0, 0.9),
        ),
        title: club.name,
        subtitle: club.category,
        scoreLabel: '${(score * 100).round()}% fit',
        score: score,
        isLiveNow: club.lastEventAt != null &&
            DateTime.now().difference(club.lastEventAt!) <
                const Duration(days: 14),
        secondaryMeta: '${club.memberCount} members',
        isSaved: savedKeys.contains('club:${club.id}'),
        canRenderOnMap: false,
        club: club,
      );
    }).toList()
      ..sort((a, b) => b.score.compareTo(a.score));
  }

  (double, double)? _deriveListCentroid(SpotList list) {
    final withCoordinates = list.spots;
    if (withCoordinates.isEmpty) {
      return null;
    }

    final lat =
        withCoordinates.map((spot) => spot.latitude).reduce((a, b) => a + b) /
            withCoordinates.length;
    final lon =
        withCoordinates.map((spot) => spot.longitude).reduce((a, b) => a + b) /
            withCoordinates.length;
    return (lat, lon);
  }

  Future<(double, double)?> _resolveCommunityCoordinates(String eventId) async {
    try {
      final event = await _eventService.getEventById(eventId);
      if (event?.latitude == null || event?.longitude == null) {
        return null;
      }
      return (event!.latitude!, event.longitude!);
    } catch (_) {
      return null;
    }
  }

  double _calculateListGovernedBoost(SpotList list) {
    final cityCode = _deriveListCityCode(list);
    final listState = _latestGovernedState(
      cityCode: cityCode,
      domainId: 'list',
    );
    final placeState = _latestGovernedState(
      cityCode: cityCode,
      domainId: 'place',
    );
    return (_boundedGovernedBoost(listState, maxBoost: 0.05) +
            _boundedGovernedBoost(placeState, maxBoost: 0.03))
        .clamp(0.0, 0.08);
  }

  double _calculateCommunityGovernedBoost(Community community) {
    final communityState = _latestGovernedState(
      cityCode: community.cityCode,
      domainId: 'community',
    );
    final localityState = _latestGovernedState(
      cityCode: community.cityCode,
      domainId: 'locality',
    );
    return (_boundedGovernedBoost(communityState, maxBoost: 0.05) +
            _boundedGovernedBoost(localityState, maxBoost: 0.03))
        .clamp(0.0, 0.08);
  }

  double _calculateClubGovernedBoost(Club club) {
    final communityState = _latestGovernedState(
      cityCode: club.cityCode,
      domainId: 'community',
    );
    final localityState = _latestGovernedState(
      cityCode: club.cityCode,
      domainId: 'locality',
    );
    return (_boundedGovernedBoost(communityState, maxBoost: 0.04) +
            _boundedGovernedBoost(localityState, maxBoost: 0.03))
        .clamp(0.0, 0.07);
  }

  GovernedDomainConsumerState? _latestGovernedState({
    String? cityCode,
    required String domainId,
  }) {
    if (_governedStateService == null) {
      return null;
    }
    return _governedStateService.latestLiveStateFor(
      cityCode: cityCode,
      domainId: domainId,
    );
  }

  double _boundedGovernedBoost(
    GovernedDomainConsumerState? state, {
    required double maxBoost,
  }) {
    if (state == null ||
        state.status != 'executed_local_governed_domain_consumer_refresh') {
      return 0.0;
    }
    final confidence = (state.averageConfidence ?? 0.65).clamp(0.0, 1.0);
    final requestSignal = (state.requestCount / 4.0).clamp(0.35, 1.0);
    final recommendationSignal =
        (state.recommendationCount / 3.0).clamp(0.35, 1.0);
    final combinedSignal =
        ((confidence + requestSignal + recommendationSignal) / 3.0)
            .clamp(0.0, 1.0);
    return (combinedSignal * state.temporalFreshnessWeight() * maxBoost)
        .clamp(0.0, maxBoost);
  }

  String? _deriveListCityCode(SpotList list) {
    for (final spot in list.spots) {
      final cityCode = spot.cityCode?.trim();
      if (cityCode != null && cityCode.isNotEmpty) {
        return cityCode;
      }
    }
    return null;
  }

  Future<List<UserVisibleGovernedLearningRecord>>
      _loadVisibleGovernedLearningRecords(String ownerUserId) async {
    final service = _userGovernedLearningProjectionService;
    if (service == null) {
      return const <UserVisibleGovernedLearningRecord>[];
    }
    try {
      return await service.listVisibleRecords(
        ownerUserId: ownerUserId,
        limit: 20,
      );
    } catch (_) {
      return const <UserVisibleGovernedLearningRecord>[];
    }
  }

  _GovernedLearningSpotInfluence _calculateGovernedLearningInfluence({
    required Spot spot,
    required List<UserVisibleGovernedLearningRecord> visibleRecords,
  }) {
    if (visibleRecords.isEmpty) {
      return const _GovernedLearningSpotInfluence.none();
    }
    final candidates = <_GovernedLearningSpotInfluenceCandidate>[];
    for (final record in visibleRecords) {
      if (record.futureSignalUseBlocked) {
        continue;
      }
      final rawScore = _scoreGovernedLearningRecordForSpot(
        record: record,
        spot: spot,
      );
      if (rawScore <= 0.0) {
        continue;
      }
      candidates.add(
        _GovernedLearningSpotInfluenceCandidate(
          record: record,
          rawScore: rawScore,
        ),
      );
    }
    if (candidates.isEmpty) {
      return const _GovernedLearningSpotInfluence.none();
    }
    candidates.sort((left, right) => right.rawScore.compareTo(left.rawScore));
    final topCandidates = candidates.take(2).toList(growable: false);
    final totalRawScore = topCandidates.fold<double>(
      0.0,
      (sum, candidate) => sum + candidate.rawScore,
    );
    if (totalRawScore <= 0.0) {
      return const _GovernedLearningSpotInfluence.none();
    }
    const maxBoost = 0.1;
    final cappedTotal = totalRawScore.clamp(0.0, maxBoost);
    final normalizedCandidates = <_GovernedLearningSpotInfluenceCandidate>[];
    for (final candidate in topCandidates) {
      final normalizedScore =
          cappedTotal * (candidate.rawScore / totalRawScore);
      if (normalizedScore < 0.01) {
        continue;
      }
      normalizedCandidates.add(
        candidate.copyWith(
          normalizedScore: normalizedScore,
        ),
      );
    }
    if (normalizedCandidates.isEmpty) {
      return const _GovernedLearningSpotInfluence.none();
    }
    final totalScoreDelta = normalizedCandidates.fold<double>(
      0.0,
      (sum, candidate) => sum + candidate.normalizedScore,
    );
    return _GovernedLearningSpotInfluence(
      totalScoreDelta: totalScoreDelta,
      candidates: normalizedCandidates,
    );
  }

  double _scoreGovernedLearningRecordForSpot({
    required UserVisibleGovernedLearningRecord record,
    required Spot spot,
  }) {
    final spotName = _normalizeGovernedText(spot.name);
    final spotCategory = _normalizeGovernedText(spot.category);
    final spotDescription = _normalizeGovernedText(spot.description);
    final spotAddress = _normalizeGovernedText(spot.address ?? '');
    final spotContext = <String>[
      spotName,
      spotCategory,
      spotDescription,
      spotAddress,
      _normalizeGovernedText(spot.cityCode ?? ''),
      _normalizeGovernedText(spot.localityCode ?? ''),
      ...spot.tags.map(_normalizeGovernedText),
    ].join(' ');

    var score = 0.0;

    for (final entity in record.referencedEntities) {
      final normalizedEntity = _normalizeGovernedText(entity);
      if (normalizedEntity.isEmpty) {
        continue;
      }
      if (spotName.contains(normalizedEntity)) {
        score += 0.08;
      } else if (spotContext.contains(normalizedEntity)) {
        score += 0.05;
      }
    }

    for (final domain in record.domainHints) {
      final normalizedDomain = _normalizeGovernedText(domain);
      if (normalizedDomain.isEmpty) {
        continue;
      }
      if (spotCategory.contains(normalizedDomain)) {
        score += 0.04;
      } else if (spotContext.contains(normalizedDomain)) {
        score += 0.025;
      }
    }

    final summaryTerms = _extractGovernedLearningTerms(
      '${record.title} ${record.safeSummary}',
    );
    for (final term in summaryTerms.take(6)) {
      if (spotContext.contains(term)) {
        score += 0.012;
      }
    }

    if (record.sourceProvider == 'recommendation_feedback_intake' &&
        record.referencedEntities.any(
          (entity) => _normalizeGovernedText(entity) == spotName,
        )) {
      score += 0.02;
    }

    return score.clamp(0.0, 0.1);
  }

  Future<void> _recordGovernedLearningUsageReceiptsForSpots({
    required UnifiedUser user,
    required List<ExploreDiscoveryItem> items,
    required Map<String, _GovernedLearningSpotInfluence> influencesBySpotId,
    required String decisionFamily,
    required String surface,
  }) async {
    final usageService = _userGovernedLearningUsageService;
    if (usageService == null || items.isEmpty || influencesBySpotId.isEmpty) {
      return;
    }
    final decisionTimestamp = DateTime.now().toUtc();
    final receipts = <GovernedLearningUsageReceipt>[];
    for (final item in items) {
      final spot = item.spot;
      if (spot == null) {
        continue;
      }
      final influence = influencesBySpotId[spot.id];
      if (influence == null || !influence.hasInfluence) {
        continue;
      }
      final domainId = _deriveSpotGovernedDomainId(spot);
      final domainLabel = _deriveSpotGovernedDomainLabel(spot);
      final decisionId =
          '$decisionFamily:${user.id}:${spot.id}:${decisionTimestamp.microsecondsSinceEpoch}';
      for (final candidate in influence.candidates) {
        receipts.add(
          GovernedLearningUsageReceipt(
            id: '${candidate.record.envelopeId}:$decisionId:${candidate.record.sourceId}',
            ownerUserId: user.id,
            envelopeId: candidate.record.envelopeId,
            sourceId: candidate.record.sourceId,
            decisionFamily: decisionFamily,
            decisionId: decisionId,
            domainId: domainId,
            domainLabel: domainLabel,
            targetEntityId: spot.id,
            targetEntityType: 'spot',
            targetEntityTitle: spot.name,
            usedAtUtc: decisionTimestamp,
            influenceKind: GovernedLearningUsageInfluenceKind.boost,
            influenceScoreDelta: candidate.normalizedScore,
            influenceReason:
                'Governed learning about ${candidate.record.safeSummary} helped boost this spot recommendation.',
            surface: surface,
          ),
        );
      }
    }
    if (receipts.isEmpty) {
      return;
    }
    try {
      await usageService.recordReceipts(receipts);
      await _recordFirstSurfacedAdoptionReceiptsForSpots(
        ownerUserId: user.id,
        receipts: receipts,
        surface: surface,
        decisionFamily: decisionFamily,
      );
    } catch (_) {}
  }

  Future<void> _recordFirstSurfacedAdoptionReceiptsForSpots({
    required String ownerUserId,
    required List<GovernedLearningUsageReceipt> receipts,
    required String surface,
    required String decisionFamily,
  }) async {
    final adoptionService = _userGovernedLearningAdoptionService;
    if (adoptionService == null || receipts.isEmpty) {
      return;
    }

    final existingReceipts = await adoptionService.listReceiptsForUser(
      ownerUserId: ownerUserId,
      limit: 400,
    );
    final alreadySurfacedKeys = existingReceipts
        .where(
          (receipt) =>
              receipt.status ==
              GovernedLearningAdoptionStatus.firstSurfacedOnSurface,
        )
        .map((receipt) => '${receipt.envelopeId}:${receipt.surface ?? ''}')
        .toSet();

    final firstReceiptsByEnvelope = <String, GovernedLearningUsageReceipt>{};
    for (final receipt in receipts) {
      firstReceiptsByEnvelope.putIfAbsent(receipt.envelopeId, () => receipt);
    }

    final adoptionReceipts = <GovernedLearningAdoptionReceipt>[];
    for (final entry in firstReceiptsByEnvelope.entries) {
      final usageReceipt = entry.value;
      final surfaceKey = '${usageReceipt.envelopeId}:$surface';
      if (alreadySurfacedKeys.contains(surfaceKey)) {
        continue;
      }
      adoptionReceipts.add(
        GovernedLearningAdoptionReceipt(
          id: '${usageReceipt.envelopeId}:$surface:first_surfaced_on_surface',
          ownerUserId: ownerUserId,
          envelopeId: usageReceipt.envelopeId,
          sourceId: usageReceipt.sourceId,
          status: GovernedLearningAdoptionStatus.firstSurfacedOnSurface,
          recordedAtUtc: usageReceipt.usedAtUtc,
          surface: surface,
          decisionFamily: decisionFamily,
          domainId: usageReceipt.domainId,
          domainLabel: usageReceipt.domainLabel,
          targetEntityId: usageReceipt.targetEntityId,
          targetEntityType: usageReceipt.targetEntityType,
          targetEntityTitle: usageReceipt.targetEntityTitle,
          reason: 'first surfaced on $surface',
        ),
      );
    }
    if (adoptionReceipts.isEmpty) {
      return;
    }
    await adoptionService.recordReceipts(adoptionReceipts);
    final observationService = _userGovernedLearningChatObservationService;
    if (observationService != null) {
      for (final adoptionReceipt in adoptionReceipts) {
        await observationService.markLatestUnvalidatedAsSurfacedAdoption(
          ownerUserId: ownerUserId,
          envelopeId: adoptionReceipt.envelopeId,
          validatedAtUtc: adoptionReceipt.recordedAtUtc,
          surface: adoptionReceipt.surface ?? surface,
          targetEntityTitle: adoptionReceipt.targetEntityTitle,
        );
      }
    }
  }

  String _deriveSpotGovernedDomainId(Spot spot) {
    final category = _normalizeGovernedText(spot.category);
    if (category.contains('coffee') ||
        category.contains('cafe') ||
        category.contains('espresso')) {
      return 'coffee';
    }
    if (category.contains('nightlife') ||
        category.contains('bar') ||
        category.contains('club') ||
        category.contains('cocktail') ||
        category.contains('lounge')) {
      return 'nightlife';
    }
    if (category.contains('brunch')) {
      return 'brunch';
    }
    if (category.contains('breakfast')) {
      return 'breakfast';
    }
    if (category.contains('restaurant') ||
        category.contains('food') ||
        category.contains('dinner') ||
        category.contains('lunch')) {
      return 'restaurant';
    }
    return category.isEmpty ? 'place' : category;
  }

  String _deriveSpotGovernedDomainLabel(Spot spot) {
    final domainId = _deriveSpotGovernedDomainId(spot);
    if (domainId == 'coffee') {
      return 'Coffee';
    }
    if (domainId == 'nightlife') {
      return 'Nightlife';
    }
    if (domainId == 'restaurant') {
      return 'Restaurant';
    }
    if (domainId == 'place') {
      return 'Place';
    }
    return _humanizeGovernedLabel(domainId);
  }

  ({String why, String whyDetails}) _buildSpotAttributionCopy({
    required String compatibilitySummary,
    required _GovernedLearningSpotInfluence governedLearningInfluence,
    required Spot spot,
  }) {
    if (!governedLearningInfluence.hasInfluence) {
      return (
        why: compatibilitySummary,
        whyDetails: 'Spot compatibility from your knot and locality context.',
      );
    }

    final primaryCandidate = governedLearningInfluence.candidates.first;
    final domainLabel = _deriveSpotGovernedDomainLabel(spot).toLowerCase();
    final summary =
        _humanizeGovernedLearningSummary(primaryCandidate.record.safeSummary);
    final why = summary != null
        ? 'A recent signal that $summary helped boost this spot.'
        : 'A recent $domainLabel signal helped boost this spot.';
    final whyDetails =
        '$compatibilitySummary This spot still matches your knot and locality context, and the bounded $domainLabel learning signal added extra lift.'
        '${governedLearningInfluence.candidates.length > 1 ? ' Another recent governed learning signal also contributed.' : ''}';
    return (
      why: why,
      whyDetails: whyDetails,
    );
  }

  String _normalizeGovernedText(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\\s]+'), ' ')
        .replaceAll(RegExp(r'\\s+'), ' ')
        .trim();
  }

  List<String> _extractGovernedLearningTerms(String value) {
    const stopWords = <String>{
      'the',
      'and',
      'for',
      'with',
      'that',
      'this',
      'from',
      'your',
      'user',
      'about',
      'into',
      'what',
      'when',
      'where',
      'would',
      'could',
      'should',
      'have',
      'has',
      'like',
      'more',
      'less',
      'want',
      'wants',
      'asked',
      'said',
      'plan',
      'place',
      'places',
    };
    final unique = <String>{};
    final ordered = <String>[];
    for (final part in _normalizeGovernedText(value).split(' ')) {
      if (part.length < 4 || stopWords.contains(part) || !unique.add(part)) {
        continue;
      }
      ordered.add(part);
    }
    return ordered;
  }

  String _humanizeGovernedLabel(String value) {
    final normalized = _normalizeGovernedText(value);
    if (normalized.isEmpty) {
      return 'Place';
    }
    return normalized
        .split(' ')
        .map(
          (part) => part.isEmpty
              ? part
              : '${part[0].toUpperCase()}${part.substring(1)}',
        )
        .join(' ');
  }

  String? _humanizeGovernedLearningSummary(String? summary) {
    final trimmed = summary?.trim() ?? '';
    if (trimmed.isEmpty) {
      return null;
    }
    const replacements = <MapEntry<String, String>>[
      MapEntry('The user wants ', 'you wanted '),
      MapEntry('The user prefers ', 'you preferred '),
      MapEntry('The user likes ', 'you liked '),
      MapEntry('The user does not like ', 'you did not like '),
      MapEntry('The user reacted ', 'you reacted '),
      MapEntry('The user said ', 'you said '),
      MapEntry('The user asked ', 'you asked '),
      MapEntry('The user corrected ', 'you corrected '),
    ];
    for (final replacement in replacements) {
      if (trimmed.startsWith(replacement.key)) {
        return _ensureGovernedSentenceFragment(
          replacement.value + trimmed.substring(replacement.key.length),
        );
      }
    }
    return _ensureGovernedSentenceFragment(trimmed);
  }

  String _ensureGovernedSentenceFragment(String value) {
    final trimmed = value.trim();
    if (trimmed.endsWith('.')) {
      return trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }
}

class _GovernedLearningSpotInfluence {
  const _GovernedLearningSpotInfluence({
    required this.totalScoreDelta,
    required this.candidates,
  });

  const _GovernedLearningSpotInfluence.none()
      : totalScoreDelta = 0.0,
        candidates = const <_GovernedLearningSpotInfluenceCandidate>[];

  final double totalScoreDelta;
  final List<_GovernedLearningSpotInfluenceCandidate> candidates;

  bool get hasInfluence => totalScoreDelta > 0.0 && candidates.isNotEmpty;
}

class _GovernedLearningSpotInfluenceCandidate {
  const _GovernedLearningSpotInfluenceCandidate({
    required this.record,
    required this.rawScore,
    this.normalizedScore = 0.0,
  });

  final UserVisibleGovernedLearningRecord record;
  final double rawScore;
  final double normalizedScore;

  _GovernedLearningSpotInfluenceCandidate copyWith({
    double? normalizedScore,
  }) {
    return _GovernedLearningSpotInfluenceCandidate(
      record: record,
      rawScore: rawScore,
      normalizedScore: normalizedScore ?? this.normalizedScore,
    );
  }
}

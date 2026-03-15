import 'package:avrai_core/models/community/club.dart';
import 'package:avrai_core/models/community/community.dart';
import 'package:avrai_core/models/discovery/discovery_models.dart';
import 'package:avrai_core/models/expertise/expertise_event.dart';
import 'package:avrai_core/models/misc/list.dart';
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
import 'package:avrai_runtime_os/services/recommendations/saved_discovery_service.dart';
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
            savedDiscoveryService ?? SavedDiscoveryService();

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

    final spots = await _loadSpots(
      user: user,
      userPersonality: userPersonality,
      latitude: latitude,
      longitude: longitude,
      savedKeys: savedKeys,
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
    for (var index = 0; index < results.spots.length; index++) {
      final spot = results.spots[index];
      final compatibility =
          await _spotVibeMatchingService.calculateSpotUserCompatibilityResult(
        user: user,
        spot: spot,
        userPersonality: userPersonality,
      );
      final score = compatibility.finalScore.clamp(0.0, 1.0);
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
            why: compatibility.summary,
            whyDetails:
                'Spot compatibility from your knot and locality context.',
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
    return items;
  }

  Future<List<ExploreDiscoveryItem>> _loadLists({
    required Set<String> savedKeys,
  }) async {
    final lists = await _listsRepository.getPublicLists();
    final items = lists.take(16).map((list) {
      final centroid = _deriveListCentroid(list);
      final score = ((list.respectCount / 20).clamp(0.0, 0.35) +
              (list.spots.isNotEmpty ? 0.42 : 0.18) +
              (list.isPublic ? 0.15 : 0.0))
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
              ? 'This list is a public Birmingham collection worth building out.'
              : 'This list clusters places that already fit the BHAM beta loop.',
          whyDetails:
              'List recommendations favor public collections with useful local shape.',
          projectedEnjoyabilityPercent: (score * 100).round(),
          recommendationSource: 'public_lists',
          confidence: 0.62,
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
      final score = scoreBreakdown.combined.clamp(0.0, 1.0);
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
            why: 'This community lines up with your Birmingham social shape.',
            whyDetails:
                'Community ranking blends locality, activity, and compatibility.',
            projectedEnjoyabilityPercent: (score * 100).round(),
            recommendationSource: 'community_matching',
            confidence: 0.68,
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
      final score = ((club.memberCount / 30).clamp(0.0, 0.35) +
              club.organizationalMaturity.clamp(0.0, 0.3) +
              club.leadershipStability.clamp(0.0, 0.25) +
              (club.activityLevel == ActivityLevel.growing ? 0.1 : 0.0))
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
              'Club ranking favors local leadership stability and active membership.',
          projectedEnjoyabilityPercent: (score * 100).round(),
          recommendationSource: 'club_discovery',
          confidence: 0.64,
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
}

import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmap;
import 'package:latlong2/latlong.dart';

import 'package:avrai/injection_container.dart' as di;
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/presentation/models/explore_item.dart';
import 'package:avrai/presentation/pages/events/event_details_page.dart';
import 'package:avrai/presentation/pages/spots/spot_details_page.dart';
import 'package:avrai/presentation/services/metro_experience_service.dart';
import 'package:avrai/presentation/widgets/chat/chat_button_with_badge.dart';
import 'package:avrai/presentation/widgets/common/app_flow_scaffold.dart';
import 'package:avrai/presentation/widgets/common/undoable_negative_feedback.dart';
import 'package:avrai/theme/app_theme.dart';
import 'package:avrai/theme/colors.dart';
import 'package:avrai_core/models/community.dart';
import 'package:avrai_core/models/expertise/expertise_event.dart';
import 'package:avrai_core/models/signatures/entity_signature.dart';
import 'package:avrai_core/models/signatures/signature_match_result.dart';
import 'package:avrai_core/models/spots/spot.dart';
import 'package:avrai_core/models/user/unified_user.dart';
import 'package:avrai_core/models/user/user.dart' as app_user;
import 'package:avrai_runtime_os/ai/personality_learning.dart';
import 'package:avrai_runtime_os/data/repositories/hybrid_search_repository.dart';
import 'package:avrai_runtime_os/services/community/community_service.dart';
import 'package:avrai_runtime_os/services/events/event_recommendation_service.dart';
import 'package:avrai_runtime_os/services/expertise/expertise_event_service.dart';
import 'package:avrai_runtime_os/services/geographic/geo_hierarchy_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:avrai_runtime_os/services/matching/spot_vibe_matching_service.dart';
import 'package:avrai_runtime_os/services/signatures/entity_signature_service.dart';

enum _ExploreViewMode {
  map,
  list,
}

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final HybridSearchRepository _searchRepository =
      di.sl<HybridSearchRepository>();
  final CommunityService _communityService = di.sl<CommunityService>();
  final EventRecommendationService _eventRecommendationService =
      di.sl<EventRecommendationService>();
  final ExpertiseEventService _eventService = di.sl<ExpertiseEventService>();
  final PersonalityLearning _personalityLearning = di.sl<PersonalityLearning>();
  final SpotVibeMatchingService _spotVibeMatchingService =
      di.sl<SpotVibeMatchingService>();
  final EntitySignatureService _entitySignatureService =
      di.sl<EntitySignatureService>();
  late final MetroExperienceService _metroExperienceService =
      MetroExperienceService(
    geoHierarchyService: di.sl<GeoHierarchyService>(),
    prefs: di.sl<SharedPreferencesCompat>(),
  );

  Timer? _realtimeRefreshTimer;
  Position? _currentPosition;
  MetroExperienceContext? _metroContext;
  List<ExploreItem> _items = const [];
  bool _isLoading = true;
  String? _error;

  bool _showRealtime = true;
  bool _showSpots = true;
  bool _showEvents = true;
  bool _showCommunities = true;
  _ExploreViewMode _viewMode = _ExploreViewMode.map;
  final Set<String> _suppressedItemKeys = <String>{};

  bool get _shouldUseGoogleMaps {
    if (kIsWeb) {
      return false;
    }

    if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      return false;
    }

    return true;
  }

  @override
  void initState() {
    super.initState();
    _loadData();
    _configureRealtimeRefresh();
  }

  @override
  void dispose() {
    _realtimeRefreshTimer?.cancel();
    super.dispose();
  }

  List<ExploreItem> get _filteredItems {
    return _items.where((item) {
      if (_suppressedItemKeys.contains(_itemKey(item))) {
        return false;
      }
      final includeType = switch (item.type) {
        ExploreItemType.spot => _showSpots,
        ExploreItemType.event => _showEvents,
        ExploreItemType.community => _showCommunities,
      };

      if (!includeType) {
        return false;
      }

      if (_showRealtime && !item.isLiveNow) {
        return false;
      }

      return true;
    }).toList()
      ..sort((a, b) => b.score.compareTo(a.score));
  }

  List<ExploreItem> _itemsForType(ExploreItemType type) {
    return _filteredItems.where((item) => item.type == type).toList();
  }

  String get _exploreSubtitle {
    if (_metroContext?.hasMetroProfile == true) {
      return 'Map-first discovery for ${_metroContext!.displayName}, with ranked spots, events, and communities that should feel logical for your pace.';
    }
    return 'Map-first discovery for spots, events, and communities ranked around what feels most relevant to you.';
  }

  String get _locationContextLabel {
    if (_currentPosition != null) {
      return 'Using your location';
    }
    if (_metroContext?.hasMetroProfile == true) {
      return 'Using ${_metroContext!.displayName} context';
    }
    return 'Using broad nearby context';
  }

  void _setLayerEnabled(ExploreItemType type, bool value) {
    setState(() {
      switch (type) {
        case ExploreItemType.spot:
          _showSpots = value;
          break;
        case ExploreItemType.event:
          _showEvents = value;
          break;
        case ExploreItemType.community:
          _showCommunities = value;
          break;
      }
    });
  }

  void _resetFilters() {
    setState(() {
      _showRealtime = true;
      _showSpots = true;
      _showEvents = true;
      _showCommunities = true;
      _viewMode = _ExploreViewMode.map;
    });
    _configureRealtimeRefresh();
  }

  Future<void> _loadData({bool showLoading = true}) async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _items = const [];
        _error = 'Sign in to explore recommendations.';
      });
      return;
    }

    if (showLoading && mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final position = await _loadCurrentLocation();
      final user = authState.user;
      final metroContext = await _metroExperienceService.resolveBestEffort(
        latitude: position?.latitude,
        longitude: position?.longitude,
        locationLabel: user.displayName ?? user.name,
      );

      final results = await Future.wait<List<ExploreItem>>([
        _loadSpotItems(user, position, metroContext),
        _loadEventItems(user, metroContext),
        _loadCommunityItems(user, metroContext),
      ]);

      final items = results.expand((result) => result).toList()
        ..sort((a, b) => b.score.compareTo(a.score));

      if (!mounted) {
        return;
      }

      setState(() {
        _currentPosition = position;
        _metroContext = metroContext;
        _items = items;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _error = 'Failed to load explore data: $e';
      });
    }
  }

  Future<Position?> _loadCurrentLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return _currentPosition;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
        ),
      );
    } catch (_) {
      return _currentPosition;
    }
  }

  Future<List<ExploreItem>> _loadSpotItems(
    app_user.User user,
    Position? position,
    MetroExperienceContext metroContext,
  ) async {
    final searchResult = position != null
        ? await _searchRepository.searchNearbySpots(
            latitude: position.latitude,
            longitude: position.longitude,
            maxResults: 18,
            includeExternal: true,
          )
        : await _searchRepository.searchSpots(
            query: '',
            maxResults: 18,
            includeExternal: true,
          );

    final unifiedUser = _toUnifiedUser(user);
    final userPersonality =
        await _personalityLearning.initializePersonality(unifiedUser.id);

    final items = <ExploreItem>[];
    for (var index = 0; index < searchResult.spots.length; index++) {
      final spot = searchResult.spots[index];
      final metadata =
          searchResult.metadata != null && index < searchResult.metadata!.length
              ? searchResult.metadata![index]
              : null;

      final compatibility =
          await _spotVibeMatchingService.calculateSpotUserCompatibilityResult(
        user: unifiedUser,
        spot: spot,
        userPersonality: userPersonality,
      );

      final distanceBoost = metadata?.distance != null
          ? (0.06 - ((metadata!.distance! / 12000).clamp(0.0, 1.0) * 0.06))
          : 0.02;
      final score = (compatibility.finalScore +
              distanceBoost +
              _metroExperienceService.scoreCategoryAffinity(
                context: metroContext,
                category: spot.category,
                title: spot.name,
                subtitle: spot.description,
              ) +
              _metroExperienceService.scoreLocationAffinity(
                context: metroContext,
                cityCode: spot.cityCode,
                localityCode: spot.localityCode,
                locationLabel: spot.address,
              ))
          .clamp(0.0, 1.0);

      final reason = compatibility.usedSignaturePrimary
          ? '${compatibility.summary} ${_buildSpotReason(
              spot: spot,
              distanceMeters: metadata?.distance,
              communityFirst: spot.metadata['is_external'] != true,
              metroContext: metroContext,
            )}'
          : _buildSpotReason(
              spot: spot,
              distanceMeters: metadata?.distance,
              communityFirst: spot.metadata['is_external'] != true,
              metroContext: metroContext,
            );

      items.add(
        ExploreItem(
          id: spot.id,
          type: ExploreItemType.spot,
          title: spot.name,
          subtitle: spot.category,
          scoreLabel: '${(score * 100).toStringAsFixed(0)}% fit',
          reason: reason,
          score: score,
          latitude: spot.latitude,
          longitude: spot.longitude,
          isLiveNow: true,
          secondaryMeta: metadata?.distance != null
              ? _formatDistance(metadata!.distance!)
              : spot.address,
          spot: spot,
        ),
      );
    }

    return items;
  }

  Future<List<ExploreItem>> _loadEventItems(
    app_user.User user,
    MetroExperienceContext metroContext,
  ) async {
    final recommendations =
        await _eventRecommendationService.getPersonalizedRecommendations(
      user: _toUnifiedUser(user),
      maxResults: 14,
    );

    final now = DateTime.now();

    return recommendations.map((recommendation) {
      final event = recommendation.event;
      final isLiveNow = event.status == EventStatus.ongoing ||
          (event.startTime.isAfter(now) &&
              event.startTime.difference(now) <= const Duration(hours: 6));
      final metroCategoryBoost = _metroExperienceService.scoreCategoryAffinity(
        context: metroContext,
        category: event.category,
        title: event.title,
        subtitle: event.location,
      );
      final metroLocationBoost = _metroExperienceService.scoreLocationAffinity(
        context: metroContext,
        cityCode: event.cityCode,
        localityCode: event.localityCode,
        locationLabel: event.location,
      );
      final blendedScore = (recommendation.relevanceScore +
              metroCategoryBoost +
              metroLocationBoost)
          .clamp(0.0, 1.0);

      return ExploreItem(
        id: event.id,
        type: ExploreItemType.event,
        title: event.title,
        subtitle: event.category,
        scoreLabel: '${(blendedScore * 100).toStringAsFixed(0)}% fit',
        reason: '${recommendation.recommendationReason} ${_buildEventReason(
          event: event,
          isLiveNow: isLiveNow,
          blendedScore: blendedScore,
          metroContext: metroContext,
        )}',
        score: blendedScore,
        latitude: event.latitude,
        longitude: event.longitude,
        isLiveNow: isLiveNow,
        secondaryMeta: _formatEventTime(event),
        event: event,
      );
    }).toList();
  }

  Future<List<ExploreItem>> _loadCommunityItems(
    app_user.User user,
    MetroExperienceContext metroContext,
  ) async {
    final communities =
        await _communityService.getAllCommunities(maxResults: 200);
    final candidates = communities.where((community) {
      return !community.isMember(user.id);
    }).toList();

    final breakdowns = await _scoreCommunitiesBounded(candidates, user.id);
    final matches = await _scoreCommunityMatchesBounded(
      communities: candidates,
      userId: user.id,
      fallbackBreakdowns: breakdowns,
    );
    candidates.sort((a, b) {
      final scoreA =
          matches[a.id]?.finalScore ?? breakdowns[a.id]?.combined ?? 0.0;
      final scoreB =
          matches[b.id]?.finalScore ?? breakdowns[b.id]?.combined ?? 0.0;
      return scoreB.compareTo(scoreA);
    });

    final topCommunities = candidates.take(12).toList();
    final items = <ExploreItem>[];

    for (final community in topCommunities) {
      final breakdown = breakdowns[community.id];
      final match = matches[community.id];
      final resolvedCoordinates =
          await _resolveCommunityCoordinates(community.originatingEventId);
      final metroCategoryBoost = _metroExperienceService.scoreCategoryAffinity(
        context: metroContext,
        category: community.category,
        title: community.name,
        subtitle: community.originalLocality,
      );
      final metroLocationBoost = _metroExperienceService.scoreLocationAffinity(
        context: metroContext,
        localityCode: community.originalLocality,
        locationLabel: community.originalLocality,
      );
      final blendedScore =
          (((match?.finalScore ?? breakdown?.combined) ?? 0.5) +
                  metroCategoryBoost +
                  metroLocationBoost)
              .clamp(0.0, 1.0);

      items.add(
        ExploreItem(
          id: community.id,
          type: ExploreItemType.community,
          title: community.name,
          subtitle: community.category,
          scoreLabel: '${(blendedScore * 100).toStringAsFixed(0)}% fit',
          reason: match != null && match.usedSignaturePrimary
              ? '${match.summary} ${_buildCommunityReason(
                  community: community,
                  breakdown: breakdown,
                  metroContext: metroContext,
                )}'
              : _buildCommunityReason(
                  community: community,
                  breakdown: breakdown,
                  metroContext: metroContext,
                ),
          score: blendedScore,
          latitude: resolvedCoordinates?.latitude,
          longitude: resolvedCoordinates?.longitude,
          isLiveNow: community.lastEventAt != null &&
              DateTime.now().difference(community.lastEventAt!) <=
                  const Duration(days: 7),
          secondaryMeta: community.originalLocality,
          community: community,
        ),
      );
    }

    return items;
  }

  Future<Map<String, CommunityTrueCompatibilityBreakdown>>
      _scoreCommunitiesBounded(
    List<Community> communities,
    String userId,
  ) async {
    const maxConcurrency = 6;
    if (communities.isEmpty) {
      return const {};
    }

    final result = <String, CommunityTrueCompatibilityBreakdown>{};
    var nextIndex = 0;

    Future<void> worker() async {
      while (true) {
        final index = nextIndex++;
        if (index >= communities.length) {
          return;
        }

        final community = communities[index];
        try {
          final breakdown = await _communityService
              .calculateUserCommunityTrueCompatibilityBreakdown(
            communityId: community.id,
            userId: userId,
          );
          result[community.id] = breakdown;
        } catch (_) {
          // Best-effort ranking keeps the page responsive even if one score fails.
        }
      }
    }

    final workers = List<Future<void>>.generate(
      communities.length < maxConcurrency ? communities.length : maxConcurrency,
      (_) => worker(),
    );
    await Future.wait(workers);
    return result;
  }

  Future<Map<String, SignatureMatchResult>> _scoreCommunityMatchesBounded({
    required List<Community> communities,
    required String userId,
    required Map<String, CommunityTrueCompatibilityBreakdown>
        fallbackBreakdowns,
  }) async {
    const maxConcurrency = 6;
    if (communities.isEmpty) {
      return const {};
    }

    final result = <String, SignatureMatchResult>{};
    var nextIndex = 0;

    Future<void> worker() async {
      while (true) {
        final index = nextIndex++;
        if (index >= communities.length) {
          return;
        }

        final community = communities[index];
        final fallbackScore = fallbackBreakdowns[community.id]?.combined ?? 0.5;
        try {
          final match =
              await _communityService.calculateUserCommunitySignatureMatch(
            community: community,
            userId: userId,
            fallbackScore: fallbackScore,
          );
          if (match != null) {
            result[community.id] = match;
          } else {
            result[community.id] = SignatureMatchResult(
              entityId: community.id,
              entityKind: SignatureEntityKind.community,
              dnaScore: fallbackScore,
              pheromoneScore: fallbackScore,
              signatureScore: fallbackScore,
              finalScore: fallbackScore,
              fallbackScore: fallbackScore,
              confidence: 0.5,
              freshness: 0.5,
              mode: SignatureScoreMode.fallback,
              summary: 'Fallback community score only.',
            );
          }
        } catch (_) {
          // Best-effort page ranking.
        }
      }
    }

    final workers = List<Future<void>>.generate(
      communities.length < maxConcurrency ? communities.length : maxConcurrency,
      (_) => worker(),
    );
    await Future.wait(workers);
    return result;
  }

  Future<_CoordinatePair?> _resolveCommunityCoordinates(String eventId) async {
    try {
      final event = await _eventService.getEventById(eventId);
      if (event == null || event.latitude == null || event.longitude == null) {
        return null;
      }

      return _CoordinatePair(
        latitude: event.latitude!,
        longitude: event.longitude!,
      );
    } catch (_) {
      return null;
    }
  }

  UnifiedUser _toUnifiedUser(app_user.User user) {
    return UnifiedUser(
      id: user.id,
      email: user.email,
      displayName: user.displayName ?? user.name,
      photoUrl: null,
      location: null,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
      isOnline: user.isOnline ?? false,
      hasCompletedOnboarding: true,
      hasReceivedStarterLists: false,
      expertise: null,
      locations: null,
      hostedEventsCount: null,
      differentSpotsCount: null,
      tags: const [],
      expertiseMap: const {},
      friends: const [],
      curatedLists: user.curatedLists,
      collaboratedLists: user.collaboratedLists,
      followedLists: user.followedLists,
      primaryRole: UserRole.follower,
      isAgeVerified: false,
      ageVerificationDate: null,
    );
  }

  void _configureRealtimeRefresh() {
    _realtimeRefreshTimer?.cancel();
    if (!_showRealtime) {
      return;
    }

    _realtimeRefreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _loadData(showLoading: false),
    );
  }

  void _toggleRealtime(bool value) {
    setState(() {
      _showRealtime = value;
    });
    _configureRealtimeRefresh();
  }

  void _onMarkerTapped(ExploreItem item) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _TypeIcon(type: item.type),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    _ScoreChip(label: item.scoreLabel),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  item.subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                if (item.secondaryMeta != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    item.secondaryMeta!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  item.reason,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _dismissExploreItem(
                                  item,
                                  intent: NegativePreferenceIntent.softIgnore,
                                );
                              },
                              child: const Text('Ignore for now'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _dismissExploreItem(
                                  item,
                                  intent: NegativePreferenceIntent
                                      .hardNotInterested,
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.error,
                                side: const BorderSide(color: AppColors.error),
                              ),
                              child: const Text('Not interested'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _openItem(item);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: AppColors.white,
                          ),
                          child: const Text('View details'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openItem(ExploreItem item) {
    _recordExploreSelection(item);
    switch (item.type) {
      case ExploreItemType.spot:
        if (item.spot == null) {
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SpotDetailsPage(spot: item.spot!),
          ),
        );
        break;
      case ExploreItemType.event:
        if (item.event == null) {
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailsPage(event: item.event!),
          ),
        );
        break;
      case ExploreItemType.community:
        if (item.community == null) {
          return;
        }
        context.push('/community/${item.community!.id}');
        break;
    }
  }

  void _recordExploreSelection(ExploreItem item) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) {
      return;
    }
    switch (item.type) {
      case ExploreItemType.spot:
        if (item.spot != null) {
          unawaited(
            _entitySignatureService.recordSpotBrowseSelectionSignal(
              userId: authState.user.id,
              spot: item.spot!,
            ),
          );
        }
      case ExploreItemType.event:
        if (item.event != null) {
          unawaited(
            _entitySignatureService.recordEventBrowseSelectionSignal(
              userId: authState.user.id,
              event: item.event!,
            ),
          );
        }
      case ExploreItemType.community:
        if (item.community != null) {
          unawaited(
            _entitySignatureService.recordCommunityBrowseSelectionSignal(
              userId: authState.user.id,
              community: item.community!,
            ),
          );
        }
    }
  }

  void _dismissExploreItem(
    ExploreItem item, {
    required NegativePreferenceIntent intent,
  }) {
    final itemKey = _itemKey(item);
    unawaited(
      showUndoableNegativeFeedback(
        context: context,
        message: intent == NegativePreferenceIntent.softIgnore
            ? '${item.title} hidden for now.'
            : '${item.title} marked as not interested.',
        onOptimisticUpdate: () {
          if (!mounted) {
            return;
          }
          setState(() {
            _suppressedItemKeys.add(itemKey);
          });
        },
        onUndo: () {
          if (!mounted) {
            return;
          }
          setState(() {
            _suppressedItemKeys.remove(itemKey);
          });
        },
        onCommit: () async {
          if (!mounted) {
            return;
          }
          final authState = context.read<AuthBloc>().state;
          if (authState is! Authenticated) {
            return;
          }
          await _entitySignatureService.recordNegativePreferenceSignal(
            userId: authState.user.id,
            title: item.title,
            subtitle: item.subtitle,
            category: item.type.name,
            tags: <String>[
              item.type.name,
              if (item.secondaryMeta != null) item.secondaryMeta!,
            ],
            intent: intent,
            entityType: item.type.name,
            cityCode: _itemCityCode(item),
            localityCode: _itemLocalityCode(item),
          );
        },
      ),
    );
  }

  String _itemKey(ExploreItem item) => '${item.type.name}:${item.id}';

  String? _itemCityCode(ExploreItem item) {
    switch (item.type) {
      case ExploreItemType.spot:
        return item.spot?.cityCode;
      case ExploreItemType.event:
        return item.event?.cityCode;
      case ExploreItemType.community:
        return item.community?.cityCode;
    }
  }

  String? _itemLocalityCode(ExploreItem item) {
    switch (item.type) {
      case ExploreItemType.spot:
        return item.spot?.localityCode;
      case ExploreItemType.event:
        return item.event?.localityCode;
      case ExploreItemType.community:
        return item.community?.localityCode;
    }
  }

  String _buildSpotReason({
    required Spot spot,
    required double? distanceMeters,
    required bool communityFirst,
    required MetroExperienceContext metroContext,
  }) {
    final parts = <String>[];

    if (communityFirst) {
      parts.add('strong local signal');
    } else {
      parts.add('fits your pace');
    }

    if (distanceMeters != null) {
      parts.add('near ${_formatDistance(distanceMeters)}');
    }

    if (spot.rating > 0) {
      parts.add('${spot.rating.toStringAsFixed(1)} rating');
    }

    final metroAffinity = _metroExperienceService.scoreCategoryAffinity(
      context: metroContext,
      category: spot.category,
      title: spot.name,
      subtitle: spot.description,
    );
    if (metroAffinity > 0.0) {
      parts.add('aligned with your city pattern');
    }

    return parts.join(' • ');
  }

  String _buildEventReason({
    required ExpertiseEvent event,
    required bool isLiveNow,
    required double blendedScore,
    required MetroExperienceContext metroContext,
  }) {
    final parts = <String>[
      if (isLiveNow)
        'live now'
      else if (event.startTime.difference(DateTime.now()) <=
          const Duration(hours: 24))
        'happening soon'
      else
        'worth planning',
      blendedScore >= 0.78 ? 'strong fit' : 'fits your pace',
    ];

    if ((event.location ?? '').isNotEmpty) {
      parts.add(event.location!);
    }

    return _appendMetroReason(
      parts.join(' • '),
      metroContext,
      event.category,
      event.location,
    );
  }

  String _buildCommunityReason({
    required Community community,
    required CommunityTrueCompatibilityBreakdown? breakdown,
    required MetroExperienceContext metroContext,
  }) {
    final parts = <String>[
      if ((breakdown?.combined ?? 0.0) >= 0.78)
        'strong social fit'
      else
        'worth checking out',
    ];

    if (community.lastEventAt != null &&
        DateTime.now().difference(community.lastEventAt!) <=
            const Duration(days: 7)) {
      parts.add('active this week');
    }

    if (community.originalLocality.isNotEmpty) {
      parts.add(community.originalLocality);
    }

    return _appendMetroReason(
      parts.join(' • '),
      metroContext,
      community.category,
      community.originalLocality,
    );
  }

  String _appendMetroReason(
    String base,
    MetroExperienceContext metroContext,
    String category,
    String? label,
  ) {
    final categoryAffinity = _metroExperienceService.scoreCategoryAffinity(
      context: metroContext,
      category: category,
      title: label,
      subtitle: label,
    );
    if (categoryAffinity <= 0.0 || !metroContext.hasMetroProfile) {
      return base;
    }

    return '$base • aligned with your city pattern';
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()}m';
    }

    return '${(meters / 1000).toStringAsFixed(1)}km';
  }

  String _formatEventTime(ExpertiseEvent event) {
    final now = DateTime.now();
    if (event.status == EventStatus.ongoing) {
      return 'Happening now';
    }

    final difference = event.startTime.difference(now);
    if (difference.inHours >= 0 && difference.inHours < 24) {
      return 'Today • ${event.startTime.hour.toString().padLeft(2, '0')}:${event.startTime.minute.toString().padLeft(2, '0')}';
    }

    return '${event.startTime.month}/${event.startTime.day} • ${event.startTime.hour.toString().padLeft(2, '0')}:${event.startTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return AppFlowScaffold(
      title: 'Explore',
      constrainBody: false,
      actions: [
        IconButton(
          tooltip: 'Refresh',
          onPressed: () => _loadData(),
          icon: const Icon(Icons.refresh),
        ),
        const ChatButtonWithBadge(),
      ],
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: _buildBody(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.grey200),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Explore',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            _exploreSubtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeaderStatChip(
                icon: Icons.tune,
                label: '${_filteredItems.length} ranked now',
              ),
              _HeaderStatChip(
                icon: Icons.location_on_outlined,
                label: _locationContextLabel,
              ),
              _HeaderStatChip(
                icon: _showRealtime ? Icons.flash_on : Icons.schedule,
                label: _showRealtime ? 'Live now on' : 'All timing',
              ),
            ],
          ),
          if (_metroContext != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.location_city,
                        size: 16,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _metroContext!.displayName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _metroContext!.summary,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            'View',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _ModeChip(
                label: 'Map view',
                selected: _viewMode == _ExploreViewMode.map,
                onTap: () {
                  setState(() {
                    _viewMode = _ExploreViewMode.map;
                  });
                },
              ),
              const SizedBox(width: 8),
              _ModeChip(
                label: 'Curated list',
                selected: _viewMode == _ExploreViewMode.list,
                onTap: () {
                  setState(() {
                    _viewMode = _ExploreViewMode.list;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Show',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: const Text('Live now'),
                selected: _showRealtime,
                onSelected: _toggleRealtime,
                selectedColor: AppTheme.primaryColor.withValues(alpha: 0.18),
                labelStyle: TextStyle(
                  color: _showRealtime
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
              FilterChip(
                label: const Text('Live spots'),
                selected: _showSpots,
                onSelected: (value) =>
                    _setLayerEnabled(ExploreItemType.spot, value),
                selectedColor: AppTheme.primaryColor.withValues(alpha: 0.18),
              ),
              FilterChip(
                label: const Text('Events'),
                selected: _showEvents,
                onSelected: (value) =>
                    _setLayerEnabled(ExploreItemType.event, value),
                selectedColor: AppTheme.primaryColor.withValues(alpha: 0.18),
              ),
              FilterChip(
                label: const Text('Communities'),
                selected: _showCommunities,
                onSelected: (value) =>
                    _setLayerEnabled(ExploreItemType.community, value),
                selectedColor: AppTheme.primaryColor.withValues(alpha: 0.18),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 56,
                color: AppColors.error,
              ),
              const SizedBox(height: 12),
              Text(
                'Couldn\'t load Explore',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _loadData(),
                child: const Text('Retry'),
              ),
              if (_currentPosition == null) ...[
                const SizedBox(height: 10),
                Text(
                  'We can still rank by city context, but precise location helps the map feel better.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (_filteredItems.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.travel_explore,
                size: 64,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 12),
              Text(
                _showRealtime
                    ? 'Nothing live matches these filters right now.'
                    : 'Nothing matches these filters right now.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                _showRealtime
                    ? 'Try showing all timing or turning more discovery layers back on.'
                    : 'Try broadening the layers to see more ranked suggestions.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  if (_showRealtime)
                    OutlinedButton(
                      onPressed: () => _toggleRealtime(false),
                      child: const Text('Show all timing'),
                    ),
                  ElevatedButton(
                    onPressed: _resetFilters,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: AppColors.white,
                    ),
                    child: const Text('Reset filters'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return _viewMode == _ExploreViewMode.map
        ? _buildMapMode()
        : _buildListMode();
  }

  Widget _buildMapMode() {
    final mapItems =
        _filteredItems.where((item) => item.hasCoordinates).toList();
    if (mapItems.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.map_outlined,
                size: 56,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 12),
              Text(
                'Nothing in these filters is ready for the map yet.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Switch to curated list view to see the best ranked suggestions even when a map pin is missing.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _viewMode = _ExploreViewMode.list;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: AppColors.white,
                ),
                child: const Text('Open curated list'),
              ),
            ],
          ),
        ),
      );
    }

    final center = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : LatLng(mapItems.first.latitude!, mapItems.first.longitude!);

    return Stack(
      children: [
        Positioned.fill(
          child: _shouldUseGoogleMaps
              ? gmap.GoogleMap(
                  initialCameraPosition: gmap.CameraPosition(
                    target: gmap.LatLng(center.latitude, center.longitude),
                    zoom: 12.5,
                  ),
                  myLocationEnabled: _currentPosition != null,
                  myLocationButtonEnabled: true,
                  markers: mapItems.map(_buildGoogleMarker).toSet(),
                )
              : FlutterMap(
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: 12.5,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'app.avrai',
                    ),
                    MarkerLayer(
                      markers: [
                        if (_currentPosition != null)
                          Marker(
                            point: LatLng(
                              _currentPosition!.latitude,
                              _currentPosition!.longitude,
                            ),
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.my_location,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ...mapItems.map(_buildFlutterMarker),
                      ],
                    ),
                  ],
                ),
        ),
        Positioned(
          left: 12,
          right: 12,
          bottom: 12,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Text(
              _currentPosition != null
                  ? '${mapItems.length} picks on the map • Tap a marker to see why it fits you'
                  : '${mapItems.length} picks on the map • Using city context until location is available',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ),
      ],
    );
  }

  gmap.Marker _buildGoogleMarker(ExploreItem item) {
    return gmap.Marker(
      markerId: gmap.MarkerId('${item.type.name}-${item.id}'),
      position: gmap.LatLng(item.latitude!, item.longitude!),
      icon: gmap.BitmapDescriptor.defaultMarkerWithHue(
        switch (item.type) {
          ExploreItemType.spot => gmap.BitmapDescriptor.hueAzure,
          ExploreItemType.event => gmap.BitmapDescriptor.hueOrange,
          ExploreItemType.community => gmap.BitmapDescriptor.hueGreen,
        },
      ),
      infoWindow: gmap.InfoWindow(
        title: item.title,
        snippet: item.scoreLabel,
        onTap: () => _onMarkerTapped(item),
      ),
      onTap: () => _onMarkerTapped(item),
    );
  }

  Marker _buildFlutterMarker(ExploreItem item) {
    return Marker(
      point: LatLng(item.latitude!, item.longitude!),
      width: 54,
      height: 54,
      child: GestureDetector(
        onTap: () => _onMarkerTapped(item),
        child: Container(
          decoration: BoxDecoration(
            color: _markerColor(item.type),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.16),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            _markerIcon(item.type),
            color: AppColors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildListMode() {
    final spotItems = _itemsForType(ExploreItemType.spot);
    final eventItems = _itemsForType(ExploreItemType.event);
    final communityItems = _itemsForType(ExploreItemType.community);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _CuratedListIntroCard(
          metroContext: _metroContext,
          usingPreciseLocation: _currentPosition != null,
          spotCount: spotItems.length,
          eventCount: eventItems.length,
          communityCount: communityItems.length,
        ),
        const SizedBox(height: 20),
        if (_metroContext != null) ...[
          _MetroPriorsCard(context: _metroContext!),
          const SizedBox(height: 20),
        ],
        if (spotItems.isNotEmpty)
          _ExploreSection(
            title: 'Spots for you',
            subtitle: 'Places that look like the best fit right now.',
            items: spotItems,
            onTap: _openItem,
            onDismiss: (item, intent) =>
                _dismissExploreItem(item, intent: intent),
          ),
        if (eventItems.isNotEmpty) ...[
          const SizedBox(height: 20),
          _ExploreSection(
            title: 'Events worth checking',
            subtitle:
                'Live or upcoming plans ranked around what should feel most worth it.',
            items: eventItems,
            onTap: _openItem,
            onDismiss: (item, intent) =>
                _dismissExploreItem(item, intent: intent),
          ),
        ],
        if (communityItems.isNotEmpty) ...[
          const SizedBox(height: 20),
          _ExploreSection(
            title: 'Communities to join',
            subtitle:
                'Groups and organizations that look like a strong social match.',
            items: communityItems,
            onTap: _openItem,
            onDismiss: (item, intent) =>
                _dismissExploreItem(item, intent: intent),
          ),
        ],
      ],
    );
  }

  IconData _markerIcon(ExploreItemType type) {
    return switch (type) {
      ExploreItemType.spot => Icons.place,
      ExploreItemType.event => Icons.event,
      ExploreItemType.community => Icons.groups,
    };
  }

  Color _markerColor(ExploreItemType type) {
    return switch (type) {
      ExploreItemType.spot => AppColors.primary,
      ExploreItemType.event => AppTheme.warningColor,
      ExploreItemType.community => AppColors.grey600,
    };
  }
}

class _ExploreSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<ExploreItem> items;
  final ValueChanged<ExploreItem> onTap;
  final void Function(ExploreItem, NegativePreferenceIntent) onDismiss;

  const _ExploreSection({
    required this.title,
    required this.subtitle,
    required this.items,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 12),
        ...items.take(6).map((item) {
          return _ExploreCard(
            item: item,
            onTap: () => onTap(item),
            onIgnoreForNow: () =>
                onDismiss(item, NegativePreferenceIntent.softIgnore),
            onNotInterested: () =>
                onDismiss(item, NegativePreferenceIntent.hardNotInterested),
          );
        }),
      ],
    );
  }
}

class _HeaderStatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeaderStatChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _CuratedListIntroCard extends StatelessWidget {
  final MetroExperienceContext? metroContext;
  final bool usingPreciseLocation;
  final int spotCount;
  final int eventCount;
  final int communityCount;

  const _CuratedListIntroCard({
    required this.metroContext,
    required this.usingPreciseLocation,
    required this.spotCount,
    required this.eventCount,
    required this.communityCount,
  });

  @override
  Widget build(BuildContext context) {
    final locationLabel = usingPreciseLocation
        ? 'using your location and behavior'
        : metroContext?.hasMetroProfile == true
            ? 'using ${metroContext!.displayName} context and your behavior'
            : 'using your behavior and broad nearby context';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Curated for you',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'This list is ranked $locationLabel so you can scan the best options faster.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeaderStatChip(
                icon: Icons.place_outlined,
                label: '$spotCount spots',
              ),
              _HeaderStatChip(
                icon: Icons.event_outlined,
                label: '$eventCount events',
              ),
              _HeaderStatChip(
                icon: Icons.groups_2_outlined,
                label: '$communityCount communities',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExploreCard extends StatelessWidget {
  final ExploreItem item;
  final VoidCallback onTap;
  final VoidCallback onIgnoreForNow;
  final VoidCallback onNotInterested;

  const _ExploreCard({
    required this.item,
    required this.onTap,
    required this.onIgnoreForNow,
    required this.onNotInterested,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _TypeIcon(type: item.type),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.subtitle,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    _ScoreChip(label: item.scoreLabel),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  item.reason,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                ),
                if (item.secondaryMeta != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    item.secondaryMeta!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: onIgnoreForNow,
                        child: const Text('Ignore for now'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onNotInterested,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                        ),
                        child: const Text('Not interested'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TypeIcon extends StatelessWidget {
  final ExploreItemType type;

  const _TypeIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    final color = switch (type) {
      ExploreItemType.spot => AppColors.primary,
      ExploreItemType.event => AppTheme.warningColor,
      ExploreItemType.community => AppColors.grey600,
    };
    final icon = switch (type) {
      ExploreItemType.spot => Icons.place,
      ExploreItemType.event => Icons.event,
      ExploreItemType.community => Icons.groups,
    };

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        icon,
        size: 20,
        color: color,
      ),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  final String label;

  const _ScoreChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primaryColor.withValues(alpha: 0.16)
              : AppColors.grey100,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppTheme.primaryColor : AppColors.grey300,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color:
                    selected ? AppTheme.primaryColor : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }
}

class _CoordinatePair {
  final double latitude;
  final double longitude;

  const _CoordinatePair({
    required this.latitude,
    required this.longitude,
  });
}

class _MetroPriorsCard extends StatelessWidget {
  final MetroExperienceContext context;

  const _MetroPriorsCard({required this.context});

  @override
  Widget build(BuildContext buildContext) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${context.displayName} priors',
            style: Theme.of(buildContext).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'When live data is sparse, your agent should lean on these city-shaped doors instead of acting generic.',
            style: Theme.of(buildContext).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 12),
          _PriorGroup(label: 'Places', values: context.spotPriors),
          const SizedBox(height: 10),
          _PriorGroup(label: 'Events', values: context.eventPriors),
          const SizedBox(height: 10),
          _PriorGroup(label: 'Communities', values: context.communityPriors),
        ],
      ),
    );
  }
}

class _PriorGroup extends StatelessWidget {
  final String label;
  final List<String> values;

  const _PriorGroup({
    required this.label,
    required this.values,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: values.map((value) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                value,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textPrimary,
                    ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

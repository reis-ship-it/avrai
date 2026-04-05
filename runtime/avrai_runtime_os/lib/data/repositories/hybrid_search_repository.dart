import 'dart:math' as math;

import 'package:avrai_core/models/signatures/signature_match_result.dart';
import 'package:avrai_core/models/user/unified_user.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:avrai_core/models/spots/spot.dart';
import 'package:avrai_runtime_os/data/datasources/local/spots_local_datasource.dart';
import 'package:avrai_runtime_os/data/datasources/remote/spots_remote_datasource.dart';
import 'package:avrai_runtime_os/data/datasources/remote/google_places_datasource.dart';
import 'package:avrai_runtime_os/data/datasources/remote/openstreetmap_datasource.dart';
import 'package:avrai_runtime_os/services/places/google_places_cache_service.dart';
import 'package:avrai_runtime_os/services/intake/universal_intake_repository.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';

import 'package:avrai_runtime_os/services/signatures/entity_signature_service.dart';

/// Hybrid Search Repository
/// OUR_GUTS.md: "Authenticity Over Algorithms" - Community data prioritized over external sources
class HybridSearchRepository {
  static const String _logName = 'HybridSearchRepository';
  final AppLogger _logger =
      const AppLogger(defaultTag: 'SPOTS', minimumLevel: LogLevel.debug);

  final SpotsLocalDataSource? _localDataSource;
  final SpotsRemoteDataSource? _remoteDataSource;
  final GooglePlacesDataSource? _googlePlacesDataSource;
  final OpenStreetMapDataSource? _osmDataSource;
  final GooglePlacesCacheService? _googlePlacesCache;
  final Connectivity? _connectivity;
  final UniversalIntakeRepository? _intakeRepository;
  final EntitySignatureService? _entitySignatureService;

  // Search analytics tracking (privacy-preserving)
  final Map<String, int> _searchAnalytics = {};
  final Map<String, DateTime> _lastSearchTime = {};

  // Search result cache (privacy-preserving, short-lived)
  final Map<String, HybridSearchResult> _searchCache = {};
  // ignore: unused_field
  static const Duration _cacheExpiration = Duration(minutes: 5);

  EntitySignatureService? get _signatureService {
    if (_entitySignatureService != null) {
      return _entitySignatureService;
    }
    final locator = GetIt.instance;
    if (locator.isRegistered<EntitySignatureService>()) {
      return locator<EntitySignatureService>();
    }
    return null;
  }

  HybridSearchRepository({
    SpotsLocalDataSource? localDataSource,
    SpotsRemoteDataSource? remoteDataSource,
    GooglePlacesDataSource? googlePlacesDataSource,
    OpenStreetMapDataSource? osmDataSource,
    GooglePlacesCacheService? googlePlacesCache,
    Connectivity? connectivity,
    UniversalIntakeRepository? intakeRepository,
    EntitySignatureService? entitySignatureService,
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource,
        _googlePlacesDataSource = googlePlacesDataSource,
        _osmDataSource = osmDataSource,
        _googlePlacesCache = googlePlacesCache,
        _connectivity = connectivity,
        _intakeRepository = intakeRepository,
        _entitySignatureService = entitySignatureService;

  /// Hybrid search with community-first prioritization
  /// OUR_GUTS.md: "Community, Not Just Places" - Local community knowledge comes first
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
    try {
      _logger.info('Hybrid search: $query', tag: _logName);
      final startTime = DateTime.now();

      // Check cache first
      final cacheKey = _generateCacheKey(query, latitude, longitude, userId,
          maxResults, includeExternal, filters, sortOption);
      final cachedResult = _getCachedResult(cacheKey);
      if (cachedResult != null) {
        _logger.debug('Returning cached search result', tag: _logName);
        return cachedResult;
      }

      // Track search analytics (privacy-preserving)
      _trackSearch(query);

      // STEP 1: Search community data first (highest priority)
      final communitySpots = await _searchCommunityData(query);
      _logger.debug('Found ${communitySpots.length} community spots',
          tag: _logName);

      // STEP 2: Search external data if enabled and community results are limited
      List<Spot> externalSpots = [];
      if (includeExternal && communitySpots.length < maxResults) {
        // Check if offline - use cached data if available
        final isOffline = await _isOffline();
        if (isOffline && _googlePlacesCache != null) {
          _logger.debug('Device is offline, using cached Google Places data',
              tag: _logName);
          externalSpots = await _googlePlacesCache.searchCachedPlaces(query);
        } else {
          externalSpots = await _searchExternalData(
            query: query,
            latitude: latitude,
            longitude: longitude,
            maxResults: maxResults - communitySpots.length,
          );
          _logger.debug('Found ${externalSpots.length} external spots',
              tag: _logName);
        }
      }

      // STEP 3: Apply filters if provided
      var filteredCommunitySpots =
          _applyFilters(communitySpots, filters, latitude, longitude);
      var filteredExternalSpots =
          _applyFilters(externalSpots, filters, latitude, longitude);
      filteredCommunitySpots =
          await _decorateImportedSpots(filteredCommunitySpots);
      filteredExternalSpots =
          await _decorateImportedSpots(filteredExternalSpots);

      // STEP 4: Combine and rank results with community-first prioritization
      final rankedResults = await _rankAndDeduplicateResults(
        communitySpots: filteredCommunitySpots,
        externalSpots: filteredExternalSpots,
        query: query,
        userLatitude: latitude,
        userLongitude: longitude,
        userId: userId,
        sortOption: sortOption,
      );

      // STEP 5: Apply final result limit
      final finalResults = rankedResults.take(maxResults).toList();

      final searchDuration = DateTime.now().difference(startTime);
      _logger.info(
          'Hybrid search completed in ${searchDuration.inMilliseconds}ms',
          tag: _logName);

      // Calculate distances for result metadata
      final resultsWithMetadata = await _buildMetadataForResults(
        spots: finalResults,
        query: query,
        userLatitude: latitude,
        userLongitude: longitude,
        userId: userId,
      );

      final result = HybridSearchResult(
        spots: finalResults,
        communityCount: filteredCommunitySpots.length,
        externalCount: filteredExternalSpots.length,
        totalCount: finalResults.length,
        searchDuration: searchDuration,
        sources: _getSourceBreakdown(finalResults),
        metadata: resultsWithMetadata,
      );

      // Cache result
      _cacheResult(cacheKey, result);

      return result;
    } catch (e) {
      _logger.error('Error in hybrid search', error: e, tag: _logName);
      // OUR_GUTS.md: "Effortless, Seamless Discovery" - Graceful fallback
      return HybridSearchResult.empty();
    }
  }

  /// Search nearby spots with hybrid approach
  /// Community data gets priority even for location-based searches
  Future<HybridSearchResult> searchNearbySpots({
    required double latitude,
    required double longitude,
    String? userId,
    int radius = 5000,
    int maxResults = 50,
    bool includeExternal = true,
  }) async {
    try {
      _logger.info('Hybrid nearby search: $latitude,$longitude', tag: _logName);
      final startTime = DateTime.now();

      // STEP 1: Get community spots near location (highest priority)
      final communitySpots = await _searchCommunitySpotsNearby(
        latitude: latitude,
        longitude: longitude,
        radius: radius,
      );

      // STEP 2: Fill gaps with external data if needed
      List<Spot> externalSpots = [];
      if (includeExternal && communitySpots.length < maxResults) {
        // Check if offline - use cached data if available
        final isOffline = await _isOffline();
        if (isOffline && _googlePlacesCache != null) {
          _logger.debug(
              'Device is offline, using cached Google Places nearby data',
              tag: _logName);
          externalSpots = await _googlePlacesCache.getCachedPlacesNearby(
            latitude: latitude,
            longitude: longitude,
            radius: radius,
          );
        } else {
          externalSpots = await _searchExternalSpotsNearby(
            latitude: latitude,
            longitude: longitude,
            radius: radius,
            maxResults: maxResults - communitySpots.length,
          );
        }
      }

      // STEP 3: Combine and rank by distance and community priority
      final decoratedCommunitySpots =
          await _decorateImportedSpots(communitySpots);
      final decoratedExternalSpots =
          await _decorateImportedSpots(externalSpots);
      final rankedResults = await _rankByDistanceAndCommunityPriority(
        communitySpots: decoratedCommunitySpots,
        externalSpots: decoratedExternalSpots,
        userLatitude: latitude,
        userLongitude: longitude,
        userId: userId,
      );

      final finalResults = rankedResults.take(maxResults).toList();
      final searchDuration = DateTime.now().difference(startTime);
      final resultsWithMetadata = await _buildMetadataForResults(
        spots: finalResults,
        query: 'nearby',
        userLatitude: latitude,
        userLongitude: longitude,
        userId: userId,
      );

      return HybridSearchResult(
        spots: finalResults,
        communityCount: communitySpots.length,
        externalCount: externalSpots.length,
        totalCount: finalResults.length,
        searchDuration: searchDuration,
        sources: _getSourceBreakdown(finalResults),
        metadata: resultsWithMetadata,
      );
    } catch (e) {
      _logger.error('Error in hybrid nearby search', error: e, tag: _logName);
      return HybridSearchResult.empty();
    }
  }

  // Private helper methods

  Future<List<Spot>> _searchCommunityData(String query) async {
    final List<Spot> communitySpots = [];

    try {
      // Search local community data first
      if (_localDataSource != null) {
        final localSpots = await _localDataSource.searchSpots(query);
        communitySpots.addAll(localSpots);
      }

      // Search remote community data
      if (_remoteDataSource != null) {
        final remoteSpots = await _remoteDataSource.getSpots();
        final filteredRemoteSpots =
            remoteSpots.where((spot) => _matchesQuery(spot, query)).toList();
        communitySpots.addAll(filteredRemoteSpots);
      }
    } catch (e) {
      _logger.error('Error searching community data', error: e, tag: _logName);
    }

    return communitySpots;
  }

  Future<List<Spot>> _decorateImportedSpots(List<Spot> spots) async {
    if (_intakeRepository == null || spots.isEmpty) {
      return spots;
    }

    final metadataMap = await _intakeRepository.getSpotMetadataMap();
    return spots.map((spot) {
      final syncMetadata = metadataMap[spot.id];
      if (syncMetadata == null) {
        return spot;
      }
      return spot.copyWith(
        metadata: <String, dynamic>{
          ...spot.metadata,
          'is_external': true,
          'source_provider': syncMetadata.sourceProvider,
          'source_url': syncMetadata.sourceUrl,
        },
        cityCode: syncMetadata.cityCode ?? spot.cityCode,
        localityCode: syncMetadata.localityCode ?? spot.localityCode,
        externalSyncMetadata: syncMetadata,
      );
    }).toList();
  }

  Future<List<Spot>> _searchExternalData({
    required String query,
    double? latitude,
    double? longitude,
    int maxResults = 20,
  }) async {
    final List<Spot> externalSpots = [];

    try {
      // Search OpenStreetMap first (community-driven external data)
      if (_osmDataSource != null) {
        final osmSpots = await _osmDataSource.searchPlaces(
          query: query,
          latitude: latitude,
          longitude: longitude,
          limit: maxResults ~/ 2,
        );
        externalSpots.addAll(osmSpots);
      }

      // Search Google Places as fallback
      if (_googlePlacesDataSource != null &&
          externalSpots.length < maxResults) {
        final googleSpots = await _googlePlacesDataSource.searchPlaces(
          query: query,
          latitude: latitude,
          longitude: longitude,
          radius: 10000,
        );
        externalSpots.addAll(googleSpots);
      }
    } catch (e) {
      _logger.error('Error searching external data', error: e, tag: _logName);
    }

    return externalSpots;
  }

  Future<List<Spot>> _searchCommunitySpotsNearby({
    required double latitude,
    required double longitude,
    int radius = 5000,
  }) async {
    // For now, return filtered community spots
    // In a real implementation, this would use spatial queries
    final communitySpots = await _searchCommunityData('');
    return communitySpots
        .where((spot) => _isWithinRadius(spot, latitude, longitude, radius))
        .toList();
  }

  Future<List<Spot>> _searchExternalSpotsNearby({
    required double latitude,
    required double longitude,
    int radius = 5000,
    int maxResults = 20,
  }) async {
    final List<Spot> externalSpots = [];

    try {
      // OpenStreetMap nearby search (community-driven)
      if (_osmDataSource != null) {
        final osmSpots = await _osmDataSource.searchNearbyPlaces(
          latitude: latitude,
          longitude: longitude,
          radius: radius,
        );
        externalSpots.addAll(osmSpots);
      }

      // Google Places nearby search
      if (_googlePlacesDataSource != null &&
          externalSpots.length < maxResults) {
        final googleSpots = await _googlePlacesDataSource.searchNearbyPlaces(
          latitude: latitude,
          longitude: longitude,
          radius: radius,
        );
        externalSpots.addAll(googleSpots);
      }
    } catch (e) {
      _logger.error('Error searching external nearby spots',
          error: e, tag: _logName);
    }

    return externalSpots;
  }

  Future<List<Spot>> _rankAndDeduplicateResults({
    required List<Spot> communitySpots,
    required List<Spot> externalSpots,
    required String query,
    double? userLatitude,
    double? userLongitude,
    String? userId,
    SearchSortOption sortOption = SearchSortOption.relevance,
  }) async {
    // OUR_GUTS.md: "Authenticity Over Algorithms" - Community data always ranks higher
    final Map<String, Spot> deduplicatedSpots = {};

    // PRIORITY 1: Add community spots first (highest ranking)
    for (final spot in communitySpots) {
      final key = _generateDeduplicationKey(spot);
      if (!deduplicatedSpots.containsKey(key)) {
        deduplicatedSpots[key] = spot;
      }
    }

    // PRIORITY 2: Add external spots only if not duplicated
    for (final spot in externalSpots) {
      final key = _generateDeduplicationKey(spot);
      if (!deduplicatedSpots.containsKey(key)) {
        deduplicatedSpots[key] = spot;
      }
    }

    final results = deduplicatedSpots.values.toList();
    final rankings = await _buildRankingDetailsMap(
      spots: results,
      query: query,
      userLatitude: userLatitude,
      userLongitude: userLongitude,
      userId: userId,
    );

    // Sort based on sort option while maintaining community priority
    results.sort((a, b) {
      // Community spots always rank higher (unless sorting by distance)
      if (sortOption != SearchSortOption.distance) {
        final aIsCommunity = _isCommunitySpot(a);
        final bIsCommunity = _isCommunitySpot(b);

        if (aIsCommunity && !bIsCommunity) return -1;
        if (!aIsCommunity && bIsCommunity) return 1;
      }

      // Apply sorting based on option
      switch (sortOption) {
        case SearchSortOption.relevance:
          final aRelevance = rankings[a.id]?.score ??
              _calculateFallbackRelevanceScore(
                a,
                query,
                userLatitude,
                userLongitude,
              );
          final bRelevance = rankings[b.id]?.score ??
              _calculateFallbackRelevanceScore(
                b,
                query,
                userLatitude,
                userLongitude,
              );
          return bRelevance.compareTo(aRelevance);

        case SearchSortOption.distance:
          if (userLatitude == null || userLongitude == null) {
            // Fallback to relevance if no location
            final aRelevance = rankings[a.id]?.score ??
                _calculateFallbackRelevanceScore(
                  a,
                  query,
                  userLatitude,
                  userLongitude,
                );
            final bRelevance = rankings[b.id]?.score ??
                _calculateFallbackRelevanceScore(
                  b,
                  query,
                  userLatitude,
                  userLongitude,
                );
            return bRelevance.compareTo(aRelevance);
          }
          final aDistance = _calculateDistance(
              a.latitude, a.longitude, userLatitude, userLongitude);
          final bDistance = _calculateDistance(
              b.latitude, b.longitude, userLatitude, userLongitude);
          return aDistance.compareTo(bDistance);

        case SearchSortOption.rating:
          final ratingCompare = b.rating.compareTo(a.rating);
          if (ratingCompare != 0) return ratingCompare;
          // Tie-breaker: community first
          final aIsCommunity = _isCommunitySpot(a);
          final bIsCommunity = _isCommunitySpot(b);
          if (aIsCommunity && !bIsCommunity) return -1;
          if (!aIsCommunity && bIsCommunity) return 1;
          return 0;

        case SearchSortOption.alphabetical:
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());

        case SearchSortOption.recentlyAdded:
          return b.createdAt.compareTo(a.createdAt);
      }
    });

    return results;
  }

  Future<List<Spot>> _rankByDistanceAndCommunityPriority({
    required List<Spot> communitySpots,
    required List<Spot> externalSpots,
    required double userLatitude,
    required double userLongitude,
    String? userId,
  }) async {
    final allSpots = [...communitySpots, ...externalSpots];

    // Remove duplicates while preserving community priority
    final Map<String, Spot> deduplicatedSpots = {};
    for (final spot in allSpots) {
      final key = _generateDeduplicationKey(spot);
      if (!deduplicatedSpots.containsKey(key)) {
        deduplicatedSpots[key] = spot;
      } else {
        // If duplicate exists, prefer community data
        final existing = deduplicatedSpots[key]!;
        if (_isCommunitySpot(spot) && !_isCommunitySpot(existing)) {
          deduplicatedSpots[key] = spot;
        }
      }
    }

    final results = deduplicatedSpots.values.toList();
    final rankings = await _buildRankingDetailsMap(
      spots: results,
      query: 'nearby',
      userLatitude: userLatitude,
      userLongitude: userLongitude,
      userId: userId,
    );

    // Sort by community priority first, then distance
    results.sort((a, b) {
      final aIsCommunity = _isCommunitySpot(a);
      final bIsCommunity = _isCommunitySpot(b);

      if (aIsCommunity && !bIsCommunity) return -1;
      if (!aIsCommunity && bIsCommunity) return 1;

      // Within same source type, sort by distance
      final aDistance = _calculateDistance(
          a.latitude, a.longitude, userLatitude, userLongitude);
      final bDistance = _calculateDistance(
          b.latitude, b.longitude, userLatitude, userLongitude);

      final distanceCompare = aDistance.compareTo(bDistance);
      if (distanceCompare != 0) {
        return distanceCompare;
      }

      final aScore = rankings[a.id]?.score ?? 0.0;
      final bScore = rankings[b.id]?.score ?? 0.0;
      return bScore.compareTo(aScore);
    });

    return results;
  }

  // Utility methods

  bool _matchesQuery(Spot spot, String query) {
    final queryLower = query.toLowerCase();
    return spot.name.toLowerCase().contains(queryLower) ||
        spot.description.toLowerCase().contains(queryLower) ||
        spot.category.toLowerCase().contains(queryLower) ||
        spot.tags.any((tag) => tag.toLowerCase().contains(queryLower));
  }

  bool _isWithinRadius(
      Spot spot, double latitude, double longitude, int radius) {
    final distance =
        _calculateDistance(spot.latitude, spot.longitude, latitude, longitude);
    return distance <= radius;
  }

  /// Calculate distance using Haversine formula (accurate for Earth's surface)
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadiusKm = 6371.0;

    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadiusKm * c * 1000; // Convert to meters
  }

  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180.0);
  }

  String _generateDeduplicationKey(Spot spot) {
    // Generate key for deduplication based on location and name similarity
    final latKey = (spot.latitude * 1000).round();
    final lonKey = (spot.longitude * 1000).round();
    final nameKey =
        spot.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    return '${latKey}_${lonKey}_$nameKey';
  }

  bool _isCommunitySpot(Spot spot) {
    return !spot.metadata.containsKey('is_external') ||
        spot.metadata['is_external'] != true;
  }

  double _calculateFallbackRelevanceScore(
      Spot spot, String query, double? userLat, double? userLon) {
    double score = 0.0;
    final queryLower = query.toLowerCase();

    // Name match score
    if (queryLower.isNotEmpty && spot.name.toLowerCase().contains(queryLower)) {
      score += 0.34;
    }

    // Category match score
    if (queryLower.isNotEmpty &&
        spot.category.toLowerCase().contains(queryLower)) {
      score += 0.16;
    }

    // Tag match score
    for (final tag in spot.tags) {
      if (queryLower.isNotEmpty && tag.toLowerCase().contains(queryLower)) {
        score += 0.06;
      }
    }
    score = score.clamp(0.0, 0.2);

    // Community bonus remains only a fallback nudge, not the primary ranker.
    if (_isCommunitySpot(spot)) {
      score += 0.12;
    }

    // Distance matters as a bounded closeness bonus.
    if (userLat != null && userLon != null) {
      final distance =
          _calculateDistance(spot.latitude, spot.longitude, userLat, userLon);
      final closeness = (1.0 - (distance / 20000.0)).clamp(0.0, 1.0);
      score += closeness * 0.18;
    }

    score += (spot.rating / 5.0).clamp(0.0, 1.0) * 0.18;

    return score.clamp(0.0, 1.0);
  }

  Future<List<SpotWithMetadata>> _buildMetadataForResults({
    required List<Spot> spots,
    required String query,
    double? userLatitude,
    double? userLongitude,
    String? userId,
  }) async {
    final rankings = await _buildRankingDetailsMap(
      spots: spots,
      query: query,
      userLatitude: userLatitude,
      userLongitude: userLongitude,
      userId: userId,
    );

    return spots.map((spot) {
      final ranking = rankings[spot.id];
      final distance = (userLatitude != null && userLongitude != null)
          ? _calculateDistance(
              spot.latitude,
              spot.longitude,
              userLatitude,
              userLongitude,
            )
          : null;
      return SpotWithMetadata(
        spot: spot,
        distance: distance,
        relevanceScore: ranking?.score ??
            _calculateFallbackRelevanceScore(
              spot,
              query,
              userLatitude,
              userLongitude,
            ),
        matchReason: ranking?.reason ?? _getMatchReason(spot, query),
        usedSignaturePrimary: ranking?.usedSignaturePrimary ?? false,
      );
    }).toList();
  }

  Future<Map<String, _SpotRankingDetails>> _buildRankingDetailsMap({
    required List<Spot> spots,
    required String query,
    double? userLatitude,
    double? userLongitude,
    String? userId,
  }) async {
    if (spots.isEmpty) {
      return const <String, _SpotRankingDetails>{};
    }

    final entries = await Future.wait(
      spots.map((spot) async {
        final details = await _resolveRankingDetails(
          spot: spot,
          query: query,
          userLatitude: userLatitude,
          userLongitude: userLongitude,
          userId: userId,
        );
        return MapEntry(spot.id, details);
      }),
    );
    return Map<String, _SpotRankingDetails>.fromEntries(entries);
  }

  Future<_SpotRankingDetails> _resolveRankingDetails({
    required Spot spot,
    required String query,
    double? userLatitude,
    double? userLongitude,
    String? userId,
  }) async {
    final fallbackScore = _calculateFallbackRelevanceScore(
      spot,
      query,
      userLatitude,
      userLongitude,
    );
    final signatureService = _signatureService;
    if (userId == null || signatureService == null) {
      return _SpotRankingDetails(
        score: fallbackScore,
        reason: _getMatchReason(spot, query),
        usedSignaturePrimary: false,
      );
    }

    try {
      final match = await signatureService.matchUserToSpot(
        user: _buildSignatureSearchUser(userId),
        spot: spot,
        fallbackScore: fallbackScore,
      );
      return _spotRankingDetailsFromMatch(
        match: match,
        fallbackReason: _getMatchReason(spot, query),
      );
    } catch (e) {
      _logger.debug(
        'Signature rerank fell back for spot ${spot.id}: $e',
        tag: _logName,
      );
      return _SpotRankingDetails(
        score: fallbackScore,
        reason: _getMatchReason(spot, query),
        usedSignaturePrimary: false,
      );
    }
  }

  _SpotRankingDetails _spotRankingDetailsFromMatch({
    required SignatureMatchResult match,
    required String fallbackReason,
  }) {
    final summary = match.summary.trim();
    final combinedReason = summary.isEmpty
        ? fallbackReason
        : '$summary ${fallbackReason.trim()}'.trim();
    return _SpotRankingDetails(
      score: match.finalScore,
      reason: combinedReason,
      usedSignaturePrimary: match.usedSignaturePrimary,
    );
  }

  UnifiedUser _buildSignatureSearchUser(String userId) {
    return UnifiedUser(
      id: userId,
      email: '$userId@avrai.local',
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.now(),
      isOnline: false,
      hasCompletedOnboarding: true,
      hasReceivedStarterLists: true,
      tags: const <String>[],
      expertiseMap: const <String, String>{},
      friends: const <String>[],
      curatedLists: const <String>[],
      collaboratedLists: const <String>[],
      followedLists: const <String>[],
      primaryRole: UserRole.follower,
      isAgeVerified: false,
    );
  }

  Map<String, int> _getSourceBreakdown(List<Spot> spots) {
    final sources = <String, int>{};

    for (final spot in spots) {
      final source = spot.metadata['source']?.toString() ?? 'community';
      sources[source] = (sources[source] ?? 0) + 1;
    }

    return sources;
  }

  void _trackSearch(String query) {
    // Privacy-preserving analytics
    final normalizedQuery = query.toLowerCase().trim();
    if (normalizedQuery.isNotEmpty) {
      _searchAnalytics[normalizedQuery] =
          (_searchAnalytics[normalizedQuery] ?? 0) + 1;
      _lastSearchTime[normalizedQuery] = DateTime.now();

      // Keep only recent search data for privacy
      _cleanupOldAnalytics();
    }
  }

  void _cleanupOldAnalytics() {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    _lastSearchTime.removeWhere((query, time) => time.isBefore(cutoff));
    _searchAnalytics
        .removeWhere((query, count) => !_lastSearchTime.containsKey(query));
  }

  /// Check if device is offline
  Future<bool> _isOffline() async {
    if (_connectivity == null) return false;
    try {
      final result = await _connectivity.checkConnectivity();
      return result.contains(ConnectivityResult.none);
    } catch (e) {
      _logger.error('Error checking connectivity', error: e, tag: _logName);
      return false; // Assume online on error
    }
  }

  /// Get search analytics (privacy-preserving)
  Map<String, int> getSearchAnalytics() {
    return Map.from(_searchAnalytics);
  }

  /// Get search suggestions based on recent searches and popular queries
  /// Privacy-preserving: only uses anonymized, aggregated data
  List<String> getSearchSuggestions(
      {String? queryPrefix, int maxSuggestions = 5}) {
    if (queryPrefix == null || queryPrefix.isEmpty) {
      // Return popular searches
      final sortedAnalytics = _searchAnalytics.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      return sortedAnalytics.take(maxSuggestions).map((e) => e.key).toList();
    }

    final prefix = queryPrefix.toLowerCase();
    final matchingSearches = _searchAnalytics.keys
        .where((search) => search.toLowerCase().startsWith(prefix))
        .toList()
      ..sort((a, b) =>
          (_searchAnalytics[b] ?? 0).compareTo(_searchAnalytics[a] ?? 0));

    return matchingSearches.take(maxSuggestions).toList();
  }

  /// Clear search cache
  void clearSearchCache() {
    _searchCache.clear();
  }

  // Private helper methods for new features

  List<Spot> _applyFilters(
    List<Spot> spots,
    SearchFilters? filters,
    double? userLat,
    double? userLon,
  ) {
    if (filters == null) return spots;

    var filtered = spots;

    // Category filter
    if (filters.categories != null && filters.categories!.isNotEmpty) {
      filtered = filtered
          .where((spot) => filters.categories!.contains(spot.category))
          .toList();
    }

    // Minimum rating filter
    if (filters.minRating != null) {
      filtered =
          filtered.where((spot) => spot.rating >= filters.minRating!).toList();
    }

    // Maximum distance filter
    if (filters.maxDistance != null && userLat != null && userLon != null) {
      filtered = filtered.where((spot) {
        final distance =
            _calculateDistance(spot.latitude, spot.longitude, userLat, userLon);
        return distance <= filters.maxDistance!;
      }).toList();
    }

    // Community-only filter
    if (filters.communityOnly == true) {
      filtered = filtered.where((spot) => _isCommunitySpot(spot)).toList();
    }

    // Reservation available filter
    // Note: Only community spots can have reservations (external spots from Google Places can't)
    if (filters.reservationAvailable == true) {
      filtered = filtered.where((spot) => _isCommunitySpot(spot)).toList();
    }

    return filtered;
  }

  String _generateCacheKey(
    String query,
    double? lat,
    double? lon,
    String? userId,
    int maxResults,
    bool includeExternal,
    SearchFilters? filters,
    SearchSortOption sortOption,
  ) {
    final filterKey = filters != null
        ? '${filters.categories?.join(',')}_${filters.minRating}_${filters.maxDistance}_${filters.communityOnly}_${filters.reservationAvailable}'
        : 'none';
    final personalizationKey = userId == null ? 'anon' : 'user_$userId';
    return '${query}_${lat}_${lon}_${maxResults}_$includeExternal'
        '_${filterKey}_${sortOption.name}_$personalizationKey';
  }

  HybridSearchResult? _getCachedResult(String key) {
    final cached = _searchCache[key];
    if (cached == null) return null;

    // Check if cache is expired (simplified - in production, store timestamp)
    return cached;
  }

  void _cacheResult(String key, HybridSearchResult result) {
    // Limit cache size
    if (_searchCache.length > 50) {
      final oldestKey = _searchCache.keys.first;
      _searchCache.remove(oldestKey);
    }
    _searchCache[key] = result;
  }

  String _getMatchReason(Spot spot, String query) {
    final queryLower = query.toLowerCase();
    final reasons = <String>[];

    if (queryLower.isEmpty || queryLower == 'nearby') {
      if (_isCommunitySpot(spot)) {
        reasons.add('community source');
      }
      if (spot.rating > 0) {
        reasons.add('strong local rating');
      }
      return reasons.isEmpty ? 'local candidate' : reasons.join(', ');
    }

    if (spot.name.toLowerCase().contains(queryLower)) {
      reasons.add('name match');
    }
    if (spot.category.toLowerCase().contains(queryLower)) {
      reasons.add('category match');
    }
    if (spot.tags.any((tag) => tag.toLowerCase().contains(queryLower))) {
      reasons.add('tag match');
    }
    if (_isCommunitySpot(spot)) {
      reasons.add('community spot');
    }

    return reasons.isEmpty ? 'general match' : reasons.join(', ');
  }
}

class _SpotRankingDetails {
  final double score;
  final String reason;
  final bool usedSignaturePrimary;

  const _SpotRankingDetails({
    required this.score,
    required this.reason,
    required this.usedSignaturePrimary,
  });
}

/// Search filters for advanced filtering
class SearchFilters {
  final List<String>? categories;
  final double? minRating;
  final int? maxDistance; // in meters
  final bool? communityOnly;
  final bool? reservationAvailable; // Filter spots that accept reservations

  const SearchFilters({
    this.categories,
    this.minRating,
    this.maxDistance,
    this.communityOnly,
    this.reservationAvailable,
  });
}

/// Search sort options
enum SearchSortOption {
  relevance, // Default: community-first relevance
  distance, // Nearest first
  rating, // Highest rated
  alphabetical, // A-Z
  recentlyAdded, // Newest spots
}

/// Spot with enhanced metadata for UI display
class SpotWithMetadata {
  final Spot spot;
  final double? distance; // in meters
  final double relevanceScore;
  final String matchReason;
  final bool usedSignaturePrimary;

  const SpotWithMetadata({
    required this.spot,
    this.distance,
    required this.relevanceScore,
    required this.matchReason,
    this.usedSignaturePrimary = false,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'spot': spot.toJson(),
      'distance': distance,
      'relevance_score': relevanceScore,
      'match_reason': matchReason,
      'used_signature_primary': usedSignaturePrimary,
    };
  }

  factory SpotWithMetadata.fromJson(Map<String, dynamic> json) {
    return SpotWithMetadata(
      spot: Spot.fromJson(json['spot'] as Map<String, dynamic>),
      distance: (json['distance'] as num?)?.toDouble(),
      relevanceScore: (json['relevance_score'] as num?)?.toDouble() ?? 0.0,
      matchReason: json['match_reason'] as String? ?? '',
      usedSignaturePrimary: json['used_signature_primary'] as bool? ?? false,
    );
  }
}

/// Hybrid search result with source breakdown
class HybridSearchResult {
  final List<Spot> spots;
  final int communityCount;
  final int externalCount;
  final int totalCount;
  final Duration searchDuration;
  final Map<String, int> sources;
  final List<SpotWithMetadata>? metadata; // Enhanced metadata for UI

  HybridSearchResult({
    required this.spots,
    required this.communityCount,
    required this.externalCount,
    required this.totalCount,
    required this.searchDuration,
    required this.sources,
    this.metadata,
  });

  factory HybridSearchResult.empty() {
    return HybridSearchResult(
      spots: [],
      communityCount: 0,
      externalCount: 0,
      totalCount: 0,
      searchDuration: Duration.zero,
      sources: {},
      metadata: [],
    );
  }

  /// Get community-to-external ratio for quality metrics
  double get communityRatio {
    if (totalCount == 0) return 0.0;
    return communityCount / totalCount;
  }

  /// Check if search is primarily community-driven (OUR_GUTS.md compliance)
  bool get isPrimarilyCommunityDriven {
    return communityRatio >= 0.5;
  }

  /// Get formatted distance string for a spot (if metadata available)
  String? getDistanceString(int index) {
    if (metadata == null || index >= metadata!.length) return null;
    final distance = metadata![index].distance;
    if (distance == null) return null;

    if (distance < 1000) {
      return '${distance.round()}m';
    } else {
      return '${(distance / 1000).toStringAsFixed(1)}km';
    }
  }

  /// Get match reason for a spot (if metadata available)
  String? getMatchReason(int index) {
    if (metadata == null || index >= metadata!.length) return null;
    return metadata![index].matchReason;
  }
}

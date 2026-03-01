import 'dart:developer' as developer;
import 'package:avrai_core/models/spots/spot.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:avrai_runtime_os/services/places/google_place_id_finder_service_new.dart';
import 'package:avrai_runtime_os/services/places/google_places_cache_service.dart';
import 'package:avrai_runtime_os/data/datasources/remote/google_places_datasource.dart';
import 'package:avrai_runtime_os/data/datasources/local/spots_local_datasource.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Google Places Sync Service
/// Syncs community spots with Google Maps and caches data locally
/// OUR_GUTS.md: "Community, Not Just Places" - Enhance community spots with Google Maps data
class GooglePlacesSyncService {
  static const String _logName = 'GooglePlacesSyncService';
  final AppLogger _logger =
      const AppLogger(defaultTag: 'SPOTS', minimumLevel: LogLevel.debug);

  final GooglePlaceIdFinderServiceNew _placeIdFinderNew;
  final GooglePlacesCacheService _cacheService;
  final GooglePlacesDataSource _googlePlacesDataSource;
  final SpotsLocalDataSource _spotsLocalDataSource;
  final Connectivity _connectivity;

  GooglePlacesSyncService({
    required GooglePlaceIdFinderServiceNew placeIdFinderNew,
    required GooglePlacesCacheService cacheService,
    required GooglePlacesDataSource googlePlacesDataSource,
    required SpotsLocalDataSource spotsLocalDataSource,
    required Connectivity connectivity,
  })  : _placeIdFinderNew = placeIdFinderNew,
        _cacheService = cacheService,
        _googlePlacesDataSource = googlePlacesDataSource,
        _spotsLocalDataSource = spotsLocalDataSource,
        _connectivity = connectivity;

  /// Sync a single community spot with Google Maps
  /// Finds Google Place ID and updates spot with Google Maps data
  Future<Spot?> syncSpot(Spot spot) async {
    try {
      // Skip if already synced and not stale
      if (spot.hasGooglePlaceId && !spot.isGooglePlaceIdStale) {
        developer.log('Spot already synced: ${spot.name}', name: _logName);
        return spot;
      }

      // Check connectivity
      final connectivityResult = await _connectivity.checkConnectivity();
      final isOnline =
          connectivityResult.contains(ConnectivityResult.none) == false;

      if (!isOnline) {
        developer.log('Device is offline, cannot sync spot', name: _logName);
        return spot;
      }

      developer.log('Syncing spot: ${spot.name}', name: _logName);

      // Find Google Place ID using new Places API (New)
      final placeId = await _placeIdFinderNew.findPlaceId(spot);

      if (placeId == null) {
        developer.log('No Google Place ID found for: ${spot.name}',
            name: _logName);
        return spot; // Return original spot if no match found
      }

      // Get place details from Google Places
      // Note: New API expects "places/ChIJ..." format, but we store clean ID
      // The data source will handle format conversion
      final googlePlace =
          await _googlePlacesDataSource.getPlaceDetails(placeId);
      if (googlePlace == null) {
        developer.log('Could not get Google Place details for: $placeId',
            name: _logName);
        // Still update with Place ID even if details unavailable
        return spot.copyWith(
          googlePlaceId: placeId,
          googlePlaceIdSyncedAt: DateTime.now(),
        );
      }

      // Cache the Google Place data
      await _cacheService.cachePlace(googlePlace);

      // Merge community spot with Google Maps data
      final syncedSpot = _mergeSpotData(spot, googlePlace, placeId);

      // Update local database
      await _spotsLocalDataSource.updateSpot(syncedSpot);

      developer.log(
          'Successfully synced spot: ${spot.name} with Place ID: $placeId',
          name: _logName);
      return syncedSpot;
    } catch (e) {
      _logger.error('Error syncing spot', error: e, tag: _logName);
      return spot; // Return original spot on error
    }
  }

  /// Sync multiple community spots with Google Maps
  /// Processes spots in batches to avoid rate limiting
  Future<SyncResult> syncSpots(List<Spot> spots, {int batchSize = 10}) async {
    try {
      developer.log('Syncing ${spots.length} spots', name: _logName);

      final results = SyncResult();

      // Process in batches
      for (int i = 0; i < spots.length; i += batchSize) {
        final batch = spots.skip(i).take(batchSize).toList();

        for (final spot in batch) {
          final syncedSpot = await syncSpot(spot);
          if (syncedSpot != null && syncedSpot.hasGooglePlaceId) {
            results.synced++;
          } else {
            results.failed++;
          }

          // Small delay between spots to avoid rate limiting
          await Future.delayed(const Duration(milliseconds: 200));
        }

        // Delay between batches
        if (i + batchSize < spots.length) {
          await Future.delayed(const Duration(seconds: 1));
        }
      }

      developer.log(
          'Sync complete: ${results.synced} synced, ${results.failed} failed',
          name: _logName);
      return results;
    } catch (e) {
      _logger.error('Error syncing spots', error: e, tag: _logName);
      return SyncResult();
    }
  }

  /// Sync spots that need syncing (no Place ID or stale)
  Future<SyncResult> syncSpotsNeedingSync({int limit = 50}) async {
    try {
      developer.log('Finding spots that need syncing', name: _logName);

      // Get all spots
      final allSpots = await _spotsLocalDataSource.getAllSpots();

      // Filter spots that need syncing
      final spotsToSync = allSpots
          .where((spot) => !spot.hasGooglePlaceId || spot.isGooglePlaceIdStale)
          .take(limit)
          .toList();

      developer.log('Found ${spotsToSync.length} spots that need syncing',
          name: _logName);

      return await syncSpots(spotsToSync);
    } catch (e) {
      _logger.error('Error finding spots to sync', error: e, tag: _logName);
      return SyncResult();
    }
  }

  /// Merge community spot data with Google Maps data
  /// Preserves community data (respects, views, etc.) while enhancing with Google Maps data
  Spot _mergeSpotData(Spot communitySpot, Spot googlePlace, String placeId) {
    // Preserve community data
    return communitySpot.copyWith(
      // Google Place ID mapping
      googlePlaceId: placeId,
      googlePlaceIdSyncedAt: DateTime.now(),

      // Enhance with Google Maps data (only if community spot lacks it)
      address: communitySpot.address ?? googlePlace.address,
      phoneNumber: communitySpot.phoneNumber ?? googlePlace.phoneNumber,
      website: communitySpot.website ?? googlePlace.website,
      imageUrl: communitySpot.imageUrl ?? googlePlace.imageUrl,

      // Update rating if Google has better data (higher rating)
      rating: googlePlace.rating > communitySpot.rating
          ? googlePlace.rating
          : communitySpot.rating,

      // Merge tags (avoid duplicates)
      tags: [
        ...communitySpot.tags,
        ...googlePlace.tags.where((tag) => !communitySpot.tags.contains(tag)),
      ],

      // Merge metadata
      metadata: {
        ...communitySpot.metadata,
        ...googlePlace.metadata,
        'google_place_id': placeId,
        'synced_at': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Get cached Google Places data for offline use
  Future<List<Spot>> getCachedPlaces({String? query}) async {
    try {
      if (query != null && query.isNotEmpty) {
        return await _cacheService.searchCachedPlaces(query);
      }
      return [];
    } catch (e) {
      _logger.error('Error getting cached places', error: e, tag: _logName);
      return [];
    }
  }

  /// Get cached places nearby (for offline nearby search)
  Future<List<Spot>> getCachedPlacesNearby({
    required double latitude,
    required double longitude,
    int radius = 5000,
  }) async {
    try {
      return await _cacheService.getCachedPlacesNearby(
        latitude: latitude,
        longitude: longitude,
        radius: radius,
      );
    } catch (e) {
      _logger.error('Error getting cached places nearby',
          error: e, tag: _logName);
      return [];
    }
  }
}

/// Result of sync operation
class SyncResult {
  int synced = 0;
  int failed = 0;

  int get total => synced + failed;
  double get successRate => total > 0 ? synced / total : 0.0;
}

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:avrai_core/models/spots/spot.dart';
import 'package:avrai_runtime_os/data/datasources/local/spots_local_datasource.dart';
import 'package:avrai_runtime_os/data/datasources/remote/spots_remote_datasource.dart';
import 'package:avrai_runtime_os/domain/repositories/spots_repository.dart';
import 'package:avrai_runtime_os/data/repositories/repository_patterns.dart';

/// Spots Repository Implementation
///
/// Uses offline-first pattern: returns local data immediately, syncs with remote if online.
class SpotsRepositoryImpl extends SimplifiedRepositoryBase
    implements SpotsRepository {
  final SpotsRemoteDataSource remoteDataSource;
  final SpotsLocalDataSource localDataSource;

  SpotsRepositoryImpl({
    required Connectivity connectivity,
    required this.remoteDataSource,
    required this.localDataSource,
  }) : super(connectivity: connectivity);

  @override
  Future<List<Spot>> getSpots() async {
    // Offline-first contract:
    // - Always return local data immediately when available.
    // - When online, fetch remote and merge it into local without dropping
    //   offline-created records that haven't been uploaded yet.
    final localSpots = await localDataSource.getAllSpots();

    if (!await isOnline) {
      return localSpots;
    }

    try {
      final remoteSpots = await remoteDataSource.getSpots();

      // Best-effort cache remote into local (upsert).
      for (final spot in remoteSpots) {
        await localDataSource.updateSpot(spot);
      }

      // Merge local + remote by id, preferring remote on conflicts.
      final merged = <String, Spot>{};
      for (final spot in localSpots) {
        merged[spot.id] = spot;
      }
      for (final spot in remoteSpots) {
        merged[spot.id] = spot;
      }

      return merged.values.toList();
    } catch (_) {
      // If remote fetch fails, fall back to local.
      return localSpots;
    }
  }

  @override
  Future<List<Spot>> getSpotsFromRespectedLists() async {
    return executeLocalOnly(
      localOperation: () => localDataSource.getSpotsFromRespectedLists(),
    );
  }

  /// Convenience method used in performance tests
  Future<Spot?> getSpotById(String id) async {
    return executeLocalOnly(
      localOperation: () => localDataSource.getSpotById(id),
    );
  }

  @override
  Future<Spot> createSpot(Spot spot) async {
    return executeOfflineFirst(
      localOperation: () async {
        final spotId = await localDataSource.createSpot(spot);
        final createdSpot = await localDataSource.getSpotById(spotId);
        if (createdSpot == null) {
          throw Exception('Failed to create spot locally');
        }
        return createdSpot;
      },
      remoteOperation: () => remoteDataSource.createSpot(spot),
      syncToLocal: (remoteSpot) async {
        await localDataSource.updateSpot(remoteSpot);
      },
    );
  }

  @override
  Future<Spot> updateSpot(Spot spot) async {
    return executeOfflineFirst(
      localOperation: () async {
        await localDataSource.updateSpot(spot);
        final updatedSpot = await localDataSource.getSpotById(spot.id);
        if (updatedSpot == null) {
          throw Exception('Failed to update spot locally');
        }
        return updatedSpot;
      },
      remoteOperation: () => remoteDataSource.updateSpot(spot),
      syncToLocal: (remoteSpot) async {
        await localDataSource.updateSpot(remoteSpot);
      },
    );
  }

  @override
  Future<void> deleteSpot(String spotId) async {
    return executeOfflineFirst(
      localOperation: () => localDataSource.deleteSpot(spotId),
      remoteOperation: () => remoteDataSource.deleteSpot(spotId),
    );
  }
}

import 'package:avrai_core/models/quantum/decoherence_pattern.dart';
import 'package:avrai_runtime_os/domain/repositories/decoherence_pattern_repository.dart';
import 'package:avrai_runtime_os/data/datasources/local/decoherence_pattern_local_datasource.dart';
import 'package:avrai_runtime_os/data/repositories/repository_patterns.dart';

/// Decoherence Pattern Repository Implementation
///
/// Implements local-only storage for decoherence patterns.
/// No remote operations - patterns are stored locally only.
///
/// **Implementation:**
/// Part of Quantum Enhancement Implementation Plan - Phase 2.1
class DecoherencePatternRepositoryImpl extends SimplifiedRepositoryBase
    implements DecoherencePatternRepository {
  final DecoherencePatternLocalDataSource _localDataSource;

  DecoherencePatternRepositoryImpl({
    required DecoherencePatternLocalDataSource localDataSource,
  })  : _localDataSource = localDataSource,
        super(connectivity: null); // Local-only, no connectivity needed

  @override
  Future<DecoherencePattern?> getByUserId(String userId) async {
    try {
      return await executeLocalOnly<DecoherencePattern?>(
        localOperation: () => _localDataSource.getByUserId(userId),
      );
    } catch (e) {
      // Return null on error (non-critical operation)
      return null;
    }
  }

  @override
  Future<void> save(DecoherencePattern pattern) async {
    // Error handling is done at service level - rethrow to allow service to handle
    return await executeLocalOnly(
      localOperation: () => _localDataSource.save(pattern),
    );
  }

  @override
  Future<List<DecoherencePattern>> getByBehaviorPhase(
    BehaviorPhase phase,
  ) async {
    try {
      return await executeLocalOnly<List<DecoherencePattern>>(
        localOperation: () async {
          final allPatterns = await _localDataSource.getAll();
          return allPatterns
              .where((pattern) => pattern.behaviorPhase == phase)
              .toList();
        },
      );
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<DecoherencePattern>> getByTimeRange({
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      return await executeLocalOnly<List<DecoherencePattern>>(
        localOperation: () async {
          final allPatterns = await _localDataSource.getAll();
          return allPatterns.where((pattern) {
            final lastUpdated = pattern.lastUpdated.serverTime;
            return lastUpdated.isAfter(start) && lastUpdated.isBefore(end);
          }).toList();
        },
      );
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> delete(String userId) async {
    // Error handling is done at service level - rethrow to allow service to handle
    return await executeLocalOnly(
      localOperation: () => _localDataSource.delete(userId),
    );
  }
}

import 'dart:io';

import 'package:avrai_core/avra_core.dart';
import 'package:path/path.dart' as path;

class ReplayArtifactRetentionCleanupResult {
  const ReplayArtifactRetentionCleanupResult({
    required this.attempted,
    required this.succeeded,
    this.deletedRoots = const <String>[],
    this.retainedRoots = const <String>[],
    this.failures = const <String>[],
    this.lifecycleStatesByRole = const <String, String>{},
  });

  final bool attempted;
  final bool succeeded;
  final List<String> deletedRoots;
  final List<String> retainedRoots;
  final List<String> failures;
  final Map<String, String> lifecycleStatesByRole;
}

class BhamReplayArtifactRetentionService {
  const BhamReplayArtifactRetentionService({
    DateTime Function()? nowProvider,
  }) : _nowProvider = nowProvider;

  final DateTime Function()? _nowProvider;

  ReplayArtifactRetentionCleanupResult cleanupAfterSuccessfulUpload({
    required ReplayStorageExportManifest exportManifest,
    required ReplayStoragePartitionManifest partitionManifest,
  }) {
    return _cleanupRoots(
      exportManifest: exportManifest,
      partitionManifest: partitionManifest,
      shouldDeleteRole: (_, __) => true,
      retainedState: 'accepted_pending_cleanup',
      failureState: 'accepted_pending_cleanup',
    );
  }

  ReplayArtifactRetentionCleanupResult cleanupExpiredStagingRoots({
    required ReplayStorageExportManifest exportManifest,
    required ReplayStoragePartitionManifest partitionManifest,
    DateTime? referenceAt,
  }) {
    final effectiveNow =
        (referenceAt ?? _nowProvider?.call() ?? DateTime.now()).toUtc();
    return _cleanupRoots(
      exportManifest: exportManifest,
      partitionManifest: partitionManifest,
      shouldDeleteRole: (role, metadata) {
        final expiresAt = _parseExpiration(metadata);
        if (expiresAt == null) {
          return false;
        }
        return !expiresAt.isAfter(effectiveNow);
      },
      retainedState: 'accepted',
      failureState: 'accepted_pending_cleanup',
    );
  }

  ReplayArtifactRetentionCleanupResult _cleanupRoots({
    required ReplayStorageExportManifest exportManifest,
    required ReplayStoragePartitionManifest partitionManifest,
    required bool Function(String role, Map<String, dynamic> metadata)
        shouldDeleteRole,
    required String retainedState,
    required String failureState,
  }) {
    final deletedRoots = <String>[];
    final retainedRoots = <String>[];
    final failures = <String>[];
    final lifecycleStatesByRole = <String, String>{};
    final seenPaths = <String>{};

    final candidates = <({
      String role,
      String expectedSegment,
      String rootPath,
      Map<String, dynamic> metadata
    })>[
      (
        role: 'replay_storage_staging',
        expectedSegment: 'replay_storage_staging',
        rootPath: exportManifest.exportRoot,
        metadata: exportManifest.metadata,
      ),
      (
        role: 'replay_storage_partitions',
        expectedSegment: 'replay_storage_partitions',
        rootPath: partitionManifest.partitionRoot,
        metadata: partitionManifest.metadata,
      ),
    ];

    for (final candidate in candidates) {
      final normalizedPath = candidate.rootPath.trim();
      if (normalizedPath.isEmpty || !seenPaths.add(normalizedPath)) {
        lifecycleStatesByRole[candidate.role] = retainedState;
        continue;
      }
      if (!shouldDeleteRole(candidate.role, candidate.metadata)) {
        retainedRoots.add(normalizedPath);
        lifecycleStatesByRole[candidate.role] = retainedState;
        continue;
      }
      final validationError = _validateManagedRoot(
        normalizedPath,
        candidate.expectedSegment,
      );
      if (validationError != null) {
        failures.add(validationError);
        lifecycleStatesByRole[candidate.role] = failureState;
        continue;
      }
      final directory = Directory(normalizedPath);
      if (!directory.existsSync()) {
        lifecycleStatesByRole[candidate.role] = 'expired';
        continue;
      }
      try {
        directory.deleteSync(recursive: true);
        deletedRoots.add(normalizedPath);
        lifecycleStatesByRole[candidate.role] = 'expired';
      } catch (error) {
        failures.add(
          'Failed to delete ${candidate.role} root `$normalizedPath`: $error',
        );
        lifecycleStatesByRole[candidate.role] = failureState;
      }
    }

    return ReplayArtifactRetentionCleanupResult(
      attempted: true,
      succeeded: failures.isEmpty,
      deletedRoots: deletedRoots,
      retainedRoots: retainedRoots,
      failures: failures,
      lifecycleStatesByRole: lifecycleStatesByRole,
    );
  }

  DateTime? _parseExpiration(Map<String, dynamic> metadata) {
    final rawValue = metadata['retentionExpiresAtUtc']?.toString().trim();
    if (rawValue == null || rawValue.isEmpty) {
      return null;
    }
    return DateTime.tryParse(rawValue)?.toUtc();
  }

  String? _validateManagedRoot(String rootPath, String expectedSegment) {
    final normalized = path.normalize(rootPath);
    final parts = path.split(normalized);
    if (!parts.contains(expectedSegment)) {
      return 'Refusing to delete unmanaged replay root `$rootPath` because '
          'it does not contain `$expectedSegment`.';
    }
    if (normalized == path.rootPrefix(normalized)) {
      return 'Refusing to delete replay root `$rootPath` because it resolves '
          'to a filesystem root.';
    }
    return null;
  }
}

import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io' show Platform;

import 'package:permission_handler/permission_handler.dart' as perm;

import 'package:avrai_core/models/misc/cross_app_learning_insight.dart';
import 'package:avrai_runtime_os/services/cross_app/cross_app_learning_insight_service.dart';

/// Permission change event
class PermissionStatusChange {
  final CrossAppDataSource source;
  final PermissionStatus previousStatus;
  final PermissionStatus newStatus;
  final DateTime timestamp;

  const PermissionStatusChange({
    required this.source,
    required this.previousStatus,
    required this.newStatus,
    required this.timestamp,
  });

  bool get wasRevoked =>
      previousStatus == PermissionStatus.granted &&
      newStatus == PermissionStatus.revoked;

  bool get wasGranted =>
      previousStatus != PermissionStatus.granted &&
      newStatus == PermissionStatus.granted;
}

/// Service for monitoring cross-app permission status
///
/// Detects when permissions are granted, denied, or revoked
/// and notifies listeners so the UI can update accordingly.
class CrossAppPermissionMonitor {
  static const String _logName = 'CrossAppPermissionMonitor';

  final CrossAppLearningInsightService? _insightService;

  // Permission status cache
  final Map<CrossAppDataSource, PermissionStatus> _statusCache = {};

  // Stream for permission changes
  final StreamController<PermissionStatusChange> _changeController =
      StreamController<PermissionStatusChange>.broadcast();

  /// Stream of permission status changes
  Stream<PermissionStatusChange> get permissionChanges =>
      _changeController.stream;

  CrossAppPermissionMonitor({
    CrossAppLearningInsightService? insightService,
  }) : _insightService = insightService;

  /// Check permissions for all cross-app sources
  Future<Map<CrossAppDataSource, PermissionStatus>>
      checkAllPermissions() async {
    final results = <CrossAppDataSource, PermissionStatus>{};

    for (final source in CrossAppDataSource.values) {
      // Skip app usage on iOS
      if (source == CrossAppDataSource.appUsage && !Platform.isAndroid) {
        results[source] = PermissionStatus.unknown;
        continue;
      }

      results[source] = await checkPermission(source);
    }

    return results;
  }

  /// Check permission for a specific source
  Future<PermissionStatus> checkPermission(CrossAppDataSource source) async {
    try {
      final permission = _getPermissionForSource(source);
      if (permission == null) {
        return PermissionStatus.unknown;
      }

      final status = await permission.status;
      final mappedStatus = _mapPermissionStatus(status);

      // Check for changes
      final previousStatus = _statusCache[source];
      if (previousStatus != null && previousStatus != mappedStatus) {
        _notifyChange(source, previousStatus, mappedStatus);
      }

      // Update cache
      _statusCache[source] = mappedStatus;

      // Update insight service
      _insightService?.updatePermissionStatus(source, mappedStatus);

      return mappedStatus;
    } catch (e) {
      developer.log(
        'Error checking permission for ${source.name}: $e',
        name: _logName,
      );
      return PermissionStatus.unknown;
    }
  }

  /// Request permission for a specific source
  Future<PermissionStatus> requestPermission(CrossAppDataSource source) async {
    try {
      final permission = _getPermissionForSource(source);
      if (permission == null) {
        return PermissionStatus.unknown;
      }

      final status = await permission.request();
      final mappedStatus = _mapPermissionStatus(status);

      // Check for changes
      final previousStatus = _statusCache[source];
      if (previousStatus != null && previousStatus != mappedStatus) {
        _notifyChange(source, previousStatus, mappedStatus);
      }

      // Update cache
      _statusCache[source] = mappedStatus;

      // Update insight service
      _insightService?.updatePermissionStatus(source, mappedStatus);

      developer.log(
        'Permission request for ${source.name}: ${mappedStatus.name}',
        name: _logName,
      );

      return mappedStatus;
    } catch (e) {
      developer.log(
        'Error requesting permission for ${source.name}: $e',
        name: _logName,
      );
      return PermissionStatus.unknown;
    }
  }

  /// Open system settings for a specific source
  Future<bool> openSystemSettings(CrossAppDataSource source) async {
    try {
      return await perm.openAppSettings();
    } catch (e) {
      developer.log(
        'Error opening settings for ${source.name}: $e',
        name: _logName,
      );
      return false;
    }
  }

  /// Get the current cached status for a source
  PermissionStatus? getCachedStatus(CrossAppDataSource source) {
    return _statusCache[source];
  }

  /// Check if any source has permission issues
  bool get hasPermissionIssues {
    return _statusCache.values.any((status) =>
        status == PermissionStatus.denied ||
        status == PermissionStatus.revoked);
  }

  /// Get sources with permission issues
  List<CrossAppDataSource> get sourcesWithIssues {
    return _statusCache.entries
        .where((e) =>
            e.value == PermissionStatus.denied ||
            e.value == PermissionStatus.revoked)
        .map((e) => e.key)
        .toList();
  }

  /// Refresh all permission statuses
  Future<void> refresh() async {
    await checkAllPermissions();
  }

  /// Get the Permission for a given CrossAppDataSource
  perm.Permission? _getPermissionForSource(CrossAppDataSource source) {
    switch (source) {
      case CrossAppDataSource.calendar:
        return perm.Permission.calendarFullAccess;
      case CrossAppDataSource.health:
        if (Platform.isIOS) {
          return perm.Permission.sensors; // Health data on iOS
        } else {
          return perm.Permission.activityRecognition; // Activity on Android
        }
      case CrossAppDataSource.media:
        if (Platform.isIOS) {
          return perm.Permission.mediaLibrary;
        } else {
          // No specific permission on Android for now playing
          return null;
        }
      case CrossAppDataSource.appUsage:
        // App usage stats doesn't use standard permissions
        // It requires special access through system settings
        return null;
      case CrossAppDataSource.location:
        return perm.Permission.location;
      case CrossAppDataSource.contacts:
        return perm.Permission.contacts;
      case CrossAppDataSource.browserHistory:
        return null; // no standard perm
      case CrossAppDataSource.external:
        return null; // external source
    }
  }

  /// Map permission_handler status to our PermissionStatus
  PermissionStatus _mapPermissionStatus(perm.PermissionStatus status) {
    switch (status) {
      case perm.PermissionStatus.granted:
      case perm.PermissionStatus.limited:
        return PermissionStatus.granted;
      case perm.PermissionStatus.denied:
        return PermissionStatus.denied;
      case perm.PermissionStatus.permanentlyDenied:
      case perm.PermissionStatus.restricted:
        return PermissionStatus.revoked;
      default:
        return PermissionStatus.unknown;
    }
  }

  /// Notify listeners of a permission change
  void _notifyChange(
    CrossAppDataSource source,
    PermissionStatus previous,
    PermissionStatus current,
  ) {
    final change = PermissionStatusChange(
      source: source,
      previousStatus: previous,
      newStatus: current,
      timestamp: DateTime.now(),
    );

    _changeController.add(change);

    developer.log(
      'Permission change for ${source.name}: ${previous.name} -> ${current.name}',
      name: _logName,
    );
  }

  /// Dispose resources
  void dispose() {
    _changeController.close();
  }
}

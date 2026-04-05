// Live Activity Service
//
// Service for managing iOS Live Activities and Dynamic Island.
// Supports reservation countdowns and matching progress indicators.
//
// Features:
// - Start/update/end reservation activities
// - Start/update/end matching activities
// - Dynamic Island compact and expanded views
//
// Usage:
//   final service = LiveActivityService();
//   await service.startReservationActivity(reservation);

import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/services.dart';

/// Service for managing iOS Live Activities and Dynamic Island.
///
/// Provides real-time updates on the lock screen and Dynamic Island
/// for ongoing activities like reservations and matching sessions.
class LiveActivityService {
  static const String _logName = 'LiveActivityService';

  /// Method channel for live activity operations
  static const MethodChannel _channel = MethodChannel('avra/live_activities');

  // Note: Event channel available for future push notification updates
  // static const EventChannel _eventChannel =
  //     EventChannel('avra/live_activities_events');

  /// Singleton instance
  static final LiveActivityService _instance = LiveActivityService._internal();

  factory LiveActivityService() => _instance;

  LiveActivityService._internal();

  /// Current active reservation activity ID
  String? _currentReservationActivityId;

  /// Current active matching activity ID
  String? _currentMatchingActivityId;

  /// Stream subscription for activity events
  StreamSubscription<dynamic>? _eventSubscription;

  /// Stream controller for activity state changes
  final _stateController = StreamController<LiveActivityState>.broadcast();

  /// Stream of activity state changes
  Stream<LiveActivityState> get stateStream => _stateController.stream;

  /// Check if Live Activities are supported on this device
  Future<bool> get isSupported async {
    if (!Platform.isIOS) return false;

    try {
      final result = await _channel.invokeMethod<bool>('isSupported');
      return result ?? false;
    } catch (e) {
      developer.log(
        'Error checking Live Activities support: $e',
        error: e,
        name: _logName,
      );
      return false;
    }
  }

  /// Check if Live Activities are enabled by the user
  Future<bool> get isEnabled async {
    if (!Platform.isIOS) return false;

    try {
      final result = await _channel.invokeMethod<bool>('isEnabled');
      return result ?? false;
    } catch (e) {
      developer.log(
        'Error checking Live Activities enabled: $e',
        error: e,
        name: _logName,
      );
      return false;
    }
  }

  // MARK: - Reservation Activities

  /// Start a reservation countdown activity
  Future<String?> startReservationActivity({
    required String reservationId,
    required String spotName,
    required DateTime reservationTime,
    required int partySize,
    String status = 'confirmed',
    String? spotAddress,
  }) async {
    if (!Platform.isIOS) return null;

    try {
      // End any existing reservation activity
      if (_currentReservationActivityId != null) {
        await endReservationActivity();
      }

      final result = await _channel.invokeMethod<String>('startReservation', {
        'reservationId': reservationId,
        'spotName': spotName,
        'reservationTime': reservationTime.toIso8601String(),
        'partySize': partySize,
        'status': status,
        'spotAddress': spotAddress,
      });

      if (result != null) {
        _currentReservationActivityId = result;
        developer.log(
          'Started reservation activity: $result',
          name: _logName,
        );

        _stateController.add(LiveActivityState(
          type: LiveActivityType.reservation,
          activityId: result,
          state: LiveActivityStateType.started,
        ));
      }

      return result;
    } on PlatformException catch (e) {
      developer.log(
        'Error starting reservation activity: ${e.message}',
        error: e,
        name: _logName,
      );
      return null;
    }
  }

  /// Update a reservation activity status
  Future<bool> updateReservationActivity({
    required String status,
    int? minutesUntil,
    String? tableNumber,
  }) async {
    if (!Platform.isIOS || _currentReservationActivityId == null) return false;

    try {
      final result = await _channel.invokeMethod<bool>('updateReservation', {
        'activityId': _currentReservationActivityId,
        'status': status,
        'minutesUntil': minutesUntil,
        'tableNumber': tableNumber,
      });

      if (result == true) {
        developer.log(
          'Updated reservation activity: $status',
          name: _logName,
        );

        _stateController.add(LiveActivityState(
          type: LiveActivityType.reservation,
          activityId: _currentReservationActivityId!,
          state: LiveActivityStateType.updated,
          data: {'status': status},
        ));
      }

      return result ?? false;
    } on PlatformException catch (e) {
      developer.log(
        'Error updating reservation activity: ${e.message}',
        error: e,
        name: _logName,
      );
      return false;
    }
  }

  /// End the current reservation activity
  Future<bool> endReservationActivity({String? finalStatus}) async {
    if (!Platform.isIOS || _currentReservationActivityId == null) return false;

    try {
      final result = await _channel.invokeMethod<bool>('endReservation', {
        'activityId': _currentReservationActivityId,
        'finalStatus': finalStatus ?? 'completed',
      });

      if (result == true) {
        developer.log(
          'Ended reservation activity',
          name: _logName,
        );

        _stateController.add(LiveActivityState(
          type: LiveActivityType.reservation,
          activityId: _currentReservationActivityId!,
          state: LiveActivityStateType.ended,
        ));

        _currentReservationActivityId = null;
      }

      return result ?? false;
    } on PlatformException catch (e) {
      developer.log(
        'Error ending reservation activity: ${e.message}',
        error: e,
        name: _logName,
      );
      return false;
    }
  }

  // MARK: - Matching Activities

  /// Start a quantum matching activity
  Future<String?> startMatchingActivity({
    required String sessionId,
    String mode = 'discover',
    int? potentialMatches,
  }) async {
    if (!Platform.isIOS) return null;

    try {
      // End any existing matching activity
      if (_currentMatchingActivityId != null) {
        await endMatchingActivity();
      }

      final result = await _channel.invokeMethod<String>('startMatching', {
        'sessionId': sessionId,
        'mode': mode,
        'potentialMatches': potentialMatches ?? 0,
      });

      if (result != null) {
        _currentMatchingActivityId = result;
        developer.log(
          'Started matching activity: $result',
          name: _logName,
        );

        _stateController.add(LiveActivityState(
          type: LiveActivityType.matching,
          activityId: result,
          state: LiveActivityStateType.started,
        ));
      }

      return result;
    } on PlatformException catch (e) {
      developer.log(
        'Error starting matching activity: ${e.message}',
        error: e,
        name: _logName,
      );
      return null;
    }
  }

  /// Update matching activity progress
  Future<bool> updateMatchingActivity({
    required int potentialMatches,
    int? newMatches,
    double? compatibilityScore,
  }) async {
    if (!Platform.isIOS || _currentMatchingActivityId == null) return false;

    try {
      final result = await _channel.invokeMethod<bool>('updateMatching', {
        'activityId': _currentMatchingActivityId,
        'potentialMatches': potentialMatches,
        'newMatches': newMatches,
        'compatibilityScore': compatibilityScore,
      });

      if (result == true) {
        _stateController.add(LiveActivityState(
          type: LiveActivityType.matching,
          activityId: _currentMatchingActivityId!,
          state: LiveActivityStateType.updated,
          data: {'potentialMatches': potentialMatches},
        ));
      }

      return result ?? false;
    } on PlatformException catch (e) {
      developer.log(
        'Error updating matching activity: ${e.message}',
        error: e,
        name: _logName,
      );
      return false;
    }
  }

  /// End the current matching activity
  Future<bool> endMatchingActivity({int? totalMatches}) async {
    if (!Platform.isIOS || _currentMatchingActivityId == null) return false;

    try {
      final result = await _channel.invokeMethod<bool>('endMatching', {
        'activityId': _currentMatchingActivityId,
        'totalMatches': totalMatches ?? 0,
      });

      if (result == true) {
        developer.log(
          'Ended matching activity',
          name: _logName,
        );

        _stateController.add(LiveActivityState(
          type: LiveActivityType.matching,
          activityId: _currentMatchingActivityId!,
          state: LiveActivityStateType.ended,
        ));

        _currentMatchingActivityId = null;
      }

      return result ?? false;
    } on PlatformException catch (e) {
      developer.log(
        'Error ending matching activity: ${e.message}',
        error: e,
        name: _logName,
      );
      return false;
    }
  }

  // MARK: - Utility

  /// End all active activities
  Future<void> endAllActivities() async {
    await endReservationActivity();
    await endMatchingActivity();
  }

  /// Get current reservation activity ID
  String? get currentReservationActivityId => _currentReservationActivityId;

  /// Get current matching activity ID
  String? get currentMatchingActivityId => _currentMatchingActivityId;

  /// Check if there's an active reservation
  bool get hasActiveReservation => _currentReservationActivityId != null;

  /// Check if there's active matching
  bool get hasActiveMatching => _currentMatchingActivityId != null;

  /// Dispose of resources
  void dispose() {
    _eventSubscription?.cancel();
    _stateController.close();
  }
}

/// Types of live activities
enum LiveActivityType {
  reservation,
  matching,
}

/// Live activity state types
enum LiveActivityStateType {
  started,
  updated,
  ended,
}

/// Live activity state event
class LiveActivityState {
  final LiveActivityType type;
  final String activityId;
  final LiveActivityStateType state;
  final Map<String, dynamic>? data;

  LiveActivityState({
    required this.type,
    required this.activityId,
    required this.state,
    this.data,
  });

  @override
  String toString() => 'LiveActivityState($type, $state, $activityId)';
}

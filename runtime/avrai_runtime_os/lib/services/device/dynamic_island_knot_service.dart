// Dynamic Island Knot Service
//
// Service for showing the user's knot indicator in Dynamic Island
// during active sessions (matching, meditation, etc.).
//
// Features:
// - Show knot indicator during active sessions
// - Update knot appearance based on session state
// - Integrate with Live Activities
//
// Usage:
//   final service = DynamicIslandKnotService();
//   await service.showDuringMatching(sessionId);

import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:avrai_core/models/personality_knot.dart';
import 'package:avrai_runtime_os/services/device/live_activity_service.dart';

/// Service for showing knot indicator in Dynamic Island.
///
/// Coordinates with Live Activities to display the user's knot
/// in the Dynamic Island during active sessions.
class DynamicIslandKnotService {
  static const String _logName = 'DynamicIslandKnotService';

  /// Method channel for knot island operations
  static const MethodChannel _channel = MethodChannel('avra/knot_island');

  /// Singleton instance
  static final DynamicIslandKnotService _instance =
      DynamicIslandKnotService._internal();

  factory DynamicIslandKnotService() => _instance;

  DynamicIslandKnotService._internal();

  /// Live Activity service reference
  final _liveActivityService = LiveActivityService();

  /// Current active session type
  KnotIslandSessionType? _currentSessionType;

  /// Current session ID
  String? _currentSessionId;

  /// Check if Dynamic Island is available
  Future<bool> get isAvailable async {
    if (!Platform.isIOS) return false;
    return await _liveActivityService.isSupported;
  }

  /// Get current session type
  KnotIslandSessionType? get currentSessionType => _currentSessionType;

  /// Check if there's an active knot session
  bool get hasActiveSession => _currentSessionType != null;

  // MARK: - Session Management

  /// Show knot in Dynamic Island during quantum matching.
  ///
  /// The knot will pulse/animate to indicate active matching.
  Future<bool> showDuringMatching({
    required String sessionId,
    required PersonalityKnot knot,
    String mode = 'discover',
  }) async {
    if (!Platform.isIOS) return false;

    try {
      // End any existing session
      await endSession();

      // Start matching activity with knot data
      final activityId = await _liveActivityService.startMatchingActivity(
        sessionId: sessionId,
        mode: mode,
      );

      if (activityId != null) {
        _currentSessionType = KnotIslandSessionType.matching;
        _currentSessionId = sessionId;

        // Send knot visualization data to native side
        await _sendKnotData(knot);

        developer.log(
          'Started knot matching session: $sessionId',
          name: _logName,
        );

        return true;
      }

      return false;
    } catch (e) {
      developer.log(
        'Error starting matching session: $e',
        error: e,
        name: _logName,
      );
      return false;
    }
  }

  /// Show knot in Dynamic Island during meditation.
  ///
  /// The knot will breathe/pulse slowly during meditation.
  Future<bool> showDuringMeditation({
    required String sessionId,
    required PersonalityKnot knot,
    int durationMinutes = 5,
  }) async {
    if (!Platform.isIOS) return false;

    try {
      // End any existing session
      await endSession();

      // Start meditation activity
      final result = await _channel.invokeMethod<String>('startMeditation', {
        'sessionId': sessionId,
        'durationMinutes': durationMinutes,
        'knotData': _knotToMap(knot),
      });

      if (result != null) {
        _currentSessionType = KnotIslandSessionType.meditation;
        _currentSessionId = sessionId;

        developer.log(
          'Started knot meditation session: $sessionId',
          name: _logName,
        );

        return true;
      }

      return false;
    } on PlatformException catch (e) {
      developer.log(
        'Error starting meditation session: ${e.message}',
        error: e,
        name: _logName,
      );
      return false;
    }
  }

  /// Show knot in Dynamic Island during reservation wait.
  Future<bool> showDuringReservation({
    required String reservationId,
    required PersonalityKnot knot,
    required String spotName,
    required DateTime reservationTime,
    required int partySize,
  }) async {
    if (!Platform.isIOS) return false;

    try {
      // End any existing session
      await endSession();

      // Start reservation activity with knot data
      final activityId = await _liveActivityService.startReservationActivity(
        reservationId: reservationId,
        spotName: spotName,
        reservationTime: reservationTime,
        partySize: partySize,
      );

      if (activityId != null) {
        _currentSessionType = KnotIslandSessionType.reservation;
        _currentSessionId = reservationId;

        // Send knot visualization data
        await _sendKnotData(knot);

        developer.log(
          'Started knot reservation session: $reservationId',
          name: _logName,
        );

        return true;
      }

      return false;
    } catch (e) {
      developer.log(
        'Error starting reservation session: $e',
        error: e,
        name: _logName,
      );
      return false;
    }
  }

  /// Update the knot visualization during an active session.
  Future<bool> updateKnot(PersonalityKnot knot) async {
    if (!Platform.isIOS || _currentSessionType == null) return false;

    try {
      await _sendKnotData(knot);
      return true;
    } catch (e) {
      developer.log(
        'Error updating knot: $e',
        error: e,
        name: _logName,
      );
      return false;
    }
  }

  /// Update session progress.
  Future<bool> updateProgress({
    int? potentialMatches,
    int? newMatches,
    double? compatibilityScore,
    int? meditationProgress,
    String? reservationStatus,
  }) async {
    if (!Platform.isIOS || _currentSessionType == null) return false;

    try {
      switch (_currentSessionType!) {
        case KnotIslandSessionType.matching:
          if (potentialMatches != null) {
            return await _liveActivityService.updateMatchingActivity(
              potentialMatches: potentialMatches,
              newMatches: newMatches,
              compatibilityScore: compatibilityScore,
            );
          }
          break;

        case KnotIslandSessionType.meditation:
          if (meditationProgress != null) {
            await _channel.invokeMethod('updateMeditation', {
              'sessionId': _currentSessionId,
              'progress': meditationProgress,
            });
            return true;
          }
          break;

        case KnotIslandSessionType.reservation:
          if (reservationStatus != null) {
            return await _liveActivityService.updateReservationActivity(
              status: reservationStatus,
            );
          }
          break;
      }

      return false;
    } catch (e) {
      developer.log(
        'Error updating progress: $e',
        error: e,
        name: _logName,
      );
      return false;
    }
  }

  /// End the current knot island session.
  Future<bool> endSession({
    int? totalMatches,
    String? finalStatus,
  }) async {
    if (!Platform.isIOS || _currentSessionType == null) return false;

    try {
      bool result = false;

      switch (_currentSessionType!) {
        case KnotIslandSessionType.matching:
          result = await _liveActivityService.endMatchingActivity(
            totalMatches: totalMatches,
          );
          break;

        case KnotIslandSessionType.meditation:
          await _channel.invokeMethod('endMeditation', {
            'sessionId': _currentSessionId,
          });
          result = true;
          break;

        case KnotIslandSessionType.reservation:
          result = await _liveActivityService.endReservationActivity(
            finalStatus: finalStatus,
          );
          break;
      }

      if (result) {
        _currentSessionType = null;
        _currentSessionId = null;

        developer.log(
          'Ended knot island session',
          name: _logName,
        );
      }

      return result;
    } catch (e) {
      developer.log(
        'Error ending session: $e',
        error: e,
        name: _logName,
      );
      return false;
    }
  }

  // MARK: - Private Helpers

  /// Send knot data to native side for visualization.
  Future<void> _sendKnotData(PersonalityKnot knot) async {
    try {
      await _channel.invokeMethod('updateKnotData', _knotToMap(knot));
    } catch (e) {
      developer.log(
        'Error sending knot data: $e',
        error: e,
        name: _logName,
      );
    }
  }

  /// Convert knot to map for native side.
  Map<String, dynamic> _knotToMap(PersonalityKnot knot) {
    return {
      'crossingNumber': knot.invariants.crossingNumber,
      'writhe': knot.invariants.writhe.toDouble(),
      'bridgeNumber': knot.invariants.bridgeNumber,
      'unknottingNumber': knot.invariants.unknottingNumber ?? 0,
    };
  }

  /// Dispose of resources.
  void dispose() {
    endSession();
  }
}

/// Types of knot island sessions.
enum KnotIslandSessionType {
  /// Quantum matching session
  matching,

  /// Meditation session
  meditation,

  /// Reservation countdown
  reservation,
}

/// Knot visualization style for Dynamic Island.
enum KnotIslandStyle {
  /// Minimal - just the knot shape
  minimal,

  /// Compact - knot with subtle animation
  compact,

  /// Expanded - full knot with details
  expanded,
}

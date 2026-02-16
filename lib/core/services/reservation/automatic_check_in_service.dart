import 'package:avrai/core/models/spots/visit.dart';
import 'package:avrai/core/models/misc/automatic_check_in.dart';
import 'package:avrai/core/services/locality_agents/locality_agent_ingestion_service_v1.dart';
import 'package:avrai/core/services/infrastructure/logger.dart';
import 'package:avrai/core/ai/memory/episodic/episodic_memory_store.dart';
import 'package:avrai/core/ai/memory/episodic/episodic_tuple.dart';
import 'package:avrai/core/ai/memory/episodic/outcome_taxonomy.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:get_it/get_it.dart';
import 'dart:convert';
import 'dart:io';

/// Automatic Check-In Service
///
/// Handles automatic check-ins via geofencing and Bluetooth ai2ai detection.
///
/// **Philosophy Alignment:**
/// - Opens doors to expertise through automatic exploration
/// - Zero friction (no phone interaction needed)
/// - Works offline (Bluetooth-based)
///
/// **Technology:**
/// - Background location detection (geofencing, 50m radius)
/// - Bluetooth ai2ai proximity verification (works offline)
/// - Dwell time calculation (5+ minutes = valid visit)
/// - Quality scoring (longer stay = higher quality)
///
/// **Patent #30 Integration:** Uses AtomicClockService for precise timing
class AutomaticCheckInService {
  static const String _logName = 'AutomaticCheckInService';
  final AppLogger _logger = const AppLogger(
    defaultTag: 'SPOTS',
    minimumLevel: LogLevel.debug,
  );

  static int _idCounter = 0;

  /// AtomicClockService for precise timing (Patent #30)
  AtomicClockService? _atomicClock;
  EpisodicMemoryStore? _episodicMemoryStore;
  final OutcomeTaxonomy _outcomeTaxonomy = const OutcomeTaxonomy();

  /// Get AtomicClockService (lazy initialization)
  AtomicClockService get atomicClock {
    if (_atomicClock == null) {
      try {
        final sl = GetIt.instance;
        if (sl.isRegistered<AtomicClockService>()) {
          _atomicClock = sl<AtomicClockService>();
        }
      } catch (_) {}
      _atomicClock ??= AtomicClockService();
    }
    return _atomicClock!;
  }

  /// Get current atomic time (with fallback to DateTime.now())
  Future<DateTime> _getAtomicNow() async {
    try {
      final timestamp = await atomicClock.getAtomicTimestamp();
      // `AtomicTimestamp` exposes multiple time representations; for check-in
      // semantics we want the canonical server-synchronized time when available.
      return timestamp.serverTime;
    } catch (_) {
      // Graceful degradation: fallback to DateTime.now() if atomic clock fails
      return DateTime.now();
    }
  }

  EpisodicMemoryStore? get _episodicStore {
    if (_episodicMemoryStore != null) return _episodicMemoryStore;
    try {
      final sl = GetIt.instance;
      if (sl.isRegistered<EpisodicMemoryStore>()) {
        _episodicMemoryStore = sl<EpisodicMemoryStore>();
      }
    } catch (_) {}
    return _episodicMemoryStore;
  }

  // #region agent log
  static const String _agentDebugLogPath =
      '/Users/reisgordon/SPOTS/.cursor/debug.log';
  final String _agentRunId =
      'auto_check_in_${DateTime.now().microsecondsSinceEpoch}';
  void _agentLog(String hypothesisId, String location, String message,
      Map<String, Object?> data) {
    try {
      final payload = <String, Object?>{
        'sessionId': 'debug-session',
        'runId': _agentRunId,
        'hypothesisId': hypothesisId,
        'location': location,
        'message': message,
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      File(_agentDebugLogPath).writeAsStringSync('${jsonEncode(payload)}\n',
          mode: FileMode.append, flush: true);
    } catch (_) {
      // ignore: avoid_catches_without_on_clauses
    }
  }
  // #endregion

  // In-memory storage for check-ins (in production, use database)
  final Map<String, AutomaticCheckIn> _checkIns = {};
  final Map<String, Visit> _visits = {};

  // Active check-ins (user ID -> check-in)
  final Map<String, AutomaticCheckIn> _activeCheckIns = {};

  /// Handle geofence trigger (user entered geofence)
  ///
  /// **Flow:**
  /// 1. Create automatic check-in with geofence trigger
  /// 2. Create visit record
  /// 3. Start tracking dwell time
  ///
  /// **Parameters:**
  /// - `userId`: User ID
  /// - `locationId`: Location/Spot ID
  /// - `latitude`: Latitude
  /// - `longitude`: Longitude
  /// - `accuracy`: Location accuracy (meters)
  ///
  /// **Returns:**
  /// AutomaticCheckIn with geofence trigger
  Future<AutomaticCheckIn> handleGeofenceTrigger({
    required String userId,
    required String locationId,
    required double latitude,
    required double longitude,
    double? accuracy,
  }) async {
    try {
      // #region agent log
      _agentLog(
        'A',
        'automatic_check_in_service.dart:handleGeofenceTrigger:entry',
        'handleGeofenceTrigger entry',
        {
          'userId': userId,
          'locationId': locationId,
          'activeBefore': _activeCheckIns.containsKey(userId),
          'visitsSizeBefore': _visits.length,
        },
      );
      // #endregion

      _logger.info(
        'Geofence trigger: user=$userId, location=$locationId',
        tag: _logName,
      );

      // Check if user already has active check-in
      if (_activeCheckIns.containsKey(userId)) {
        // #region agent log
        _agentLog(
          'B',
          'automatic_check_in_service.dart:handleGeofenceTrigger:early_return_active',
          'Active check-in exists; returning existing',
          {
            'userId': userId,
            'existingVisitId': _activeCheckIns[userId]?.visitId
          },
        );
        // #endregion
        _logger.warning(
          'User already has active check-in, ignoring new trigger',
          tag: _logName,
        );
        return _activeCheckIns[userId]!;
      }

      // Patent #30: Use atomic time for precise timing
      final now = await _getAtomicNow();

      // Create geofence trigger
      final geofenceTrigger = GeofenceTrigger(
        locationId: locationId,
        latitude: latitude,
        longitude: longitude,
        accuracy: accuracy,
        triggeredAt: now,
      );

      // Create visit
      final visit = Visit(
        id: _generateVisitId(),
        userId: userId,
        locationId: locationId,
        checkInTime: now,
        isAutomatic: true,
        geofencingData: GeofencingData(
          latitude: latitude,
          longitude: longitude,
          accuracy: accuracy,
          triggeredAt: now,
        ),
        createdAt: now,
        updatedAt: now,
      );

      // #region agent log
      _agentLog(
        'A',
        'automatic_check_in_service.dart:handleGeofenceTrigger:visit_created',
        'Created visit prior to save',
        {
          'userId': userId,
          'visitId': visit.id,
          'visitIdAlreadyExists': _visits.containsKey(visit.id)
        },
      );
      // #endregion

      // Create automatic check-in (using atomic time)
      final checkIn = AutomaticCheckIn(
        id: _generateCheckInId(),
        visitId: visit.id,
        geofenceTrigger: geofenceTrigger,
        checkInTime: now,
        visitCreated: true,
        createdAt: now,
        updatedAt: now,
      );

      // Save check-in and visit
      await _saveCheckIn(checkIn);
      await _saveVisit(visit);
      _activeCheckIns[userId] = checkIn;

      // #region agent log
      _agentLog(
        'A',
        'automatic_check_in_service.dart:handleGeofenceTrigger:done',
        'handleGeofenceTrigger completed',
        {
          'userId': userId,
          'visitId': visit.id,
          'checkInId': checkIn.id,
          'visitsSizeAfter': _visits.length,
          'activeAfter': _activeCheckIns.containsKey(userId),
        },
      );
      // #endregion

      _logger.info('Created automatic check-in: ${checkIn.id}', tag: _logName);

      return checkIn;
    } catch (e) {
      _logger.error('Error handling geofence trigger', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Handle Bluetooth ai2ai trigger (Bluetooth device detected)
  ///
  /// **Flow:**
  /// 1. Create automatic check-in with Bluetooth trigger
  /// 2. Create visit record
  /// 3. Start tracking dwell time
  ///
  /// **Parameters:**
  /// - `userId`: User ID
  /// - `locationId`: Location/Spot ID (if known from ai2ai exchange)
  /// - `deviceId`: Detected device ID
  /// - `rssi`: Signal strength
  /// - `ai2aiConnected`: Whether ai2ai connection established
  /// - `personalityExchanged`: Whether personality exchange completed
  ///
  /// **Returns:**
  /// AutomaticCheckIn with Bluetooth trigger
  Future<AutomaticCheckIn> handleBluetoothTrigger({
    required String userId,
    String? locationId,
    String? deviceId,
    int? rssi,
    bool ai2aiConnected = false,
    bool personalityExchanged = false,
  }) async {
    try {
      _logger.info(
        'Bluetooth trigger: user=$userId, device=$deviceId',
        tag: _logName,
      );

      // Check if user already has active check-in
      if (_activeCheckIns.containsKey(userId)) {
        _logger.warning(
          'User already has active check-in, ignoring new trigger',
          tag: _logName,
        );
        return _activeCheckIns[userId]!;
      }

      // Patent #30: Use atomic time for precise timing
      final now = await _getAtomicNow();

      // Create Bluetooth trigger
      final bluetoothTrigger = BluetoothTrigger(
        deviceId: deviceId,
        rssi: rssi,
        detectedAt: now,
        ai2aiConnected: ai2aiConnected,
        personalityExchanged: personalityExchanged,
        locationId: locationId,
      );

      // Create visit (if location known)
      Visit? visit;
      if (locationId != null) {
        visit = Visit(
          id: _generateVisitId(),
          userId: userId,
          locationId: locationId,
          checkInTime: now,
          isAutomatic: true,
          bluetoothData: BluetoothData(
            deviceId: deviceId,
            rssi: rssi,
            detectedAt: now,
            ai2aiConnected: ai2aiConnected,
            personalityExchanged: personalityExchanged,
          ),
          createdAt: now,
          updatedAt: now,
        );
        await _saveVisit(visit);
      }

      // Create automatic check-in (using atomic time)
      final checkIn = AutomaticCheckIn(
        id: _generateCheckInId(),
        visitId: visit?.id ?? 'pending',
        bluetoothTrigger: bluetoothTrigger,
        checkInTime: now,
        visitCreated: visit != null,
        createdAt: now,
        updatedAt: now,
      );

      // Save check-in
      await _saveCheckIn(checkIn);
      if (visit != null) {
        _activeCheckIns[userId] = checkIn;
      }

      _logger.info('Created automatic check-in: ${checkIn.id}', tag: _logName);

      return checkIn;
    } catch (e) {
      _logger.error('Error handling Bluetooth trigger',
          error: e, tag: _logName);
      rethrow;
    }
  }

  /// Check out from automatic check-in
  ///
  /// **Flow:**
  /// 1. Calculate dwell time
  /// 2. Calculate quality score
  /// 3. Update check-in and visit
  /// 4. Remove from active check-ins
  ///
  /// **Parameters:**
  /// - `userId`: User ID
  /// - `checkOutTime`: Check-out time (optional, defaults to now)
  ///
  /// **Returns:**
  /// Updated AutomaticCheckIn with dwell time and quality score
  Future<AutomaticCheckIn> checkOut({
    required String userId,
    DateTime? checkOutTime,
  }) async {
    try {
      _logger.info('Checking out: user=$userId', tag: _logName);

      final activeCheckIn = _activeCheckIns[userId];
      if (activeCheckIn == null) {
        throw Exception('No active check-in found for user: $userId');
      }

      // Patent #30: Use atomic time for precise timing
      final checkout = checkOutTime ?? await _getAtomicNow();

      // Calculate dwell time
      final dwellTime = checkout.difference(activeCheckIn.checkInTime);

      // Check if visit exists
      final visit = _visits[activeCheckIn.visitId];
      if (visit != null) {
        // Update visit
        final updatedVisit = visit.checkOut(checkOutTime: checkout);
        await _saveVisit(updatedVisit);

        // Best-effort: update locality agents on completed visit.
        // This should never block checkout.
        try {
          final ingestion = LocalityAgentIngestionServiceV1.tryGetFromDI();
          if (ingestion != null) {
            final source = switch (activeCheckIn.triggerType) {
              CheckInTriggerType.geofence => 'geofence',
              CheckInTriggerType.bluetooth => 'bluetooth',
              CheckInTriggerType.unknown => 'unknown',
            };
            // ignore: unawaited_futures
            ingestion.ingestVisit(
                userId: userId, visit: updatedVisit, source: source);
          }
        } catch (e) {
          _logger.warning('Locality agent ingestion skipped: $e',
              tag: _logName);
        }

        // Update check-in (this calculates quality score internally)
        final updatedCheckIn = activeCheckIn.checkOut(checkOutTime: checkout);

        // Save updated check-in
        await _saveCheckIn(updatedCheckIn);

        // Remove from active check-ins
        _activeCheckIns.remove(userId);

        // #region agent log
        _agentLog(
          'B',
          'automatic_check_in_service.dart:checkOut:removed_active',
          'Removed active check-in after checkout',
          {
            'userId': userId,
            'visitId': activeCheckIn.visitId,
            'activeAfter': _activeCheckIns.containsKey(userId)
          },
        );
        // #endregion

        _logger.info(
          'Checked out: dwell=${dwellTime.inMinutes}min, quality=${updatedCheckIn.qualityScore}',
          tag: _logName,
        );
        await _recordBusinessVisitTuple(
          userId: userId,
          visit: updatedVisit,
          qualityScore: updatedCheckIn.qualityScore,
          triggerType: activeCheckIn.triggerType.name,
        );

        return updatedCheckIn;
      } else {
        // Visit not found, just update check-in
        final updatedCheckIn = activeCheckIn.checkOut(checkOutTime: checkout);
        await _saveCheckIn(updatedCheckIn);
        _activeCheckIns.remove(userId);

        // #region agent log
        _agentLog(
          'B',
          'automatic_check_in_service.dart:checkOut:removed_active_no_visit',
          'Removed active check-in after checkout (no visit found)',
          {
            'userId': userId,
            'visitId': activeCheckIn.visitId,
            'activeAfter': _activeCheckIns.containsKey(userId)
          },
        );
        // #endregion

        return updatedCheckIn;
      }
    } catch (e) {
      _logger.error('Error checking out', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Get active check-in for user
  AutomaticCheckIn? getActiveCheckIn(String userId) {
    return _activeCheckIns[userId];
  }

  /// Get visit by ID
  Visit? getVisit(String visitId) {
    return _visits[visitId];
  }

  /// Get all visits for user
  List<Visit> getUserVisits(String userId) {
    // #region agent log
    _agentLog(
      'C',
      'automatic_check_in_service.dart:getUserVisits',
      'Computing user visits',
      {
        'userId': userId,
        'visitsSize': _visits.length,
        'active': _activeCheckIns.containsKey(userId)
      },
    );
    // #endregion
    return _visits.values.where((v) => v.userId == userId).toList()
      ..sort((a, b) => b.checkInTime.compareTo(a.checkInTime));
  }

  /// Get all visits for location
  List<Visit> getLocationVisits(String locationId) {
    return _visits.values.where((v) => v.locationId == locationId).toList()
      ..sort((a, b) => b.checkInTime.compareTo(a.checkInTime));
  }

  // Private helper methods

  Future<void> _saveCheckIn(AutomaticCheckIn checkIn) async {
    _checkIns[checkIn.id] = checkIn;
    // In production, save to database
  }

  Future<void> _saveVisit(Visit visit) async {
    // #region agent log
    final hadExisting = _visits.containsKey(visit.id);
    final beforeSize = _visits.length;
    // #endregion
    _visits[visit.id] = visit;
    // In production, save to database
    // #region agent log
    _agentLog(
      'A',
      'automatic_check_in_service.dart:_saveVisit',
      'Saved visit',
      {
        'visitId': visit.id,
        'userId': visit.userId,
        'hadExisting': hadExisting,
        'beforeSize': beforeSize,
        'afterSize': _visits.length
      },
    );
    // #endregion
  }

  String _generateCheckInId() {
    final us = DateTime.now().microsecondsSinceEpoch;
    _idCounter = (_idCounter + 1) & 0x7fffffff;
    return 'checkin-${us}_$_idCounter';
  }

  String _generateVisitId() {
    final us = DateTime.now().microsecondsSinceEpoch;
    _idCounter = (_idCounter + 1) & 0x7fffffff;
    return 'visit-${us}_$_idCounter';
  }

  Future<void> _recordBusinessVisitTuple({
    required String userId,
    required Visit visit,
    required double qualityScore,
    required String triggerType,
  }) async {
    final store = _episodicStore;
    if (store == null) return;
    try {
      final normalizedScore = qualityScore.clamp(0.0, 1.0);
      final tuple = EpisodicTuple(
        agentId: userId,
        stateBefore: {
          'phase_ref': '1.2.26',
          'user_state': {
            'user_id': userId,
            'automatic_checkin': true,
          },
        },
        actionType: 'engage_business',
        actionPayload: {
          'business_features': {
            'business_entity_id': visit.locationId,
            'source': 'automatic_check_in',
          },
          'engagement_context': {
            'engagement_type': 'visit',
            'trigger_type': triggerType,
            'visit_id': visit.id,
          },
        },
        nextState: {
          'engagement_outcome': {
            'label': 'automatic_visit',
            'overall_rating': normalizedScore,
            'checked_out': true,
          },
        },
        outcome: _outcomeTaxonomy.classify(
          eventType: 'engagement_outcome',
          parameters: {
            'overall_rating': normalizedScore,
            'label': 'automatic_visit',
            'visit_id': visit.id,
            'business_entity_id': visit.locationId,
            'trigger_type': triggerType,
          },
        ),
        metadata: const {
          'phase_ref': '1.2.26',
          'pipeline': 'automatic_check_in_service',
        },
      );
      await store.writeTuple(tuple);
    } catch (e) {
      _logger.warning('Failed to write automatic visit tuple: $e',
          tag: _logName);
    }
  }
}

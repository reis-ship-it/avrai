import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:avrai_runtime_os/services/device/device_motion_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:avrai_network/network/device_discovery.dart';

/// Represents a raw environmental ping captured by the passive listener.
class PassivePing {
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final String? encounterAgentId; // Optional BLE mathematical knot encountered
  final double? encounterConfidence; // Math match score

  PassivePing({
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    this.encounterAgentId,
    this.encounterConfidence,
  });
}

/// Represents a clustered dwell event, heavily compressing raw pings.
///
/// Instead of sending 40 location pings from a coffee shop to the LLM
/// during the nightly batch, we send one DwellEvent representing 2 hours.
class DwellEvent {
  final DateTime startTime;
  DateTime endTime;
  final double latitude;
  final double longitude;

  /// The math-based "DNA" strings encountered while dwelling here
  final List<String> encounteredAgentIds;

  /// Optional health integration (Apple Health/Garmin) for true "excitement" measurement
  /// Added in v0.4.1 as a stub for future simulation/training passes
  final double? biometricArousal;

  DwellEvent({
    required this.startTime,
    required this.endTime,
    required this.latitude,
    required this.longitude,
    List<String>? encounteredAgentIds,
    this.biometricArousal,
  }) : encounteredAgentIds = encounteredAgentIds ?? [];
}

/// Service that passively listens to the physical world, capturing location
/// and BLE serendipity without running heavy LLM inference.
///
/// Employs smart clustering to reduce the token load on the nightly batch process.
class SmartPassiveCollectionService {
  static const String _logName = 'SmartPassiveCollection';

  final DeviceMotionService _motionService;
  final DeviceDiscoveryService? _deviceDiscoveryService;

  StreamSubscription<MotionData>? _motionSub;
  StreamSubscription<Position>? _locationSub;
  bool _isActive = false;
  bool _discoveryCallbackRegistered = false;

  // Activity tracking state
  int _highMotionTicks = 0;
  int _lowMotionTicks = 0;
  bool _isCurrentlyActive =
      false; // true = high motion (walking/driving), false = low motion (dwelling)

  // The in-memory buffer before flushing to SQLite/Drift
  final List<PassivePing> _rawPingBuffer = [];

  // The compressed clusters ready for the LLM
  final List<DwellEvent> _dwellClusters = [];

  // Configuration for clustering
  static const double _dwellRadiusMeters = 50.0;
  static const Duration _minDwellDuration = Duration(minutes: 5);

  SmartPassiveCollectionService({
    required DeviceMotionService motionService,
    DeviceDiscoveryService? deviceDiscoveryService,
  })  : _motionService = motionService,
        _deviceDiscoveryService = deviceDiscoveryService;

  void start() {
    if (_isActive) return;
    _isActive = true;

    // We listen to motion to adjust BLE polling frequency based on activity.
    _motionSub = _motionService.motionStream.listen(_handleMotionData);

    if (_deviceDiscoveryService != null && !_discoveryCallbackRegistered) {
      _deviceDiscoveryService.onDevicesDiscovered(_handleDiscoveredDevices);
      _discoveryCallbackRegistered = true;
    }

    // Hook up physical location stream
    _startLocationStream();

    developer.log('Smart Passive Collection started', name: _logName);
  }

  void stop() {
    _isActive = false;
    _motionSub?.cancel();
    _motionSub = null;
    _locationSub?.cancel();
    _locationSub = null;
    developer.log('Smart Passive Collection stopped', name: _logName);
  }

  Future<void> _startLocationStream() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        developer.log('Location services are disabled.', name: _logName);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          developer.log('Location permissions are denied', name: _logName);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        developer.log('Location permissions are permanently denied',
            name: _logName);
        return;
      }

      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: 20, // Send an update only if moved 20 meters
      );

      _locationSub =
          Geolocator.getPositionStream(locationSettings: locationSettings)
              .listen((Position position) {
        recordPing(PassivePing(
          timestamp: position.timestamp,
          latitude: position.latitude,
          longitude: position.longitude,
        ));
      });

      developer.log('Started physical location stream for passive collection',
          name: _logName);
    } catch (e) {
      developer.log('Error starting location stream: $e', name: _logName);
    }
  }

  void recordPing(PassivePing ping) {
    if (!_isActive) return;

    _rawPingBuffer.add(ping);
    _clusterPings();
  }

  void recordEncounterFromDiscovery(DiscoveredDevice device) {
    if (!_isActive) return;
    final anchor = _resolveEncounterAnchor();
    if (anchor == null) {
      developer.log(
        'Skipping passive encounter capture because no location anchor is available yet',
        name: _logName,
      );
      return;
    }
    recordPing(
      PassivePing(
        timestamp: DateTime.now().toUtc(),
        latitude: anchor.lat,
        longitude: anchor.lon,
        encounterAgentId: _encounterIdentifier(device),
        encounterConfidence: device.proximityScore,
      ),
    );
  }

  void _handleMotionData(MotionData motion) {
    if (!_isActive || _deviceDiscoveryService == null) return;

    // Evaluate motion "energy" using rotation
    final motionEnergy = motion.rotation.alpha.abs() +
        motion.rotation.beta.abs() +
        motion.rotation.gamma.abs();

    if (motion.shake || motionEnergy > 1.5) {
      _highMotionTicks++;
      _lowMotionTicks = 0;
    } else {
      _lowMotionTicks++;
      _highMotionTicks = 0;
    }

    // Motion data runs at ~60fps, so 180 ticks is roughly 3 seconds
    if (_highMotionTicks > 180 && !_isCurrentlyActive) {
      _isCurrentlyActive = true;
      developer.log(
          'High activity detected (moving). Reducing BLE scan frequency to save battery.',
          name: _logName);

      // Moving fast -> lower chance of serendipitous dwell encounter -> scan less
      _deviceDiscoveryService.updateScanConfig(
        scanInterval: const Duration(seconds: 30),
        scanWindow: const Duration(seconds: 3),
      );
    } else if (_lowMotionTicks > 300 && _isCurrentlyActive) {
      // 300 ticks = ~5 seconds of stillness
      _isCurrentlyActive = false;
      developer.log(
          'Low activity detected (dwelling). Increasing BLE scan frequency to catch walk-bys.',
          name: _logName);

      // Sitting still -> high chance of serendipity -> scan more frequently
      _deviceDiscoveryService.updateScanConfig(
        scanInterval: const Duration(seconds: 5),
        scanWindow: const Duration(seconds: 4),
      );
    }
  }

  void _handleDiscoveredDevices(List<DiscoveredDevice> devices) {
    if (!_isActive || devices.isEmpty) {
      return;
    }
    for (final device in devices) {
      recordEncounterFromDiscovery(device);
    }
  }

  /// Extremely lightweight, non-LLM algorithm to compress raw pings into Dwell Events.
  /// This saves massive amounts of battery and context window tokens.
  void _clusterPings() {
    if (_rawPingBuffer.isEmpty) return;

    // 1. Sort by time just in case
    _rawPingBuffer.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final latestPing = _rawPingBuffer.last;

    // 2. Are we currently in an active dwell?
    if (_dwellClusters.isNotEmpty) {
      final currentDwell = _dwellClusters.last;

      final distance = _calculateDistanceMeters(currentDwell.latitude,
          currentDwell.longitude, latestPing.latitude, latestPing.longitude);

      if (distance <= _dwellRadiusMeters) {
        // Still dwelling! Extend the time.
        currentDwell.endTime = latestPing.timestamp;

        // Add any serendipitous encounters that happened while sitting here
        if (latestPing.encounterAgentId != null) {
          if (!currentDwell.encounteredAgentIds
              .contains(latestPing.encounterAgentId)) {
            currentDwell.encounteredAgentIds.add(latestPing.encounterAgentId!);
            developer.log('Added serendipitous encounter to current dwell',
                name: _logName);
          }
        }

        // Discard the raw ping, it's safely compressed
        _rawPingBuffer.removeLast();
        return;
      }
    }

    // 3. We are not in an active dwell, or we just moved far away from the last one.
    // Let's see if the remaining raw buffer constitutes a new dwell.
    if (_rawPingBuffer.length >= 2) {
      final oldest = _rawPingBuffer.first;
      final newest = _rawPingBuffer.last;

      final duration = newest.timestamp.difference(oldest.timestamp);

      if (duration >= _minDwellDuration) {
        // We've been hovering around here long enough to call it a dwell.
        final newDwell = DwellEvent(
          startTime: oldest.timestamp,
          endTime: newest.timestamp,
          // Average the coordinates roughly
          latitude:
              _rawPingBuffer.map((p) => p.latitude).reduce((a, b) => a + b) /
                  _rawPingBuffer.length,
          longitude:
              _rawPingBuffer.map((p) => p.longitude).reduce((a, b) => a + b) /
                  _rawPingBuffer.length,
        );

        // Gather any encounters that happened during this new dwell
        for (final p in _rawPingBuffer) {
          if (p.encounterAgentId != null &&
              !newDwell.encounteredAgentIds.contains(p.encounterAgentId)) {
            newDwell.encounteredAgentIds.add(p.encounterAgentId!);
          }
        }

        _dwellClusters.add(newDwell);
        _rawPingBuffer.clear();
        developer.log(
            'Formed new DwellEvent lasting ${duration.inMinutes} mins',
            name: _logName);
      }
    }
  }

  /// Haversine formula to calculate rough distance between two coordinates
  double _calculateDistanceMeters(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // Meters
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  ({double lat, double lon})? _resolveEncounterAnchor() {
    if (_rawPingBuffer.isNotEmpty) {
      final latest = _rawPingBuffer.last;
      return (lat: latest.latitude, lon: latest.longitude);
    }
    if (_dwellClusters.isNotEmpty) {
      final latest = _dwellClusters.last;
      return (lat: latest.latitude, lon: latest.longitude);
    }
    return null;
  }

  String _encounterIdentifier(DiscoveredDevice device) {
    final vibeSignature = device.personalityData?.vibeSignature.trim();
    if (vibeSignature != null && vibeSignature.isNotEmpty) {
      return vibeSignature;
    }
    return device.deviceId;
  }

  /// Called by the Nightly Batch Process to consume and clear the queue.
  List<DwellEvent> flushForBatchProcessing() {
    final copy = List<DwellEvent>.from(_dwellClusters);
    _dwellClusters.clear();
    return copy;
  }

  // Expose state for testing
  int get rawBufferSize => _rawPingBuffer.length;
  int get dwellClusterCount => _dwellClusters.length;
}

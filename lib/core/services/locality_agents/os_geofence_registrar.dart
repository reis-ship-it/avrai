import 'dart:developer' as developer;

/// Platform geofence registrar interface (v1).
///
/// This abstracts OS-level geofence registration (iOS region monitoring / Android geofencing).
/// In v1, we ship a no-op implementation so the planner can be exercised and validated
/// without requiring native background plumbing.
abstract class OsGeofenceRegistrarV1 {
  Future<void> registerGeofences(List<PlannedOsGeofenceV1> geofences);
  Future<void> clearAll();
}

class NoopOsGeofenceRegistrarV1 implements OsGeofenceRegistrarV1 {
  static const String _logName = 'NoopOsGeofenceRegistrarV1';

  @override
  Future<void> registerGeofences(List<PlannedOsGeofenceV1> geofences) async {
    developer.log(
      'No-op registerGeofences called (count=${geofences.length})',
      name: _logName,
    );
  }

  @override
  Future<void> clearAll() async {
    developer.log('No-op clearAll called', name: _logName);
  }
}

/// A single OS geofence registration request (v1).
class PlannedOsGeofenceV1 {
  final String id;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final Map<String, dynamic> metadata;

  const PlannedOsGeofenceV1({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    this.metadata = const {},
  });
}


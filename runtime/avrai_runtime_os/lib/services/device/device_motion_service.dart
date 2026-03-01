// Device Motion Service
//
// Provides accelerometer and gyroscope data for motion-reactive 3D visualizations.
// Part of Motion-Reactive 3D Visualization System.
//
// Features:
// - Accelerometer stream for gravity/tilt detection
// - Gyroscope stream for rotation detection
// - Low-pass filtering for smooth motion data
// - Shake detection
// - Platform-normalized data (iOS/Android)

import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Motion data representing device orientation and movement
class MotionData {
  /// Device tilt angles in radians
  /// x: pitch (front-to-back tilt, -π/2 to π/2)
  /// y: roll (left-to-right tilt, -π to π)
  final ({double x, double y}) tilt;

  /// Gravity direction vector (normalized)
  /// Points in direction of gravity relative to device
  final ({double x, double y, double z}) gravity;

  /// Device rotation rates in radians per second
  final ({double alpha, double beta, double gamma}) rotation;

  /// Whether a shake was detected this frame
  final bool shake;

  /// Timestamp of this reading
  final DateTime timestamp;

  const MotionData({
    required this.tilt,
    required this.gravity,
    required this.rotation,
    required this.shake,
    required this.timestamp,
  });

  /// Zero/neutral motion data
  static MotionData get zero => MotionData(
        tilt: (x: 0.0, y: 0.0),
        gravity: (x: 0.0, y: -1.0, z: 0.0),
        rotation: (alpha: 0.0, beta: 0.0, gamma: 0.0),
        shake: false,
        timestamp: DateTime.fromMillisecondsSinceEpoch(0),
      );

  /// Create zero motion data with current timestamp
  factory MotionData.neutral() {
    return MotionData(
      tilt: (x: 0.0, y: 0.0),
      gravity: (x: 0.0, y: -1.0, z: 0.0),
      rotation: (alpha: 0.0, beta: 0.0, gamma: 0.0),
      shake: false,
      timestamp: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'MotionData(tilt: (${tilt.x.toStringAsFixed(2)}, ${tilt.y.toStringAsFixed(2)}), '
        'shake: $shake)';
  }
}

/// Service for accessing device motion sensors
///
/// Provides unified accelerometer and gyroscope data with:
/// - Low-pass filtering for smooth motion
/// - Shake detection
/// - Platform normalization
/// - Configurable update rates
class DeviceMotionService {
  static const String _logName = 'DeviceMotionService';

  // Sensor subscriptions
  StreamSubscription<AccelerometerEvent>? _accelerometerSub;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSub;

  // Motion data stream
  final _motionController = StreamController<MotionData>.broadcast();

  // Low-pass filter state
  double _filteredAccelX = 0.0;
  double _filteredAccelY = 0.0;
  double _filteredAccelZ = 0.0;

  // Shake detection state
  double _lastAccelMagnitude = 0.0;
  DateTime? _lastShakeTime;
  static const double _shakeThreshold = 25.0; // m/s²
  static const Duration _shakeCooldown = Duration(milliseconds: 500);

  // Latest gyroscope data
  double _gyroAlpha = 0.0;
  double _gyroBeta = 0.0;
  double _gyroGamma = 0.0;

  // Filter coefficient (0-1, higher = smoother but more lag)
  final double _filterAlpha;

  // Whether service is active
  bool _isActive = false;

  // Sensitivity multiplier (0-1)
  double _sensitivity = 1.0;

  // Whether motion is enabled (accessibility setting)
  bool _motionEnabled = true;

  // Adaptive quality settings
  bool _adaptiveQualityEnabled = true;
  bool _isLowBattery = false;
  bool _isBackground = false;
  int _throttleMs = 16; // Default ~60fps
  DateTime? _lastEmitTime;

  // Battery monitoring
  final Battery _battery = Battery();
  StreamSubscription<BatteryState>? _batterySub;
  static const int _lowBatteryThreshold = 20;

  // App lifecycle
  AppLifecycleListener? _lifecycleListener;

  DeviceMotionService({
    double filterAlpha = 0.15,
  }) : _filterAlpha = filterAlpha {
    _initAdaptiveQuality();
  }

  void _initAdaptiveQuality() {
    // Monitor battery level
    _battery.batteryLevel.then((level) {
      _isLowBattery = level <= _lowBatteryThreshold;
      _adjustQuality();
    });

    _batterySub = _battery.onBatteryStateChanged.listen((state) {
      // Check battery level when state changes
      _battery.batteryLevel.then((level) {
        _isLowBattery = level <= _lowBatteryThreshold;
        _adjustQuality();
      });
    });

    // Monitor app lifecycle
    _lifecycleListener = AppLifecycleListener(
      onStateChange: (state) {
        _isBackground = state != AppLifecycleState.resumed;
        _adjustQuality();
      },
    );
  }

  void _adjustQuality() {
    if (!_adaptiveQualityEnabled) {
      _throttleMs = 16; // 60fps
      return;
    }

    if (_isBackground) {
      // Stop motion when in background
      _throttleMs = 1000; // 1fps essentially disabled
      developer.log('Motion throttled - app in background', name: _logName);
    } else if (_isLowBattery) {
      // Reduce to 30fps when battery is low
      _throttleMs = 33;
      developer.log('Motion throttled - low battery', name: _logName);
    } else {
      // Full 60fps
      _throttleMs = 16;
    }
  }

  /// Enable or disable adaptive quality
  void setAdaptiveQualityEnabled(bool enabled) {
    _adaptiveQualityEnabled = enabled;
    _adjustQuality();
    developer.log('Adaptive quality: $enabled', name: _logName);
  }

  /// Stream of motion data updates
  Stream<MotionData> get motionStream => _motionController.stream;

  /// Whether the service is currently active
  bool get isActive => _isActive;

  /// Current sensitivity (0-1)
  double get sensitivity => _sensitivity;

  /// Whether motion is enabled
  bool get motionEnabled => _motionEnabled;

  /// Start listening to motion sensors
  ///
  /// Call this when entering a screen with motion-reactive visualizations.
  Future<void> start() async {
    if (_isActive) return;

    developer.log('Starting device motion sensors', name: _logName);

    try {
      // Subscribe to accelerometer
      _accelerometerSub = accelerometerEventStream(
        samplingPeriod: const Duration(milliseconds: 16), // ~60fps
      ).listen(
        _onAccelerometerEvent,
        onError: (error) {
          developer.log(
            'Accelerometer error: $error',
            error: error,
            name: _logName,
          );
        },
      );

      // Subscribe to gyroscope
      _gyroscopeSub = gyroscopeEventStream(
        samplingPeriod: const Duration(milliseconds: 16),
      ).listen(
        _onGyroscopeEvent,
        onError: (error) {
          developer.log(
            'Gyroscope error: $error',
            error: error,
            name: _logName,
          );
        },
      );

      _isActive = true;
      developer.log('Device motion sensors started', name: _logName);
    } catch (e, st) {
      developer.log(
        'Failed to start motion sensors: $e',
        error: e,
        stackTrace: st,
        name: _logName,
      );
    }
  }

  /// Stop listening to motion sensors
  ///
  /// Call this when leaving a screen with motion-reactive visualizations
  /// to save battery.
  Future<void> stop() async {
    if (!_isActive) return;

    developer.log('Stopping device motion sensors', name: _logName);

    await _accelerometerSub?.cancel();
    await _gyroscopeSub?.cancel();

    _accelerometerSub = null;
    _gyroscopeSub = null;
    _isActive = false;

    developer.log('Device motion sensors stopped', name: _logName);
  }

  /// Set motion sensitivity (0-1)
  ///
  /// Lower values = less responsive motion effects
  void setSensitivity(double value) {
    _sensitivity = value.clamp(0.0, 1.0);
    developer.log('Motion sensitivity set to $_sensitivity', name: _logName);
  }

  /// Enable or disable motion effects
  ///
  /// When disabled, emits neutral motion data.
  /// Used for accessibility (reduce motion preference).
  void setMotionEnabled(bool enabled) {
    _motionEnabled = enabled;
    developer.log('Motion enabled: $_motionEnabled', name: _logName);

    if (!enabled) {
      // Emit neutral data when disabled
      _motionController.add(MotionData.neutral());
    }
  }

  void _onAccelerometerEvent(AccelerometerEvent event) {
    if (!_motionEnabled) {
      _motionController.add(MotionData.neutral());
      return;
    }

    // Throttle based on adaptive quality
    final currentTime = DateTime.now();
    if (_lastEmitTime != null) {
      final elapsed = currentTime.difference(_lastEmitTime!).inMilliseconds;
      if (elapsed < _throttleMs) {
        return; // Skip this update
      }
    }
    _lastEmitTime = currentTime;

    // Apply low-pass filter
    _filteredAccelX =
        _filterAlpha * event.x + (1 - _filterAlpha) * _filteredAccelX;
    _filteredAccelY =
        _filterAlpha * event.y + (1 - _filterAlpha) * _filteredAccelY;
    _filteredAccelZ =
        _filterAlpha * event.z + (1 - _filterAlpha) * _filteredAccelZ;

    // Detect shake
    final magnitude = math.sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );
    final deltaMagnitude = (magnitude - _lastAccelMagnitude).abs();
    _lastAccelMagnitude = magnitude;

    bool shake = false;
    final now = DateTime.now();
    if (deltaMagnitude > _shakeThreshold) {
      if (_lastShakeTime == null ||
          now.difference(_lastShakeTime!) > _shakeCooldown) {
        shake = true;
        _lastShakeTime = now;
        developer.log('Shake detected! Δ=$deltaMagnitude', name: _logName);
      }
    }

    // Calculate tilt from gravity
    // Normalize gravity vector
    final gravMag = math.sqrt(
      _filteredAccelX * _filteredAccelX +
          _filteredAccelY * _filteredAccelY +
          _filteredAccelZ * _filteredAccelZ,
    );

    double gravX = 0.0;
    double gravY = -1.0;
    double gravZ = 0.0;

    if (gravMag > 0.1) {
      gravX = _filteredAccelX / gravMag;
      gravY = _filteredAccelY / gravMag;
      gravZ = _filteredAccelZ / gravMag;
    }

    // Calculate tilt angles
    // Pitch: rotation around X axis (front-to-back)
    final pitch = math.atan2(gravY, gravZ);
    // Roll: rotation around Y axis (left-to-right)
    final roll = math.atan2(
      -gravX,
      math.sqrt(gravY * gravY + gravZ * gravZ),
    );

    // Apply sensitivity
    final adjustedPitch = pitch * _sensitivity;
    final adjustedRoll = roll * _sensitivity;

    final motionData = MotionData(
      tilt: (x: adjustedPitch, y: adjustedRoll),
      gravity: (x: gravX, y: gravY, z: gravZ),
      rotation: (alpha: _gyroAlpha, beta: _gyroBeta, gamma: _gyroGamma),
      shake: shake,
      timestamp: now,
    );

    _motionController.add(motionData);
  }

  void _onGyroscopeEvent(GyroscopeEvent event) {
    if (!_motionEnabled) return;

    // Store latest gyroscope values (will be included in next motion update)
    _gyroAlpha = event.x * _sensitivity;
    _gyroBeta = event.y * _sensitivity;
    _gyroGamma = event.z * _sensitivity;
  }

  /// Dispose of resources
  void dispose() {
    stop();
    _batterySub?.cancel();
    _lifecycleListener?.dispose();
    _motionController.close();
  }

  /// Get current adaptive quality status
  ({bool isLowBattery, bool isBackground, int throttleMs}) get adaptiveStatus {
    return (
      isLowBattery: _isLowBattery,
      isBackground: _isBackground,
      throttleMs: _throttleMs,
    );
  }
}

/// Motion sensitivity presets
enum MotionSensitivityPreset {
  /// No motion response
  off(0.0),

  /// Reduced motion for accessibility
  reduced(0.3),

  /// Normal motion response
  normal(0.7),

  /// Full motion response
  full(1.0);

  final double value;
  const MotionSensitivityPreset(this.value);
}

import 'dart:developer' as developer;
import 'dart:async';
import 'dart:math' as math;
import 'package:sensors_plus/sensors_plus.dart';
import 'package:vector_math/vector_math_64.dart';

/// A single fused orientation reading.
///
/// - `worldRotation`: Device rotation relative to world (fused accel + mag).
/// - `deviceDown`: Unit vector in **device coordinates** pointing "down"
///   (i.e. the direction of gravity), derived from accelerometer.
class WorldOrientationFrame {
  final Quaternion worldRotation;
  final Vector3 deviceDown;

  const WorldOrientationFrame({
    required this.worldRotation,
    required this.deviceDown,
  });
}

/// Service that provides a smooth, world-locked orientation stream.
///
/// It fuses Accelerometer (Gravity) and Magnetometer (Compass) data
/// to produce a stable Quaternion representing the device's rotation
/// relative to the Earth (North/East/Down).
class WorldOrientationService {
  // Singleton instance
  static final WorldOrientationService _instance = WorldOrientationService._internal();
  factory WorldOrientationService() => _instance;
  WorldOrientationService._internal();

  // Stream controllers
  final StreamController<Quaternion> _orientationController = StreamController<Quaternion>.broadcast();
  Stream<Quaternion> get orientationStream => _orientationController.stream;

  final StreamController<WorldOrientationFrame> _frameController =
      StreamController<WorldOrientationFrame>.broadcast();
  Stream<WorldOrientationFrame> get frameStream => _frameController.stream;

  // Sensor subscriptions
  StreamSubscription<AccelerometerEvent>? _accelSubscription;
  StreamSubscription<MagnetometerEvent>? _magSubscription;

  // Current sensor readings
  Vector3? _gravity;
  Vector3? _geomagnetic;

  // Smoothing
  Quaternion? _lastOrientation;
  // Slightly higher than before to reduce "laggy" feel while staying stable.
  static const double _smoothingFactor = 0.22;

  // Throttle orientation output so we don't rebuild/paint at sensor event rates.
  static const Duration _maxOutputInterval = Duration(milliseconds: 33); // ~30Hz
  DateTime _lastEmittedAt = DateTime.fromMillisecondsSinceEpoch(0);

  bool _isInitialized = false;

  /// Start listening to sensors
  Future<void> start() async {
    if (_isInitialized) return;

    try {
      // Set update interval to game rate (approx 60Hz)
      // Note: This is platform specific, sensors_plus handles it best effort
      
      _accelSubscription = accelerometerEventStream().listen((event) {
        _gravity = Vector3(event.x, event.y, event.z);
        _computeOrientation();
      });

      _magSubscription = magnetometerEventStream().listen((event) {
        _geomagnetic = Vector3(event.x, event.y, event.z);
        _computeOrientation();
      });

      _isInitialized = true;
    } catch (e) {
      // Handle sensor unavailability
      developer.log('Error starting WorldOrientationService: $e', name: 'WorldOrientationService');
    }
  }

  /// Stop listening to sensors to save battery
  void stop() {
    _accelSubscription?.cancel();
    _magSubscription?.cancel();
    _isInitialized = false;
    _lastOrientation = null;
  }

  void _computeOrientation() {
    if (_gravity == null || _geomagnetic == null) return;

    final now = DateTime.now();
    if (now.difference(_lastEmittedAt) < _maxOutputInterval) {
      // Skip work to avoid spamming repaints; we’ll catch up next tick.
      return;
    }

    // 1. Compute Rotation Matrix from Gravity and Geomagnetic
    // Android's SensorManager.getRotationMatrix equivalent
    // 
    // We want to find the basis vectors for the world frame relative to device.
    // Device coordinates: X (Right), Y (Up), Z (Out of screen) - typically
    // BUT sensors_plus (and Android) usually: X (Right), Y (Up), Z (Forward/Out)
    
    // Normalize gravity
    final g = _gravity!.normalized();
    
    // Normalize magnetic
    final m = _geomagnetic!.normalized();

    // H = M x G (East vector, tangent to ground)
    // Note: Cross product order depends on coordinate system.
    // Assuming standard Android:
    // G points roughly DOWN (0, 9.8, 0) when flat? No, (0,0,9.8) when flat on back.
    // Let's assume standard conventions.
    
    final h = m.cross(g).normalized();
    final mPrime = g.cross(h).normalized(); // True North, tangent to ground

    // Rotation Matrix R transforms from Device to World.
    // R = [H, M', G] (cols)
    // But we usually want World to Device or vice-versa for the camera.
    // 
    // For the shader, we likely want the camera's rotation in world space.
    
    final rMatrix = Matrix3(
      h.x, mPrime.x, g.x,
      h.y, mPrime.y, g.y,
      h.z, mPrime.z, g.z,
    );

    // 2. Convert to Quaternion
    final targetOrientation = Quaternion.fromRotation(rMatrix);

    // 3. Smooth (SLERP)
    if (_lastOrientation != null) {
      _lastOrientation = _slerp(_lastOrientation!, targetOrientation, _smoothingFactor);
    } else {
      _lastOrientation = targetOrientation;
    }

    _lastEmittedAt = now;
    final current = _lastOrientation!;
    _orientationController.add(current);

    // Derive a "down" vector in device coordinates from accelerometer.
    // Accelerometer measures proper acceleration (up), so negate to get down.
    final deviceDown = Vector3(-g.x, -g.y, -g.z);
    _frameController.add(
      WorldOrientationFrame(
        worldRotation: current,
        deviceDown: deviceDown,
      ),
    );
  }

  /// Spherical linear interpolation
  Quaternion _slerp(Quaternion a, Quaternion b, double t) {
    double cosHalfTheta = a.x * b.x + a.y * b.y + a.z * b.z + a.w * b.w;
    
    // If the dot product is negative, the quaternions
    // have opposite-handedness and slerp won't take
    // the shorter path. Fix by reversing one quaternion.
    var bTarget = b;
    if (cosHalfTheta < 0) {
      bTarget = Quaternion(-b.x, -b.y, -b.z, -b.w);
      cosHalfTheta = -cosHalfTheta;
    }
    
    if (cosHalfTheta >= 1.0) {
      return a;
    }
    
    final double halfTheta = math.acos(cosHalfTheta);
    final double sinHalfTheta = math.sqrt(1.0 - cosHalfTheta * cosHalfTheta);
    
    if (sinHalfTheta < 0.001) {
      // If the angle is small, use linear interpolation
      return Quaternion(
        (a.x * 0.5 + bTarget.x * 0.5),
        (a.y * 0.5 + bTarget.y * 0.5),
        (a.z * 0.5 + bTarget.z * 0.5),
        (a.w * 0.5 + bTarget.w * 0.5),
      )..normalize();
    }
    
    final double ratioA = math.sin((1 - t) * halfTheta) / sinHalfTheta;
    final double ratioB = math.sin(t * halfTheta) / sinHalfTheta;
    
    return Quaternion(
      (a.x * ratioA + bTarget.x * ratioB),
      (a.y * ratioA + bTarget.y * ratioB),
      (a.z * ratioA + bTarget.z * ratioB),
      (a.w * ratioA + bTarget.w * ratioB),
    );
  }
}

import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:avrai_runtime_os/services/device/world_orientation_service.dart';

/// The immersive 3D background of the Portal Design System.
///
/// It renders a procedurally generated world using a GLSL fragment shader.
/// The view is "World-Locked" using sensor fusion, meaning if you turn
/// your phone North, you see the virtual North.
class PortalShaderWidget extends StatefulWidget {
  /// Global rotation notifier for parallax effects in other widgets
  static final ValueNotifier<Quaternion> rotationNotifier =
      ValueNotifier(Quaternion.identity());

  const PortalShaderWidget({super.key});

  @override
  State<PortalShaderWidget> createState() => _PortalShaderWidgetState();
}

class _PortalShaderWidgetState extends State<PortalShaderWidget>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  ui.FragmentProgram? _program;

  // Day/Night Cycle (0.0 = Night, 1.0 = Day)
  // Synced to real-world system time
  double get _dayCycle {
    final now = DateTime.now();
    final hours = now.hour + now.minute / 60.0 + now.second / 3600.0;
    // Sine wave mapping: 0:00 -> ~0.0 (Night), 12:00 -> 1.0 (Day)
    return (math.sin((hours - 6) / 24.0 * 2 * math.pi) + 1.0) / 2.0;
  }

  StreamSubscription<WorldOrientationFrame>? _orientationSubscription;
  final WorldOrientationService _orientationService = WorldOrientationService();

  // Drives repaints without rebuilding the widget tree every frame.
  final _repaint = _PortalRepaintController();

  @override
  void initState() {
    super.initState();
    _loadShader();

    // Start the animation loop
    _ticker = createTicker(_onTick)..start();

    // Start sensor fusion
    _orientationService.start();
    _orientationSubscription = _orientationService.frameStream.listen((frame) {
      // Keep the horizon "upright" even if the device boots rotated.
      _repaint.uprightCorrection = _computeUprightCorrection(frame.deviceDown);
      // Update orientation and repaint; no setState needed.
      _repaint.cameraRotation = frame.worldRotation;
      PortalShaderWidget.rotationNotifier.value = frame.worldRotation;
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    _orientationSubscription?.cancel();
    _orientationService.stop();
    _repaint.dispose();
    super.dispose();
  }

  /// Compute a roll correction so "screen down" is always down.
  ///
  /// This uses the accelerometer-derived gravity direction in device coords.
  /// It fixes cases where devices boot in landscape (or have a landscape-native
  /// sensor frame), without relying on `MediaQuery.orientation` heuristics.
  Quaternion _computeUprightCorrection(Vector3 deviceDown) {
    // If the device is nearly flat, XY projection is unstable; keep last value.
    final xyLen2 = deviceDown.x * deviceDown.x + deviceDown.y * deviceDown.y;
    if (xyLen2 < 0.02) return _repaint.uprightCorrection;

    // Rotate around Z so deviceDown projects to (0, -1) (screen-bottom).
    final angle = math.atan2(-deviceDown.x, -deviceDown.y);
    return Quaternion.axisAngle(Vector3(0, 0, 1), angle);
  }

  Future<void> _loadShader() async {
    try {
      final program =
          await ui.FragmentProgram.fromAsset('shaders/portal_world.frag');
      if (mounted) {
        setState(() {
          _program = program;
        });
      }
    } catch (e) {
      developer.log('Failed to load portal shader: $e',
          name: 'PortalShaderWidget');
    }
  }

  void _onTick(Duration elapsed) {
    _repaint.time = elapsed.inMilliseconds / 1000.0;
  }

  @override
  Widget build(BuildContext context) {
    if (_program == null) {
      // Fallback while loading (Deep Blue/Black)
      return Container(color: const Color(0xFF0A1A2F));
    }

    return CustomPaint(
      size: Size.infinite,
      painter: _PortalShaderPainter(
        program: _program!,
        repaintController: _repaint,
        dayCycle: _dayCycle,
      ),
    );
  }
}

class _PortalRepaintController extends ChangeNotifier {
  double _time = 0.0;
  Quaternion _cameraRotation = Quaternion.identity();
  Quaternion _uprightCorrection = Quaternion.identity();

  double get time => _time;
  Quaternion get cameraRotation => _cameraRotation;
  Quaternion get uprightCorrection => _uprightCorrection;

  set time(double v) {
    _time = v;
    notifyListeners();
  }

  set cameraRotation(Quaternion q) {
    _cameraRotation = q;
    notifyListeners();
  }

  set uprightCorrection(Quaternion q) {
    _uprightCorrection = q;
    notifyListeners();
  }
}

class _PortalShaderPainter extends CustomPainter {
  final ui.FragmentProgram program;
  final _PortalRepaintController repaintController;
  final double dayCycle;

  _PortalShaderPainter({
    required this.program,
    required this.repaintController,
    required this.dayCycle,
  }) : super(repaint: repaintController);

  @override
  void paint(Canvas canvas, Size size) {
    final shader = program.fragmentShader();

    // Uniforms matching GLSL:
    // 0: uResolution (vec2)
    // 1: uTime (float)
    // 2: uCameraRotation (vec4)
    // 3: uDayCycle (float)

    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    shader.setFloat(2, repaintController.time);

    // Upright correction: roll the camera frame so "down" is always down.
    final q =
        repaintController.uprightCorrection * repaintController.cameraRotation;

    shader.setFloat(3, q.x);
    shader.setFloat(4, q.y);
    shader.setFloat(5, q.z);
    shader.setFloat(6, q.w);
    shader.setFloat(7, dayCycle);

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..shader = shader,
    );
  }

  @override
  bool shouldRepaint(covariant _PortalShaderPainter oldDelegate) {
    // Repaint is driven by the repaint listenable; only change when shader/program changes.
    return oldDelegate.program != program || oldDelegate.dayCycle != dayCycle;
  }
}

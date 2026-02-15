// Knot 3D Widget
//
// Widget for 3D visualization of personality knots using Three.js WebView
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Phase 1: 3D Knot Visualization and Conversion
// Updated: Now uses Three.js for true 3D rendering with WebGL

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart' hide Colors;
import 'package:avrai/core/theme/colors.dart';

import 'package:get_it/get_it.dart';
import 'package:vector_math/vector_math.dart';
import 'package:avrai_core/models/personality_knot.dart';
import 'package:avrai_knot/models/knot/knot_3d.dart';
import 'package:avrai_knot/services/knot/knot_3d_converter_service.dart';
import 'package:avrai/core/models/misc/visualization_style.dart';
import 'package:avrai/core/models/misc/motion_reactivity_config.dart';
import 'package:avrai/core/services/device/device_motion_service.dart';
import 'package:avrai/core/services/visualization/three_js_bridge_service.dart';
import 'package:avrai/presentation/widgets/visualization/three_js_visualization_widget.dart';

/// Widget for 3D visualization of personality knots
///
/// Features:
/// - True 3D rendering with Three.js WebGL
/// - Interactive 3D view (rotation, zoom, pan via OrbitControls)
/// - Metallic tube geometry with proper lighting
/// - Color coding based on knot invariants
/// - Post-processing effects (bloom, glow)
/// - Falls back to CustomPainter if WebView unavailable
class Knot3DWidget extends StatefulWidget {
  final PersonalityKnot knot;
  final double size;
  final bool showControls;
  final Color? color;
  final Knot3DConverterService? converterService;

  /// Whether to use Three.js WebView (true) or fallback CustomPainter (false)
  final bool useThreeJs;

  /// Visualization style preset
  final KnotVisualizationStyle? style;

  // Motion-Reactive 3D Visualization System properties

  /// Whether to show bubble container around knot
  final bool showBubble;

  /// Bubble container style
  final BubbleStyle bubbleStyle;

  /// Motion reactivity configuration
  final MotionReactivityConfig? motionConfig;

  /// Whether to enable device motion response
  final bool enableMotion;

  const Knot3DWidget({
    super.key,
    required this.knot,
    this.size = 300.0,
    this.showControls = true,
    this.color,
    this.converterService,
    this.useThreeJs = true,
    this.style,
    this.showBubble = false,
    this.bubbleStyle = BubbleStyle.glass,
    this.motionConfig,
    this.enableMotion = true,
  });

  @override
  State<Knot3DWidget> createState() => _Knot3DWidgetState();
}

class _Knot3DWidgetState extends State<Knot3DWidget>
    with SingleTickerProviderStateMixin {
  Knot3D? _knot3d;
  bool _isLoading = true;
  String? _error;
  ThreeJsBridgeService? _bridge;
  bool _threeJsReady = false;

  // Rotation state (for fallback CustomPainter)
  double _rotationX = 0.0;
  double _rotationY = 0.0;
  double _zoom = 1.0;
  Offset _panOffset = Offset.zero;

  // Gesture tracking
  Offset? _lastPanPosition;

  // Motion-Reactive 3D Visualization System
  DeviceMotionService? _motionService;
  StreamSubscription<MotionData>? _motionSubscription;
  late MotionReactivityConfig _motionConfig;

  @override
  void initState() {
    super.initState();
    _motionConfig = widget.motionConfig ?? MotionReactivityConfig.profileKnot();
    _initMotionService();
    _load3DKnot();
  }

  void _initMotionService() {
    if (!widget.enableMotion) return;

    try {
      _motionService = GetIt.I<DeviceMotionService>();
    } catch (e) {
      // DeviceMotionService not registered - motion disabled
    }
  }

  Future<void> _load3DKnot() async {
    try {
      final converter = widget.converterService ?? Knot3DConverterService();
      final knot3d = converter.convertTo3D(widget.knot);

      if (mounted) {
        setState(() {
          _knot3d = knot3d;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _onThreeJsReady(ThreeJsBridgeService bridge) {
    _bridge = bridge;
    _threeJsReady = true;

    // Render the knot in Three.js
    if (_knot3d != null) {
      _renderKnotInThreeJs();
    }

    // Setup motion after rendering
    _setupMotion();
  }

  void _setupMotion() {
    if (!widget.enableMotion || _motionService == null || _bridge == null) {
      return;
    }

    // Start motion service
    _motionService!.start();

    // Configure motion reactivity
    _bridge!.setMotionReactivity(
      reactivity: _motionConfig.reactivity.name,
      physicsBehavior: _motionConfig.physicsBehavior.name,
      tiltSensitivity: _motionConfig.tiltSensitivity,
      damping: _motionConfig.damping,
      shakeEnabled: _motionConfig.shakeEnabled,
    );

    // Enable bubble if configured
    if (widget.showBubble) {
      _bridge!.setBubbleContainer(
        enabled: true,
        style: widget.bubbleStyle.name,
      );
    }

    // Add physics to knot
    _bridge!.addPhysicsToKnot(
      behavior: _motionConfig.physicsBehavior.name,
    );

    // Subscribe to motion updates
    _motionSubscription = _motionService!.motionStream.listen(_onMotionUpdate);
  }

  void _onMotionUpdate(MotionData motion) {
    if (!_threeJsReady || _bridge == null) return;

    _bridge!.updateDeviceMotion(
      tiltX: motion.tilt.x,
      tiltY: motion.tilt.y,
      gravityX: motion.gravity.x,
      gravityY: motion.gravity.y,
      gravityZ: motion.gravity.z,
      shake: motion.shake,
    );

    // Handle shake
    if (motion.shake && _motionConfig.shakeEnabled) {
      _resetView();
    }
  }

  @override
  void dispose() {
    _motionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _renderKnotInThreeJs() async {
    if (_bridge == null || _knot3d == null) return;

    final isSmallSize = widget.size <= 100;
    final lod = isSmallSize
        ? VisualizationLOD.low
        : widget.size <= 200
            ? VisualizationLOD.medium
            : VisualizationLOD.high;

    final style = widget.style ??
        KnotVisualizationStyle.metallic(
          primaryColor:
              widget.color?.toHex() ?? AppColors.electricGreen.toHex(),
          lod: lod,
        ).copyWith(
          autoRotate: isSmallSize,
          autoRotateSpeed: 0.3,
        );

    await _bridge!.renderKnot(
      knot: _knot3d!,
      style: style,
      tubeRadius: isSmallSize ? 0.08 : 0.1,
    );
  }

  void _handlePanStart(DragStartDetails details) {
    _lastPanPosition = details.localPosition;
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_lastPanPosition == null) return;

    final delta = details.localPosition - _lastPanPosition!;

    setState(() {
      // Rotate based on pan
      _rotationY += delta.dx * 0.01;
      _rotationX += delta.dy * 0.01;

      // Clamp rotation
      _rotationX = _rotationX.clamp(-math.pi / 2, math.pi / 2);

      _lastPanPosition = details.localPosition;
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    _lastPanPosition = null;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      _zoom *= details.scale;
      _zoom = _zoom.clamp(0.5, 3.0);
    });
  }

  void _resetView() {
    if (_bridge != null && _threeJsReady) {
      _bridge!.resetCamera();
    } else {
      setState(() {
        _rotationX = 0.0;
        _rotationY = 0.0;
        _zoom = 1.0;
        _panOffset = Offset.zero;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_error != null) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: Center(
          child: Icon(
            Icons.error_outline,
            size: widget.size * 0.5,
            color: AppColors.error,
          ),
        ),
      );
    }

    if (_knot3d == null) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: Center(
          child: Icon(
            Icons.account_circle,
            size: widget.size * 0.7,
            color: AppColors.grey400,
          ),
        ),
      );
    }

    // Use Three.js WebView for true 3D rendering
    if (widget.useThreeJs) {
      return _buildThreeJsVisualization();
    }

    // Fallback to CustomPainter for simple 2D projection
    return _buildFallbackVisualization();
  }

  Widget _buildThreeJsVisualization() {
    return ThreeJsVisualizationWidget(
      size: widget.size,
      onReady: _onThreeJsReady,
      showControls: widget.showControls,
      backgroundColor: AppColors.black,
    );
  }

  Widget _buildFallbackVisualization() {
    // For small sizes (profile images), disable controls and auto-rotate
    final isSmallSize = widget.size <= 100;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 3D visualization (CustomPainter fallback)
        GestureDetector(
          onPanStart: isSmallSize ? null : _handlePanStart,
          onPanUpdate: isSmallSize ? null : _handlePanUpdate,
          onPanEnd: isSmallSize ? null : _handlePanEnd,
          onScaleUpdate: isSmallSize ? null : _handleScaleUpdate,
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: CustomPaint(
              painter: Knot3DPainter(
                knot3d: _knot3d!,
                rotationX: isSmallSize ? 0.3 : _rotationX,
                rotationY: isSmallSize ? 0.5 : _rotationY,
                zoom: isSmallSize ? 0.8 : _zoom,
                panOffset: _panOffset,
                color: widget.color ?? AppColors.primary,
              ),
            ),
          ),
        ),

        // Controls
        if (widget.showControls) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _resetView,
                tooltip: 'Reset view',
              ),
              IconButton(
                icon: const Icon(Icons.zoom_in),
                onPressed: () {
                  setState(() {
                    _zoom = (_zoom * 1.2).clamp(0.5, 3.0);
                  });
                },
                tooltip: 'Zoom in',
              ),
              IconButton(
                icon: const Icon(Icons.zoom_out),
                onPressed: () {
                  setState(() {
                    _zoom = (_zoom / 1.2).clamp(0.5, 3.0);
                  });
                },
                tooltip: 'Zoom out',
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Custom painter for 3D knot visualization
///
/// Uses 3D to 2D projection (isometric/perspective)
class Knot3DPainter extends CustomPainter {
  final Knot3D knot3d;
  final double rotationX;
  final double rotationY;
  final double zoom;
  final Offset panOffset;
  final Color color;

  Knot3DPainter({
    required this.knot3d,
    required this.rotationX,
    required this.rotationY,
    required this.zoom,
    required this.panOffset,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Project 3D coordinates to 2D
    final projectedPoints = <Offset>[];

    for (final coord in knot3d.coordinates) {
      // Apply rotations
      var rotated = _rotateX(coord, rotationX);
      rotated = _rotateY(rotated, rotationY);

      // Apply zoom
      rotated = rotated * zoom;

      // Project to 2D (isometric projection)
      final x2d = center.dx + rotated.x + rotated.z * 0.5;
      final y2d = center.dy + rotated.y - rotated.z * 0.5;

      projectedPoints.add(Offset(x2d, y2d));
    }

    // Draw knot curve
    if (projectedPoints.length > 1) {
      final path = Path();
      path.moveTo(projectedPoints[0].dx, projectedPoints[0].dy);

      for (int i = 1; i < projectedPoints.length; i++) {
        path.lineTo(projectedPoints[i].dx, projectedPoints[i].dy);
      }

      // Close the path
      path.close();

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..color = color;

      canvas.drawPath(path, paint);
    }

    // Draw crossings
    final crossingPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = color;

    for (final crossing in knot3d.crossings) {
      var rotated = _rotateX(crossing.position, rotationX);
      rotated = _rotateY(rotated, rotationY);
      rotated = rotated * zoom;

      final x2d = center.dx + rotated.x + rotated.z * 0.5;
      final y2d = center.dy + rotated.y - rotated.z * 0.5;

      // Draw crossing indicator
      canvas.drawCircle(
        Offset(x2d, y2d),
        5.0,
        crossingPaint,
      );

      // Draw over/under indicator
      if (crossing.isOver) {
        final overPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..color = AppColors.white;
        canvas.drawCircle(Offset(x2d, y2d), 3.0, overPaint);
      }
    }
  }

  /// Rotate point around X axis
  Vector3 _rotateX(Vector3 point, double angle) {
    final cos = math.cos(angle);
    final sin = math.sin(angle);

    return Vector3(
      point.x,
      point.y * cos - point.z * sin,
      point.y * sin + point.z * cos,
    );
  }

  /// Rotate point around Y axis
  Vector3 _rotateY(Vector3 point, double angle) {
    final cos = math.cos(angle);
    final sin = math.sin(angle);

    return Vector3(
      point.x * cos + point.z * sin,
      point.y,
      -point.x * sin + point.z * cos,
    );
  }

  @override
  bool shouldRepaint(Knot3DPainter oldDelegate) {
    return oldDelegate.knot3d != knot3d ||
        oldDelegate.rotationX != rotationX ||
        oldDelegate.rotationY != rotationY ||
        oldDelegate.zoom != zoom ||
        oldDelegate.panOffset != panOffset ||
        oldDelegate.color != color;
  }
}

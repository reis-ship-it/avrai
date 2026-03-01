// Worldsheet 4D Widget
//
// Widget for 4D visualization of worldsheet evolution (3D space + time)
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Medium Priority: 4D Worldsheet Visualization
// Updated: Now uses Three.js for true 3D parametric surface visualization

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart' hide Colors;
import 'package:flutter/scheduler.dart';
import 'package:avrai/theme/colors.dart';

import 'package:get_it/get_it.dart';
import 'package:vector_math/vector_math.dart';
import 'package:avrai_runtime_os/runtime_api.dart';
import 'package:avrai_core/models/misc/visualization_style.dart';
import 'package:avrai_core/models/misc/motion_reactivity_config.dart';
import 'package:avrai_runtime_os/services/device/device_motion_service.dart';
import 'package:avrai_runtime_os/services/visualization/three_js_bridge_service.dart';
import 'package:avrai/presentation/widgets/visualization/three_js_visualization_widget.dart';

/// Widget for 4D worldsheet visualization (3D space + time dimension)
///
/// **Features (Three.js mode):**
/// - Parametric surface rendering with Three.js WebGL
/// - Semi-transparent material with wireframe overlay
/// - Time-based surface deformation
/// - Morph targets for smooth time scrubbing
/// - Interactive 3D view (rotation, zoom, pan via OrbitControls)
/// - Time slider with animation controls
///
/// **Features (Fallback mode):**
/// - Interactive 3D view (rotation, zoom, pan)
/// - Time scrubbing (slider to navigate through time)
/// - Animation mode (play/pause timeline)
/// - Multiple strand visualization (one per user)
/// - Color coding based on fabric invariants
class Worldsheet4DWidget extends StatefulWidget {
  final KnotWorldsheet worldsheet;
  final double size;
  final bool showControls;
  final Worldsheet4DVisualizationService? visualizationService;

  /// Whether to use Three.js WebView (true) or fallback CustomPainter (false)
  final bool useThreeJs;

  // Motion-Reactive 3D Visualization System properties

  /// Motion reactivity configuration
  final MotionReactivityConfig? motionConfig;

  /// Whether to enable device motion response (tilt to time-scrub)
  final bool enableMotion;

  const Worldsheet4DWidget({
    super.key,
    required this.worldsheet,
    this.size = 400.0,
    this.showControls = true,
    this.visualizationService,
    this.useThreeJs = true,
    this.motionConfig,
    this.enableMotion = true,
  });

  @override
  State<Worldsheet4DWidget> createState() => _Worldsheet4DWidgetState();
}

class _Worldsheet4DWidgetState extends State<Worldsheet4DWidget>
    with TickerProviderStateMixin {
  Worldsheet4DData? _worldsheet4d;
  bool _isLoading = true;
  String? _error;
  ThreeJsBridgeService? _bridge;
  bool _threeJsReady = false;

  // Time state
  DateTime _currentTime = DateTime.now();
  bool _isPlaying = false;
  late AnimationController _animationController;

  // Rotation state (for fallback CustomPainter)
  double _rotationX = 0.3;
  double _rotationY = 0.5;
  double _zoom = 1.0;
  Offset _panOffset = Offset.zero;

  // Gesture tracking
  Offset? _lastPanPosition;

  // Motion-Reactive 3D Visualization System
  DeviceMotionService? _motionService;
  StreamSubscription<MotionData>? _motionSubscription;
  late MotionReactivityConfig _motionConfig;
  double _tiltAccumulator = 0.0; // For tilt-based time scrubbing

  // Performance optimization: Caching and LOD
  // Cache key: (timeIndex, rotationX, rotationY, zoom, panOffset)
  Map<String, List<List<Offset>>>? _cachedProjections;

  // Performance constants
  static const int _maxVisibleStrands = 100; // Limit strands for 100+ users
  static const double _lodZoomThreshold = 0.8; // Below this zoom, reduce detail

  @override
  void initState() {
    super.initState();
    _motionConfig = widget.motionConfig ?? MotionReactivityConfig.worldsheet();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..addListener(_onAnimationTick);
    _initMotionService();
    _load4DData();
  }

  void _initMotionService() {
    if (!widget.enableMotion) return;

    try {
      _motionService = GetIt.I<DeviceMotionService>();
    } catch (e) {
      // DeviceMotionService not registered
    }
  }

  @override
  void dispose() {
    _motionSubscription?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _onThreeJsReady(ThreeJsBridgeService bridge) {
    _bridge = bridge;
    _threeJsReady = true;

    if (_worldsheet4d != null) {
      _renderWorldsheetInThreeJs();
    }

    _setupMotion();
  }

  void _setupMotion() {
    if (!widget.enableMotion || _motionService == null || _bridge == null) {
      return;
    }

    _motionService!.start();

    // Configure motion reactivity for worldsheet (tilt to time-scrub)
    _bridge!.setMotionReactivity(
      reactivity: _motionConfig.reactivity.name,
      physicsBehavior: 'parallax',
      tiltSensitivity: _motionConfig.tiltSensitivity,
      damping: _motionConfig.damping,
      shakeEnabled: _motionConfig.shakeEnabled,
    );

    // Subscribe to motion updates
    _motionSubscription = _motionService!.motionStream.listen(_onMotionUpdate);
  }

  void _onMotionUpdate(MotionData motion) {
    if (_bridge == null || !_threeJsReady) return;

    // Send basic motion for parallax
    _bridge!.updateDeviceMotion(
      tiltX: motion.tilt.x,
      tiltY: motion.tilt.y,
      gravityX: motion.gravity.x,
      gravityY: motion.gravity.y,
      gravityZ: motion.gravity.z,
      shake: motion.shake,
    );

    // Tilt-based time scrubbing (when playing is paused)
    if (!_isPlaying && _worldsheet4d != null) {
      // Accumulate horizontal tilt for time scrubbing
      _tiltAccumulator += motion.tilt.y * 0.01;

      // Map accumulator to time position
      final timeRange =
          _worldsheet4d!.endTime.difference(_worldsheet4d!.startTime);
      final currentProgress =
          _currentTime.difference(_worldsheet4d!.startTime).inMilliseconds /
              timeRange.inMilliseconds;
      final newProgress = (currentProgress + _tiltAccumulator).clamp(0.0, 1.0);

      if ((newProgress - currentProgress).abs() > 0.01) {
        _tiltAccumulator = 0.0; // Reset accumulator after applying
        setState(() {
          _currentTime = _worldsheet4d!.startTime.add(
            Duration(
                milliseconds: (timeRange.inMilliseconds * newProgress).round()),
          );
        });
        _bridge!.setAnimationTime(newProgress);
      }
    }

    // Shake resets to beginning
    if (motion.shake && _motionConfig.shakeEnabled) {
      setState(() {
        _currentTime = _worldsheet4d?.startTime ?? DateTime.now();
        _tiltAccumulator = 0.0;
      });
      _bridge!.setAnimationTime(0.0);
    }
  }

  Future<void> _renderWorldsheetInThreeJs() async {
    if (_bridge == null || _worldsheet4d == null) return;

    final style = WorldsheetVisualizationStyle.flowing(
      lod: widget.size <= 300 ? VisualizationLOD.medium : VisualizationLOD.high,
    );

    await _bridge!.renderWorldsheet(
      worldsheet: _worldsheet4d!,
      style: style,
      timePosition: _getTimeSliderValue(),
    );
  }

  void _updateThreeJsTime() {
    if (_bridge != null && _threeJsReady) {
      _bridge!.setAnimationTime(_getTimeSliderValue());
    }
  }

  Future<void> _load4DData() async {
    try {
      final service =
          widget.visualizationService ?? Worldsheet4DVisualizationService();

      final worldsheet4d = await service.convertTo4DData(
        worldsheet: widget.worldsheet,
        timeStep: const Duration(hours: 1), // 1 hour intervals
      );

      if (mounted) {
        setState(() {
          _worldsheet4d = worldsheet4d;
          _currentTime = worldsheet4d.startTime;
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

  void _onAnimationTick() {
    if (!_isPlaying || _worldsheet4d == null) return;

    final progress = _animationController.value;
    final duration =
        _worldsheet4d!.endTime.difference(_worldsheet4d!.startTime);
    final currentOffset = Duration(
      milliseconds: (duration.inMilliseconds * progress).round(),
    );

    setState(() {
      _currentTime = _worldsheet4d!.startTime.add(currentOffset);
    });
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        // Calculate animation progress based on current time
        if (_worldsheet4d != null) {
          final duration =
              _worldsheet4d!.endTime.difference(_worldsheet4d!.startTime);
          final currentOffset =
              _currentTime.difference(_worldsheet4d!.startTime);
          final progress = duration.inMilliseconds > 0
              ? (currentOffset.inMilliseconds / duration.inMilliseconds)
                  .clamp(0.0, 1.0)
              : 0.0;
          _animationController.value = progress;
        }
        _animationController.repeat();
      } else {
        _animationController.stop();
      }
    });
  }

  void _onTimeSliderChanged(double value) {
    if (_worldsheet4d == null) return;

    final duration =
        _worldsheet4d!.endTime.difference(_worldsheet4d!.startTime);
    final offset = Duration(
      milliseconds: (duration.inMilliseconds * value).round(),
    );

    setState(() {
      _currentTime = _worldsheet4d!.startTime.add(offset);
      if (_isPlaying) {
        _animationController.value = value;
      }
    });

    // Update Three.js time if using WebGL
    _updateThreeJsTime();
  }

  double _getTimeSliderValue() {
    if (_worldsheet4d == null) return 0.0;

    final duration =
        _worldsheet4d!.endTime.difference(_worldsheet4d!.startTime);
    if (duration.inMilliseconds == 0) return 0.0;

    final currentOffset = _currentTime.difference(_worldsheet4d!.startTime);
    return (currentOffset.inMilliseconds / duration.inMilliseconds)
        .clamp(0.0, 1.0);
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _lastPanPosition = details.localFocalPoint;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      _zoom *= details.scale;
      _zoom = _zoom.clamp(0.5, 3.0);
      if (_lastPanPosition != null) {
        final delta = details.localFocalPoint - _lastPanPosition!;
        _rotationY += delta.dx * 0.01;
        _rotationX += delta.dy * 0.01;
        _rotationX = _rotationX.clamp(-math.pi / 2, math.pi / 2);
      }
      _lastPanPosition = details.localFocalPoint;
    });
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    _lastPanPosition = null;
  }

  void _resetView() {
    if (_bridge != null && _threeJsReady) {
      _bridge!.resetCamera();
    } else {
      setState(() {
        _rotationX = 0.3;
        _rotationY = 0.5;
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
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: widget.size * 0.2,
                color: AppColors.error,
              ),
              const SizedBox(height: 8),
              Text(
                'Error loading worldsheet',
                style: TextStyle(color: AppColors.error),
              ),
            ],
          ),
        ),
      );
    }

    if (_worldsheet4d == null || _worldsheet4d!.fabricData.isEmpty) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.group,
                size: widget.size * 0.2,
                color: AppColors.grey400,
              ),
              const SizedBox(height: 8),
              Text(
                'No worldsheet data',
                style: TextStyle(color: AppColors.grey400),
              ),
            ],
          ),
        ),
      );
    }

    // Build with Three.js or fallback
    if (widget.useThreeJs) {
      return _buildThreeJsVisualization();
    }

    return _buildFallbackVisualization();
  }

  Widget _buildThreeJsVisualization() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Three.js visualization
        ThreeJsVisualizationWidget(
          size: widget.size,
          onReady: _onThreeJsReady,
          showControls: false,
          backgroundColor: AppColors.black,
        ),

        // Time controls
        if (widget.showControls) _buildTimeControls(),
      ],
    );
  }

  Widget _buildFallbackVisualization() {
    // Get fabric data at current time
    final fabric3d = _worldsheet4d!.getFabricAtTime(_currentTime);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 3D visualization (CustomPainter fallback)
        GestureDetector(
          onScaleStart: _handleScaleStart,
          onScaleUpdate: _handleScaleUpdate,
          onScaleEnd: _handleScaleEnd,
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: CustomPaint(
              painter: Worldsheet4DPainter(
                fabric3d: fabric3d,
                rotationX: _rotationX,
                rotationY: _rotationY,
                zoom: _zoom,
                panOffset: _panOffset,
                maxVisibleStrands: _maxVisibleStrands,
                lodZoomThreshold: _lodZoomThreshold,
                cachedProjections: _cachedProjections,
                onProjectionsCached: (key, projections) {
                  if (!mounted) return;
                  SchedulerBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    setState(() {
                      _cachedProjections ??= {};
                      _cachedProjections![key] = projections;
                    });
                  });
                },
              ),
            ),
          ),
        ),

        // Time controls
        if (widget.showControls) _buildTimeControls(),
      ],
    );
  }

  Widget _buildTimeControls() {
    return Column(
      children: [
        const SizedBox(height: 16),

        // Time slider
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatTime(_worldsheet4d!.startTime),
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    _formatTime(_currentTime),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _formatTime(_worldsheet4d!.endTime),
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              Slider(
                value: _getTimeSliderValue(),
                onChanged: _onTimeSliderChanged,
              ),
            ],
          ),
        ),

        // Playback controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
              onPressed: _togglePlayPause,
              tooltip: _isPlaying ? 'Pause' : 'Play',
            ),
            IconButton(
              icon: const Icon(Icons.skip_previous),
              onPressed: () {
                if (_worldsheet4d == null) return;
                final timeStep = const Duration(hours: 1);
                setState(() {
                  _currentTime = _currentTime.subtract(timeStep);
                  if (_currentTime.isBefore(_worldsheet4d!.startTime)) {
                    _currentTime = _worldsheet4d!.startTime;
                  }
                });
                _updateThreeJsTime();
              },
              tooltip: 'Previous hour',
            ),
            IconButton(
              icon: const Icon(Icons.skip_next),
              onPressed: () {
                if (_worldsheet4d == null) return;
                final timeStep = const Duration(hours: 1);
                setState(() {
                  _currentTime = _currentTime.add(timeStep);
                  if (_currentTime.isAfter(_worldsheet4d!.endTime)) {
                    _currentTime = _worldsheet4d!.endTime;
                  }
                });
                _updateThreeJsTime();
              },
              tooltip: 'Next hour',
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _resetView,
              tooltip: 'Reset view',
            ),
          ],
        ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    return '${time.month}/${time.day} ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }
}

/// Custom painter for 4D worldsheet visualization
///
/// Renders multiple strands (one per user) in 3D space
///
/// **Performance Optimizations (Phase 4):**
/// - LOD (Level of Detail): Reduces strand count when zoomed out
/// - Strand limiting: Caps visible strands at maxVisibleStrands (default: 100)
/// - Caching: Caches projected 2D coordinates to avoid recalculation
class Worldsheet4DPainter extends CustomPainter {
  final Fabric3DData? fabric3d;
  final double rotationX;
  final double rotationY;
  final double zoom;
  final Offset panOffset;

  // Performance optimization parameters
  final int maxVisibleStrands;
  final double lodZoomThreshold;
  final Map<String, List<List<Offset>>>? cachedProjections;
  final void Function(String key, List<List<Offset>> projections)?
      onProjectionsCached;

  Worldsheet4DPainter({
    required this.fabric3d,
    required this.rotationX,
    required this.rotationY,
    required this.zoom,
    required this.panOffset,
    this.maxVisibleStrands = 100,
    this.lodZoomThreshold = 0.8,
    this.cachedProjections,
    this.onProjectionsCached,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (fabric3d == null || fabric3d!.strandPositions.isEmpty) {
      // Draw placeholder
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..color = AppColors.grey400;

      canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        size.width * 0.1,
        paint,
      );
      return;
    }

    final center = Offset(size.width / 2, size.height / 2);

    // Performance optimization: LOD and strand limiting
    // Determine how many strands to render based on zoom level
    final effectiveStrandCount = _calculateEffectiveStrandCount(
      totalStrands: fabric3d!.strandPositions.length,
      zoom: zoom,
    );

    // Limit to maxVisibleStrands
    final strandsToRender = effectiveStrandCount.clamp(0, maxVisibleStrands);

    // Generate colors for visible strands only
    final colors = _generateStrandColors(strandsToRender);

    // Check cache first
    final cacheKey = _generateCacheKey();
    List<List<Offset>>? cachedProjectionsList;
    if (cachedProjections != null && cachedProjections!.containsKey(cacheKey)) {
      cachedProjectionsList = cachedProjections![cacheKey];
    }

    // Project 3D coordinates to 2D (or use cache)
    final allProjectedStrands = cachedProjectionsList ?? <List<Offset>>[];
    bool needsCacheUpdate = cachedProjectionsList == null;

    if (needsCacheUpdate) {
      // Project strands (only the ones we'll render)
      for (int i = 0;
          i < strandsToRender && i < fabric3d!.strandPositions.length;
          i++) {
        final strand = fabric3d!.strandPositions[i];
        if (strand.isEmpty) {
          allProjectedStrands.add([]);
          continue;
        }

        // LOD: Reduce points when zoomed out
        final pointsToUse = _getLODPoints(strand, zoom);

        final projectedPoints = <Offset>[];
        for (final coord in pointsToUse) {
          // Apply rotations
          var rotated = _rotateX(coord, rotationX);
          rotated = _rotateY(rotated, rotationY);

          // Apply zoom
          rotated = rotated * zoom;

          // Project to 2D (isometric projection)
          final x2d = center.dx + rotated.x + rotated.z * 0.5 + panOffset.dx;
          final y2d = center.dy + rotated.y - rotated.z * 0.5 + panOffset.dy;

          projectedPoints.add(Offset(x2d, y2d));
        }

        allProjectedStrands.add(projectedPoints);
      }

      // Cache projections if callback provided
      if (onProjectionsCached != null &&
          needsCacheUpdate &&
          allProjectedStrands.isNotEmpty) {
        onProjectionsCached!(cacheKey, allProjectedStrands);
      }
    }

    // Draw strands
    for (int i = 0;
        i < allProjectedStrands.length && i < strandsToRender;
        i++) {
      final projectedPoints = allProjectedStrands[i];
      if (projectedPoints.isEmpty || projectedPoints.length < 2) continue;

      final color = colors[i % colors.length];

      // Draw strand curve
      final path = Path();
      path.moveTo(projectedPoints[0].dx, projectedPoints[0].dy);

      for (int j = 1; j < projectedPoints.length; j++) {
        path.lineTo(projectedPoints[j].dx, projectedPoints[j].dy);
      }

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth =
            zoom < lodZoomThreshold ? 1.5 : 2.0 // Thinner lines when zoomed out
        ..color = color;

      canvas.drawPath(path, paint);
    }

    // Show indicator if strands are limited
    if (fabric3d!.strandPositions.length > maxVisibleStrands) {
      final textPainter = TextPainter(
        text: TextSpan(
          text:
              'Showing $strandsToRender/${fabric3d!.strandPositions.length} strands',
          style: TextStyle(
            color: AppColors.grey600,
            fontSize: 10,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(8, 8));
    }
  }

  /// Calculate effective strand count based on zoom (LOD)
  int _calculateEffectiveStrandCount({
    required int totalStrands,
    required double zoom,
  }) {
    if (zoom >= 1.0) {
      // Full detail when zoomed in
      return totalStrands;
    } else if (zoom >= lodZoomThreshold) {
      // Medium detail
      return (totalStrands * 0.7).round();
    } else {
      // Low detail when zoomed out
      return (totalStrands * 0.4).round();
    }
  }

  /// Get points to use based on LOD (Level of Detail)
  List<Vector3> _getLODPoints(List<Vector3> strand, double zoom) {
    if (zoom >= lodZoomThreshold || strand.length <= 10) {
      // Use all points when zoomed in or few points
      return strand;
    }

    // Sample points when zoomed out
    final sampleRate = zoom < 0.5 ? 4 : 2; // Every Nth point
    return strand
        .asMap()
        .entries
        .where((entry) => entry.key % sampleRate == 0)
        .map((entry) => entry.value)
        .toList();
  }

  /// Generate cache key for current view state
  String _generateCacheKey() {
    // Cache key based on fabric timestamp and view parameters
    final fabricTime = fabric3d?.timestamp.millisecondsSinceEpoch ?? 0;
    return '${fabricTime}_${rotationX.toStringAsFixed(2)}_${rotationY.toStringAsFixed(2)}_${zoom.toStringAsFixed(2)}_${panOffset.dx.toStringAsFixed(0)}_${panOffset.dy.toStringAsFixed(0)}';
  }

  List<Color> _generateStrandColors(int count) {
    final colors = <Color>[];
    final hueStep = 360.0 / count.clamp(1, 20);

    for (int i = 0; i < count; i++) {
      final hue = (i * hueStep) % 360.0;
      colors.add(HSVColor.fromAHSV(1.0, hue, 0.8, 0.9).toColor());
    }

    return colors;
  }

  Vector3 _rotateX(Vector3 v, double angle) {
    final cos = math.cos(angle);
    final sin = math.sin(angle);
    return Vector3(
      v.x,
      v.y * cos - v.z * sin,
      v.y * sin + v.z * cos,
    );
  }

  Vector3 _rotateY(Vector3 v, double angle) {
    final cos = math.cos(angle);
    final sin = math.sin(angle);
    return Vector3(
      v.x * cos + v.z * sin,
      v.y,
      -v.x * sin + v.z * cos,
    );
  }

  @override
  bool shouldRepaint(Worldsheet4DPainter oldDelegate) {
    return oldDelegate.fabric3d != fabric3d ||
        oldDelegate.rotationX != rotationX ||
        oldDelegate.rotationY != rotationY ||
        oldDelegate.zoom != zoom ||
        oldDelegate.panOffset != panOffset;
  }
}

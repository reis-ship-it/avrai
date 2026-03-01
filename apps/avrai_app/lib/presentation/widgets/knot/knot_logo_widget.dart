// Knot Logo Widget
//
// Compact 3D knot visualization for use as app logo/avatar.
// Part of Motion-Reactive 3D Visualization System.
//
// Features:
// - Compact size (40x40 to 80x80)
// - Auto-rotating with subtle parallax
// - Real-time updates from knot evolution
// - Low LOD for performance
// - Bubble container option
// - Tap to expand full knot view
// - Motion-reactive with device sensors

import 'dart:async';
import 'dart:developer' as developer;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:avrai/theme/colors.dart';

import 'package:get_it/get_it.dart';
import 'package:avrai_core/models/personality_knot.dart';
import 'package:avrai_runtime_os/runtime_api.dart';
import 'package:avrai_core/models/misc/motion_reactivity_config.dart';
import 'package:avrai_core/models/misc/visualization_style.dart';
import 'package:avrai_runtime_os/services/device/device_motion_service.dart';
import 'package:avrai_runtime_os/services/device/haptics_service.dart';
import 'package:avrai_runtime_os/services/visualization/three_js_bridge_service.dart';
import 'package:avrai/presentation/widgets/visualization/three_js_visualization_widget.dart';

/// Compact knot logo widget for app bar, navigation, and profile.
///
/// Displays the user's personality knot as a small, animated 3D icon.
/// Supports motion reactivity with device sensors.
class KnotLogoWidget extends StatefulWidget {
  /// Size of the widget (width and height)
  final double size;

  /// Agent ID to load knot for (null = current user)
  final String? agentId;

  /// Pre-loaded knot (if available, skips loading)
  final PersonalityKnot? knot;

  /// Whether to show bubble container around knot
  final bool showBubble;

  /// Bubble style (if showBubble is true)
  final BubbleStyle bubbleStyle;

  /// Motion reactivity configuration
  final MotionReactivityConfig? motionConfig;

  /// Whether to enable device motion response
  final bool enableMotion;

  /// Callback when tapped (e.g., to expand full knot view)
  final VoidCallback? onTap;

  /// Whether to use Three.js (true) or fallback (false)
  final bool useThreeJs;

  /// Placeholder widget while loading
  final Widget? placeholder;

  const KnotLogoWidget({
    super.key,
    this.size = 40.0,
    this.agentId,
    this.knot,
    this.showBubble = true,
    this.bubbleStyle = BubbleStyle.glass,
    this.motionConfig,
    this.enableMotion = true,
    this.onTap,
    this.useThreeJs = true,
    this.placeholder,
  });

  @override
  State<KnotLogoWidget> createState() => _KnotLogoWidgetState();
}

class _KnotLogoWidgetState extends State<KnotLogoWidget> {
  static const String _logName = 'KnotLogoWidget';

  PersonalityKnot? _knot;
  bool _isLoading = true;
  String? _error;

  ThreeJsBridgeService? _bridge;
  bool _threeJsReady = false;

  StreamSubscription<MotionData>? _motionSubscription;
  DeviceMotionService? _motionService;

  KnotStorageService? _storageService;
  StreamSubscription<PersonalityKnot?>? _knotSubscription;

  late MotionReactivityConfig _motionConfig;

  @override
  void initState() {
    super.initState();
    _motionConfig = widget.motionConfig ?? MotionReactivityConfig.knotLogo();
    _initServices();
    _loadKnot();
  }

  void _initServices() {
    try {
      _storageService = GetIt.I<KnotStorageService>();
    } catch (e) {
      developer.log(
        'KnotStorageService not registered: $e',
        name: _logName,
      );
    }

    if (widget.enableMotion) {
      try {
        _motionService = GetIt.I<DeviceMotionService>();
      } catch (e) {
        developer.log(
          'DeviceMotionService not registered: $e',
          name: _logName,
        );
      }
    }
  }

  Future<void> _loadKnot() async {
    // Use pre-loaded knot if available
    if (widget.knot != null) {
      setState(() {
        _knot = widget.knot;
        _isLoading = false;
      });
      return;
    }

    // Load from storage
    if (_storageService != null && widget.agentId != null) {
      try {
        final knot = await _storageService!.loadKnot(widget.agentId!);
        if (mounted) {
          setState(() {
            _knot = knot;
            _isLoading = false;
          });
        }

        // Subscribe to knot updates
        _subscribeToKnotUpdates();
      } catch (e) {
        developer.log(
          'Failed to load knot: $e',
          error: e,
          name: _logName,
        );
        if (mounted) {
          setState(() {
            _error = e.toString();
            _isLoading = false;
          });
        }
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _subscribeToKnotUpdates() {
    // Subscribe to real-time knot updates if service supports it
    // This would connect to KnotEvolutionStringService's update stream
    // For now, we'll rely on the initial load
  }

  void _onThreeJsReady(ThreeJsBridgeService bridge) {
    _bridge = bridge;
    _threeJsReady = true;

    // Render the knot
    _renderKnot();

    // Start motion listening
    _startMotionListening();

    // Configure motion in Three.js
    _configureMotion();
  }

  Future<void> _renderKnot() async {
    if (_bridge == null || _knot == null) return;

    try {
      // Use metallic style for compact rendering (low LOD for performance)
      final style = KnotVisualizationStyle.metallic(
        primaryColor: AppColors.electricGreen.toARGB32(),
        lod: VisualizationLOD.low,
      ).copyWith(
        autoRotate: _motionConfig.autoRotate,
        autoRotateSpeed: 0.3,
      );

      await _bridge!.renderPersonalityKnot(
        knot: _knot!,
        style: style,
        animate: true,
      );

      // Enable bubble if configured
      if (widget.showBubble && _threeJsReady) {
        await _bridge!.evaluateJavascript(
          'setBubbleEnabled(true, "${widget.bubbleStyle.name}")',
        );
      }

      // Add physics to knot
      await _bridge!.evaluateJavascript(
        'addPhysicsToKnot("${_motionConfig.physicsBehavior.name}")',
      );
    } catch (e) {
      developer.log(
        'Failed to render knot: $e',
        error: e,
        name: _logName,
      );
    }
  }

  void _configureMotion() {
    if (_bridge == null) return;

    _bridge!.evaluateJavascript(
      'setMotionConfig(${_motionConfig.toJson()})',
    );
  }

  void _startMotionListening() {
    if (!widget.enableMotion || _motionService == null) return;

    _motionService!.start();

    _motionSubscription = _motionService!.motionStream.listen(
      _onMotionUpdate,
      onError: (error) {
        developer.log(
          'Motion error: $error',
          error: error,
          name: _logName,
        );
      },
    );
  }

  void _onMotionUpdate(MotionData motion) {
    if (!_threeJsReady || _bridge == null) return;

    // Send motion data to Three.js
    final motionJson = '''
      {
        "tilt": {"x": ${motion.tilt.x}, "y": ${motion.tilt.y}},
        "gravity": {"x": ${motion.gravity.x}, "y": ${motion.gravity.y}, "z": ${motion.gravity.z}},
        "shake": ${motion.shake}
      }
    ''';

    _bridge!.evaluateJavascript('setDeviceMotion($motionJson)');
  }

  @override
  void didUpdateWidget(KnotLogoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Re-render if knot changed
    if (widget.knot != oldWidget.knot && widget.knot != null) {
      setState(() {
        _knot = widget.knot;
      });
      _renderKnot();
    }

    // Update motion config
    if (widget.motionConfig != oldWidget.motionConfig) {
      _motionConfig = widget.motionConfig ?? MotionReactivityConfig.knotLogo();
      _configureMotion();
    }
  }

  @override
  void dispose() {
    _motionSubscription?.cancel();
    _knotSubscription?.cancel();

    // Stop motion service if we started it
    // Note: Don't stop if it's shared across widgets
    // _motionService?.stop();

    super.dispose();
  }

  /// Handle tap with haptic feedback
  void _handleTap() {
    HapticsService.knotInteraction();
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Use Liquid Glass style for iOS 26 aesthetic
    final useGlass =
        widget.showBubble && widget.bubbleStyle == BubbleStyle.glass;

    Widget content = _buildContent();

    if (useGlass) {
      // Wrap in Liquid Glass container
      return GestureDetector(
        onTap: _handleTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.size),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.electricGreen
                        .withValues(alpha: isDark ? 0.08 : 0.1),
                    AppColors.white.withValues(alpha: isDark ? 0.04 : 0.06),
                  ],
                ),
                border: Border.all(
                  color: AppColors.electricGreen.withValues(alpha: 0.2),
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.electricGreen.withValues(alpha: 0.15),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: content,
            ),
          ),
        ),
      );
    }

    // Standard container without glass effect
    return GestureDetector(
      onTap: _handleTap,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.grey900,
        ),
        clipBehavior: Clip.antiAlias,
        child: content,
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return widget.placeholder ?? _buildLoadingPlaceholder();
    }

    if (_error != null || _knot == null) {
      return _buildErrorState();
    }

    if (widget.useThreeJs) {
      return _buildThreeJsVisualization();
    }

    return _buildFallbackVisualization();
  }

  Widget _buildLoadingPlaceholder() {
    return Center(
      child: SizedBox(
        width: widget.size * 0.4,
        height: widget.size * 0.4,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            AppColors.electricGreen.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Icon(
        Icons.blur_circular,
        size: widget.size * 0.5,
        color: AppColors.grey600,
      ),
    );
  }

  Widget _buildThreeJsVisualization() {
    return ThreeJsVisualizationWidget(
      size: widget.size,
      onReady: _onThreeJsReady,
      showControls: false,
      backgroundColor: AppColors.black,
    );
  }

  Widget _buildFallbackVisualization() {
    // Simple fallback - animated rotating circle with knot complexity indicator
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(seconds: 3),
      builder: (context, value, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _KnotLogoFallbackPainter(
            knot: _knot!,
            rotation: value * 3.14159 * 2,
          ),
        );
      },
      onEnd: () {
        // Restart animation
        if (mounted) {
          setState(() {});
        }
      },
    );
  }
}

/// Fallback painter for when Three.js is unavailable
class _KnotLogoFallbackPainter extends CustomPainter {
  final PersonalityKnot knot;
  final double rotation;

  _KnotLogoFallbackPainter({
    required this.knot,
    required this.rotation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.35;

    // Draw outer glow
    final glowPaint = Paint()
      ..color = AppColors.electricGreen.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center, radius, glowPaint);

    // Draw knot representation as overlapping circles
    final crossings = knot.invariants.crossingNumber.clamp(3, 12);
    final strokePaint = Paint()
      ..color = AppColors.electricGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < crossings; i++) {
      final angle = rotation + (i * 3.14159 * 2 / crossings);
      final x = center.dx + radius * 0.5 * (angle).abs() % 1;
      final y = center.dy + radius * 0.3 * (angle + 1).abs() % 1;

      canvas.drawCircle(
        Offset(
          center.dx + (x - center.dx) * 0.5,
          center.dy + (y - center.dy) * 0.5,
        ),
        radius * 0.4,
        strokePaint,
      );
    }

    // Draw center dot
    final dotPaint = Paint()..color = AppColors.electricGreen;
    canvas.drawCircle(center, 3, dotPaint);
  }

  @override
  bool shouldRepaint(_KnotLogoFallbackPainter oldDelegate) {
    return oldDelegate.rotation != rotation;
  }
}

// Knot Formation Widget
//
// Animated visualization of knot formation:
// Phase 1: Random quantum dots (chaos)
// Phase 2: Dots forming into strings
// Phase 3: Strings weaving into knot topology
// Phase 4: Complete knot with harmony
//
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Onboarding: AI Loading Page Enhancement

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:avrai_core/models/personality_knot.dart';
import 'package:avrai/theme/colors.dart';

/// Represents a quantum dot in the formation animation
class _QuantumDot {
  double x;
  double y;
  double targetX;
  double targetY;
  double velocityX;
  double velocityY;
  double size;
  double opacity;
  Color color;
  int stringIndex; // Which string this dot belongs to (-1 = unassigned)

  _QuantumDot({
    required this.x,
    required this.y,
    required this.targetX,
    required this.targetY,
    this.velocityX = 0,
    this.velocityY = 0,
    this.size = 3.0,
    this.opacity = 1.0,
    required this.color,
    this.stringIndex = -1,
  });
}

/// Formation phase enum
enum KnotFormationPhase {
  /// Random quantum dots moving chaotically
  quantumChaos,

  /// Dots beginning to coalesce into strings
  stringFormation,

  /// Strings weaving into knot topology
  knotWeaving,

  /// Complete knot with final form
  complete,
}

/// Widget that animates knot formation from quantum chaos to harmony
///
/// Animation phases:
/// 1. Quantum Chaos (0-25%): Random dots moving chaotically
/// 2. String Formation (25-50%): Dots coalesce into strings
/// 3. Knot Weaving (50-85%): Strings weave into knot structure
/// 4. Complete (85-100%): Final knot with polish effects
///
/// Can be driven by:
/// - Internal timer (autoStart = true, externalProgress = null)
/// - External progress (externalProgress != null) - synced to actual work
class KnotFormationWidget extends StatefulWidget {
  /// The target knot to form (optional - if null, generates generic pattern)
  final PersonalityKnot? targetKnot;

  /// Size of the widget
  final double size;

  /// Duration of the full formation animation (used when not externally controlled)
  final Duration duration;

  /// Callback when formation phase changes
  final ValueChanged<KnotFormationPhase>? onPhaseChange;

  /// Callback with current progress (0.0 to 1.0)
  final ValueChanged<double>? onProgress;

  /// Callback when formation completes
  final VoidCallback? onComplete;

  /// Whether to auto-start the animation (ignored if externalProgress is provided)
  final bool autoStart;

  /// Base color for the knot (uses knot properties if available)
  final Color? baseColor;

  /// External progress value (0.0 to 1.0) to drive animation
  /// When provided, animation is controlled externally instead of by internal timer
  final double? externalProgress;

  const KnotFormationWidget({
    super.key,
    this.targetKnot,
    this.size = 200.0,
    this.duration = const Duration(seconds: 8),
    this.onPhaseChange,
    this.onProgress,
    this.onComplete,
    this.autoStart = true,
    this.baseColor,
    this.externalProgress,
  });

  @override
  State<KnotFormationWidget> createState() => KnotFormationWidgetState();
}

class KnotFormationWidgetState extends State<KnotFormationWidget>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _chaosController;
  late Animation<double> _progressAnimation;

  final List<_QuantumDot> _dots = [];
  final math.Random _random = math.Random();

  KnotFormationPhase _currentPhase = KnotFormationPhase.quantumChaos;
  double _currentProgress = 0.0;

  // Knot path points (generated from target knot or default trefoil)
  List<Offset> _knotPath = [];
  List<List<Offset>> _stringPaths = [];

  // Colors derived from knot properties
  late Color _primaryColor;
  late Color _secondaryColor;
  late Color _accentColor;

  /// Whether we're using external progress control
  bool get _isExternallyControlled => widget.externalProgress != null;

  @override
  void initState() {
    super.initState();

    _initializeColors();
    _initializeDots();
    _generateKnotPath();

    // Main formation animation (only used when not externally controlled)
    _mainController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeInOut),
    );

    _mainController.addListener(_onAnimationTick);
    _mainController.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_isExternallyControlled) {
        widget.onComplete?.call();
      }
    });

    // Chaos animation (continuous random movement)
    _chaosController = AnimationController(
      duration: const Duration(milliseconds: 50),
      vsync: this,
    )..repeat();

    _chaosController.addListener(_updateChaos);

    // If externally controlled, apply initial progress after first frame
    // to avoid calling callbacks during build phase
    if (_isExternallyControlled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _applyExternalProgress(widget.externalProgress!);
        }
      });
    } else if (widget.autoStart) {
      _mainController.forward();
    }
  }

  @override
  void didUpdateWidget(KnotFormationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle external progress updates
    // Use addPostFrameCallback to avoid calling callbacks during build phase
    if (_isExternallyControlled &&
        widget.externalProgress != oldWidget.externalProgress) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _applyExternalProgress(widget.externalProgress!);
        }
      });
    }

    // Handle knot updates
    if (widget.targetKnot != oldWidget.targetKnot) {
      _initializeColors();
      _generateKnotPath();
    }
  }

  /// Apply external progress value
  void _applyExternalProgress(double progress) {
    final clampedProgress = progress.clamp(0.0, 1.0);

    // Check for completion
    final wasComplete = _currentPhase == KnotFormationPhase.complete;

    _currentProgress = clampedProgress;
    widget.onProgress?.call(clampedProgress);

    // Determine phase
    final newPhase = _getPhaseForProgress(clampedProgress);
    if (newPhase != _currentPhase) {
      _currentPhase = newPhase;
      widget.onPhaseChange?.call(newPhase);
    }

    // Update dots
    _updateDotsForPhase(clampedProgress);

    // Fire completion callback when reaching complete phase
    if (!wasComplete && _currentPhase == KnotFormationPhase.complete) {
      widget.onComplete?.call();
    }

    setState(() {});
  }

  void _initializeColors() {
    if (widget.baseColor != null) {
      _primaryColor = widget.baseColor!;
    } else if (widget.targetKnot != null) {
      // Derive color from knot properties
      final knot = widget.targetKnot!;
      final hue = (knot.invariants.crossingNumber * 30.0) % 360.0;
      _primaryColor = HSLColor.fromAHSL(1.0, hue, 0.7, 0.5).toColor();
    } else {
      _primaryColor = AppColors.primary;
    }

    // Generate complementary colors
    final hsl = HSLColor.fromColor(_primaryColor);
    _secondaryColor =
        hsl.withHue((hsl.hue + 120) % 360).withLightness(0.6).toColor();
    _accentColor =
        hsl.withHue((hsl.hue + 240) % 360).withLightness(0.7).toColor();
  }

  void _initializeDots() {
    _dots.clear();

    // Create quantum dots - number based on knot complexity
    final dotCount = widget.targetKnot != null
        ? (widget.targetKnot!.invariants.crossingNumber * 10).clamp(50, 200)
        : 100;

    for (int i = 0; i < dotCount; i++) {
      final color = [_primaryColor, _secondaryColor, _accentColor][i % 3];

      final startX = _random.nextDouble() * widget.size;
      final startY = _random.nextDouble() * widget.size;
      _dots.add(_QuantumDot(
        x: startX,
        y: startY,
        targetX: startX, // Will be updated in _assignDotsToStrings
        targetY: startY, // Will be updated in _assignDotsToStrings
        velocityX: (_random.nextDouble() - 0.5) * 4,
        velocityY: (_random.nextDouble() - 0.5) * 4,
        size: 2.0 + _random.nextDouble() * 3.0,
        opacity: 0.5 + _random.nextDouble() * 0.5,
        color: color.withValues(alpha: 0.5 + _random.nextDouble() * 0.5),
        stringIndex: -1,
      ));
    }
  }

  void _generateKnotPath() {
    final center = widget.size / 2;
    final radius = widget.size * 0.35;

    if (widget.targetKnot != null) {
      // Generate path based on knot properties
      _knotPath = _generateKnotPathFromInvariants(
        widget.targetKnot!,
        center,
        radius,
      );
    } else {
      // Default trefoil knot path
      _knotPath = _generateTrefoilPath(center, radius);
    }

    // Split path into strings based on crossing number
    final stringCount = widget.targetKnot != null
        ? widget.targetKnot!.invariants.crossingNumber.clamp(3, 12)
        : 3;

    _stringPaths = _splitPathIntoStrings(_knotPath, stringCount);

    // Assign dots to strings
    _assignDotsToStrings();
  }

  List<Offset> _generateKnotPathFromInvariants(
    PersonalityKnot knot,
    double center,
    double radius,
  ) {
    final points = <Offset>[];
    final crossings = knot.invariants.crossingNumber.clamp(3, 12);
    final writhe = knot.invariants.writhe;

    // Generate parametric curve based on knot invariants
    // Uses Lissajous-style curves modified by polynomial coefficients
    final steps = 200;
    final jonesCoeffs = knot.invariants.jonesPolynomial;
    final alexanderCoeffs = knot.invariants.alexanderPolynomial;

    for (int i = 0; i <= steps; i++) {
      final t = (i / steps) * 2 * math.pi;

      // Base Lissajous curve with crossings determining frequency
      var x = center + radius * math.sin(crossings * t / 2);
      var y = center + radius * math.cos((crossings - 1) * t / 2);

      // Modify with polynomial coefficients for unique shape
      if (jonesCoeffs.isNotEmpty) {
        x += jonesCoeffs[0].clamp(-1, 1) * radius * 0.2 * math.sin(t * 3);
      }
      if (alexanderCoeffs.isNotEmpty) {
        y += alexanderCoeffs[0].clamp(-1, 1) * radius * 0.2 * math.cos(t * 3);
      }

      // Add writhe influence (twist)
      final writheRotation = writhe * 0.1 * t;
      final rotatedX = center +
          (x - center) * math.cos(writheRotation) -
          (y - center) * math.sin(writheRotation);
      final rotatedY = center +
          (x - center) * math.sin(writheRotation) +
          (y - center) * math.cos(writheRotation);

      points.add(Offset(rotatedX, rotatedY));
    }

    return points;
  }

  List<Offset> _generateTrefoilPath(double center, double radius) {
    final points = <Offset>[];
    final steps = 200;

    for (int i = 0; i <= steps; i++) {
      final t = (i / steps) * 2 * math.pi;
      // Trefoil knot parametric equations
      final x = center + radius * (math.sin(t) + 2 * math.sin(2 * t));
      final y = center + radius * (math.cos(t) - 2 * math.cos(2 * t));
      points.add(Offset(x * 0.3 + center * 0.7, y * 0.3 + center * 0.7));
    }

    return points;
  }

  List<List<Offset>> _splitPathIntoStrings(List<Offset> path, int count) {
    final strings = <List<Offset>>[];
    final segmentSize = path.length ~/ count;

    for (int i = 0; i < count; i++) {
      final start = i * segmentSize;
      final end = (i == count - 1) ? path.length : (i + 1) * segmentSize;
      strings.add(path.sublist(start, end));
    }

    return strings;
  }

  void _assignDotsToStrings() {
    if (_stringPaths.isEmpty) return;

    final dotsPerString = _dots.length ~/ _stringPaths.length;

    for (int i = 0; i < _dots.length; i++) {
      final stringIndex =
          (i ~/ dotsPerString).clamp(0, _stringPaths.length - 1);
      _dots[i].stringIndex = stringIndex;

      // Assign target position along the string
      final stringPath = _stringPaths[stringIndex];
      final positionInString = i % dotsPerString;
      final pathIndex = ((positionInString / dotsPerString) * stringPath.length)
          .floor()
          .clamp(0, stringPath.length - 1);

      _dots[i].targetX = stringPath[pathIndex].dx;
      _dots[i].targetY = stringPath[pathIndex].dy;
    }
  }

  void _updateChaos() {
    if (!mounted) return;

    // Only apply full chaos in first phase
    final chaosStrength = _currentPhase == KnotFormationPhase.quantumChaos
        ? 1.0
        : _currentPhase == KnotFormationPhase.stringFormation
            ? 0.3
            : 0.0;

    if (chaosStrength > 0) {
      for (final dot in _dots) {
        // Add random velocity changes
        dot.velocityX += (_random.nextDouble() - 0.5) * chaosStrength;
        dot.velocityY += (_random.nextDouble() - 0.5) * chaosStrength;

        // Dampen velocity
        dot.velocityX *= 0.98;
        dot.velocityY *= 0.98;

        // Update position
        dot.x += dot.velocityX * chaosStrength;
        dot.y += dot.velocityY * chaosStrength;

        // Bounce off edges
        if (dot.x < 0 || dot.x > widget.size) {
          dot.velocityX *= -1;
          dot.x = dot.x.clamp(0, widget.size);
        }
        if (dot.y < 0 || dot.y > widget.size) {
          dot.velocityY *= -1;
          dot.y = dot.y.clamp(0, widget.size);
        }
      }
      setState(() {});
    }
  }

  void _onAnimationTick() {
    final progress = _progressAnimation.value;
    _currentProgress = progress;
    widget.onProgress?.call(progress);

    // Determine phase based on progress
    final newPhase = _getPhaseForProgress(progress);
    if (newPhase != _currentPhase) {
      _currentPhase = newPhase;
      widget.onPhaseChange?.call(newPhase);
    }

    // Update dots based on phase
    _updateDotsForPhase(progress);

    setState(() {});
  }

  KnotFormationPhase _getPhaseForProgress(double progress) {
    if (progress < 0.25) {
      return KnotFormationPhase.quantumChaos;
    } else if (progress < 0.50) {
      return KnotFormationPhase.stringFormation;
    } else if (progress < 0.85) {
      return KnotFormationPhase.knotWeaving;
    } else {
      return KnotFormationPhase.complete;
    }
  }

  void _updateDotsForPhase(double progress) {
    for (final dot in _dots) {
      if (progress < 0.25) {
        // Quantum chaos - dots move randomly (handled in _updateChaos)
        dot.opacity = 0.5 + _random.nextDouble() * 0.5;
      } else if (progress < 0.50) {
        // String formation - dots start moving toward string positions
        final lerpFactor = (progress - 0.25) / 0.25; // 0 to 1 within this phase
        dot.x = _lerpDouble(dot.x, dot.targetX, lerpFactor * 0.1);
        dot.y = _lerpDouble(dot.y, dot.targetY, lerpFactor * 0.1);
        dot.opacity = 0.6 + lerpFactor * 0.2;
      } else if (progress < 0.85) {
        // Knot weaving - dots move firmly into position
        final lerpFactor = (progress - 0.50) / 0.35; // 0 to 1 within this phase
        dot.x = _lerpDouble(dot.x, dot.targetX, 0.2 + lerpFactor * 0.3);
        dot.y = _lerpDouble(dot.y, dot.targetY, 0.2 + lerpFactor * 0.3);
        dot.opacity = 0.8 + lerpFactor * 0.2;
        dot.size = 3.0 + lerpFactor * 2.0; // Dots grow
      } else {
        // Complete - dots are in final position
        dot.x = dot.targetX;
        dot.y = dot.targetY;
        dot.opacity = 1.0;
        dot.size = 5.0;
      }
    }
  }

  double _lerpDouble(double a, double b, double t) {
    return a + (b - a) * t.clamp(0.0, 1.0);
  }

  /// Start the formation animation
  void start() {
    _mainController.forward(from: 0.0);
  }

  /// Reset the animation
  void reset() {
    _mainController.reset();
    _initializeDots();
    _currentPhase = KnotFormationPhase.quantumChaos;
    _currentProgress = 0.0;
    setState(() {});
  }

  /// Get current progress (0.0 to 1.0)
  double get progress => _currentProgress;

  /// Get current phase
  KnotFormationPhase get phase => _currentPhase;

  @override
  void dispose() {
    _mainController.dispose();
    _chaosController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: CustomPaint(
        painter: _KnotFormationPainter(
          dots: _dots,
          knotPath: _knotPath,
          stringPaths: _stringPaths,
          progress: _currentProgress,
          phase: _currentPhase,
          primaryColor: _primaryColor,
          secondaryColor: _secondaryColor,
          accentColor: _accentColor,
        ),
      ),
    );
  }
}

/// Custom painter for the knot formation animation
class _KnotFormationPainter extends CustomPainter {
  final List<_QuantumDot> dots;
  final List<Offset> knotPath;
  final List<List<Offset>> stringPaths;
  final double progress;
  final KnotFormationPhase phase;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;

  _KnotFormationPainter({
    required this.dots,
    required this.knotPath,
    required this.stringPaths,
    required this.progress,
    required this.phase,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw background glow
    _drawBackgroundGlow(canvas, size);

    // Draw strings (when in string formation or later)
    if (progress >= 0.25) {
      _drawStrings(canvas);
    }

    // Draw dots
    _drawDots(canvas);

    // Draw knot outline (when nearly complete)
    if (progress >= 0.70) {
      _drawKnotOutline(canvas, size);
    }

    // Draw completion effects
    if (phase == KnotFormationPhase.complete) {
      _drawCompletionEffects(canvas, size);
    }
  }

  void _drawBackgroundGlow(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.4;

    // Glow intensity based on progress
    final glowOpacity =
        phase == KnotFormationPhase.complete ? 0.3 : progress * 0.2;

    final gradient = RadialGradient(
      colors: [
        primaryColor.withValues(alpha: glowOpacity),
        primaryColor.withValues(alpha: glowOpacity * 0.5),
        Colors.transparent,
      ],
    );

    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      );

    canvas.drawCircle(center, radius, paint);
  }

  void _drawStrings(Canvas canvas) {
    final stringProgress = ((progress - 0.25) / 0.60).clamp(0.0, 1.0);

    for (int i = 0; i < stringPaths.length; i++) {
      final path = stringPaths[i];
      if (path.isEmpty) continue;

      final color = [primaryColor, secondaryColor, accentColor][i % 3];
      final paint = Paint()
        ..color = color.withValues(alpha: stringProgress * 0.6)
        ..strokeWidth = 2.0 + stringProgress * 2.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      // Draw partial path based on progress
      final pathToDraw = Path();
      final pointsToDraw = (path.length * stringProgress).ceil();

      if (pointsToDraw > 0) {
        pathToDraw.moveTo(path[0].dx, path[0].dy);
        for (int j = 1; j < pointsToDraw && j < path.length; j++) {
          pathToDraw.lineTo(path[j].dx, path[j].dy);
        }
        canvas.drawPath(pathToDraw, paint);
      }
    }
  }

  void _drawDots(Canvas canvas) {
    for (final dot in dots) {
      final paint = Paint()
        ..color = dot.color.withValues(alpha: dot.opacity)
        ..style = PaintingStyle.fill;

      // Add glow effect for dots
      if (phase != KnotFormationPhase.quantumChaos) {
        final glowPaint = Paint()
          ..color = dot.color.withValues(alpha: dot.opacity * 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawCircle(Offset(dot.x, dot.y), dot.size * 1.5, glowPaint);
      }

      canvas.drawCircle(Offset(dot.x, dot.y), dot.size, paint);
    }
  }

  void _drawKnotOutline(Canvas canvas, Size size) {
    if (knotPath.isEmpty) return;

    final outlineProgress = ((progress - 0.70) / 0.15).clamp(0.0, 1.0);
    final paint = Paint()
      ..color = primaryColor.withValues(alpha: outlineProgress * 0.8)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(knotPath[0].dx, knotPath[0].dy);

    for (int i = 1; i < knotPath.length; i++) {
      path.lineTo(knotPath[i].dx, knotPath[i].dy);
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  void _drawCompletionEffects(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Pulsing glow
    final pulseProgress = ((progress - 0.85) / 0.15).clamp(0.0, 1.0);
    final pulseRadius = size.width * 0.4 * (1.0 + pulseProgress * 0.1);

    final glowPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.2 + pulseProgress * 0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

    canvas.drawCircle(center, pulseRadius, glowPaint);

    // Sparkle effects
    if (pulseProgress > 0.5) {
      final sparkleCount = 8;
      for (int i = 0; i < sparkleCount; i++) {
        final angle = (i / sparkleCount) * 2 * math.pi;
        final sparkleRadius = size.width * 0.3;
        final sparkleX = center.dx + math.cos(angle) * sparkleRadius;
        final sparkleY = center.dy + math.sin(angle) * sparkleRadius;

        final sparklePaint = Paint()
          ..color = accentColor.withValues(alpha: (pulseProgress - 0.5) * 2)
          ..style = PaintingStyle.fill;

        canvas.drawCircle(Offset(sparkleX, sparkleY), 3, sparklePaint);
      }
    }
  }

  @override
  bool shouldRepaint(_KnotFormationPainter oldDelegate) {
    return true; // Always repaint for animation
  }
}

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:avrai/theme/colors.dart';
import 'package:flutter/material.dart' hide Colors;

/// A widget that visually represents the progressive confidence of a knot match.
/// 
/// Instead of showing a number like "68% match", this widget displays a 
/// topological "resonance" that starts cloudy/murky at low confidence and 
/// solidifies into a sharp, glowing knot at high confidence.
/// 
/// Part of the v0.1 Reality Check "Quantum UX" spike.
class ProgressiveConfidenceWidget extends StatefulWidget {
  /// The math-based match score between [0.0, 1.0].
  /// Calculated by the DeterministicMatcherService.
  final double confidence;
  
  final double size;
  final Color primaryColor;

  const ProgressiveConfidenceWidget({
    super.key,
    required this.confidence,
    this.size = 150.0,
    this.primaryColor = AppColors.electricGreen,
  });

  @override
  State<ProgressiveConfidenceWidget> createState() => _ProgressiveConfidenceWidgetState();
}

class _ProgressiveConfidenceWidgetState extends State<ProgressiveConfidenceWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Animation speed scales inversely with confidence.
    // Lower confidence = slower, more ambient drifting.
    // Higher confidence = faster, tighter energetic rotation.
    final durationMs = 4000 - (widget.confidence * 2000).toInt();
    
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: durationMs),
    )..repeat();
  }

  @override
  void didUpdateWidget(ProgressiveConfidenceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.confidence != widget.confidence) {
      final durationMs = 4000 - (widget.confidence * 2000).toInt();
      _controller.duration = Duration(milliseconds: durationMs);
      if (_controller.isAnimating) {
        _controller.repeat();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _ResonancePainter(
              confidence: widget.confidence,
              animationValue: _controller.value,
              baseColor: widget.primaryColor,
            ),
          );
        },
      ),
    );
  }
}

class _ResonancePainter extends CustomPainter {
  final double confidence;
  final double animationValue;
  final Color baseColor;

  _ResonancePainter({
    required this.confidence,
    required this.animationValue,
    required this.baseColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2.5;

    // 1. Calculate states based on confidence
    // At low confidence, it's mostly a cloudy blur.
    // At high confidence, it's a sharp, glowing geometric path.
    
    final blurRadius = ui.lerpDouble(20.0, 2.0, confidence)!;
    final strokeWidth = ui.lerpDouble(1.0, 4.0, confidence)!;
    final pathClarity = confidence; // 0.0 to 1.0
    
    // 2. Draw the "Cloud" (Uncertainty)
    // As confidence drops, the cloud gets more opaque.
    final cloudOpacity = ui.lerpDouble(0.6, 0.1, confidence)!;
    final cloudPaint = Paint()
      ..color = baseColor.withOpacity(cloudOpacity)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurRadius)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius * 0.8, cloudPaint);

    // 3. Draw the "Strands" (The Knot forming)
    // The number of loops/complexity is a visual proxy for the "math" being calculated
    final strandPaint = Paint()
      ..color = baseColor.withOpacity(ui.lerpDouble(0.2, 1.0, confidence)!)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (confidence > 0.8) {
      // Add a glow effect when highly confident
      strandPaint.maskFilter = const MaskFilter.blur(BlurStyle.solid, 4.0);
    }

    final path = Path();
    final numPoints = 100;
    
    // Create a Lissajous-curve-like knot that "tightens" as confidence goes up.
    // The rotation depends on the animation value.
    final rotationOffset = animationValue * math.pi * 2;
    
    // Wavelength frequency depends on confidence (tighter when more confident)
    final freqX = ui.lerpDouble(1.0, 3.0, confidence)!;
    final freqY = ui.lerpDouble(2.0, 4.0, confidence)!;
    
    // Random jitter depends on IN-confidence (murky when low confidence)
    final jitterAmount = ui.lerpDouble(radius * 0.3, 0.0, confidence)!;

    for (int i = 0; i <= numPoints; i++) {
      final t = (i / numPoints) * math.pi * 2;
      
      // Base knot geometry
      final x = math.sin(t * freqX + rotationOffset) * radius;
      final y = math.cos(t * freqY) * radius;
      
      // Add uncertainty jitter
      // Use a pseudo-random value based on position so it animates somewhat smoothly
      final jx = math.sin(t * 10 + rotationOffset * 5) * jitterAmount;
      final jy = math.cos(t * 15 - rotationOffset * 3) * jitterAmount;

      final point = Offset(center.dx + x + jx, center.dy + y + jy);

      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        // Draw the path. If confidence is very low, we only draw broken segments
        if (pathClarity > 0.3 || i % 3 != 0) {
          path.lineTo(point.dx, point.dy);
        } else {
          path.moveTo(point.dx, point.dy);
        }
      }
    }

    canvas.drawPath(path, strandPaint);
    
    // Draw the "Core" (Solidifies as confidence reaches 1.0)
    if (confidence > 0.6) {
      final coreOpacity = ui.lerpDouble(0.0, 0.8, (confidence - 0.6) / 0.4)!;
      final corePaint = Paint()
        ..color = AppColors.white.withOpacity(coreOpacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0)
        ..style = PaintingStyle.fill;
        
      canvas.drawCircle(center, radius * 0.2, corePaint);
    }
  }

  @override
  bool shouldRepaint(_ResonancePainter oldDelegate) {
    return oldDelegate.confidence != confidence ||
           oldDelegate.animationValue != animationValue ||
           oldDelegate.baseColor != baseColor;
  }
}

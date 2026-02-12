// Braiding Animation Widget
// 
// Widget for animating the braiding process between two personality knots
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Phase 2: Knot Weaving

import 'package:flutter/material.dart';
import 'package:avrai_core/models/personality_knot.dart';
import 'package:avrai_knot/models/knot/braided_knot.dart';
import 'package:avrai/core/theme/colors.dart';

/// Widget for animating the braiding process
/// 
/// Shows an animated visualization of two personality knots being woven together
class BraidingAnimationWidget extends StatefulWidget {
  final PersonalityKnot knotA;
  final PersonalityKnot knotB;
  final RelationshipType relationshipType;
  final double size;
  final Duration animationDuration;
  final VoidCallback? onAnimationComplete;

  const BraidingAnimationWidget({
    super.key,
    required this.knotA,
    required this.knotB,
    required this.relationshipType,
    this.size = 200.0,
    this.animationDuration = const Duration(seconds: 2),
    this.onAnimationComplete,
  });

  @override
  State<BraidingAnimationWidget> createState() => _BraidingAnimationWidgetState();
}

class _BraidingAnimationWidgetState extends State<BraidingAnimationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _controller.forward().then((_) {
      widget.onAnimationComplete?.call();
    });
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
        animation: _animation,
        builder: (context, child) {
          return CustomPaint(
            painter: BraidingAnimationPainter(
              knotA: widget.knotA,
              knotB: widget.knotB,
              relationshipType: widget.relationshipType,
              progress: _animation.value,
            ),
            child: Container(),
          );
        },
      ),
    );
  }

  /// Restart the animation
  void restart() {
    _controller.reset();
    _controller.forward();
  }

  /// Pause the animation
  void pause() {
    _controller.stop();
  }

  /// Resume the animation
  void resume() {
    _controller.forward();
  }
}

/// Custom painter for braiding animation
class BraidingAnimationPainter extends CustomPainter {
  final PersonalityKnot knotA;
  final PersonalityKnot knotB;
  final RelationshipType relationshipType;
  final double progress; // 0.0 to 1.0

  BraidingAnimationPainter({
    required this.knotA,
    required this.knotB,
    required this.relationshipType,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.35;
    final relationshipColor = _getRelationshipColor(relationshipType);

    // Calculate positions based on animation progress
    // Start: knots far apart (progress = 0.0)
    // End: knots close together, braided (progress = 1.0)
    final startDistance = radius * 0.8;
    final endDistance = radius * 0.1;
    final currentDistance = startDistance - (startDistance - endDistance) * progress;

    // Knot A position (left side, moving toward center)
    final knotACenter = Offset(
      center.dx - currentDistance * (1 - progress * 0.5),
      center.dy,
    );

    // Knot B position (right side, moving toward center)
    final knotBCenter = Offset(
      center.dx + currentDistance * (1 - progress * 0.5),
      center.dy,
    );

    // Draw knot A
    _drawKnot(
      canvas,
      knotACenter,
      radius * 0.4 * (1 - progress * 0.3), // Slightly shrink as they approach
      relationshipColor.withValues(alpha: 0.6 + progress * 0.2),
      'A',
    );

    // Draw knot B
    _drawKnot(
      canvas,
      knotBCenter,
      radius * 0.4 * (1 - progress * 0.3), // Slightly shrink as they approach
      relationshipColor.withValues(alpha: 0.6 + progress * 0.2),
      'B',
    );

    // Draw braiding strands (appear as progress increases)
    if (progress > 0.3) {
      final braidingProgress = ((progress - 0.3) / 0.7).clamp(0.0, 1.0);
      _drawBraidingAnimation(
        canvas,
        knotACenter,
        knotBCenter,
        radius,
        relationshipColor,
        braidingProgress,
      );
    }

    // Draw center connection point (appears when close)
    if (progress > 0.7) {
      final centerProgress = ((progress - 0.7) / 0.3).clamp(0.0, 1.0);
      final centerPaint = Paint()
        ..color = relationshipColor.withValues(alpha: centerProgress)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, 8 * centerProgress, centerPaint);

      // Draw center border
      final centerBorderPaint = Paint()
        ..color = AppColors.white.withValues(alpha: centerProgress)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(center, 8 * centerProgress, centerBorderPaint);
    }
  }

  void _drawKnot(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
    String label,
  ) {
    // Draw knot circle
    final knotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius, knotPaint);

    // Draw knot label
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  void _drawBraidingAnimation(
    Canvas canvas,
    Offset knotACenter,
    Offset knotBCenter,
    double radius,
    Color color,
    double braidingProgress,
  ) {
    // Draw interweaving strands based on braid sequence
    // Number of strands increases with progress
    const maxStrands = 6;
    final numStrands = (maxStrands * braidingProgress).ceil().clamp(1, maxStrands);

    for (int i = 0; i < numStrands; i++) {
      final strandProgress = (i / numStrands).clamp(0.0, 1.0);
      final strandAlpha = braidingProgress * (1.0 - strandProgress * 0.5);

      // Create curved path between knots
      final path = Path();
      path.moveTo(knotACenter.dx, knotACenter.dy);

      // Control points for bezier curve
      final controlPoint1 = Offset(
        knotACenter.dx + (knotBCenter.dx - knotACenter.dx) * 0.3,
        knotACenter.dy - radius * 0.5 * (i.isEven ? 1 : -1) * braidingProgress,
      );
      final controlPoint2 = Offset(
        knotACenter.dx + (knotBCenter.dx - knotACenter.dx) * 0.7,
        knotBCenter.dy - radius * 0.5 * (i.isEven ? -1 : 1) * braidingProgress,
      );

      path.cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        knotBCenter.dx,
        knotBCenter.dy,
      );

      // Alternate over/under
      if (i.isEven) {
        // Draw over strand (thicker, more opaque)
        final overPaint = Paint()
          ..color = color.withValues(alpha: strandAlpha)
          ..strokeWidth = 3 * braidingProgress
          ..style = PaintingStyle.stroke;
        canvas.drawPath(path, overPaint);
      } else {
        // Draw under strand (thinner, less opaque)
        final underPaint = Paint()
          ..color = color.withValues(alpha: strandAlpha * 0.4)
          ..strokeWidth = 1.5 * braidingProgress
          ..style = PaintingStyle.stroke;
        canvas.drawPath(path, underPaint);
      }
    }
  }

  Color _getRelationshipColor(RelationshipType relationshipType) {
    switch (relationshipType) {
      case RelationshipType.friendship:
        return AppColors.success; // Green
      case RelationshipType.mentorship:
        return AppColors.primary; // Blue
      case RelationshipType.romantic:
        return AppColors.error; // Red/Pink
      case RelationshipType.collaborative:
        return AppColors.accent; // Purple
      case RelationshipType.professional:
        return AppColors.warning; // Orange/Yellow
    }
  }

  @override
  bool shouldRepaint(BraidingAnimationPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.knotA != knotA ||
        oldDelegate.knotB != knotB ||
        oldDelegate.relationshipType != relationshipType;
  }
}

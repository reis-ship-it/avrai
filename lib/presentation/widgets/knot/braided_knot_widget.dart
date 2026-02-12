// Braided Knot Widget
// 
// Widget for visualizing braided knots
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Phase 2: Knot Weaving

import 'package:flutter/material.dart';
import 'package:avrai_knot/models/knot/braided_knot.dart';
import 'package:avrai/core/theme/colors.dart';

/// Widget for visualizing a braided knot
/// 
/// Displays the topological structure of two personality knots woven together
class BraidedKnotWidget extends StatelessWidget {
  final BraidedKnot braidedKnot;
  final double size;
  final bool showLabels;
  final bool showMetrics;

  const BraidedKnotWidget({
    super.key,
    required this.braidedKnot,
    this.size = 200.0,
    this.showLabels = false,
    this.showMetrics = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Knot visualization
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: BraidedKnotPainter(
              braidedKnot: braidedKnot,
            ),
            child: Container(),
          ),
        ),
        
        // Labels and metrics (if enabled)
        if (showLabels || showMetrics) ...[
          const SizedBox(height: 8),
          if (showLabels)
            Text(
              braidedKnot.relationshipType.displayName,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.textPrimary,
                  ),
            ),
          if (showMetrics) ...[
            const SizedBox(height: 4),
            _buildMetricsRow(context),
          ],
        ],
      ],
    );
  }

  Widget _buildMetricsRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildMetricChip(
          context,
          'Complexity',
          braidedKnot.complexity,
          AppColors.primary,
        ),
        const SizedBox(width: 8),
        _buildMetricChip(
          context,
          'Stability',
          braidedKnot.stability,
          AppColors.success,
        ),
        const SizedBox(width: 8),
        _buildMetricChip(
          context,
          'Harmony',
          braidedKnot.harmonyScore,
          AppColors.accent,
        ),
      ],
    );
  }

  Widget _buildMetricChip(
    BuildContext context,
    String label,
    double value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(width: 4),
          Text(
            '${(value * 100).toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for braided knot visualization
class BraidedKnotPainter extends CustomPainter {
  final BraidedKnot braidedKnot;

  BraidedKnotPainter({
    required this.braidedKnot,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.35;

    // Get relationship type color
    final relationshipColor = _getRelationshipColor(braidedKnot.relationshipType);

    // Draw knot A (left side)
    final knotACenter = Offset(center.dx - radius * 0.3, center.dy);
    _drawKnot(canvas, knotACenter, radius * 0.4, relationshipColor.withValues(alpha: 0.6), 'A');

    // Draw knot B (right side)
    final knotBCenter = Offset(center.dx + radius * 0.3, center.dy);
    _drawKnot(canvas, knotBCenter, radius * 0.4, relationshipColor.withValues(alpha: 0.6), 'B');

    // Draw braided interweaving
    _drawBraiding(canvas, knotACenter, knotBCenter, radius, relationshipColor);

    // Draw center connection point
    final centerPaint = Paint()
      ..color = relationshipColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 8, centerPaint);

    // Draw center border
    final centerBorderPaint = Paint()
      ..color = AppColors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, 8, centerBorderPaint);
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

  void _drawBraiding(
    Canvas canvas,
    Offset knotACenter,
    Offset knotBCenter,
    double radius,
    Color color,
  ) {
    final braidPaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw interweaving strands based on braid sequence
    // Simplified visualization: draw curved lines connecting the two knots
    final crossingCount = (braidedKnot.braidSequence.length - 1) ~/ 2;
    final maxCrossings = crossingCount.clamp(3, 8); // Limit for visual clarity

    for (int i = 0; i < maxCrossings; i++) {
      // Create curved path between knots
      final path = Path();
      path.moveTo(knotACenter.dx, knotACenter.dy);
      
      // Control points for bezier curve
      final controlPoint1 = Offset(
        knotACenter.dx + (knotBCenter.dx - knotACenter.dx) * 0.3,
        knotACenter.dy - radius * 0.5 * (i.isEven ? 1 : -1),
      );
      final controlPoint2 = Offset(
        knotACenter.dx + (knotBCenter.dx - knotACenter.dx) * 0.7,
        knotBCenter.dy - radius * 0.5 * (i.isEven ? -1 : 1),
      );
      
      path.cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        knotBCenter.dx,
        knotBCenter.dy,
      );
      
      // Alternate over/under based on braid sequence
      if (i < braidedKnot.braidSequence.length - 1) {
        final isOver = braidedKnot.braidSequence[i + 1] > 0.5;
        if (isOver) {
          // Draw over strand (thicker, more opaque)
          final overPaint = Paint()
            ..color = color
            ..strokeWidth = 3
            ..style = PaintingStyle.stroke;
          canvas.drawPath(path, overPaint);
        } else {
          // Draw under strand (thinner, less opaque)
          final underPaint = Paint()
            ..color = color.withValues(alpha: 0.4)
            ..strokeWidth = 1.5
            ..style = PaintingStyle.stroke;
          canvas.drawPath(path, underPaint);
        }
      } else {
        canvas.drawPath(path, braidPaint);
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
  bool shouldRepaint(BraidedKnotPainter oldDelegate) {
    return oldDelegate.braidedKnot != braidedKnot;
  }
}

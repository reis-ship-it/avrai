// Personality Knot Widget
// 
// Widget for visualizing a single personality knot
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Phase 3: Onboarding Integration

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:avrai_core/models/personality_knot.dart';
import 'package:avrai/core/theme/colors.dart';

/// Widget for visualizing a single personality knot
/// 
/// Displays the topological structure of a personality knot
class PersonalityKnotWidget extends StatelessWidget {
  final PersonalityKnot knot;
  final double size;
  final bool showLabels;
  final bool showMetrics;
  final Color? color;

  const PersonalityKnotWidget({
    super.key,
    required this.knot,
    this.size = 150.0,
    this.showLabels = false,
    this.showMetrics = false,
    this.color,
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
            painter: PersonalityKnotPainter(
              knot: knot,
              color: color ?? AppColors.primary,
            ),
            child: Container(),
          ),
        ),
        
        // Labels and metrics (if enabled)
        if (showLabels || showMetrics) ...[
          const SizedBox(height: 8),
          if (showLabels)
            Text(
              'Your Knot',
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
          'Crossings',
          knot.invariants.crossingNumber.toDouble(),
          AppColors.primary,
        ),
        const SizedBox(width: 8),
        _buildMetricChip(
          context,
          'Writhe',
          knot.invariants.writhe.toDouble(),
          AppColors.success,
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
      child: Text(
        '$label: ${value.toStringAsFixed(0)}',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

/// Custom painter for personality knot visualization
class PersonalityKnotPainter extends CustomPainter {
  final PersonalityKnot knot;
  final Color color;

  PersonalityKnotPainter({
    required this.knot,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.35;

    // Draw knot as a circular structure with crossings
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = color;

    // Draw main circle
    canvas.drawCircle(center, radius, paint);

    // Draw crossings based on crossing number
    final crossingCount = knot.invariants.crossingNumber;
    if (crossingCount > 0) {
      final angleStep = (2 * math.pi) / crossingCount;
      for (int i = 0; i < crossingCount; i++) {
        final angle = i * angleStep;
        final crossingPos = Offset(
          center.dx + radius * math.cos(angle),
          center.dy + radius * math.sin(angle),
        );
        
        // Draw crossing indicator
        final crossingPaint = Paint()
          ..style = PaintingStyle.fill
          ..color = color;
        canvas.drawCircle(crossingPos, 6, crossingPaint);
        
        // Draw over/under indicator based on writhe
        final textPainter = TextPainter(
          text: TextSpan(
            text: knot.invariants.writhe > 0 ? 'O' : 'U',
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          crossingPos - Offset(textPainter.width / 2, textPainter.height / 2),
        );
      }
    }

    // Draw center point
    final centerPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = color;
    canvas.drawCircle(center, 4, centerPaint);
  }

  @override
  bool shouldRepaint(PersonalityKnotPainter oldDelegate) {
    return oldDelegate.knot != knot || oldDelegate.color != color;
  }
}

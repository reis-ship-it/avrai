// Knot Pattern Heatmap
//
// Heatmap visualization for pattern strength analysis
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Optional Enhancement: Heatmaps

import 'package:flutter/material.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai_knot/models/knot/knot_pattern_analysis.dart';

/// Heatmap widget for pattern strength visualization
class KnotPatternHeatmap extends StatelessWidget {
  final List<PatternInsight> patterns;
  final double cellSize;

  const KnotPatternHeatmap({
    super.key,
    required this.patterns,
    this.cellSize = 40.0,
  });

  @override
  Widget build(BuildContext context) {
    if (patterns.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text('No patterns to visualize'),
        ),
      );
    }

    // Sort patterns by strength (descending)
    final sortedPatterns = List<PatternInsight>.from(patterns)
      ..sort((a, b) => b.strength.compareTo(a.strength));

    // Calculate grid dimensions
    const columns = 4;
    // ignore: unused_local_variable - Reserved for future grid layout calculations
    final rows = (sortedPatterns.length / columns).ceil();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Text(
            'Pattern Strength Heatmap',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        // Heatmap Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.0,
          ),
          itemCount: sortedPatterns.length,
          itemBuilder: (context, index) {
            final pattern = sortedPatterns[index];
            final strength = pattern.strength;

            // Color intensity based on strength (0.0 = light, 1.0 = dark)
            final colorIntensity = strength.clamp(0.0, 1.0);
            final color = Color.lerp(
              AppTheme.primaryColor.withValues(alpha: 0.2),
              AppTheme.primaryColor,
              colorIntensity,
            )!;

            return Tooltip(
              message:
                  '${pattern.description}\nStrength: ${strength.toStringAsFixed(2)}',
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        (index + 1).toString(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorIntensity > 0.5
                              ? AppColors.white
                              : AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        strength.toStringAsFixed(2),
                        style: TextStyle(
                          fontSize: 10,
                          color: colorIntensity > 0.5
                              ? AppColors.white
                              : AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        // Legend
        Row(
          children: [
            const Text('Low', style: TextStyle(fontSize: 12)),
            Expanded(
              child: Container(
                height: 20,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor.withValues(alpha: 0.2),
                      AppTheme.primaryColor,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const Text('High', style: TextStyle(fontSize: 12)),
          ],
        ),
      ],
    );
  }
}

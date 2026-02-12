// Knot Type Distribution Chart
// 
// Interactive pie chart for knot type distribution
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Optional Enhancement: Interactive Charts

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';

/// Pie chart widget for knot type distribution
class KnotTypeDistributionChart extends StatelessWidget {
  final Map<String, int> distribution;
  final double size;

  const KnotTypeDistributionChart({
    super.key,
    required this.distribution,
    this.size = 200.0,
  });

  @override
  Widget build(BuildContext context) {
    if (distribution.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text('No distribution data available'),
        ),
      );
    }

    final total = distribution.values.reduce((a, b) => a + b);
    final colors = [
      AppTheme.primaryColor,
      AppColors.electricGreen,
      AppColors.warning,
      AppColors.success,
      AppColors.error,
      AppColors.grey600,
    ];

    int colorIndex = 0;
    final pieChartSections = distribution.entries.map((entry) {
      final percentage = (entry.value / total) * 100;
      final color = colors[colorIndex % colors.length];
      colorIndex++;

      return PieChartSectionData(
        value: entry.value.toDouble(),
        title: '${percentage.toStringAsFixed(1)}%',
        color: color,
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.white,
        ),
      );
    }).toList();

    return SizedBox(
      height: size,
      child: Row(
        children: [
          // Pie Chart
          Expanded(
            child: PieChart(
              PieChartData(
                sections: pieChartSections,
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Legend
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: distribution.entries.toList().asMap().entries.map((entry) {
                final index = entry.key;
                final mapEntry = entry.value;
                final color = colors[index % colors.length];
                final percentage = (mapEntry.value / total) * 100;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          mapEntry.key,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      Text(
                        '${mapEntry.value} (${percentage.toStringAsFixed(1)}%)',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// Knot Complexity Distribution Chart
//
// Interactive bar chart for crossing number and writhe distribution
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Optional Enhancement: Interactive Charts

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/presentation/presentation_spacing.dart';

/// Bar chart widget for crossing number distribution
class KnotCrossingNumberChart extends StatelessWidget {
  final Map<int, int> distribution;
  final double height;

  const KnotCrossingNumberChart({
    super.key,
    required this.distribution,
    this.height = 200.0,
  });

  @override
  Widget build(BuildContext context) {
    if (distribution.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text('No crossing number data available'),
        ),
      );
    }

    final sortedEntries = distribution.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final maxValue = distribution.values.reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: height,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxValue * 1.2,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) => AppTheme.primaryColor,
              tooltipBorderRadius: BorderRadius.circular(8),
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final key = value.toInt();
                  if (sortedEntries.any((e) => e.key == key)) {
                    return Padding(
                      padding: const EdgeInsets.only(top: kSpaceXs),
                      child: Text(
                        key.toString(),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    );
                  }
                  return Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: Theme.of(context).textTheme.bodySmall,
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval:
                maxValue > 10 ? (maxValue / 5).ceil().toDouble() : 1,
          ),
          borderData: FlBorderData(show: true),
          barGroups: sortedEntries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value.toDouble(),
                  color: AppTheme.primaryColor,
                  width: 20,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// Bar chart widget for writhe distribution
class KnotWritheChart extends StatelessWidget {
  final Map<int, int> distribution;
  final double height;

  const KnotWritheChart({
    super.key,
    required this.distribution,
    this.height = 200.0,
  });

  @override
  Widget build(BuildContext context) {
    if (distribution.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text('No writhe data available'),
        ),
      );
    }

    final sortedEntries = distribution.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final maxValue = distribution.values.reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: height,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxValue * 1.2,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) => AppColors.electricGreen,
              tooltipBorderRadius: BorderRadius.circular(8),
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final key = value.toInt();
                  if (sortedEntries.any((e) => e.key == key)) {
                    return Padding(
                      padding: const EdgeInsets.only(top: kSpaceXs),
                      child: Text(
                        key.toString(),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    );
                  }
                  return Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: Theme.of(context).textTheme.bodySmall,
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval:
                maxValue > 10 ? (maxValue / 5).ceil().toDouble() : 1,
          ),
          borderData: FlBorderData(show: true),
          barGroups: sortedEntries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value.toDouble(),
                  color: AppColors.electricGreen,
                  width: 20,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

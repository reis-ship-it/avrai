import 'package:flutter/material.dart';
import 'package:avrai/core/theme/colors.dart';

import 'package:avrai/core/models/misc/cross_app_learning_insight.dart';
import 'package:avrai/core/services/cross_app/cross_app_consent_service.dart';
import 'package:avrai/core/services/cross_app/cross_app_learning_insight_service.dart';
import 'package:avrai/injection_container.dart' as di;

/// Widget displaying the effectiveness of cross-app learning
///
/// Shows:
/// - Total insights learned
/// - Per-source statistics
/// - Learning activity over time
/// - Effectiveness indicators
class LearningEffectivenessWidget extends StatefulWidget {
  const LearningEffectivenessWidget({super.key});

  @override
  State<LearningEffectivenessWidget> createState() =>
      _LearningEffectivenessWidgetState();
}

class _LearningEffectivenessWidgetState
    extends State<LearningEffectivenessWidget> {
  CrossAppLearningInsightService? _insightService;
  CrossAppLearningHistory? _history;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (di.sl.isRegistered<CrossAppLearningInsightService>()) {
      _insightService = di.sl<CrossAppLearningInsightService>();
    }
    _loadData();
  }

  Future<void> _loadData() async {
    if (_insightService == null) {
      setState(() => _isLoading = false);
      return;
    }

    final history = _insightService!.getLearningHistory();
    if (mounted) {
      setState(() {
        _history = history;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.grey800 : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? AppColors.white.withValues(alpha: 0.1)
              : AppColors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.insights,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Learning Effectiveness',
                style: textTheme.titleMedium?.copyWith(
                  color: isDark ? AppColors.white : Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Overall stats
          _buildOverallStats(isDark, textTheme),
          const SizedBox(height: 20),

          // Per-source breakdown
          _buildSourceBreakdown(isDark, textTheme),
        ],
      ),
    );
  }

  Widget _buildOverallStats(bool isDark, TextTheme textTheme) {
    final totalInsights = _history?.totalInsights ?? 0;
    final activeSources = _history?.sourceStats.values
            .where((s) => s.insightCount > 0)
            .length ??
        0;
    final lastLearning = _history?.lastLearningAt;

    return Row(
      children: [
        // Total insights
        Expanded(
          child: _buildStatCard(
            icon: Icons.lightbulb_outline,
            label: 'Total Insights',
            value: totalInsights.toString(),
            color: AppColors.warning,
            isDark: isDark,
            textTheme: textTheme,
          ),
        ),
        const SizedBox(width: 12),
        // Active sources
        Expanded(
          child: _buildStatCard(
            icon: Icons.apps,
            label: 'Active Sources',
            value: '$activeSources/4',
            color: AppColors.electricBlue,
            isDark: isDark,
            textTheme: textTheme,
          ),
        ),
        const SizedBox(width: 12),
        // Last learning
        Expanded(
          child: _buildStatCard(
            icon: Icons.schedule,
            label: 'Last Learning',
            value: lastLearning != null
                ? _formatTimeAgo(lastLearning)
                : 'Never',
            color: AppColors.success,
            isDark: isDark,
            textTheme: textTheme,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
    required TextTheme textTheme,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: textTheme.titleMedium?.copyWith(
              color: isDark ? AppColors.white : Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(
              color: isDark ? Colors.white54 : Colors.black54,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceBreakdown(bool isDark, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'By Source',
          style: textTheme.titleSmall?.copyWith(
            color: isDark ? Colors.white70 : Colors.black54,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...CrossAppDataSource.values.map((source) {
          final stats = _history?.getStatsForSource(source) ??
              SourceLearningStats.initial();
          return _buildSourceRow(source, stats, isDark, textTheme);
        }),
      ],
    );
  }

  Widget _buildSourceRow(
    CrossAppDataSource source,
    SourceLearningStats stats,
    bool isDark,
    TextTheme textTheme,
  ) {
    final maxInsights = 50; // Maximum expected insights per source
    final progress = (stats.insightCount / maxInsights).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Source icon
          Text(source.icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          // Source name and progress
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      source.displayName,
                      style: textTheme.bodySmall?.copyWith(
                        color: isDark ? AppColors.white : Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${stats.insightCount} insights',
                      style: textTheme.bodySmall?.copyWith(
                        color: isDark ? Colors.white54 : Colors.black45,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: isDark
                        ? AppColors.white.withValues(alpha: 0.1)
                        : AppColors.black.withValues(alpha: 0.05),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getSourceColor(source),
                    ),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Status indicator
          _buildStatusIndicator(stats, isDark),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(SourceLearningStats stats, bool isDark) {
    IconData icon;
    Color color;

    if (stats.hasIssue) {
      icon = Icons.warning_amber;
      color = AppColors.warning;
    } else if (stats.isActive) {
      icon = Icons.check_circle;
      color = AppColors.success;
    } else {
      icon = Icons.circle_outlined;
      color = isDark ? Colors.white38 : Colors.black26;
    }

    return Icon(icon, size: 18, color: color);
  }

  Color _getSourceColor(CrossAppDataSource source) {
    switch (source) {
      case CrossAppDataSource.calendar:
        return AppColors.electricBlue;
      case CrossAppDataSource.health:
        return AppColors.error;
      case CrossAppDataSource.media:
        return Colors.purple;
      case CrossAppDataSource.appUsage:
        return AppColors.success;
    }
  }

  String _formatTimeAgo(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);

    if (diff.inMinutes < 1) {
      return 'Now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h';
    } else {
      return '${diff.inDays}d';
    }
  }
}

import 'package:flutter/material.dart';
import 'package:avrai/core/theme/colors.dart';

import 'package:avrai/core/models/misc/cross_app_learning_insight.dart';
import 'package:avrai/core/services/cross_app/cross_app_consent_service.dart';
import 'package:avrai/core/services/cross_app/cross_app_learning_insight_service.dart';
import 'package:avrai/injection_container.dart' as di;

/// Widget displaying insights learned from cross-app tracking
///
/// Shows what the AI has learned from each data source:
/// - Calendar patterns
/// - Health/fitness insights
/// - Music/mood preferences
/// - App usage behaviors
///
/// Provides transparency into the AI's learning process.
class CrossAppLearningInsightsWidget extends StatefulWidget {
  /// Maximum number of insights to display per source
  final int maxInsightsPerSource;

  /// Whether to show empty sources
  final bool showEmptySources;

  const CrossAppLearningInsightsWidget({
    super.key,
    this.maxInsightsPerSource = 3,
    this.showEmptySources = false,
  });

  @override
  State<CrossAppLearningInsightsWidget> createState() =>
      _CrossAppLearningInsightsWidgetState();
}

class _CrossAppLearningInsightsWidgetState
    extends State<CrossAppLearningInsightsWidget> {
  CrossAppLearningInsightService? _insightService;
  CrossAppLearningHistory? _history;
  bool _isLoading = true;
  final Set<CrossAppDataSource> _expandedSources = {};

  @override
  void initState() {
    super.initState();
    if (di.sl.isRegistered<CrossAppLearningInsightService>()) {
      _insightService = di.sl<CrossAppLearningInsightService>();
    }
    _loadInsights();
  }

  Future<void> _loadInsights() async {
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

    if (_history == null || _history!.totalInsights == 0) {
      return _buildEmptyState(isDark, textTheme);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Icon(
              Icons.lightbulb_outline,
              color: AppColors.primary,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'What Your AI Learned',
              style: textTheme.titleMedium?.copyWith(
                color: isDark ? AppColors.white : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              '${_history!.totalInsights} insights',
              style: textTheme.bodySmall?.copyWith(
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Source sections
        ...CrossAppDataSource.values.map((source) {
          final insights = _history!.getInsightsForSource(source);
          if (insights.isEmpty && !widget.showEmptySources) {
            return const SizedBox.shrink();
          }
          return _buildSourceSection(source, insights, isDark, textTheme);
        }),
      ],
    );
  }

  Widget _buildEmptyState(bool isDark, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.grey800 : AppColors.grey100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? AppColors.white.withValues(alpha: 0.1)
              : AppColors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.psychology_outlined,
            size: 48,
            color: isDark ? Colors.white38 : Colors.black26,
          ),
          const SizedBox(height: 12),
          Text(
            'No Insights Yet',
            style: textTheme.titleMedium?.copyWith(
              color: isDark ? Colors.white70 : Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your AI is learning from your enabled data sources. Check back later to see what it has discovered.',
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceSection(
    CrossAppDataSource source,
    List<CrossAppLearningInsight> insights,
    bool isDark,
    TextTheme textTheme,
  ) {
    final isExpanded = _expandedSources.contains(source);
    final displayInsights = isExpanded
        ? insights
        : insights.take(widget.maxInsightsPerSource).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.grey800 : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? AppColors.white.withValues(alpha: 0.1)
              : AppColors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Source header
          InkWell(
            onTap: insights.length > widget.maxInsightsPerSource
                ? () {
                    setState(() {
                      if (isExpanded) {
                        _expandedSources.remove(source);
                      } else {
                        _expandedSources.add(source);
                      }
                    });
                  }
                : null,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    source.icon,
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          source.displayName,
                          style: textTheme.bodyLarge?.copyWith(
                            color: isDark ? AppColors.white : Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (insights.isNotEmpty)
                          Text(
                            '${insights.length} insight${insights.length == 1 ? '' : 's'}',
                            style: textTheme.bodySmall?.copyWith(
                              color: isDark ? Colors.white54 : Colors.black45,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (insights.length > widget.maxInsightsPerSource)
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                ],
              ),
            ),
          ),

          // Insights list
          if (insights.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                'No insights yet from ${source.displayName.toLowerCase()}',
                style: textTheme.bodySmall?.copyWith(
                  color: isDark ? Colors.white38 : Colors.black38,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            ...displayInsights.map((insight) => _buildInsightTile(
                  insight,
                  isDark,
                  textTheme,
                )),

          // Show more indicator
          if (!isExpanded && insights.length > widget.maxInsightsPerSource)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                '+ ${insights.length - widget.maxInsightsPerSource} more',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInsightTile(
    CrossAppLearningInsight insight,
    bool isDark,
    TextTheme textTheme,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6, right: 12),
            decoration: BoxDecoration(
              color: _getInsightColor(insight.insightType),
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.description,
                  style: textTheme.bodyMedium?.copyWith(
                    color: isDark ? AppColors.white.withValues(alpha: 0.87) : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 12,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatTimestamp(insight.learnedAt),
                      style: textTheme.bodySmall?.copyWith(
                        color: isDark ? Colors.white38 : Colors.black38,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getInsightColor(insight.insightType)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        insight.insightType.name,
                        style: textTheme.bodySmall?.copyWith(
                          color: _getInsightColor(insight.insightType),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getInsightColor(InsightType type) {
    switch (type) {
      case InsightType.pattern:
        return AppColors.electricBlue;
      case InsightType.preference:
        return Colors.purple;
      case InsightType.behavior:
        return AppColors.success;
      case InsightType.temporal:
        return AppColors.warning;
      case InsightType.spatial:
        return Colors.teal;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${(diff.inDays / 7).floor()}w ago';
    }
  }
}

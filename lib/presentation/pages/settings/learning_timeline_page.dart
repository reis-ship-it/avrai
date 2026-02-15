import 'package:flutter/material.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/tokens/theme_tokens.dart';

import 'package:avrai/core/models/misc/cross_app_learning_insight.dart';
import 'package:avrai/core/services/cross_app/cross_app_consent_service.dart';
import 'package:avrai/core/services/cross_app/cross_app_learning_insight_service.dart';
import 'package:avrai/injection_container.dart' as di;
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';
import 'package:avrai/presentation/widgets/portal/portal_surface.dart';

/// Page displaying the timeline of cross-app learning events
///
/// Shows when insights were learned, from which sources,
/// and how they affected the AI's understanding.
class LearningTimelinePage extends StatefulWidget {
  const LearningTimelinePage({super.key});

  @override
  State<LearningTimelinePage> createState() => _LearningTimelinePageState();
}

class _LearningTimelinePageState extends State<LearningTimelinePage> {
  CrossAppLearningInsightService? _insightService;
  List<CrossAppLearningInsight> _insights = [];
  CrossAppDataSource? _filterSource;
  bool _isLoading = true;

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

    final insights = _filterSource != null
        ? _insightService!.getInsightsBySource(_filterSource!)
        : _insightService!.getAllInsights();

    if (mounted) {
      setState(() {
        _insights = insights;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    return AdaptivePlatformPageScaffold(
      title: 'Learning Timeline',
      constrainBody: false,
      body: Column(
        children: [
          // Filter chips
          _buildFilterChips(isDark, textTheme),
          const Divider(height: 1),

          // Timeline
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _insights.isEmpty
                    ? _buildEmptyState(isDark, textTheme)
                    : _buildTimeline(isDark, textTheme),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(bool isDark, TextTheme textTheme) {
    final spacing = context.spacing;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding:
          EdgeInsets.symmetric(horizontal: spacing.md, vertical: spacing.sm),
      child: Row(
        children: [
          // All filter
          _buildFilterChip(
            label: 'All',
            icon: '🔮',
            isSelected: _filterSource == null,
            onTap: () {
              setState(() => _filterSource = null);
              _loadInsights();
            },
            isDark: isDark,
          ),
          SizedBox(width: spacing.xs),
          // Source filters
          ...CrossAppDataSource.values.map((source) => Padding(
                padding: EdgeInsets.only(right: spacing.xs),
                child: _buildFilterChip(
                  label: source.displayName,
                  icon: source.icon,
                  isSelected: _filterSource == source,
                  onTap: () {
                    setState(() => _filterSource = source);
                    _loadInsights();
                  },
                  isDark: isDark,
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final spacing = context.spacing;
    final textTheme = Theme.of(context).textTheme;
    final chipTextColor = isSelected
        ? AppColors.white
        : (isDark ? Colors.white70 : Colors.black87);
    return GestureDetector(
      onTap: onTap,
      child: Chip(
        backgroundColor: isSelected
            ? AppColors.primary
            : (isDark ? AppColors.grey800 : AppColors.white),
        side: BorderSide(
          color: isSelected
              ? AppColors.primary
              : (isDark
                  ? AppColors.white.withValues(alpha: 0.1)
                  : AppColors.black.withValues(alpha: 0.1)),
        ),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        labelPadding: EdgeInsets.symmetric(horizontal: spacing.xxs),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: textTheme.bodyMedium),
            SizedBox(width: spacing.xxs),
            Text(
              label,
              style: textTheme.bodySmall?.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: chipTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, TextTheme textTheme) {
    final spacing = context.spacing;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(spacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.timeline,
              size: 64,
              color: isDark ? Colors.white24 : Colors.black12,
            ),
            SizedBox(height: spacing.md),
            Text(
              'No Learning Events Yet',
              style: textTheme.titleMedium?.copyWith(
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            SizedBox(height: spacing.xs),
            Text(
              'As your AI learns from your activities, you\'ll see the timeline here.',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline(bool isDark, TextTheme textTheme) {
    final spacing = context.spacing;
    return ListView.builder(
      padding: EdgeInsets.all(spacing.md),
      itemCount: _insights.length,
      itemBuilder: (context, index) {
        final insight = _insights[index];
        final isLast = index == _insights.length - 1;
        return _buildTimelineItem(insight, isLast, isDark, textTheme);
      },
    );
  }

  Widget _buildTimelineItem(
    CrossAppLearningInsight insight,
    bool isLast,
    bool isDark,
    TextTheme textTheme,
  ) {
    final spacing = context.spacing;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line and dot
          SizedBox(
            width: spacing.xl,
            child: Column(
              children: [
                CircleAvatar(
                  radius: spacing.xxs + (spacing.xs / 2),
                  backgroundColor: AppColors.primary,
                  child: CircleAvatar(
                    radius: spacing.xxs,
                    backgroundColor:
                        isDark ? AppColors.grey800 : AppColors.white,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: PortalSurface(
              margin: EdgeInsets.only(bottom: spacing.md),
              padding: EdgeInsets.all(spacing.sm),
              color: isDark ? AppColors.grey800 : AppColors.white,
              borderColor: isDark
                  ? AppColors.white.withValues(alpha: 0.1)
                  : AppColors.black.withValues(alpha: 0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Text(
                        insight.source.icon,
                        style: textTheme.bodyLarge,
                      ),
                      SizedBox(width: spacing.xs),
                      Text(
                        insight.source.displayName,
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatTimestamp(insight.learnedAt),
                        style: textTheme.bodySmall?.copyWith(
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: spacing.xs),
                  // Description
                  Text(
                    insight.description,
                    style: textTheme.bodyMedium?.copyWith(
                      color: isDark ? AppColors.white : Colors.black87,
                    ),
                  ),
                  SizedBox(height: spacing.xs),
                  // Affected dimensions
                  if (insight.affectedDimensions.isNotEmpty)
                    Wrap(
                      spacing: spacing.xs - (spacing.xxs / 2),
                      runSpacing: spacing.xxs,
                      children: insight.affectedDimensions.map((dim) {
                        return Chip(
                          side: BorderSide.none,
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          backgroundColor: isDark
                              ? AppColors.white.withValues(alpha: 0.1)
                              : AppColors.black.withValues(alpha: 0.05),
                          label: Text(
                            dim.replaceAll('_', ' '),
                            style: textTheme.bodySmall?.copyWith(
                              color: isDark ? Colors.white54 : Colors.black54,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}

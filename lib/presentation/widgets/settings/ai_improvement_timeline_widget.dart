/// AI Improvement History Timeline Widget
///
/// Part of Feature Matrix Phase 2: Medium Priority UI/UX
/// Section 2.2: AI Self-Improvement Visibility
///
/// Widget showing AI improvement history as a timeline:
/// - Timeline of improvements
/// - Major milestones
/// - Evolution events
/// - Achievement markers
///
/// Location: Settings/Account page
/// Uses AppColors and AppTheme for consistent styling per design token requirements.
library;

import 'package:flutter/material.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/services/ai_infrastructure/ai_improvement_tracking_service.dart';
import 'package:avrai/core/theme/tokens/theme_tokens.dart';
import 'package:avrai/presentation/presentation_spacing.dart';

/// Widget displaying AI improvement history timeline
class AIImprovementTimelineWidget extends StatefulWidget {
  /// User ID to show timeline for
  final String userId;

  /// Improvement tracking service
  final AIImprovementTrackingService trackingService;

  const AIImprovementTimelineWidget({
    super.key,
    required this.userId,
    required this.trackingService,
  });

  @override
  State<AIImprovementTimelineWidget> createState() =>
      _AIImprovementTimelineWidgetState();
}

class _AIImprovementTimelineWidgetState
    extends State<AIImprovementTimelineWidget> {
  List<ImprovementMilestone> _milestones = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMilestones();
  }

  void _loadMilestones() {
    setState(() {
      _isLoading = true;
    });

    try {
      final milestones = widget.trackingService.getMilestones(widget.userId);

      setState(() {
        _milestones = milestones;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    return Semantics(
      label: 'AI Improvement History Timeline',
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.only(bottom: spacing.md),
        child: Padding(
          padding: EdgeInsets.all(spacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              if (_isLoading)
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(spacing.lg),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_milestones.isEmpty)
                _buildEmptyState()
              else
                _buildTimeline(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final spacing = context.spacing;
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(spacing.xs),
          decoration: BoxDecoration(
            color: AppColors.electricGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.timeline,
            color: AppColors.electricGreen,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Improvement History',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
              ),
              Text(
                '${_milestones.length} milestones achieved',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final spacing = context.spacing;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(spacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.history,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No Milestones Yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your AI will track significant improvements as milestones',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _milestones.length,
      itemBuilder: (context, index) {
        final milestone = _milestones[index];
        final isFirst = index == 0;
        final isLast = index == _milestones.length - 1;

        return _buildTimelineItem(
          milestone: milestone,
          isFirst: isFirst,
          isLast: isLast,
        );
      },
    );
  }

  Widget _buildTimelineItem({
    required ImprovementMilestone milestone,
    required bool isFirst,
    required bool isLast,
  }) {
    final spacing = context.spacing;
    final improvementColor = _getImprovementColor(milestone.improvement);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline indicator column
        SizedBox(
          width: 40,
          child: Column(
            children: [
              if (!isFirst)
                Container(
                  width: 2,
                  height: 20,
                  color: AppColors.grey300,
                ),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: improvementColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.white,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: improvementColor.withValues(alpha: 0.3),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(
                  _getImprovementIcon(milestone.improvement),
                  size: 12,
                  color: AppColors.white,
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 40,
                  color: AppColors.grey300,
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Milestone content
        Expanded(
          child: Container(
            margin: EdgeInsets.only(bottom: spacing.md),
            padding: EdgeInsets.all(spacing.sm),
            decoration: BoxDecoration(
              color: AppColors.grey100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        milestone.description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: kSpaceXs,
                        vertical: kSpaceXxs,
                      ),
                      decoration: BoxDecoration(
                        color: improvementColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '+${(milestone.improvement * 100).toStringAsFixed(0)}%',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: improvementColor,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _formatDimensionName(milestone.dimension),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ),
                    Text(
                      _formatTimeAgo(milestone.timestamp),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildScoreBadge(
                      'From',
                      milestone.fromScore,
                      isFrom: true,
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    _buildScoreBadge(
                      'To',
                      milestone.toScore,
                      isFrom: false,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScoreBadge(String label, double score, {required bool isFrom}) {
    final spacing = context.spacing;
    final color = _getScoreColor(score);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.xs,
        vertical: spacing.xxs,
      ),
      decoration: BoxDecoration(
        color: isFrom ? AppColors.grey200 : color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(width: 4),
          Text(
            '${(score * 100).toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isFrom ? AppColors.textSecondary : color,
                ),
          ),
        ],
      ),
    );
  }

  Color _getImprovementColor(double improvement) {
    if (improvement >= 0.15) return AppColors.success;
    if (improvement >= 0.10) return AppColors.electricGreen;
    return AppColors.primary;
  }

  IconData _getImprovementIcon(double improvement) {
    if (improvement >= 0.15) return Icons.star;
    if (improvement >= 0.10) return Icons.arrow_upward;
    return Icons.trending_up;
  }

  Color _getScoreColor(double score) {
    if (score >= 0.9) return AppColors.success;
    if (score >= 0.75) return AppColors.electricGreen;
    if (score >= 0.6) return AppColors.warning;
    return AppColors.error;
  }

  String _formatDimensionName(String dimension) {
    return dimension
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  String _formatTimeAgo(DateTime time) {
    final duration = DateTime.now().difference(time);

    if (duration.inMinutes < 1) return 'just now';
    if (duration.inMinutes < 60) return '${duration.inMinutes}m ago';
    if (duration.inHours < 24) return '${duration.inHours}h ago';
    if (duration.inDays < 7) return '${duration.inDays}d ago';
    if (duration.inDays < 30) return '${(duration.inDays / 7).floor()}w ago';
    return '${(duration.inDays / 30).floor()}mo ago';
  }
}

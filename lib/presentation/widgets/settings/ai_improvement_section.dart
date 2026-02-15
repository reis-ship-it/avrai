/// AI Improvement Metrics Section
///
/// Part of Feature Matrix Phase 2: Medium Priority UI/UX
/// Section 2.2: AI Self-Improvement Visibility
///
/// Widget showing AI improvement metrics in Settings/Account page:
/// - Overall improvement score
/// - Performance dimensions with scores
/// - Improvement rate and trend
/// - Accuracy measurements
/// - Total improvements count
///
/// Location: Settings/Account page
/// Uses AppColors and AppTheme for consistent styling per design token requirements.
library;

import 'package:flutter/material.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/services/ai_infrastructure/ai_improvement_tracking_service.dart';
import 'package:avrai/core/theme/tokens/theme_tokens.dart';

/// Widget displaying AI improvement metrics section
class AIImprovementSection extends StatefulWidget {
  /// User ID to show metrics for
  final String userId;

  /// Improvement tracking service
  final AIImprovementTrackingService trackingService;

  const AIImprovementSection({
    super.key,
    required this.userId,
    required this.trackingService,
  });

  @override
  State<AIImprovementSection> createState() => _AIImprovementSectionState();
}

class _AIImprovementSectionState extends State<AIImprovementSection> {
  AIImprovementMetrics? _metrics;
  AccuracyMetrics? _accuracyMetrics;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMetrics();

    // Listen to metrics stream for real-time updates
    widget.trackingService.metricsStream.listen((metrics) {
      if (mounted && metrics.userId == widget.userId) {
        setState(() {
          _metrics = metrics;
        });
      }
    });
  }

  Future<void> _loadMetrics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final metrics =
          await widget.trackingService.getCurrentMetrics(widget.userId);
      final accuracyMetrics =
          await widget.trackingService.getAccuracyMetrics(widget.userId);

      if (mounted) {
        setState(() {
          _metrics = metrics;
          _accuracyMetrics = accuracyMetrics;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    if (_isLoading) {
      return Semantics(
        label: 'Loading AI improvement metrics',
        child: Card(
          margin: EdgeInsets.only(bottom: spacing.md),
          child: Padding(
            padding: EdgeInsets.all(spacing.lg),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      );
    }

    if (_metrics == null) {
      return Semantics(
        label: 'No improvement data available',
        child: Card(
          margin: EdgeInsets.only(bottom: spacing.md),
          child: Padding(
            padding: EdgeInsets.all(spacing.lg),
            child: Center(
              child: Text('No improvement data available'),
            ),
          ),
        ),
      );
    }

    return Semantics(
      label: 'AI Improvement Metrics',
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
              const SizedBox(height: 20),
              _buildOverallScore(),
              const SizedBox(height: 24),
              _buildAccuracySection(),
              const SizedBox(height: 24),
              _buildPerformanceScores(),
              const SizedBox(height: 24),
              _buildDimensionScores(),
              const SizedBox(height: 16),
              _buildImprovementRate(),
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
            Icons.trending_up,
            color: AppColors.electricGreen,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'AI Improvement Metrics',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
          ),
        ),
        Semantics(
          label: 'Learn more about AI improvement metrics',
          button: true,
          child: IconButton(
            icon: const Icon(
              Icons.info_outline,
              color: AppColors.textSecondary,
              size: 20,
            ),
            onPressed: _showInfoDialog,
            tooltip: 'Learn more',
          ),
        ),
      ],
    );
  }

  Widget _buildOverallScore() {
    final spacing = context.spacing;
    final score = _metrics!.overallScore;
    final scoreColor = _getScoreColor(score);
    final scoreLabel = _getScoreLabel(score);

    return Container(
      padding: EdgeInsets.all(spacing.md),
      decoration: BoxDecoration(
        color: scoreColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: scoreColor.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Overall AI Performance',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
              ),
              Text(
                scoreLabel,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: scoreColor,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Semantics(
            label:
                'Overall AI performance: ${(score * 100).toStringAsFixed(1)}%',
            value: '${(score * 100).toStringAsFixed(1)}%',
            child: LinearProgressIndicator(
              value: score,
              backgroundColor: AppColors.grey200,
              valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(score * 100).toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: scoreColor,
                    ),
              ),
              Text(
                '${_metrics!.totalImprovements} improvements',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccuracySection() {
    if (_accuracyMetrics == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.verified_outlined,
              size: 18,
              color: AppColors.electricGreen,
            ),
            SizedBox(width: 8),
            Text(
              'Accuracy Measurements',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildAccuracyItem(
          'Recommendation Acceptance',
          _accuracyMetrics!.recommendationAcceptanceRate,
          '${_accuracyMetrics!.acceptedRecommendations}/${_accuracyMetrics!.totalRecommendations} accepted',
        ),
        const SizedBox(height: 8),
        _buildAccuracyItem(
          'Prediction Accuracy',
          _accuracyMetrics!.predictionAccuracy,
          'Pattern recognition quality',
        ),
        const SizedBox(height: 8),
        _buildAccuracyItem(
          'User Satisfaction',
          _accuracyMetrics!.userSatisfactionScore,
          'Based on user feedback',
        ),
      ],
    );
  }

  Widget _buildAccuracyItem(String label, double score, String subtitle) {
    final spacing = context.spacing;
    final color = _getScoreColor(score);

    return Container(
      padding: EdgeInsets.all(spacing.sm),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Semantics(
              label: '$label: ${(score * 100).toStringAsFixed(0)}%',
              value: '${(score * 100).toStringAsFixed(0)}%',
              child: LinearProgressIndicator(
                value: score,
                backgroundColor: AppColors.grey200,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${(score * 100).toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceScores() {
    final spacing = context.spacing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.speed,
              size: 18,
              color: AppColors.electricGreen,
            ),
            SizedBox(width: 8),
            Text(
              'Performance Scores',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._metrics!.performanceScores.entries.map((entry) {
          return Padding(
            padding: EdgeInsets.only(bottom: spacing.xs),
            child: _buildScoreItem(
              _formatDimensionName(entry.key),
              entry.value,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDimensionScores() {
    final spacing = context.spacing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.insights,
              size: 18,
              color: AppColors.electricGreen,
            ),
            SizedBox(width: 8),
            Text(
              'Improvement Dimensions',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._metrics!.dimensionScores.entries.take(6).map((entry) {
          return Padding(
            padding: EdgeInsets.only(bottom: spacing.xs),
            child: _buildScoreItem(
              _formatDimensionName(entry.key),
              entry.value,
            ),
          );
        }),
        if (_metrics!.dimensionScores.length > 6)
          Semantics(
            label: 'View all improvement dimensions',
            button: true,
            child: TextButton(
              onPressed: () {
                // Show all dimensions dialog
                _showAllDimensionsDialog();
              },
              child: Text('View all dimensions'),
            ),
          ),
      ],
    );
  }

  Widget _buildScoreItem(String label, double score) {
    final color = _getScoreColor(score);

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 100,
          child: Semantics(
            label: '$label: ${(score * 100).toStringAsFixed(0)}%',
            value: '${(score * 100).toStringAsFixed(0)}%',
            child: LinearProgressIndicator(
              value: score,
              backgroundColor: AppColors.grey200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 45,
          child: Text(
            '${(score * 100).toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildImprovementRate() {
    final spacing = context.spacing;
    final rate = _metrics!.improvementRate;
    final isPositive = rate > 0;
    final color = isPositive ? AppColors.success : AppColors.error;

    return Container(
      padding: EdgeInsets.all(spacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isPositive
                  ? 'Improving at ${(rate * 100).toStringAsFixed(1)}% per week'
                  : 'Stable performance',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
            ),
          ),
          Text(
            'Updated ${_formatTimeAgo(_metrics!.lastUpdated)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 0.9) return AppColors.success;
    if (score >= 0.75) return AppColors.electricGreen;
    if (score >= 0.6) return AppColors.warning;
    return AppColors.error;
  }

  String _getScoreLabel(double score) {
    if (score >= 0.9) return 'Excellent';
    if (score >= 0.75) return 'Good';
    if (score >= 0.6) return 'Fair';
    return 'Needs Improvement';
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
    return '${duration.inDays}d ago';
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('AI Improvement Metrics'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Your AI continuously learns and improves across multiple dimensions:',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 12),
              Text(
                  '• Accuracy: How well recommendations match your preferences'),
              SizedBox(height: 8),
              Text('• Speed: How quickly AI processes and responds'),
              SizedBox(height: 8),
              Text('• Efficiency: Resource usage and optimization'),
              SizedBox(height: 8),
              Text('• Adaptability: How well AI adjusts to changes'),
              SizedBox(height: 8),
              Text('• Creativity: AI\'s ability to suggest novel ideas'),
              SizedBox(height: 8),
              Text('• Collaboration: Effectiveness in AI-to-AI learning'),
              SizedBox(height: 12),
              Text(
                'Metrics update every 5 minutes based on your interactions.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showAllDimensionsDialog() {
    final spacing = context.spacing;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('All Improvement Dimensions'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: _metrics!.dimensionScores.entries.map((entry) {
              return Padding(
                padding: EdgeInsets.only(bottom: spacing.sm),
                child: _buildScoreItem(
                  _formatDimensionName(entry.key),
                  entry.value,
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}

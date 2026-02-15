import 'package:flutter/material.dart';
import 'package:avrai/core/models/user/unified_user.dart';
import 'package:avrai/core/models/expertise/expertise_requirements.dart';
import 'package:avrai/core/services/recommendations/dynamic_threshold_service.dart';
import 'package:avrai/core/services/geographic/locality_value_analysis_service.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/core/theme/tokens/theme_tokens.dart';

/// Locality Threshold Widget
/// Agent 2: Phase 6, Week 25 - Qualification UI
///
/// CRITICAL: Uses AppColors/AppTheme (100% adherence required)
///
/// Features:
/// - Show current threshold for user's locality
/// - Show how locality values different activities
/// - Show progress to local expert qualification
/// - Display locality-specific adjustments
class LocalityThresholdWidget extends StatefulWidget {
  final UnifiedUser user;
  final String category;
  final String? locality;
  final ThresholdValues? baseThresholds;

  const LocalityThresholdWidget({
    super.key,
    required this.user,
    required this.category,
    this.locality,
    this.baseThresholds,
  });

  @override
  State<LocalityThresholdWidget> createState() =>
      _LocalityThresholdWidgetState();
}

class _LocalityThresholdWidgetState extends State<LocalityThresholdWidget> {
  final DynamicThresholdService _thresholdService = DynamicThresholdService();
  final LocalityValueAnalysisService _valueService =
      LocalityValueAnalysisService();

  ThresholdValues? _localityThresholds;
  Map<String, double>? _activityWeights;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLocalityThresholds();
  }

  Future<void> _loadLocalityThresholds() async {
    if (widget.locality == null || widget.baseThresholds == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get locality-specific thresholds
      final thresholds = await _thresholdService.calculateLocalThreshold(
        locality: widget.locality!,
        category: widget.category,
        baseThresholds: widget.baseThresholds!,
      );

      // Get activity weights to show what locality values
      final weights = await _valueService.getActivityWeights(widget.locality!);

      setState(() {
        _localityThresholds = thresholds;
        _activityWeights = weights;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Get activity display name
  String _getActivityDisplayName(String activity) {
    switch (activity) {
      case 'events_hosted':
        return 'Events Hosted';
      case 'lists_created':
        return 'Lists Created';
      case 'reviews_written':
        return 'Reviews Written';
      case 'event_attendance':
        return 'Event Attendance';
      case 'professional_background':
        return 'Professional Background';
      case 'positive_trends':
        return 'Positive Trends';
      default:
        return activity;
    }
  }

  /// Get activity icon
  IconData _getActivityIcon(String activity) {
    switch (activity) {
      case 'events_hosted':
        return Icons.event;
      case 'lists_created':
        return Icons.list;
      case 'reviews_written':
        return Icons.rate_review;
      case 'event_attendance':
        return Icons.people;
      case 'professional_background':
        return Icons.work;
      case 'positive_trends':
        return Icons.trending_up;
      default:
        return Icons.info;
    }
  }

  /// Get weight color based on value
  Color _getWeightColor(double weight) {
    if (weight >= 0.25) {
      return AppColors.electricGreen; // High value
    } else if (weight >= 0.15) {
      return AppTheme.primaryColor; // Medium value
    } else {
      return AppColors.textSecondary; // Low value
    }
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    if (widget.locality == null) {
      return const SizedBox.shrink();
    }

    if (_isLoading) {
      return Container(
        padding: EdgeInsets.all(spacing.md),
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.textSecondary.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.primaryColor,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Loading locality-specific thresholds...',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Container(
        padding: EdgeInsets.all(spacing.md),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.error.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline,
              size: 16,
              color: AppColors.error,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Error loading thresholds: $_error',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.error,
                    ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(spacing.md),
      decoration: BoxDecoration(
        color: AppColors.electricGreen.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.electricGreen.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(
                Icons.location_on,
                color: AppColors.electricGreen,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Locality-Specific Thresholds',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    Text(
                      widget.locality!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              const Tooltip(
                message: 'Thresholds adapt to what your locality values most. '
                    'Activities valued by your locality have lower thresholds.',
                child: Icon(
                  Icons.help_outline,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Threshold Summary
          if (_localityThresholds != null) ...[
            Container(
              padding: EdgeInsets.all(spacing.sm),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Qualification Requirements',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  _buildThresholdRow('Visits', _localityThresholds!.minVisits),
                  if (_localityThresholds!.minRatings > 0)
                    _buildThresholdRow(
                        'Ratings', _localityThresholds!.minRatings),
                  if (_localityThresholds!.minEventHosting != null)
                    _buildThresholdRow(
                        'Events Hosted', _localityThresholds!.minEventHosting!),
                  if (_localityThresholds!.minListCuration != null)
                    _buildThresholdRow(
                        'Lists Created', _localityThresholds!.minListCuration!),
                  if (_localityThresholds!.minCommunityEngagement != null)
                    _buildThresholdRow('Community Engagement',
                        _localityThresholds!.minCommunityEngagement!),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Activity Values
          if (_activityWeights != null && _activityWeights!.isNotEmpty) ...[
            Text(
              'What Your Locality Values',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 8),
            ..._activityWeights!.entries.map((entry) {
              final activity = entry.key;
              final weight = entry.value;
              return _buildActivityValueRow(activity, weight);
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildThresholdRow(String label, int value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.spacing.xxs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          Text(
            value.toString(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityValueRow(String activity, double weight) {
    final displayName = _getActivityDisplayName(activity);
    final icon = _getActivityIcon(activity);
    final color = _getWeightColor(weight);
    final percentage = (weight * 100).toStringAsFixed(0);

    return Container(
      margin: EdgeInsets.only(bottom: context.spacing.xs),
      padding: EdgeInsets.all(context.spacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              displayName,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: context.spacing.xs,
              vertical: context.spacing.xxs,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '$percentage%',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

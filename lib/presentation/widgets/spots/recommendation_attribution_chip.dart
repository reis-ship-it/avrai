import 'package:flutter/material.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/tokens/theme_tokens.dart';

import 'package:avrai/core/models/quantum/recommendation_attribution.dart';

/// A compact chip displaying why a spot was recommended
///
/// Shows:
/// - Primary reason as text
/// - Cross-app learning indicators (source icons)
/// - Expandable to show full attribution breakdown
class RecommendationAttributionChip extends StatelessWidget {
  /// The attribution data to display
  final RecommendationAttribution attribution;

  /// Whether to show the expanded view with all factors
  final bool showExpanded;

  /// Callback when the chip is tapped
  final VoidCallback? onTap;

  /// Maximum width for the chip
  final double? maxWidth;

  const RecommendationAttributionChip({
    super.key,
    required this.attribution,
    this.showExpanded = false,
    this.onTap,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (showExpanded) {
      return _buildExpandedView(context, isDark);
    }

    return _buildCompactChip(context, isDark);
  }

  Widget _buildCompactChip(BuildContext context, bool isDark) {
    final spacing = context.spacing;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints:
            maxWidth != null ? BoxConstraints(maxWidth: maxWidth!) : null,
        padding: EdgeInsets.symmetric(
          horizontal: spacing.sm,
          vertical: spacing.xxs,
        ),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.primary.withValues(alpha: 0.15)
              : AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cross-app source indicators
            if (attribution.hasCrossAppInfluence) ...[
              ...attribution.crossAppInfluence!.sourceIcons
                  .map((icon) => Padding(
                        padding: EdgeInsets.only(right: spacing.xxs),
                        child: Text(icon,
                            style: Theme.of(context).textTheme.bodySmall),
                      )),
              Container(
                width: 1,
                height: 12,
                margin: EdgeInsets.only(right: spacing.xxs),
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ],

            // Primary reason text
            Flexible(
              child: Text(
                attribution.shortSummary,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white70 : AppColors.primary,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Expand indicator
            if (onTap != null) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.expand_more,
                size: 14,
                color: isDark
                    ? Colors.white54
                    : AppColors.primary.withValues(alpha: 0.7),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedView(BuildContext context, bool isDark) {
    final spacing = context.spacing;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.all(spacing.sm),
      decoration: BoxDecoration(
        color: isDark ? AppColors.grey800 : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? AppColors.white.withValues(alpha: 0.1)
              : AppColors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 16,
                color: AppColors.primary,
              ),
              SizedBox(width: spacing.xxs),
              Text(
                'Why This Spot?',
                style: textTheme.titleSmall?.copyWith(
                  color: isDark ? AppColors.white : Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Cross-app influence (if any)
          if (attribution.hasCrossAppInfluence) ...[
            _buildCrossAppSection(context, isDark, textTheme),
            const SizedBox(height: 12),
          ],

          // Factors
          ...attribution.getTopFactors(3).map(
                (factor) => _buildFactorRow(
                  context,
                  factor,
                  isDark,
                  textTheme,
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildCrossAppSection(
    BuildContext context,
    bool isDark,
    TextTheme textTheme,
  ) {
    final spacing = context.spacing;
    final influence = attribution.crossAppInfluence!;

    return Container(
      padding: EdgeInsets.all(spacing.sm),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.primary.withValues(alpha: 0.1)
            : AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Source icons
          ...influence.sourceIcons.map((icon) => Padding(
                padding: EdgeInsets.only(right: spacing.xxs),
                child:
                    Text(icon, style: Theme.of(context).textTheme.bodyMedium),
              )),
          const SizedBox(width: 4),
          // Summary
          Expanded(
            child: Text(
              influence.summary,
              style: textTheme.bodySmall?.copyWith(
                color: isDark ? Colors.white70 : Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFactorRow(
    BuildContext context,
    AttributionFactor factor,
    bool isDark,
    TextTheme textTheme,
  ) {
    final spacing = context.spacing;
    return Padding(
      padding: EdgeInsets.only(bottom: spacing.xs),
      child: Row(
        children: [
          // Icon
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.white.withValues(alpha: 0.1)
                  : AppColors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              factor.icon,
              size: 14,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          const SizedBox(width: 10),
          // Description
          Expanded(
            child: Text(
              factor.description,
              style: textTheme.bodySmall?.copyWith(
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
          // Weight indicator
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.xs,
              vertical: spacing.xxs,
            ),
            decoration: BoxDecoration(
              color: _getWeightColor(factor.weight).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${factor.percentageContribution}%',
              style: textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: _getWeightColor(factor.weight),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getWeightColor(double weight) {
    if (weight > 0.7) return AppColors.success;
    if (weight > 0.4) return AppColors.warning;
    return AppColors.grey600;
  }
}

/// A simple badge showing cross-app learning indicators
class CrossAppLearningBadge extends StatelessWidget {
  /// The cross-app influence data
  final CrossAppInfluence influence;

  /// Size of the badge
  final double size;

  const CrossAppLearningBadge({
    super.key,
    required this.influence,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: influence.sourceIcons
          .map((icon) => Padding(
                padding: EdgeInsets.only(right: spacing.xxs),
                child:
                    Text(icon, style: Theme.of(context).textTheme.bodyMedium),
              ))
          .toList(),
    );
  }
}

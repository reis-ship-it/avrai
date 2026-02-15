import 'package:flutter/material.dart';
import 'package:avrai/core/models/expertise/expertise_progress.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/presentation/presentation_spacing.dart';

/// Expertise Progress Widget
/// Shows progress toward next expertise level
/// OUR_GUTS.md: Progress visibility without gamification
class ExpertiseProgressWidget extends StatelessWidget {
  final ExpertiseProgress progress;
  final bool showDetails;
  final VoidCallback? onTap;

  const ExpertiseProgressWidget({
    super.key,
    required this.progress,
    this.showDetails = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(kSpaceMd),
        decoration: BoxDecoration(
          color: AppColors.grey50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.grey200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Text(
                  progress.category,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                if (progress.nextLevel != null)
                  Text(
                    progress.nextLevel!.emoji,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // Current Level
            Row(
              children: [
                Text(
                  progress.currentLevel.emoji,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(width: 4),
                Text(
                  '${progress.currentLevel.displayName} Level',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                if (progress.location != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    '• ${progress.location}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            // Progress Bar
            if (progress.nextLevel != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress.progressPercentage / 100.0,
                  minHeight: 8,
                  backgroundColor: AppColors.grey200,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.electricGreen),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                progress.getFormattedProgress(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(kSpaceXs),
                decoration: BoxDecoration(
                  color: AppColors.electricGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.star,
                      size: 16,
                      color: AppColors.electricGreen,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Highest level achieved!',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.electricGreen,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // Details
            if (showDetails) ...[
              const SizedBox(height: 16),
              _buildContributionSection(context),
              if (progress.nextSteps.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildNextStepsSection(context),
              ],
              // Locality-specific threshold info (if working toward Local level)
              if (progress.nextLevel != null && progress.location != null) ...[
                const SizedBox(height: 16),
                _buildLocalityThresholdInfo(context),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContributionSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Contributions',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          progress.getContributionSummary(),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }

  Widget _buildNextStepsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Next Steps',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 8),
        ...progress.nextSteps.map((step) => Padding(
              padding: const EdgeInsets.only(bottom: kSpaceXxs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(
                        top: kSpaceXsTight, right: kSpaceXs),
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: AppColors.electricGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      step,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildLocalityThresholdInfo(BuildContext context) {
    // Extract locality from location string
    String? extractLocality(String? location) {
      if (location == null || location.isEmpty) return null;
      final parts = location.split(',').map((s) => s.trim()).toList();
      return parts.isNotEmpty ? parts.first : null;
    }

    final locality = extractLocality(progress.location);
    if (locality == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(kSpaceSm),
      decoration: BoxDecoration(
        color: AppColors.electricGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.electricGreen.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                size: 16,
                color: AppColors.electricGreen,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Locality-Specific Qualification',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.electricGreen,
                      ),
                ),
              ),
              Tooltip(
                message: 'Thresholds adapt to what $locality values most. '
                    'Activities valued by your locality have lower thresholds, '
                    'making it easier to qualify as a local expert.',
                child: const Icon(
                  Icons.help_outline,
                  size: 14,
                  color: AppColors.electricGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Your qualification requirements are adjusted based on what $locality values. '
            'Focus on activities your locality cares about most to reach Local expert faster.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
          ),
        ],
      ),
    );
  }
}

/// Compact Expertise Progress Widget
/// Smaller version for use in lists/cards
class CompactExpertiseProgressWidget extends StatelessWidget {
  final ExpertiseProgress progress;

  const CompactExpertiseProgressWidget({
    super.key,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: kSpaceSm, vertical: kSpaceXs),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            progress.currentLevel.emoji,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(width: 4),
          Text(
            progress.currentLevel.displayName,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
          ),
          if (progress.nextLevel != null) ...[
            const SizedBox(width: 8),
            SizedBox(
              width: 60,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: progress.progressPercentage / 100.0,
                  minHeight: 4,
                  backgroundColor: AppColors.grey200,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.electricGreen),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

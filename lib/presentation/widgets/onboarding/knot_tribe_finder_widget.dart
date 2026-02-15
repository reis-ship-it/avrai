// Knot Tribe Finder Widget
//
// Widget for finding and displaying knot tribes during onboarding
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Phase 3: Onboarding Integration

import 'package:flutter/material.dart';
import 'package:avrai_core/models/personality_knot.dart';
import 'package:avrai_knot/models/knot/knot_community.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/tokens/theme_tokens.dart';
import 'package:avrai/presentation/widgets/knot/personality_knot_widget.dart';

/// Widget for finding and displaying knot tribes
///
/// Shows the user's knot and communities with similar topological structures
class KnotTribeFinderWidget extends StatelessWidget {
  final PersonalityKnot userKnot;
  final List<KnotCommunity> tribes;
  final bool isLoading;
  final VoidCallback? onRefresh;
  final Function(KnotCommunity)? onTribeSelected;

  const KnotTribeFinderWidget({
    super.key,
    required this.userKnot,
    this.tribes = const [],
    this.isLoading = false,
    this.onRefresh,
    this.onTribeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: EdgeInsets.all(spacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Find Your Knot Tribe',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Communities with similar personality structures',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),

        // User's knot visualization
        Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: spacing.md),
            child: Column(
              children: [
                Text(
                  'Your Personality Knot',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 12),
                PersonalityKnotWidget(
                  knot: userKnot,
                  size: 150.0,
                  showLabels: true,
                  showMetrics: true,
                ),
              ],
            ),
          ),
        ),

        const Divider(),

        // Tribes list
        Expanded(
          child: isLoading
              ? Center(child: CircularProgressIndicator())
              : tribes.isEmpty
                  ? _buildEmptyState(context)
                  : _buildTribesList(context),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final spacing = context.spacing;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(spacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.group_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No knot tribes found yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Communities will appear here as more people join with similar knots',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            if (onRefresh != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh),
                label: Text('Refresh'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTribesList(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.all(context.spacing.md),
      itemCount: tribes.length,
      itemBuilder: (context, index) {
        final tribe = tribes[index];
        return _buildTribeCard(context, tribe);
      },
    );
  }

  Widget _buildTribeCard(BuildContext context, KnotCommunity tribe) {
    return Card(
      margin: EdgeInsets.only(bottom: context.spacing.sm),
      child: InkWell(
        onTap: onTribeSelected != null ? () => onTribeSelected!(tribe) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(context.spacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Community name and similarity
              Row(
                children: [
                  Expanded(
                    child: Text(
                      tribe.community.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  _buildSimilarityBadge(context, tribe.knotSimilarity),
                ],
              ),
              const SizedBox(height: 8),

              // Community description
              if (tribe.community.description != null) ...[
                Text(
                  tribe.community.description!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
              ],

              // Community metrics
              Row(
                children: [
                  _buildMetricChip(
                    context,
                    Icons.people,
                    '${tribe.memberCount} members',
                    AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  if (tribe.membersWithKnots > 0)
                    _buildMetricChip(
                      context,
                      Icons.category,
                      '${tribe.membersWithKnots} with knots',
                      AppColors.success,
                    ),
                ],
              ),

              // Category badge
              const SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.spacing.xs,
                  vertical: context.spacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tribe.community.category,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSimilarityBadge(BuildContext context, double similarity) {
    final similarityPercent = (similarity * 100).toInt();
    Color badgeColor;
    if (similarity >= 0.8) {
      badgeColor = AppColors.success;
    } else if (similarity >= 0.6) {
      badgeColor = AppColors.warning;
    } else {
      badgeColor = AppColors.textSecondary;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.sm,
        vertical: context.spacing.xxs,
      ),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.favorite,
            size: 16,
            color: badgeColor,
          ),
          const SizedBox(width: 4),
          Text(
            '$similarityPercent% match',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: badgeColor,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.xs,
        vertical: context.spacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

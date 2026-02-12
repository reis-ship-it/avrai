// Knot Tribe Finder Widget
// 
// Widget for finding and displaying knot tribes during onboarding
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Phase 3: Onboarding Integration

import 'package:flutter/material.dart';
import 'package:avrai_core/models/personality_knot.dart';
import 'package:avrai_knot/models/knot/knot_community.dart';
import 'package:avrai/core/theme/colors.dart';
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16.0),
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
            padding: const EdgeInsets.symmetric(vertical: 16.0),
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
              ? const Center(child: CircularProgressIndicator())
              : tribes.isEmpty
                  ? _buildEmptyState(context)
                  : _buildTribesList(context),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
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
                label: const Text('Refresh'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTribesList(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: tribes.length,
      itemBuilder: (context, index) {
        final tribe = tribes[index];
        return _buildTribeCard(context, tribe);
      },
    );
  }

  Widget _buildTribeCard(BuildContext context, KnotCommunity tribe) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: onTribeSelected != null
            ? () => onTribeSelected!(tribe)
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

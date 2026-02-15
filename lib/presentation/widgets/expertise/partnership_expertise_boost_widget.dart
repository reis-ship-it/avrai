import 'package:flutter/material.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/presentation/presentation_spacing.dart';

/// Partnership Expertise Boost Widget
///
/// Displays how partnerships contribute to expertise calculation.
///
/// **CRITICAL:** Uses AppColors/AppTheme (100% adherence required)
class PartnershipExpertiseBoostWidget extends StatelessWidget {
  final double totalBoost;
  final Map<String, double> boostByCategory;
  final int activePartnerships;
  final int completedPartnerships;
  final VoidCallback? onViewPartnerships;

  const PartnershipExpertiseBoostWidget({
    super.key,
    required this.totalBoost,
    this.boostByCategory = const {},
    this.activePartnerships = 0,
    this.completedPartnerships = 0,
    this.onViewPartnerships,
  });

  @override
  Widget build(BuildContext context) {
    if (totalBoost <= 0 &&
        activePartnerships == 0 &&
        completedPartnerships == 0) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(kSpaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.handshake,
                      color: AppTheme.primaryColor,
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Partnership Boost',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                    ),
                  ],
                ),
                if (onViewPartnerships != null)
                  TextButton(
                    onPressed: onViewPartnerships,
                    child: Text(
                      'View All',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.primaryColor,
                          ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Total Boost Indicator
            Container(
              padding: const EdgeInsets.all(kSpaceMd),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Boost',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '+${(totalBoost * 100).toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                      ),
                    ],
                  ),
                  const Icon(
                    Icons.trending_up,
                    color: AppTheme.primaryColor,
                    size: 32,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Partnership Stats
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Active',
                    activePartnerships.toString(),
                    Icons.event_available,
                    AppColors.electricGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Completed',
                    completedPartnerships.toString(),
                    Icons.check_circle,
                    AppColors.textSecondary,
                  ),
                ),
              ],
            ),

            // Category Breakdown (if available)
            if (boostByCategory.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Boost by Category',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: 8),
              ...boostByCategory.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: kSpaceXs),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      Text(
                        '+${(entry.value * 100).toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor,
                            ),
                      ),
                    ],
                  ),
                );
              }),
            ],

            // Info Text
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(kSpaceSm),
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Partnerships boost your expertise in related categories. '
                      'Active partnerships provide ongoing boosts, while completed '
                      'partnerships contribute to your expertise history.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(kSpaceSm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

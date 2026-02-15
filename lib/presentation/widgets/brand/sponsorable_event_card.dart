import 'package:flutter/material.dart';
import 'package:avrai/core/models/business/brand_discovery.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/presentation/widgets/partnerships/compatibility_badge.dart';
import 'package:avrai/presentation/presentation_spacing.dart';

/// Sponsorable Event Card Widget
///
/// Displays an event that can be sponsored, with compatibility information.
/// Shows vibe matching scores and match reasons.
///
/// **CRITICAL:** Uses AppColors/AppTheme (100% adherence required)
class SponsorableEventCard extends StatelessWidget {
  final BrandMatch brandMatch;
  final VoidCallback? onTap;
  final VoidCallback? onPropose;

  const SponsorableEventCard({
    super.key,
    required this.brandMatch,
    this.onTap,
    this.onPropose,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final compatibility = brandMatch.vibeCompatibility;
    final meetsThreshold = brandMatch.meetsThreshold; // 70%+ check

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(kSpaceMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Compatibility Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CompatibilityBadge(
                    compatibility: compatibility.overallScore / 100.0,
                  ),
                  if (meetsThreshold)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: kSpaceXs, vertical: kSpaceXxs),
                      decoration: BoxDecoration(
                        color: AppColors.electricGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star,
                              size: 16, color: AppColors.electricGreen),
                          SizedBox(width: 4),
                          Text(
                            'Recommended',
                            style: textTheme.labelLarge?.copyWith(
                              color: AppColors.electricGreen,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Event Title
              Text(
                brandMatch.metadata['eventTitle'] as String? ?? 'Event',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 4),

              // Host Info
              if (brandMatch.metadata['hostName'] != null)
                Row(
                  children: [
                    const Icon(Icons.person,
                        size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      'By ${brandMatch.metadata['hostName']}',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 12),

              // Compatibility Breakdown
              if (meetsThreshold) ...[
                Container(
                  padding: const EdgeInsets.all(kSpaceSm),
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Match Score: ${compatibility.overallScore.toStringAsFixed(0)}% ⭐',
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: AppColors.electricGreen,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildCompatibilityRow(context, 'Value Alignment',
                          compatibility.valueAlignment),
                      _buildCompatibilityRow(context, 'Style Compatibility',
                          compatibility.styleCompatibility),
                      _buildCompatibilityRow(
                          context, 'Quality Focus', compatibility.qualityFocus),
                      _buildCompatibilityRow(context, 'Audience Alignment',
                          compatibility.audienceAlignment),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Match Reasons
              if (brandMatch.matchReasons.isNotEmpty) ...[
                ...brandMatch.matchReasons.take(3).map((reason) => Padding(
                      padding: const EdgeInsets.only(
                          left: kSpaceXs, top: kSpaceNano),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle,
                              size: 14, color: AppColors.electricGreen),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              reason,
                              style: textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 12),
              ],

              // Estimated Contribution
              if (brandMatch.estimatedContribution != null) ...[
                Container(
                  padding: const EdgeInsets.all(kSpaceSm),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.account_balance_wallet,
                          size: 16, color: AppTheme.primaryColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Estimated: \$${brandMatch.estimatedContribution!.minAmount.toStringAsFixed(0)} - \$${brandMatch.estimatedContribution!.maxAmount.toStringAsFixed(0)}',
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onTap,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.grey300),
                      ),
                      child: Text('View Details'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: meetsThreshold ? onPropose : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: AppColors.white,
                      ),
                      child: Text('Propose Sponsorship'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompatibilityRow(
      BuildContext context, String label, double score) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: kSpaceXxs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            '${score.toStringAsFixed(0)}%',
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

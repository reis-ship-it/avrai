import 'package:flutter/material.dart';
import 'package:avrai/core/models/events/event_partnership.dart';
import 'package:avrai/core/models/expertise/expertise_event.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/presentation/widgets/partnerships/compatibility_badge.dart';
import 'package:avrai/presentation/presentation_spacing.dart';

/// Partnership Card Widget
///
/// Displays partnership information in list views.
///
/// **CRITICAL:** Uses AppColors/AppTheme (100% adherence required)
class PartnershipCard extends StatelessWidget {
  final EventPartnership partnership;
  final ExpertiseEvent? event;
  final VoidCallback? onTap;
  final VoidCallback? onManage;
  final bool showActions;

  const PartnershipCard({
    super.key,
    required this.partnership,
    this.event,
    this.onTap,
    this.onManage,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    final business = partnership.business;
    final agreement = partnership.agreement;

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
              // Business Info Row
              Row(
                children: [
                  // Business Icon/Logo
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: business?.logoUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              business!.logoUrl!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Icon(
                            Icons.business,
                            color: AppTheme.primaryColor,
                            size: 24,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          business?.name ?? 'Business',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                        ),
                        if (business?.categories.isNotEmpty ?? false) ...[
                          const SizedBox(height: 4),
                          Text(
                            business!.categories.join(', '),
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (partnership.vibeCompatibilityScore != null)
                    CompatibilityBadge(
                      compatibility: partnership.vibeCompatibilityScore!,
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Event Info
              if (event != null) ...[
                Row(
                  children: [
                    const Icon(Icons.event,
                        size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        event!.title,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(event!.startTime),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.confirmation_number,
                        size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      '${event!.attendeeCount} / ${event!.maxAttendees} tickets',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Revenue Split Info
              if (agreement != null &&
                  agreement.terms['revenueSplit'] != null) ...[
                Row(
                  children: [
                    const Icon(Icons.account_balance_wallet,
                        size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      'Revenue: ${agreement.terms['revenueSplit']['userPercentage'].toStringAsFixed(0)}% / ${agreement.terms['revenueSplit']['businessPercentage'].toStringAsFixed(0)}% split',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // Status Badge
              _buildStatusBadge(context),

              // Actions
              if (showActions) ...[
                const SizedBox(height: 12),
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
                        onPressed: onManage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: AppColors.white,
                        ),
                        child: Text('Manage'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    final status = partnership.status;
    Color badgeColor;
    String statusText;

    switch (status) {
      case PartnershipStatus.active:
        badgeColor = AppColors.electricGreen;
        statusText = 'Active';
        break;
      case PartnershipStatus.approved:
      case PartnershipStatus.locked:
        badgeColor = AppColors.electricGreen;
        statusText = 'Approved';
        break;
      case PartnershipStatus.pending:
      case PartnershipStatus.proposed:
      case PartnershipStatus.negotiating:
        badgeColor = AppColors.warning;
        statusText = 'Pending';
        break;
      case PartnershipStatus.completed:
        badgeColor = AppColors.textSecondary;
        statusText = 'Completed';
        break;
      case PartnershipStatus.cancelled:
        badgeColor = AppColors.error;
        statusText = 'Cancelled';
        break;
      case PartnershipStatus.disputed:
        badgeColor = AppColors.error;
        statusText = 'Disputed';
        break;
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: kSpaceXs, vertical: kSpaceXxs),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        statusText,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: badgeColor,
            ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final month = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ][date.month - 1];
    return '$month ${date.day}, ${date.year}';
  }
}

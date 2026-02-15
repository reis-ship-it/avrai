import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:avrai/core/models/payment/revenue_split.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/presentation/presentation_spacing.dart';

/// Revenue Split Display Widget
///
/// Displays transparent revenue breakdown for partnerships.
/// Shows platform fees, processing fees, and N-way partner splits.
///
/// **CRITICAL:** Uses AppColors/AppTheme (100% adherence required)
///
/// **Features:**
/// - Total revenue display
/// - Platform fee breakdown (10%)
/// - Processing fee breakdown (~3%)
/// - Net revenue after fees
/// - N-way partner splits
/// - Lock status indicator
class RevenueSplitDisplay extends StatelessWidget {
  final RevenueSplit split;
  final bool showDetails;
  final bool showLockStatus;

  static final NumberFormat _currency =
      NumberFormat.currency(locale: 'en_US', symbol: '\$', decimalDigits: 2);

  const RevenueSplitDisplay({
    super.key,
    required this.split,
    this.showDetails = true,
    this.showLockStatus = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(kSpaceMd),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Icon(
                    Icons.account_balance_wallet,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Revenue Breakdown',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  if (showLockStatus && split.isLocked) ...[
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: kSpaceXs, vertical: kSpaceXxs),
                      decoration: BoxDecoration(
                        color: AppColors.electricGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.electricGreen.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lock,
                            size: 12,
                            color: AppColors.electricGreen,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Locked',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: AppColors.electricGreen,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),

              // Total Revenue
              _buildRevenueRow(
                context: context,
                label: 'Total Revenue',
                amount: split.totalAmount,
                isTotal: true,
                ticketsSold: split.ticketsSold,
              ),
              const SizedBox(height: 12),

              if (showDetails) ...[
                // Platform Fee
                _buildFeeRow(
                  context: context,
                  label: 'Platform Fee',
                  amount: split.platformFee,
                  percentage: split.platformFeePercentage,
                  description: '10% to avrai',
                ),
                const SizedBox(height: 8),

                // Processing Fee
                _buildFeeRow(
                  context: context,
                  label: 'Processing Fee',
                  amount: split.processingFee,
                  percentage: split.processingFeePercentage,
                  description: '~3% to Stripe (2.9% + \$0.30 per ticket)',
                ),
                const SizedBox(height: 12),
                const Divider(color: AppColors.grey300),
                const SizedBox(height: 12),
              ],

              // Net Revenue
              _buildRevenueRow(
                context: context,
                label: 'Net Revenue',
                amount: split.splitAmount,
                isTotal: false,
                isHighlighted: true,
              ),
              const SizedBox(height: 16),

              // Partner Splits (N-way)
              if (split.parties.isNotEmpty) ...[
                Text(
                  'Partner Distribution',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 8),
                ...split.parties.map((party) => _buildPartyRow(context, party)),
              ] else if (split.hostPayout != null) ...[
                // Solo event (legacy)
                _buildRevenueRow(
                  context: context,
                  label: 'Host Payout',
                  amount: split.hostPayout!,
                  isTotal: false,
                  isHighlighted: true,
                ),
              ],

              if (showLockStatus && !split.isLocked) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(kSpaceSm),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 20,
                        color: AppColors.warning,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Revenue split must be locked before event starts',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRevenueRow({
    required BuildContext context,
    required String label,
    required double amount,
    required bool isTotal,
    int? ticketsSold,
    bool isHighlighted = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: (isTotal
                      ? Theme.of(context).textTheme.titleMedium
                      : Theme.of(context).textTheme.bodyMedium)
                  ?.copyWith(
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            if (ticketsSold != null && ticketsSold > 0)
              Text(
                '($ticketsSold tickets)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
          ],
        ),
        Text(
          _currency.format(amount),
          style: (isTotal
                  ? Theme.of(context).textTheme.titleMedium
                  : Theme.of(context).textTheme.bodyMedium)
              ?.copyWith(
            fontWeight: FontWeight.bold,
            color: isHighlighted
                ? AppColors.electricGreen
                : isTotal
                    ? AppTheme.primaryColor
                    : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildFeeRow({
    required BuildContext context,
    required String label,
    required double amount,
    required double percentage,
    required String description,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                    ),
              ),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
        Text(
          '${_currency.format(amount)} (${percentage.toStringAsFixed(1)}%)',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }

  Widget _buildPartyRow(BuildContext context, SplitParty party) {
    final partyTypeLabel = party.type.displayName;
    final partyName = party.name ?? partyTypeLabel;

    return Padding(
      padding: const EdgeInsets.only(bottom: kSpaceSm),
      child: Container(
        padding: const EdgeInsets.all(kSpaceSm),
        decoration: BoxDecoration(
          color: AppColors.electricGreen.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.electricGreen.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: kSpaceXsTight, vertical: kSpaceNano),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          partyTypeLabel,
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.primaryColor,
                                  ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          partyName,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textPrimary,
                                  ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (party.percentage > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${party.percentage.toStringAsFixed(1)}% of net revenue',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            if (party.amount != null)
              Text(
                _currency.format(party.amount!),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.electricGreen,
                    ),
              )
            else if (party.percentage > 0)
              Text(
                '${party.percentage.toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
              ),
          ],
        ),
      ),
    );
  }
}

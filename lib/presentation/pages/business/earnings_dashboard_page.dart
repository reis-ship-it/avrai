import 'package:flutter/material.dart';
import 'package:avrai/core/design/feedback_presenter.dart';
import 'package:avrai/core/models/business/business_account.dart';
import 'package:avrai/core/models/payment/revenue_split.dart';
import 'package:avrai/core/services/payment/payout_service.dart';
import 'package:avrai/core/services/business/business_service.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/presentation/widgets/business/business_stats_card.dart';
import 'package:avrai/presentation/widgets/partnerships/revenue_split_display.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';
import 'package:avrai/presentation/widgets/portal/portal_surface.dart';
import 'package:avrai/presentation/presentation_spacing.dart';

/// Earnings Dashboard Page
///
/// Displays earnings overview, payout schedule, and revenue breakdown for businesses.
///
/// **CRITICAL:** Uses AppColors/AppTheme (100% adherence required)
///
/// **Features:**
/// - Earnings overview (total earned, pending payout)
/// - Payout schedule
/// - Revenue breakdown by event
/// - Earnings history
class EarningsDashboardPage extends StatefulWidget {
  final BusinessAccount business;

  const EarningsDashboardPage({
    super.key,
    required this.business,
  });

  @override
  State<EarningsDashboardPage> createState() => _EarningsDashboardPageState();
}

class _EarningsDashboardPageState extends State<EarningsDashboardPage> {
  final _payoutService = GetIt.instance<PayoutService>();
  // ignore: unused_field
  final _businessService = GetIt.instance<BusinessService>();

  bool _isLoading = true;
  double _totalEarned = 0.0;
  double _pendingPayout = 0.0;
  List<RevenueSplit> _revenueSplits = [];
  DateTime? _nextPayoutDate;

  @override
  void initState() {
    super.initState();
    _loadEarnings();
  }

  Future<void> _loadEarnings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get total earnings and payout history
      final earningsReport = await _payoutService.trackEarnings(
        partyId: widget.business.id,
      );
      final totalEarned = earningsReport.totalEarnings;
      final payoutHistory = earningsReport.payouts;

      // Calculate pending payout (from scheduled but not yet completed payouts)
      double pending = 0.0;
      for (final payout in payoutHistory) {
        if (payout.status == PayoutStatus.scheduled ||
            payout.status == PayoutStatus.processing) {
          pending += payout.amount;
        }
      }

      // TODO: Get revenue splits separately if needed for detailed breakdown
      // For now, using payout data
      final revenueSplits = <RevenueSplit>[];

      // Calculate next payout date (2 days after most recent event)
      DateTime? nextPayout;
      if (payoutHistory.isNotEmpty) {
        // In production, would get event dates
        // For now, use current date + 2 days
        nextPayout = DateTime.now().add(const Duration(days: 2));
      }

      setState(() {
        _totalEarned = totalEarned;
        _pendingPayout = pending;
        _revenueSplits =
            revenueSplits; // Empty for now, can be populated from RevenueSplitService if needed
        _nextPayoutDate = nextPayout;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        context.showError('Error loading earnings: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdaptivePlatformPageScaffold(
      title: 'Earnings Dashboard',
      backgroundColor: AppColors.background,
      appBarBackgroundColor: AppTheme.primaryColor,
      appBarForegroundColor: AppColors.white,
      appBarElevation: 0,
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Business Header
                  Container(
                    padding: const EdgeInsets.all(kSpaceMdWide),
                    color: AppColors.surface,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (widget.business.logoUrl != null)
                              CircleAvatar(
                                radius: 24,
                                backgroundImage:
                                    NetworkImage(widget.business.logoUrl!),
                              )
                            else
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: AppTheme.primaryColor
                                    .withValues(alpha: 0.2),
                                child: const Icon(
                                  Icons.business,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.business.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                  ),
                                  if (widget
                                          .business.verification?.isComplete ??
                                      false)
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.verified,
                                          size: 16,
                                          color: AppColors.electricGreen,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Verified Business',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: AppColors.electricGreen,
                                                fontWeight: FontWeight.w500,
                                              ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Quick Stats
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: kSpaceMdWide),
                    child: Row(
                      children: [
                        Expanded(
                          child: BusinessStatsCard(
                            label: 'Total Earned',
                            value: '\$${_totalEarned.toStringAsFixed(2)}',
                            icon: Icons.account_balance_wallet,
                            color: AppColors.electricGreen,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: BusinessStatsCard(
                            label: 'Pending',
                            value: '\$${_pendingPayout.toStringAsFixed(2)}',
                            icon: Icons.pending,
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Earnings Summary
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: kSpaceMdWide),
                    child: PortalSurface(
                      padding: const EdgeInsets.all(kSpaceMd),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Earnings Summary',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                          ),
                          const SizedBox(height: 16),
                          _buildSummaryRow(
                            'Total Earned',
                            '\$${_totalEarned.toStringAsFixed(2)}',
                            isTotal: true,
                          ),
                          const SizedBox(height: 8),
                          _buildSummaryRow(
                            'Pending Payout',
                            '\$${_pendingPayout.toStringAsFixed(2)}',
                            color: AppColors.warning,
                          ),
                          if (_nextPayoutDate != null) ...[
                            const SizedBox(height: 8),
                            _buildSummaryRow(
                              'Next Payout',
                              _formatDate(_nextPayoutDate!),
                              color: AppColors.textSecondary,
                            ),
                          ],
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () {
                                // Navigate to full earnings history
                                // TODO: Create earnings history page
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.textPrimary,
                                side:
                                    const BorderSide(color: AppColors.grey300),
                              ),
                              child: Text('View All Earnings'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Recent Revenue Splits
                  if (_revenueSplits.isNotEmpty) ...[
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: kSpaceMdWide),
                      child: Text(
                        'Recent Revenue',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._revenueSplits.take(5).map((split) => Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: kSpaceMdWide, vertical: kSpaceXs),
                          child: RevenueSplitDisplay(
                            split: split,
                            showDetails: false,
                            showLockStatus: true,
                          ),
                        )),
                  ] else ...[
                    Padding(
                      padding: const EdgeInsets.all(kSpaceXl),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.account_balance_wallet_outlined,
                              size: 64,
                              color: AppColors.textSecondary
                                  .withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No earnings yet',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textSecondary,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Start hosting events to see your earnings here',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryRow(String label, String value,
      {bool isTotal = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: (isTotal
                  ? Theme.of(context).textTheme.titleMedium
                  : Theme.of(context).textTheme.bodyMedium)
              ?.copyWith(
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                  color: AppColors.textPrimary),
        ),
        Text(
          value,
          style: (isTotal
                  ? Theme.of(context).textTheme.headlineSmall
                  : Theme.of(context).textTheme.titleMedium)
              ?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color ??
                      (isTotal
                          ? AppTheme.primaryColor
                          : AppColors.textPrimary)),
        ),
      ],
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

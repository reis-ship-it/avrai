// Refund Status Widget
//
// Phase 15: Reservation System Implementation
// Section 15.2.2: Reservation Management UI
//
// Widget for displaying refund status

import 'package:flutter/material.dart';
import 'package:avrai/core/models/misc/reservation.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/presentation/presentation_spacing.dart';

/// Refund Status Widget
///
/// **Purpose:** Display refund status for cancelled reservations
///
/// **Features:**
/// - Refund eligibility indicator
/// - Refund amount display
/// - Refund status (pending/processed/failed)
/// - Refund processing timeline
/// - Dispute status (if applicable)
class RefundStatusWidget extends StatelessWidget {
  final Reservation reservation;
  final bool qualifiesForRefund;
  final double? refundAmount;
  final bool refundIssued;

  const RefundStatusWidget({
    super.key,
    required this.reservation,
    this.qualifiesForRefund = false,
    this.refundAmount,
    this.refundIssued = false,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    if (reservation.status != ReservationStatus.cancelled) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(kSpaceMd),
      decoration: BoxDecoration(
        color: refundIssued
            ? AppTheme.successColor.withValues(alpha: 0.1)
            : qualifiesForRefund
                ? AppTheme.warningColor.withValues(alpha: 0.1)
                : AppTheme.errorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: refundIssued
              ? AppTheme.successColor
              : qualifiesForRefund
                  ? AppTheme.warningColor
                  : AppTheme.errorColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                refundIssued
                    ? Icons.check_circle
                    : qualifiesForRefund
                        ? Icons.pending
                        : Icons.cancel,
                color: refundIssued
                    ? AppTheme.successColor
                    : qualifiesForRefund
                        ? AppTheme.warningColor
                        : AppTheme.errorColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  refundIssued
                      ? 'Refund Processed'
                      : qualifiesForRefund
                          ? 'Refund Pending'
                          : 'No Refund',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: refundIssued
                        ? AppTheme.successColor
                        : qualifiesForRefund
                            ? AppTheme.warningColor
                            : AppTheme.errorColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (qualifiesForRefund &&
              refundAmount != null &&
              refundAmount! > 0) ...[
            Row(
              children: [
                const Icon(Icons.attach_money, color: AppTheme.primaryColor),
                const SizedBox(width: 4),
                Text(
                  'Refund Amount: \$${refundAmount!.toStringAsFixed(2)}',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          if (!qualifiesForRefund &&
              reservation.disputeStatus == DisputeStatus.none) ...[
            Text(
              'This reservation does not qualify for a refund based on the cancellation policy.',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'If you have extenuating circumstances, you can file a dispute for review.',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (reservation.disputeStatus != DisputeStatus.none) ...[
            _buildDisputeStatus(context, reservation),
          ],
        ],
      ),
    );
  }

  Widget _buildDisputeStatus(BuildContext context, Reservation reservation) {
    final textTheme = Theme.of(context).textTheme;
    final status = reservation.disputeStatus;
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status) {
      case DisputeStatus.submitted:
        statusColor = AppTheme.warningColor;
        statusIcon = Icons.send;
        statusText = 'Dispute Submitted - Under Review';
        break;
      case DisputeStatus.underReview:
        statusColor = AppTheme.warningColor;
        statusIcon = Icons.search;
        statusText = 'Dispute Under Review';
        break;
      case DisputeStatus.resolved:
        if (reservation.disputeReason != null) {
          statusColor = AppTheme.successColor;
          statusIcon = Icons.check_circle;
          statusText = 'Dispute Approved - Refund Eligible';
        } else {
          statusColor = AppTheme.errorColor;
          statusIcon = Icons.cancel;
          statusText = 'Dispute Denied';
        }
        break;
      case DisputeStatus.none:
        return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: kSpaceXs),
      padding: const EdgeInsets.all(kSpaceSm),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: statusColor),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              statusText,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Pricing Display Widget
//
// Phase 15: Reservation System Implementation
// Section 15.2.1: Reservation Creation UI
//
// Displays pricing information for reservations

import 'package:flutter/material.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/presentation/presentation_spacing.dart';

/// Pricing Display Widget
///
/// **Purpose:** Display pricing information for reservations
///
/// **Features:**
/// - Free/paid indicator
/// - Ticket price display
/// - Deposit amount display
/// - SPOTS fee display (10% of ticket fee)
/// - Total cost calculation
class PricingDisplayWidget extends StatelessWidget {
  final double? ticketPrice;
  final double? depositAmount;
  final int ticketCount;
  final bool isFree;

  const PricingDisplayWidget({
    super.key,
    this.ticketPrice,
    this.depositAmount,
    this.ticketCount = 1,
    this.isFree = true,
  });

  /// Calculate total cost
  double? get totalCost {
    if (isFree || ticketPrice == null) return null;
    final baseCost = (ticketPrice! * ticketCount);
    final spotsFee = baseCost * 0.10; // avrai takes 10%
    final deposit = depositAmount ?? 0.0;
    return baseCost + spotsFee + deposit;
  }

  /// Calculate avrai fee (10% of ticket fee)
  double? get spotsFee {
    if (isFree || ticketPrice == null) return null;
    return (ticketPrice! * ticketCount) * 0.10;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    if (isFree && depositAmount == null) {
      return Container(
        padding: const EdgeInsets.all(kSpaceMd),
        decoration: BoxDecoration(
          color: AppTheme.successColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.successColor),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: AppTheme.successColor),
            SizedBox(width: 8),
            Text(
              'Free Reservation',
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.successColor,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(kSpaceMd),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.grey300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Pricing Breakdown',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          if (ticketPrice != null) ...[
            _buildPriceRow(
              context,
              'Ticket Price (x$ticketCount)',
              '\$${(ticketPrice! * ticketCount).toStringAsFixed(2)}',
            ),
            const SizedBox(height: 8),
            _buildPriceRow(
              context,
              'avrai Fee (10%)',
              '\$${spotsFee!.toStringAsFixed(2)}',
              isFee: true,
            ),
          ],
          if (depositAmount != null) ...[
            if (ticketPrice != null) const SizedBox(height: 8),
            _buildPriceRow(
              context,
              'Deposit',
              '\$${depositAmount!.toStringAsFixed(2)}',
            ),
          ],
          if (totalCost != null) ...[
            const Divider(height: 24),
            _buildPriceRow(
              context,
              'Total',
              '\$${totalCost!.toStringAsFixed(2)}',
              isTotal: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPriceRow(
    BuildContext context,
    String label,
    String amount, {
    bool isFee = false,
    bool isTotal = false,
  }) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isFee ? AppColors.textSecondary : AppColors.textPrimary,
          ),
        ),
        Text(
          amount,
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

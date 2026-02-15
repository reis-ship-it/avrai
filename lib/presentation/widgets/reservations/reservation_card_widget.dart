// Reservation Card Widget
//
// Phase 15: Reservation System Implementation
// Section 15.2.2: Reservation Management UI
//
// Widget for displaying reservation in a card format

import 'package:flutter/material.dart';
import 'package:avrai/core/models/misc/reservation.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/presentation/presentation_spacing.dart';

/// Reservation Card Widget
///
/// **Purpose:** Display reservation information in a card format for lists
///
/// **Features:**
/// - Reservation type and target display
/// - Status badge
/// - Date and time
/// - Party size
/// - Tap to view details
class ReservationCardWidget extends StatelessWidget {
  final Reservation reservation;
  final VoidCallback onTap;

  const ReservationCardWidget({
    super.key,
    required this.reservation,
    required this.onTap,
  });

  Color _getStatusColor(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.pending:
        return AppTheme.warningColor;
      case ReservationStatus.confirmed:
        return AppTheme.successColor;
      case ReservationStatus.cancelled:
        return AppTheme.errorColor;
      case ReservationStatus.completed:
        return AppTheme.primaryColor;
      case ReservationStatus.noShow:
        return AppTheme.errorColor;
    }
  }

  String _getTypeLabel(ReservationType type) {
    switch (type) {
      case ReservationType.event:
        return 'Event';
      case ReservationType.spot:
        return 'Spot';
      case ReservationType.business:
        return 'Business';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: kSpaceSm),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(kSpaceMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _getTypeLabel(reservation.type),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: kSpaceXs, vertical: kSpaceXxs),
                    decoration: BoxDecoration(
                      color: _getStatusColor(reservation.status)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                          color: _getStatusColor(reservation.status)),
                    ),
                    child: Text(
                      reservation.status
                          .toString()
                          .split('.')
                          .last
                          .toUpperCase(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(reservation.status),
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                reservation.targetId,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      reservation.reservationTime
                          .toLocal()
                          .toString()
                          .split('.')[0],
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.people,
                      size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    '${reservation.partySize} ${reservation.partySize == 1 ? 'person' : 'people'}',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                  if (reservation.ticketCount != reservation.partySize) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.confirmation_number,
                        size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '${reservation.ticketCount} tickets',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avrai/core/design/feedback_presenter.dart';
import 'package:avrai/core/models/events/event_partnership.dart';
import 'package:avrai/core/models/expertise/expertise_event.dart';
import 'package:avrai/core/services/partnerships/partnership_service.dart';
import 'package:avrai/core/services/expertise/expertise_event_service.dart';
import 'package:avrai/core/services/payment/payment_service.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/core/theme/tokens/theme_tokens.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/presentation/widgets/partnerships/revenue_split_display.dart';
import 'package:avrai/presentation/widgets/partnerships/compatibility_badge.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';
import 'package:avrai/presentation/widgets/portal/portal_surface.dart';
import 'package:avrai/presentation/presentation_spacing.dart';

/// Partnership Acceptance Page
///
/// Allows businesses to view, accept, or decline partnership proposals.
///
/// **CRITICAL:** Uses AppColors/AppTheme (100% adherence required)
class PartnershipAcceptancePage extends StatefulWidget {
  final EventPartnership partnership;

  const PartnershipAcceptancePage({
    super.key,
    required this.partnership,
  });

  @override
  State<PartnershipAcceptancePage> createState() =>
      _PartnershipAcceptancePageState();
}

class _PartnershipAcceptancePageState extends State<PartnershipAcceptancePage> {
  final _partnershipService = GetIt.instance<PartnershipService>();
  final _eventService = GetIt.instance<ExpertiseEventService>();
  // ignore: unused_field
  final _paymentService = GetIt.instance<PaymentService>();

  bool _isLoading = false;
  ExpertiseEvent? _event;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadEvent();
  }

  Future<void> _loadEvent() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final event =
          await _eventService.getEventById(widget.partnership.eventId);
      setState(() {
        _event = event;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _acceptPartnership() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is! Authenticated) {
        throw Exception('User must be signed in');
      }

      // Approve partnership (business side)
      await _partnershipService.approvePartnership(
        partnershipId: widget.partnership.id,
        approvedBy: authState.user.id,
      );

      if (mounted) {
        Navigator.pop(context);
        context.showSuccess('Partnership accepted!');
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });

      if (mounted) {
        context.showError('Error accepting partnership: $e');
      }
    }
  }

  Future<void> _declinePartnership() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Decline Partnership?'),
        content:
            Text('Are you sure you want to decline this partnership proposal?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: Text('Decline'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Update partnership status to cancelled
      await _partnershipService.updatePartnershipStatus(
        partnershipId: widget.partnership.id,
        status: PartnershipStatus.cancelled,
      );

      if (mounted) {
        Navigator.pop(context);
        context.showWarning('Partnership declined');
      }
    } catch (e) {
      if (mounted) {
        context.showError('Error declining partnership: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _event == null) {
      return const AdaptivePlatformPageScaffold(
        title: 'Partnership Proposal',
        appBarBackgroundColor: AppTheme.primaryColor,
        appBarForegroundColor: AppColors.white,
        constrainBody: false,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final event = _event!;
    final agreement = widget.partnership.agreement;
    final revenueSplit = widget.partnership.revenueSplit;

    return AdaptivePlatformPageScaffold(
      title: 'Partnership Proposal',
      backgroundColor: AppColors.background,
      appBarBackgroundColor: AppTheme.primaryColor,
      appBarForegroundColor: AppColors.white,
      appBarElevation: 0,
      constrainBody: false,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Proposal Header
            Container(
              padding: EdgeInsets.all(context.spacing.lg),
              color: AppColors.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Partnership Proposal',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  SizedBox(height: context.spacing.xs),
                  if (widget.partnership.user != null)
                    Text(
                      'from ${widget.partnership.user!.displayName}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  if (widget.partnership.vibeCompatibilityScore != null) ...[
                    SizedBox(height: context.spacing.sm),
                    CompatibilityBadge(
                      compatibility: widget.partnership.vibeCompatibilityScore!,
                    ),
                  ],
                ],
              ),
            ),

            SizedBox(height: context.spacing.lg),

            // Event Preview
            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.spacing.lg),
              child: PortalSurface(
                padding: EdgeInsets.all(context.spacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Event Details',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    SizedBox(height: context.spacing.sm),
                    _buildInfoRow(Icons.event, event.title),
                    _buildInfoRow(
                        Icons.calendar_today, _formatDateTime(event.startTime)),
                    if (event.location != null)
                      _buildInfoRow(Icons.location_on, event.location!),
                    _buildInfoRow(
                        Icons.people, '${event.maxAttendees} max attendees'),
                    if (event.price != null)
                      _buildInfoRow(Icons.attach_money,
                          '\$${event.price!.toStringAsFixed(2)}/ticket'),
                  ],
                ),
              ),
            ),

            SizedBox(height: context.spacing.lg),

            // Partnership Details
            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.spacing.lg),
              child: PortalSurface(
                padding: EdgeInsets.all(context.spacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Partnership Details',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    SizedBox(height: context.spacing.sm),
                    _buildInfoRow(Icons.handshake,
                        'Type: ${widget.partnership.type.displayName}'),
                    if (agreement != null &&
                        agreement.terms['revenueSplit'] != null) ...[
                      SizedBox(height: context.spacing.xs),
                      _buildInfoRow(
                        Icons.account_balance_wallet,
                        'Revenue Split: ${agreement.terms['revenueSplit']['userPercentage'].toStringAsFixed(0)}% / ${agreement.terms['revenueSplit']['businessPercentage'].toStringAsFixed(0)}%',
                      ),
                    ],
                    if (widget
                        .partnership.sharedResponsibilities.isNotEmpty) ...[
                      SizedBox(height: context.spacing.sm),
                      Text(
                        'Responsibilities:',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                      ),
                      SizedBox(height: context.spacing.xs),
                      ...widget.partnership.sharedResponsibilities
                          .map((resp) => Padding(
                                padding: EdgeInsets.only(
                                  left: context.spacing.xs,
                                  bottom: context.spacing.xxs,
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check,
                                        size: 16,
                                        color: AppColors.electricGreen),
                                    SizedBox(width: context.spacing.xs),
                                    Text(
                                      resp,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: AppColors.textPrimary,
                                          ),
                                    ),
                                  ],
                                ),
                              )),
                    ],
                    if (agreement?.customArrangementDetails != null) ...[
                      SizedBox(height: context.spacing.sm),
                      Text(
                        'Custom Terms:',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                      ),
                      SizedBox(height: context.spacing.xs),
                      Text(
                        agreement!.customArrangementDetails!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            SizedBox(height: context.spacing.lg),

            // Revenue Breakdown (if paid event)
            if (event.price != null && event.price! > 0) ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: context.spacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estimated Revenue Breakdown',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    SizedBox(height: context.spacing.sm),
                    if (revenueSplit != null)
                      RevenueSplitDisplay(
                        split: revenueSplit,
                        showDetails: true,
                        showLockStatus: false,
                      )
                    else
                      PortalSurface(
                        padding: EdgeInsets.all(kSpaceMd),
                        child: Text(
                          'Revenue split will be calculated after event details are finalized',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: context.spacing.lg),
            ],

            // Action Buttons
            Padding(
              padding: EdgeInsets.all(context.spacing.lg),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _acceptPartnership,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: AppColors.white,
                        padding:
                            EdgeInsets.symmetric(vertical: context.spacing.md),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.white,
                              ),
                            )
                          : Text(
                              'Accept Partnership',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                    ),
                  ),
                  SizedBox(height: context.spacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _isProcessing ? null : _declinePartnership,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.grey300),
                        padding:
                            EdgeInsets.symmetric(vertical: context.spacing.md),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('Decline'),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: context.spacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.spacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          SizedBox(width: context.spacing.xs),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final weekday = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ][dateTime.weekday - 1];
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
    ][dateTime.month - 1];
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final ampm = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$weekday, $month ${dateTime.day} at $hour:${dateTime.minute.toString().padLeft(2, '0')} $ampm';
  }
}

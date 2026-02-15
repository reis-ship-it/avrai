import 'package:flutter/material.dart';
import 'package:avrai/core/controllers/partnership_checkout_controller.dart';
import 'package:avrai/core/models/expertise/expertise_event.dart';
import 'package:avrai/core/models/events/event_partnership.dart';
import 'package:avrai/core/models/payment/revenue_split.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/core/theme/tokens/theme_tokens.dart';
import 'package:avrai/presentation/widgets/payment/payment_form_widget.dart';
import 'package:avrai/presentation/widgets/partnerships/revenue_split_display.dart';
import 'package:avrai/presentation/pages/payment/payment_success_page.dart';
import 'package:avrai/presentation/pages/payment/payment_failure_page.dart';
import 'package:avrai/presentation/widgets/common/page_transitions.dart';
import 'package:avrai/presentation/widgets/portal/portal_surface.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';

/// Partnership Checkout Page
///
/// Enhanced checkout page for partnership events.
/// Shows revenue split breakdown and multi-party payment information.
///
/// **CRITICAL:** Uses AppColors/AppTheme (100% adherence required)
///
/// **Features:**
/// - Event details display
/// - Partnership information
/// - Revenue split breakdown
/// - Multi-party payment display
/// - Payment form integration
class PartnershipCheckoutPage extends StatefulWidget {
  final ExpertiseEvent event;
  final EventPartnership? partnership;

  const PartnershipCheckoutPage({
    super.key,
    required this.event,
    this.partnership,
  });

  @override
  State<PartnershipCheckoutPage> createState() =>
      _PartnershipCheckoutPageState();
}

class _PartnershipCheckoutPageState extends State<PartnershipCheckoutPage> {
  final _partnershipCheckoutController =
      GetIt.instance<PartnershipCheckoutController>();
  int _quantity = 1;
  bool _isProcessing = false;
  String? _error;
  RevenueSplit? _revenueSplit;

  @override
  void initState() {
    super.initState();
    _calculateRevenueSplit();
  }

  Future<void> _calculateRevenueSplit() async {
    if (widget.event.price == null) return;

    try {
      // Use PartnershipCheckoutController to calculate revenue split
      final revenueSplit =
          await _partnershipCheckoutController.calculateRevenueSplit(
        event: widget.event,
        quantity: _quantity,
        partnership: widget.partnership,
      );

      setState(() {
        _revenueSplit = revenueSplit;
      });
    } catch (e) {
      // Don't show error, just proceed without revenue split display
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticketPrice = widget.event.price ?? 0.0;
    final totalAmount = ticketPrice * _quantity;
    final availableTickets =
        widget.event.maxAttendees - widget.event.attendeeCount;
    final isPartnershipEvent = widget.partnership != null;

    return AdaptivePlatformPageScaffold(
      title: 'Checkout',
      backgroundColor: AppColors.background,
      appBarBackgroundColor: AppTheme.primaryColor,
      appBarForegroundColor: AppColors.white,
      appBarElevation: 0,
      constrainBody: false,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Details Card
            PortalSurface(
              padding: EdgeInsets.all(context.spacing.lg),
              color: AppColors.surface,
              radius: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: context.radius.xl,
                        backgroundColor:
                            AppTheme.primaryColor.withValues(alpha: 0.1),
                        child: Text(
                          widget.event.getEventTypeEmoji(),
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                      ),
                      SizedBox(width: context.spacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.event.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                            ),
                            SizedBox(height: context.spacing.xxs),
                            Text(
                              widget.event.getEventTypeDisplayName(),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: context.spacing.md),
                  _buildDetailRow(Icons.calendar_today,
                      _formatDateTime(widget.event.startTime)),
                  if (widget.event.location != null)
                    _buildDetailRow(Icons.location_on, widget.event.location!),
                  _buildDetailRow(Icons.people,
                      '${widget.event.attendeeCount} / ${widget.event.maxAttendees} attendees'),

                  // Partnership Info
                  if (isPartnershipEvent &&
                      widget.partnership!.business != null) ...[
                    SizedBox(height: context.spacing.sm),
                    const Divider(color: AppColors.grey300),
                    SizedBox(height: context.spacing.sm),
                    Row(
                      children: [
                        const Icon(Icons.handshake,
                            size: 18, color: AppTheme.primaryColor),
                        SizedBox(width: context.spacing.xs),
                        Expanded(
                          child: Text(
                            'Partnership Event with ${widget.partnership!.business!.name}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            SizedBox(height: context.spacing.lg),

            // Revenue Split Display (if partnership event)
            if (isPartnershipEvent && _revenueSplit != null) ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: context.spacing.lg),
                child: RevenueSplitDisplay(
                  split: _revenueSplit!,
                  showDetails: true,
                  showLockStatus: true,
                ),
              ),
              SizedBox(height: context.spacing.lg),
            ],

            // Order Summary
            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.spacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order Summary',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  SizedBox(height: context.spacing.md),

                  // Ticket Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Ticket Price',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textPrimary,
                            ),
                      ),
                      Text(
                        '\$${ticketPrice.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  ),
                  SizedBox(height: context.spacing.sm),

                  // Quantity Selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Quantity',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textPrimary,
                            ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: _quantity > 1 && !_isProcessing
                                ? () {
                                    setState(() {
                                      _quantity--;
                                      _calculateRevenueSplit();
                                    });
                                  }
                                : null,
                            icon: Icon(
                              Icons.remove_circle_outline,
                              color: _quantity > 1 && !_isProcessing
                                  ? AppTheme.primaryColor
                                  : AppColors.grey400,
                            ),
                          ),
                          Chip(
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            side: BorderSide.none,
                            backgroundColor: AppColors.grey100,
                            label: Text(
                              '$_quantity',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                            ),
                          ),
                          IconButton(
                            onPressed:
                                _quantity < availableTickets && !_isProcessing
                                    ? () {
                                        setState(() {
                                          _quantity++;
                                          _calculateRevenueSplit();
                                        });
                                      }
                                    : null,
                            icon: Icon(
                              Icons.add_circle_outline,
                              color:
                                  _quantity < availableTickets && !_isProcessing
                                      ? AppTheme.primaryColor
                                      : AppColors.grey400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  if (availableTickets <= 5 && availableTickets > 0)
                    Padding(
                      padding: EdgeInsets.only(top: context.spacing.xs),
                      child: Text(
                        'Only $availableTickets tickets remaining!',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.warningColor,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),

                  SizedBox(height: context.spacing.md),
                  const Divider(color: AppColors.grey300),
                  SizedBox(height: context.spacing.md),

                  // Total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                      ),
                      Text(
                        '\$${totalAmount.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: context.spacing.xxl),

            // Payment Form
            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.spacing.lg),
              child: PaymentFormWidget(
                amount: totalAmount,
                quantity: _quantity,
                event: widget.event,
                onPaymentSuccess: _handlePaymentSuccess,
                onPaymentFailure: _handlePaymentFailure,
                isProcessing: _isProcessing,
                onProcessingChange: (processing) {
                  setState(() {
                    _isProcessing = processing;
                  });
                },
              ),
            ),

            if (_error != null) ...[
              SizedBox(height: context.spacing.md),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: context.spacing.lg),
                child: PortalSurface(
                  padding: EdgeInsets.all(context.spacing.sm),
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderColor: AppColors.error.withValues(alpha: 0.3),
                  radius: context.radius.sm,
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error),
                      SizedBox(width: context.spacing.xs),
                      Expanded(
                        child: Text(
                          _error!,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.error,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            SizedBox(height: context.spacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
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

  void _handlePaymentSuccess(String paymentId, String? paymentIntentId) {
    Navigator.pushReplacement(
      context,
      PageTransitions.scaleAndFade(
        PaymentSuccessPage(
          event: widget.event,
          paymentId: paymentId,
          quantity: _quantity,
        ),
      ),
    );
  }

  void _handlePaymentFailure(String errorMessage, String? errorCode) {
    Navigator.pushReplacement(
      context,
      PageTransitions.fade(
        PaymentFailurePage(
          event: widget.event,
          errorMessage: errorMessage,
          errorCode: errorCode,
          quantity: _quantity,
        ),
      ),
    );
  }
}

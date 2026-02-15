import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avrai/core/models/expertise/expertise_event.dart';
import 'package:avrai/core/controllers/checkout_controller.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/presentation/widgets/payment/payment_form_widget.dart';
import 'package:avrai/presentation/pages/payment/payment_success_page.dart';
import 'package:avrai/presentation/pages/payment/payment_failure_page.dart';
import 'package:avrai/presentation/pages/legal/event_waiver_page.dart';
import 'package:avrai/presentation/widgets/common/page_transitions.dart';
import 'package:avrai/core/services/misc/legal_document_service.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';
import 'package:avrai/presentation/widgets/portal/portal_surface.dart';
import 'package:avrai/core/theme/tokens/theme_tokens.dart';
import 'package:avrai/presentation/presentation_spacing.dart';

/// Checkout Page
/// Agent 2: Event Discovery & Hosting UI (Section 2, Task 2.2)
///
/// CRITICAL: Uses AppColors/AppTheme (100% adherence required)
///
/// Features:
/// - Display event details
/// - Show ticket price
/// - Quantity selector
/// - Display total amount
/// - Payment form integration
class CheckoutPage extends StatefulWidget {
  final ExpertiseEvent event;
  final CheckoutController? checkoutController;
  final LegalDocumentService? legalService;

  const CheckoutPage({
    super.key,
    required this.event,
    this.checkoutController,
    this.legalService,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  late final CheckoutController _checkoutController;
  late final LegalDocumentService? _legalService;
  int _quantity = 1;
  bool _isProcessing = false;
  bool _isLoadingTax = false;
  bool _hasAcceptedWaiver = false;
  bool _isCheckingWaiver = true;
  String? _error;
  double _salesTax = 0.0;
  double _taxRate = 0.0;
  bool _isTaxExempt = false;
  String? _exemptionReason;

  @override
  void initState() {
    super.initState();
    _checkoutController =
        widget.checkoutController ?? GetIt.instance<CheckoutController>();
    _legalService = widget.legalService ??
        (GetIt.instance.isRegistered<LegalDocumentService>()
            ? GetIt.instance<LegalDocumentService>()
            : null);
    _calculateSalesTax();
    // Delay waiver check until after first frame to ensure context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _checkWaiverStatus();
      }
    });
  }

  Future<void> _checkWaiverStatus() async {
    setState(() {
      _isCheckingWaiver = true;
    });

    try {
      if (_legalService == null) {
        setState(() {
          _isCheckingWaiver = false;
        });
        return;
      }

      final authState = context.read<AuthBloc>().state;
      if (authState is Authenticated) {
        final accepted = await _legalService.hasAcceptedEventWaiver(
          authState.user.id,
          widget.event.id,
        );
        setState(() {
          _hasAcceptedWaiver = accepted;
          _isCheckingWaiver = false;
        });
      } else {
        setState(() {
          _isCheckingWaiver = false;
        });
      }
    } catch (e) {
      setState(() {
        _isCheckingWaiver = false;
      });
    }
  }

  Future<void> _acceptWaiver() async {
    final result = await Navigator.push(
      context,
      PageTransitions.slideFromRight(
        EventWaiverPage(
          event: widget.event,
          requireAcceptance: true,
        ),
      ),
    );

    if (result == true) {
      setState(() {
        _hasAcceptedWaiver = true;
      });
    }
  }

  Future<void> _calculateSalesTax() async {
    setState(() {
      _isLoadingTax = true;
    });

    try {
      // Use CheckoutController to calculate totals (includes tax calculation)
      final totals = await _checkoutController.calculateTotals(
        event: widget.event,
        quantity: _quantity,
      );

      setState(() {
        _salesTax = totals.taxAmount;
        _taxRate = totals.taxAmount > 0 && totals.subtotal > 0
            ? (totals.taxAmount / totals.subtotal) * 100
            : 0.0;
        _isTaxExempt = totals.taxAmount == 0.0 && widget.event.isPaid;
        _exemptionReason = _isTaxExempt ? 'Event is tax-exempt' : null;
        _isLoadingTax = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingTax = false;
        // Don't show error, just proceed without tax
      });
    }
  }

  @override
  void didUpdateWidget(CheckoutPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.event.id != widget.event.id ||
        oldWidget.event.price != widget.event.price) {
      _calculateSalesTax();
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final ticketPrice = widget.event.price ?? 0.0;
    final subtotal = ticketPrice * _quantity;
    final totalAmount = subtotal + _salesTax;
    final availableTickets =
        widget.event.maxAttendees - widget.event.attendeeCount;

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
              borderColor: AppColors.grey300,
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
                          style: textTheme.headlineMedium,
                        ),
                      ),
                      SizedBox(width: context.spacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.event.title,
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: context.spacing.xxs),
                            Text(
                              widget.event.getEventTypeDisplayName(),
                              style: textTheme.bodyMedium
                                  ?.copyWith(color: AppColors.textSecondary),
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
                ],
              ),
            ),

            SizedBox(height: context.spacing.lg),

            // Order Summary
            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.spacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order Summary',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: context.spacing.md),

                  // Ticket Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'Ticket Price',
                          style: textTheme.bodyLarge
                              ?.copyWith(color: AppColors.textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '\$${ticketPrice.toStringAsFixed(2)}',
                        style: textTheme.bodyLarge?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: context.spacing.sm),

                  // Subtotal
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'Subtotal',
                          style: textTheme.bodyLarge
                              ?.copyWith(color: AppColors.textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '\$${subtotal.toStringAsFixed(2)}',
                        style: textTheme.bodyLarge?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: context.spacing.sm),

                  // Sales Tax
                  if (_isLoadingTax)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'Sales Tax',
                            style: textTheme.bodyLarge
                                ?.copyWith(color: AppColors.textPrimary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ],
                    )
                  else if (_isTaxExempt)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      'Sales Tax',
                                      style: textTheme.bodyLarge?.copyWith(
                                          color: AppColors.textPrimary),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(
                                    Icons.check_circle,
                                    size: 16,
                                    color: AppColors.electricGreen,
                                  ),
                                ],
                              ),
                            ),
                            Flexible(
                              child: Text(
                                'Tax-Exempt',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: AppColors.electricGreen,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (_exemptionReason != null) ...[
                          SizedBox(height: context.spacing.xxs),
                          Text(
                            _exemptionReason!,
                            style: textTheme.bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ],
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  'Sales Tax',
                                  style: textTheme.bodyLarge
                                      ?.copyWith(color: AppColors.textPrimary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (_taxRate > 0) ...[
                                SizedBox(width: context.spacing.xxs),
                                Flexible(
                                  child: Text(
                                    '(${_taxRate.toStringAsFixed(2)}%)',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Text(
                          '\$${_salesTax.toStringAsFixed(2)}',
                          style: textTheme.bodyLarge?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  SizedBox(height: context.spacing.sm),
                  const Divider(color: AppColors.grey300),
                  SizedBox(height: context.spacing.sm),

                  // Quantity Selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'Quantity',
                          style: textTheme.bodyLarge
                              ?.copyWith(color: AppColors.textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: _quantity > 1 && !_isProcessing
                                ? () => setState(() => _quantity--)
                                : null,
                            icon: Icon(
                              Icons.remove_circle_outline,
                              color: _quantity > 1 && !_isProcessing
                                  ? AppTheme.primaryColor
                                  : AppColors.grey400,
                            ),
                          ),
                          Chip(
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            side: BorderSide.none,
                            backgroundColor: AppColors.grey100,
                            labelPadding: EdgeInsets.zero,
                            padding: const EdgeInsets.symmetric(
                                horizontal: kSpaceMd, vertical: kSpaceXs),
                            label: Text(
                              '$_quantity',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed:
                                _quantity < availableTickets && !_isProcessing
                                    ? () => setState(() => _quantity++)
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
                        style: textTheme.bodySmall?.copyWith(
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
                      Flexible(
                        child: Text(
                          'Total',
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '\$${totalAmount.toStringAsFixed(2)}',
                        style: textTheme.headlineSmall?.copyWith(
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

            // Event Waiver Section
            if (_isCheckingWaiver)
              const Padding(
                padding: EdgeInsets.all(kSpaceMdWide),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (!_hasAcceptedWaiver) ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: context.spacing.lg),
                child: PortalSurface(
                  padding: EdgeInsets.all(context.spacing.md),
                  color: AppTheme.warningColor.withValues(alpha: 0.1),
                  borderColor: AppTheme.warningColor.withValues(alpha: 0.3),
                  radius: context.radius.sm,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.warning,
                              color: AppTheme.warningColor),
                          SizedBox(width: context.spacing.xs),
                          Expanded(
                            child: Text(
                              'Event Waiver Required',
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: context.spacing.xs),
                      Text(
                        'You must accept the event waiver before completing your purchase.',
                        style: textTheme.bodyMedium
                            ?.copyWith(color: AppColors.textPrimary),
                      ),
                      SizedBox(height: context.spacing.sm),
                      ElevatedButton(
                        onPressed: _acceptWaiver,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: AppColors.white,
                          minimumSize:
                              Size(double.infinity, context.spacing.xxl),
                        ),
                        child: const Text('Review & Accept Waiver'),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: context.spacing.md),
            ],

            // Payment Form (only show if waiver accepted)
            if (_hasAcceptedWaiver)
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
                          style: textTheme.bodyMedium
                              ?.copyWith(color: AppColors.error),
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
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(bottom: context.spacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          SizedBox(width: context.spacing.xs),
          Expanded(
            child: Text(
              text,
              style:
                  textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
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

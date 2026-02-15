import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avrai/core/controllers/sponsorship_checkout_controller.dart';
import 'package:avrai/core/models/expertise/expertise_event.dart';
import 'package:avrai/core/models/sponsorship/sponsorship.dart';
import 'package:avrai/core/models/payment/revenue_split.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/core/theme/tokens/theme_tokens.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart'
    show AuthBloc, Authenticated;
import 'package:avrai/presentation/widgets/payment/payment_form_widget.dart';
import 'package:avrai/presentation/widgets/brand/product_contribution_widget.dart';
import 'package:avrai/presentation/widgets/brand/sponsorship_revenue_split_display.dart';
import 'package:avrai/presentation/pages/payment/payment_success_page.dart';
import 'package:avrai/presentation/widgets/common/page_transitions.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';
import 'package:avrai/presentation/widgets/portal/portal_surface.dart';

/// Brand Sponsorship Checkout Page
///
/// Multi-party checkout page for brand sponsorship contributions.
/// Supports financial, product, and hybrid sponsorship types.
///
/// **CRITICAL:** Uses AppColors/AppTheme (100% adherence required)
///
/// **Features:**
/// - Event details display
/// - Sponsorship contribution type selection
/// - Financial contribution payment
/// - Product contribution tracking
/// - Revenue split display (N-way with sponsors)
/// - Payment confirmation
class SponsorshipCheckoutPage extends StatefulWidget {
  final ExpertiseEvent event;
  final Sponsorship? sponsorship; // If editing existing sponsorship
  final SponsorshipType? preselectedType;

  const SponsorshipCheckoutPage({
    super.key,
    required this.event,
    this.sponsorship,
    this.preselectedType,
  });

  @override
  State<SponsorshipCheckoutPage> createState() =>
      _SponsorshipCheckoutPageState();
}

class _SponsorshipCheckoutPageState extends State<SponsorshipCheckoutPage> {
  final _sponsorshipCheckoutController =
      GetIt.instance<SponsorshipCheckoutController>();

  SponsorshipType _contributionType = SponsorshipType.financial;
  double? _cashAmount;
  double? _productValue;
  int _productQuantity = 1;
  String? _productName;
  bool _isProcessing = false;
  String? _error;
  RevenueSplit? _revenueSplit;

  @override
  void initState() {
    super.initState();
    if (widget.preselectedType != null) {
      _contributionType = widget.preselectedType!;
    }
    if (widget.sponsorship != null) {
      _loadExistingSponsorship();
    }
    _calculateRevenueSplit();
  }

  void _loadExistingSponsorship() {
    final sponsorship = widget.sponsorship!;
    setState(() {
      _contributionType = sponsorship.type;
      _cashAmount = sponsorship.contributionAmount;
      _productValue = sponsorship.productValue;
    });
  }

  Future<void> _calculateRevenueSplit() async {
    try {
      // Calculate revenue split including this sponsorship
      final totalContribution = (_cashAmount ?? 0.0) + (_productValue ?? 0.0);

      if (totalContribution > 0) {
        // Use SponsorshipCheckoutController to calculate revenue split
        final revenueSplit = await _sponsorshipCheckoutController
            .calculateSponsorshipRevenueSplit(
          event: widget.event,
          totalContribution: totalContribution,
          existingSplit: null, // Could pass existing split if available
        );

        if (revenueSplit != null) {
          setState(() {
            _revenueSplit = revenueSplit;
          });
        }
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error calculating revenue split: $e',
        name: 'SponsorshipCheckoutPage',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalContribution = (_cashAmount ?? 0.0) + (_productValue ?? 0.0);

    return AdaptivePlatformPageScaffold(
      title: widget.sponsorship != null ? 'Edit Sponsorship' : 'Sponsor Event',
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
                ],
              ),
            ),

            SizedBox(height: context.spacing.lg),

            // Contribution Type Selection
            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.spacing.lg),
              child: PortalSurface(
                padding: EdgeInsets.all(context.spacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contribution Type',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    SizedBox(height: context.spacing.md),
                    _buildContributionTypeOption(
                      SponsorshipType.financial,
                      'Financial',
                      'Cash contribution',
                      Icons.account_balance_wallet,
                    ),
                    SizedBox(height: context.spacing.sm),
                    _buildContributionTypeOption(
                      SponsorshipType.product,
                      'Product',
                      'Product/in-kind contribution',
                      Icons.inventory_2,
                    ),
                    SizedBox(height: context.spacing.sm),
                    _buildContributionTypeOption(
                      SponsorshipType.hybrid,
                      'Hybrid',
                      'Cash + Product combination',
                      Icons.all_inclusive,
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: context.spacing.lg),

            // Financial Contribution Section
            if (_contributionType == SponsorshipType.financial ||
                _contributionType == SponsorshipType.hybrid) ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: context.spacing.lg),
                child: PortalSurface(
                  padding: EdgeInsets.all(context.spacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Financial Contribution',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                      ),
                      SizedBox(height: context.spacing.md),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Amount',
                          hintText: '500.00',
                          prefixText: '\$',
                          filled: true,
                          fillColor: AppColors.grey100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        onChanged: (value) {
                          setState(() {
                            _cashAmount = double.tryParse(value);
                            _calculateRevenueSplit();
                          });
                        },
                        initialValue: _cashAmount?.toStringAsFixed(2),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: context.spacing.lg),
            ],

            // Product Contribution Section
            if (_contributionType == SponsorshipType.product ||
                _contributionType == SponsorshipType.hybrid) ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: context.spacing.lg),
                child: ProductContributionWidget(
                  productName: _productName,
                  productQuantity: _productQuantity,
                  productValue: _productValue,
                  onProductNameChanged: (name) {
                    setState(() => _productName = name);
                  },
                  onQuantityChanged: (quantity) {
                    setState(() {
                      _productQuantity = quantity;
                      _calculateProductValue();
                    });
                  },
                  onUnitPriceChanged: (price) {
                    setState(() {
                      _productValue = price * _productQuantity;
                      _calculateRevenueSplit();
                    });
                  },
                ),
              ),
              SizedBox(height: context.spacing.lg),
            ],

            // Revenue Split Display (if contribution set)
            if (totalContribution > 0 && _revenueSplit != null) ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: context.spacing.lg),
                child: SponsorshipRevenueSplitDisplay(
                  split: _revenueSplit!,
                  sponsorshipContribution: totalContribution,
                  showDetails: true,
                ),
              ),
              SizedBox(height: context.spacing.lg),
            ],

            // Contribution Summary
            if (totalContribution > 0) ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: context.spacing.lg),
                child: PortalSurface(
                  padding: EdgeInsets.all(context.spacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Contribution Summary',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                      ),
                      SizedBox(height: context.spacing.md),
                      if (_cashAmount != null && _cashAmount! > 0)
                        _buildSummaryRow('Cash Contribution', _cashAmount!),
                      if (_productValue != null && _productValue! > 0)
                        _buildSummaryRow('Product Value', _productValue!),
                      SizedBox(height: context.spacing.sm),
                      const Divider(color: AppColors.grey300),
                      SizedBox(height: context.spacing.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Contribution',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                          ),
                          Text(
                            '\$${totalContribution.toStringAsFixed(2)}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: context.spacing.lg),
            ],

            // Payment Form (only for financial contributions)
            if ((_contributionType == SponsorshipType.financial ||
                    _contributionType == SponsorshipType.hybrid) &&
                _cashAmount != null &&
                _cashAmount! > 0) ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: context.spacing.lg),
                child: PaymentFormWidget(
                  amount: _cashAmount!,
                  quantity: 1,
                  event: widget.event,
                  onPaymentSuccess: _handlePaymentSuccess,
                  onPaymentFailure: _handlePaymentFailure,
                  isProcessing: _isProcessing,
                  onProcessingChange: (processing) {
                    setState(() => _isProcessing = processing);
                  },
                ),
              ),
              SizedBox(height: context.spacing.lg),
            ],

            // Submit Button (for product-only or after payment)
            if ((_contributionType == SponsorshipType.product ||
                (_cashAmount != null &&
                    _cashAmount! > 0 &&
                    !_isProcessing))) ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: context.spacing.lg),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: totalContribution > 0 && !_isProcessing
                        ? _submitSponsorship
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: AppColors.white,
                      padding:
                          EdgeInsets.symmetric(vertical: context.spacing.md),
                    ),
                    child: Text(
                      widget.sponsorship != null
                          ? 'Update Sponsorship'
                          : 'Submit Sponsorship Proposal',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: context.spacing.lg),
            ],

            if (_error != null) ...[
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
              SizedBox(height: context.spacing.lg),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContributionTypeOption(
    SponsorshipType type,
    String title,
    String description,
    IconData icon,
  ) {
    final isSelected = _contributionType == type;

    return InkWell(
      onTap: () {
        setState(() {
          _contributionType = type;
          _calculateRevenueSplit();
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: PortalSurface(
        padding: EdgeInsets.all(context.spacing.sm),
        color: isSelected
            ? AppTheme.primaryColor.withValues(alpha: 0.1)
            : AppColors.grey100,
        borderColor: isSelected ? AppTheme.primaryColor : AppColors.grey300,
        radius: context.radius.md,
        child: Row(
          children: [
            Icon(
              icon,
              color:
                  isSelected ? AppTheme.primaryColor : AppColors.textSecondary,
            ),
            SizedBox(width: context.spacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  SizedBox(height: context.spacing.xxs),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppTheme.primaryColor,
              ),
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

  Widget _buildSummaryRow(String label, double amount) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.spacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                ),
          ),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
          ),
        ],
      ),
    );
  }

  void _calculateProductValue() {
    // Calculate product value based on quantity and unit price
    // This would be set by the ProductContributionWidget
  }

  Future<void> _submitSponsorship() async {
    if (_cashAmount == null && _productValue == null) {
      setState(() {
        _error = 'Please specify a contribution amount or product value';
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      final authState = context.read<AuthBloc>().state;
      final userId = authState is Authenticated ? authState.user.id : null;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // TODO: Get brand account for user (when BrandAccountService is available)
      // For now, use userId as brandId placeholder
      final brandId =
          'brand_$userId'; // Placeholder - should come from BrandAccountService

      // Use SponsorshipCheckoutController to process sponsorship checkout
      final result =
          await _sponsorshipCheckoutController.processSponsorshipCheckout(
        event: widget.event,
        brandId: brandId,
        type: _contributionType,
        contributionAmount: _cashAmount,
        productValue: _productValue,
        productName: _productName,
        productQuantity: _productQuantity,
        existingSponsorship: widget.sponsorship,
      );

      if (!result.success) {
        throw Exception(result.error ?? 'Failed to submit sponsorship');
      }

      if (!mounted) return;

      // Navigate to success page
      Navigator.pushReplacement(
        context,
        PageTransitions.scaleAndFade(
          PaymentSuccessPage(
            event: widget.event,
            paymentId: result.payment?.id ??
                'sponsorship-${DateTime.now().millisecondsSinceEpoch}',
            quantity: 1,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _error = 'Failed to submit sponsorship: ${e.toString()}';
      });
    }
  }

  void _handlePaymentSuccess(String paymentId, String? paymentIntentId) {
    // Payment successful, now submit sponsorship
    _submitSponsorship();
  }

  void _handlePaymentFailure(String errorMessage, String? errorCode) {
    setState(() {
      _isProcessing = false;
      _error = errorMessage;
    });
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

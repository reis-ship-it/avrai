import 'package:flutter/material.dart';
import 'package:avrai/core/design/feedback_presenter.dart';
import 'package:avrai/core/navigation/app_navigator.dart';
import 'package:avrai/core/models/expertise/expertise_event.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/presentation/pages/payment/checkout_page.dart';
import 'package:avrai/presentation/pages/events/event_details_page.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';
import 'package:avrai/presentation/widgets/portal/portal_surface.dart';
import 'package:avrai/presentation/presentation_spacing.dart';

/// Payment Failure Page
/// Agent 2: Event Discovery & Hosting UI (Section 2, Task 2.2)
///
/// CRITICAL: Uses AppColors/AppTheme (100% adherence required)
///
/// Features:
/// - Error message
/// - Retry button
/// - Support information
/// - Navigation back to event
class PaymentFailurePage extends StatelessWidget {
  final ExpertiseEvent event;
  final String errorMessage;
  final String? errorCode;
  final int quantity;

  const PaymentFailurePage({
    super.key,
    required this.event,
    required this.errorMessage,
    this.errorCode,
    required this.quantity,
  });

  String _getUserFriendlyMessage() {
    // Provide user-friendly error messages based on error codes
    if (errorCode != null) {
      switch (errorCode) {
        case 'EVENT_NOT_FOUND':
          return 'This event is no longer available.';
        case 'EVENT_NOT_PAID':
          return 'This event is free and does not require payment.';
        case 'PRICE_MISMATCH':
          return 'The ticket price has changed. Please try again.';
        case 'INSUFFICIENT_CAPACITY':
          return 'Sorry, there are not enough tickets available.';
        case 'USER_CANNOT_ATTEND':
          return 'You cannot attend this event.';
        case 'PAYMENT_INTENT_FAILED':
          return 'We couldn\'t process your payment. Please try again.';
        case 'PAYMENT_PROCESSING_ERROR':
          return 'An error occurred while processing your payment.';
        case 'NOT_INITIALIZED':
          return 'Payment service is not available. Please try again later.';
        default:
          return errorMessage;
      }
    }
    return errorMessage;
  }

  String _getSupportMessage() {
    if (errorCode != null) {
      switch (errorCode) {
        case 'INSUFFICIENT_CAPACITY':
        case 'EVENT_NOT_FOUND':
          return 'Please check the event details and try again.';
        case 'PAYMENT_INTENT_FAILED':
        case 'PAYMENT_PROCESSING_ERROR':
          return 'If this problem persists, please contact support.';
        default:
          return 'If you continue to experience issues, please contact support for assistance.';
      }
    }
    return 'If you continue to experience issues, please contact support for assistance.';
  }

  @override
  Widget build(BuildContext context) {
    final userFriendlyMessage = _getUserFriendlyMessage();
    final supportMessage = _getSupportMessage();

    return AdaptivePlatformPageScaffold(
      title: 'Payment Failed',
      backgroundColor: AppColors.background,
      appBarBackgroundColor: AppColors.error,
      appBarForegroundColor: AppColors.white,
      appBarElevation: 0,
      automaticallyImplyLeading: false,
      constrainBody: false,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(kSpaceXl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),

                // Error Icon
                CircleAvatar(
                  radius: 64,
                  backgroundColor: AppColors.error.withValues(alpha: 0.1),
                  child: const Icon(
                    Icons.error_outline,
                    size: 80,
                    color: AppColors.error,
                  ),
                ),

                const SizedBox(height: 24),

                // Error Message
                Text(
                  'Payment Failed',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                Text(
                  userFriendlyMessage,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                // Error Details Card
                PortalSurface(
                  padding: const EdgeInsets.all(kSpaceMd),
                  color: AppColors.grey100,
                  radius: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Error Details',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        errorMessage,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      if (errorCode != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Error Code: $errorCode',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textHint,
                                    fontFamily: 'monospace',
                                  ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Support Message
                PortalSurface(
                  padding: const EdgeInsets.all(kSpaceMd),
                  color: AppColors.electricGreen.withValues(alpha: 0.1),
                  borderColor: AppColors.electricGreen.withValues(alpha: 0.3),
                  radius: 12,
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          color: AppColors.electricGreen),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          supportMessage,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Action Buttons
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      AppNavigator.replaceBuilder(
                        context,
                        builder: (context) => CheckoutPage(event: event),
                      );
                    },
                    icon: const Icon(Icons.refresh, size: 20),
                    label: Text('Try Again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: kSpaceMd),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      AppNavigator.replaceBuilder(
                        context,
                        builder: (context) => EventDetailsPage(event: event),
                      );
                    },
                    icon: const Icon(Icons.event, size: 20),
                    label: Text('Back to Event'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      padding: const EdgeInsets.symmetric(vertical: kSpaceMd),
                      side: const BorderSide(color: AppColors.grey300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                TextButton(
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  child: Text(
                    'Back to Home',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                ),

                const SizedBox(height: 24),

                // Support Contact
                Text(
                  'Need help?',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () {
                    // TODO: Open support contact
                    context.showInfo('Support contact coming soon');
                  },
                  child: Text(
                    'Contact Support',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppTheme.primaryColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avrai/core/controllers/payment_processing_controller.dart';
import 'package:avrai/core/models/expertise/expertise_event.dart';
import 'package:avrai/core/models/user/unified_user.dart';
import 'package:avrai/core/models/user/user.dart' as user_model;
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:get_it/get_it.dart';

/// Payment Form Widget
/// Agent 2: Event Discovery & Hosting UI (Section 2, Task 2.2)
/// 
/// CRITICAL: Uses AppColors/AppTheme (100% adherence required)
/// 
/// Features:
/// - Card input fields (simplified for MVP - uses text fields)
/// - Payment button
/// - Error display
/// - Loading states
/// 
/// **Note:** In production, this should use Stripe's card input widget for PCI compliance.
/// For MVP, we use basic text fields to demonstrate the payment flow.
class PaymentFormWidget extends StatefulWidget {
  final double amount;
  final int quantity;
  final ExpertiseEvent event;
  final Function(String paymentId, String? paymentIntentId) onPaymentSuccess;
  final Function(String errorMessage, String? errorCode) onPaymentFailure;
  final bool isProcessing;
  final Function(bool) onProcessingChange;

  const PaymentFormWidget({
    super.key,
    required this.amount,
    required this.quantity,
    required this.event,
    required this.onPaymentSuccess,
    required this.onPaymentFailure,
    this.isProcessing = false,
    required this.onProcessingChange,
  });

  @override
  State<PaymentFormWidget> createState() => _PaymentFormWidgetState();
}

class _PaymentFormWidgetState extends State<PaymentFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cardholderNameController = TextEditingController();
  String? _error;

  PaymentProcessingController _resolvePaymentController() {
    // Avoid hard-crashing at build-time if DI isn't wired (common in widget tests).
    // We surface a user-facing error only if the user attempts to submit payment.
    if (!GetIt.instance.isRegistered<PaymentProcessingController>()) {
      throw Exception('Payment processing is unavailable');
    }
    return GetIt.instance<PaymentProcessingController>();
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardholderNameController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _error = null;
      widget.onProcessingChange(true);
    });

    try {
      // Get current user
      final authState = context.read<AuthBloc>().state;
      if (authState is! Authenticated) {
        throw Exception('User must be signed in to make a payment');
      }

      final buyer = _convertUserToUnifiedUser(authState.user);

      // Process payment using PaymentProcessingController
      // This handles: validation, tax calculation, payment processing, and event registration
      final paymentController = _resolvePaymentController();
      final result = await paymentController.processEventPayment(
        event: widget.event,
        buyer: buyer,
        quantity: widget.quantity,
      );

      if (!result.isSuccess) {
        // Handle validation errors
        if (result.validationErrors != null && result.validationErrors!.isNotEmpty) {
          final errorMessages = result.validationErrors!.values.join(', ');
          throw Exception(errorMessages);
        }
        throw Exception(result.error ?? 'Payment failed');
      }

      if (result.payment == null) {
        // Free events might not have payment
        if (widget.event.isPaid) {
          throw Exception('Payment record not found');
        }
      }

      // Payment successful - call callback
      // Note: PaymentIntent may be null for free events or if not yet created
      final paymentId = result.payment?.id ?? 'free_event_${widget.event.id}';
      final paymentIntentId = result.paymentIntent?.id;
      widget.onPaymentSuccess(paymentId, paymentIntentId);
    } catch (e) {
      setState(() {
        _error = e.toString();
        widget.onProcessingChange(false);
      });

      if (mounted) {
        widget.onPaymentFailure(_error!, null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Payment form',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: const Text(
                'Payment Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          const SizedBox(height: 20),

          // Order summary
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.grey100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.grey200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${widget.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Quantity: ${widget.quantity}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Cardholder Name
          Semantics(
            label: 'Cardholder name',
            textField: true,
            child: TextFormField(
              controller: _cardholderNameController,
              decoration: InputDecoration(
                labelText: 'Cardholder Name',
                hintText: 'John Doe',
                hintStyle: const TextStyle(color: AppColors.textHint),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppColors.grey100,
                prefixIcon: const Icon(Icons.person, color: AppColors.textSecondary),
              ),
              style: const TextStyle(color: AppColors.textPrimary),
              textCapitalization: TextCapitalization.words,
              enabled: !widget.isProcessing,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Cardholder name is required';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 16),

          // Card Number
          Semantics(
            label: 'Card number',
            textField: true,
            hint: 'Enter your card number',
            child: TextFormField(
              controller: _cardNumberController,
              decoration: InputDecoration(
                labelText: 'Card Number',
                hintText: '1234 5678 9012 3456',
                hintStyle: const TextStyle(color: AppColors.textHint),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppColors.grey100,
                prefixIcon: const Icon(Icons.credit_card, color: AppColors.textSecondary),
              ),
              style: const TextStyle(color: AppColors.textPrimary),
              keyboardType: TextInputType.number,
              enabled: !widget.isProcessing,
              maxLength: 19, // 16 digits + 3 spaces
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Card number is required';
                }
                // Basic validation (remove spaces)
                final cardNumber = value.replaceAll(' ', '');
                if (cardNumber.length < 13 || cardNumber.length > 19) {
                  return 'Invalid card number';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 16),

          // Expiry and CVV Row
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _expiryController,
                  decoration: InputDecoration(
                    labelText: 'Expiry (MM/YY)',
                    hintText: '12/25',
                    hintStyle: const TextStyle(color: AppColors.textHint),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: AppColors.grey100,
                    prefixIcon: const Icon(Icons.calendar_today, color: AppColors.textSecondary, size: 20),
                  ),
                  style: const TextStyle(color: AppColors.textPrimary),
                  keyboardType: TextInputType.number,
                  enabled: !widget.isProcessing,
                  maxLength: 5,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Expiry is required';
                    }
                    if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(value)) {
                      return 'Invalid format (MM/YY)';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _cvvController,
                  decoration: InputDecoration(
                    labelText: 'CVV',
                    hintText: '123',
                    hintStyle: const TextStyle(color: AppColors.textHint),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: AppColors.grey100,
                    prefixIcon: const Icon(Icons.lock, color: AppColors.textSecondary, size: 20),
                  ),
                  style: const TextStyle(color: AppColors.textPrimary),
                  keyboardType: TextInputType.number,
                  enabled: !widget.isProcessing,
                  maxLength: 4,
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'CVV is required';
                    }
                    if (value.length < 3 || value.length > 4) {
                      return 'Invalid CVV';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),

          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Payment Button
          Semantics(
            label: 'Pay ${widget.amount.toStringAsFixed(2)}',
            button: true,
            enabled: !widget.isProcessing,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.isProcessing ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(0, 44), // Minimum touch target
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: widget.isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.payment, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Pay \$${widget.amount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Security Notice
          const Row(
            children: [
              Icon(Icons.lock, size: 16, color: AppColors.textSecondary),
              SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Your payment is secure and encrypted',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }

  /// Convert User to UnifiedUser for service compatibility
  UnifiedUser _convertUserToUnifiedUser(user_model.User user) {
    return UnifiedUser(
      id: user.id,
      email: user.email,
      displayName: user.displayName ?? user.name,
      photoUrl: null, // User model doesn't have photoUrl
      location: null, // User model doesn't have location
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
      isOnline: user.isOnline ?? false,
      hasCompletedOnboarding: true, // Assume completed if authenticated
      hasReceivedStarterLists: false,
      expertise: null,
      locations: null,
      hostedEventsCount: null,
      differentSpotsCount: null,
      tags: const [],
      expertiseMap: const {},
      friends: const [],
      curatedLists: user.curatedLists,
      collaboratedLists: user.collaboratedLists,
      followedLists: user.followedLists,
      primaryRole: UserRole.follower, // Default role
      isAgeVerified: false,
      ageVerificationDate: null,
    );
  }
}


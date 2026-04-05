import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avrai_core/models/expertise/expertise_event.dart';
import 'package:avrai_core/models/user/unified_user.dart';
import 'package:avrai_runtime_os/services/expertise/expertise_event_service.dart';
import 'package:avrai_runtime_os/services/payment/payment_service.dart';
import 'package:avrai/theme/colors.dart';
import 'package:avrai/theme/app_theme.dart';
import 'package:avrai/presentation/pages/events/event_details_page.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/presentation/widgets/common/app_flow_scaffold.dart';
import 'package:avrai/presentation/widgets/common/app_surface.dart';

/// Payment Success Page
/// Agent 2: Event Discovery & Hosting UI (Section 2, Task 2.2)
///
/// CRITICAL: Uses AppColors/AppTheme (100% adherence required)
///
/// Features:
/// - Success message
/// - Event details
/// - Registration confirmation
/// - Navigation to event details
class PaymentSuccessPage extends StatefulWidget {
  final ExpertiseEvent event;
  final String paymentId;
  final int quantity;

  /// Optional eventService for testing. If not provided, uses GetIt instance.
  final ExpertiseEventService? eventService;

  const PaymentSuccessPage({
    super.key,
    required this.event,
    required this.paymentId,
    required this.quantity,
    this.eventService,
  });

  @override
  State<PaymentSuccessPage> createState() => _PaymentSuccessPageState();
}

class _PaymentSuccessPageState extends State<PaymentSuccessPage> {
  final _paymentService = GetIt.instance<PaymentService>();
  late final ExpertiseEventService _eventService;
  bool _isRegistering = false;
  bool _registrationComplete = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Use injected instance (for testing) or get from DI (for production)
    // This ensures single instance across app, not per-page
    _eventService =
        widget.eventService ?? GetIt.instance<ExpertiseEventService>();
    _registerForEvent();
  }

  Future<void> _registerForEvent() async {
    setState(() {
      _isRegistering = true;
      _error = null;
    });

    try {
      final payment = _paymentService.getPayment(widget.paymentId);
      if (payment == null) {
        throw Exception('Payment not found');
      }

      // Get current user from AuthBloc
      final authState = context.read<AuthBloc>().state;
      if (authState is! Authenticated) {
        throw Exception('User not authenticated');
      }

      final authUser = authState.user;
      final unifiedUser = UnifiedUser(
        id: authUser.id,
        email: authUser.email,
        displayName: authUser.displayName ?? authUser.name,
        createdAt: authUser.createdAt,
        updatedAt: authUser.updatedAt,
        isOnline: authUser.isOnline ?? false,
      );

      // Register user for event (for each ticket quantity)
      for (int i = 0; i < widget.quantity; i++) {
        await _eventService.registerForEvent(
          widget.event,
          unifiedUser,
        );
      }

      setState(() {
        _registrationComplete = true;
        _isRegistering = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Registration failed: $e';
        _isRegistering = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppFlowScaffold(
      title: 'Payment Successful',
      backgroundColor: AppColors.background,
      appBarBackgroundColor: AppTheme.primaryColor,
      appBarForegroundColor: AppColors.white,
      appBarElevation: 0,
      automaticallyImplyLeading: false,
      constrainBody: false,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),

                // Success Icon
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.electricGreen.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    size: 80,
                    color: AppColors.electricGreen,
                  ),
                ),

                const SizedBox(height: 24),

                // Success Message
                const Text(
                  'Payment Successful!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                Text(
                  _registrationComplete
                      ? 'You are registered for ${widget.quantity > 1 ? "${widget.quantity} tickets" : "the event"}!'
                      : 'Registering you for the event...',
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),

                if (_isRegistering) ...[
                  const SizedBox(height: 24),
                  const CircularProgressIndicator(),
                ],

                if (_error != null) ...[
                  const SizedBox(height: 24),
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
                        const Icon(Icons.error_outline, color: AppColors.error),
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

                const SizedBox(height: 40),

                // Event Preview Card
                AppSurface(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.electricGreen
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              widget.event.getEventTypeEmoji(),
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.event.title,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.event.getEventTypeDisplayName(),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow(Icons.calendar_today,
                          _formatDateTime(widget.event.startTime)),
                      if (widget.event.location != null)
                        _buildInfoRow(
                            Icons.location_on, widget.event.location!),
                      if (widget.quantity > 1)
                        _buildInfoRow(Icons.confirmation_number,
                            '${widget.quantity} tickets'),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Action Buttons
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              EventDetailsPage(event: widget.event),
                        ),
                      );
                    },
                    icon: const Icon(Icons.event, size: 20),
                    label: const Text('View Event Details'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
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
                  child: const Text(
                    'Back to Home',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
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

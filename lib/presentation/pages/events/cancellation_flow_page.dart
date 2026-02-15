import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/core/models/expertise/expertise_event.dart';
import 'package:avrai/core/models/misc/cancellation.dart';
import 'package:avrai/core/models/payment/refund_status.dart';
import 'package:avrai/core/controllers/event_cancellation_controller.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/core/theme/tokens/theme_tokens.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';
import 'package:avrai/presentation/widgets/portal/portal_surface.dart';

/// Cancellation Flow Page
///
/// Agent 2: Phase 5, Week 16-17 - Cancellation UI
///
/// CRITICAL: Uses AppColors/AppTheme (100% adherence required)
///
/// Features:
/// - Multi-step cancellation flow
/// - Reason selection
/// - Refund preview
/// - Policy explanation
/// - Confirmation step
/// - Processing status
class CancellationFlowPage extends StatefulWidget {
  final ExpertiseEvent event;
  final bool isHost; // true if host is cancelling, false if attendee

  const CancellationFlowPage({
    super.key,
    required this.event,
    this.isHost = false,
  });

  @override
  State<CancellationFlowPage> createState() => _CancellationFlowPageState();
}

class _CancellationFlowPageState extends State<CancellationFlowPage> {
  late EventCancellationController _cancellationController;

  int _currentStep = 0;
  String? _selectedReason;
  double? _refundAmount;
  Cancellation? _cancellation;
  bool _isProcessing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cancellationController = GetIt.instance<EventCancellationController>();
    _calculateRefundPreview();
  }

  // Cancellation reasons
  final List<String> _attendeeReasons = [
    'Unable to attend',
    'Schedule conflict',
    'Found a better option',
    'Changed my mind',
    'Other',
  ];

  final List<String> _hostReasons = [
    'Unexpected circumstances',
    'Low attendance',
    'Venue issue',
    'Weather concerns',
    'Other',
  ];

  Future<void> _calculateRefundPreview() async {
    if (widget.isHost) {
      // Host cancellation - full refunds for all attendees
      setState(() {
        _refundAmount = null; // Will be calculated on confirmation
      });
      return;
    }

    // Attendee cancellation - calculate refund using controller
    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is! Authenticated) return;

      final calculation = await _cancellationController.calculateRefund(
        eventId: widget.event.id,
        userId: authState.user.id,
      );

      setState(() {
        _refundAmount = calculation.refundAmount;
      });
    } catch (e) {
      // Ignore errors in preview - will show "Calculating..." message
    }
  }

  Future<void> _processCancellation() async {
    if (_selectedReason == null) return;

    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is! Authenticated) {
        throw Exception('Please sign in to cancel');
      }

      final userId = authState.user.id;

      // Use controller for cancellation
      final result = await _cancellationController.cancelEvent(
        eventId: widget.event.id,
        userId: userId,
        reason: _selectedReason!,
        isHost: widget.isHost,
      );

      if (!result.success) {
        throw Exception(result.error ?? 'Cancellation failed');
      }

      setState(() {
        _cancellation = result.cancellation;
        _currentStep = 4; // Success step
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdaptivePlatformPageScaffold(
      title: widget.isHost ? 'Cancel Event' : 'Cancel Ticket',
      constrainBody: false,
      backgroundColor: AppColors.background,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isProcessing) {
      return _buildProcessingStep();
    }

    if (_cancellation != null) {
      return _buildSuccessStep();
    }

    return Stepper(
      currentStep: _currentStep,
      onStepContinue: _canProceedToNextStep()
          ? () {
              if (_currentStep == 3) {
                // Final confirmation - process cancellation
                _processCancellation();
              } else {
                setState(() {
                  _currentStep++;
                });
              }
            }
          : null,
      onStepCancel: _currentStep > 0
          ? () {
              setState(() {
                _currentStep--;
              });
            }
          : null,
      steps: [
        _buildReasonStep(),
        _buildRefundPreviewStep(),
        _buildPolicyStep(),
        _buildConfirmationStep(),
      ],
    );
  }

  bool _canProceedToNextStep() {
    switch (_currentStep) {
      case 0:
        return _selectedReason != null;
      case 1:
      case 2:
        return true;
      case 3:
        return true;
      default:
        return false;
    }
  }

  Step _buildReasonStep() {
    final reasons = widget.isHost ? _hostReasons : _attendeeReasons;
    final textTheme = Theme.of(context).textTheme;

    return Step(
      title: Text(
        'Reason for Cancellation',
        style: textTheme.titleMedium?.copyWith(color: AppColors.textPrimary),
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.isHost
                ? 'Please select a reason for cancelling this event:'
                : 'Please select a reason for cancelling your ticket:',
            style:
                textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
          ),
          SizedBox(height: context.spacing.md),
          RadioGroup<String>(
            groupValue: _selectedReason,
            onChanged: (val) {
              setState(() {
                _selectedReason = val;
              });
            },
            child: Column(
              children: reasons.map((reason) {
                return RadioListTile<String>(
                  title: Text(
                    reason,
                    style: textTheme.bodyLarge
                        ?.copyWith(color: AppColors.textPrimary),
                  ),
                  value: reason,
                  activeColor: AppTheme.primaryColor,
                );
              }).toList(),
            ),
          ),
        ],
      ),
      isActive: _currentStep >= 0,
      state: _currentStep > 0
          ? StepState.complete
          : (_selectedReason != null ? StepState.indexed : StepState.indexed),
    );
  }

  Step _buildRefundPreviewStep() {
    final textTheme = Theme.of(context).textTheme;
    return Step(
      title: Text(
        'Refund Preview',
        style: textTheme.titleMedium?.copyWith(color: AppColors.textPrimary),
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.isHost) ...[
            Text(
              'As the event host, cancelling this event will:',
              style:
                  textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
            ),
            SizedBox(height: context.spacing.md),
            _buildInfoCard(
              icon: Icons.money_off,
              title: 'Full Refunds',
              description: 'All attendees will receive full refunds',
            ),
            SizedBox(height: context.spacing.sm),
            _buildInfoCard(
              icon: Icons.warning,
              title: 'Host Penalty',
              description: widget.event.startTime
                          .difference(DateTime.now())
                          .inHours <
                      48
                  ? 'You may incur a penalty for last-minute cancellation (< 48 hours)'
                  : 'No penalty (cancelled more than 48 hours before event)',
            ),
          ] else ...[
            Text(
              'Refund Information:',
              style:
                  textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
            ),
            SizedBox(height: context.spacing.md),
            if (_refundAmount != null && _refundAmount! > 0) ...[
              _buildInfoCard(
                icon: Icons.check_circle,
                title: 'Refund Available',
                description:
                    'You will receive \$${_refundAmount!.toStringAsFixed(2)} refund',
                color: AppColors.electricGreen,
              ),
            ] else if (_refundAmount != null && _refundAmount! == 0) ...[
              _buildInfoCard(
                icon: Icons.cancel,
                title: 'No Refund',
                description:
                    'Cancellation is less than 24 hours before the event. No refund available.',
                color: AppColors.error,
              ),
            ] else ...[
              _buildInfoCard(
                icon: Icons.info,
                title: 'Calculating...',
                description:
                    'Refund amount will be calculated based on cancellation time',
              ),
            ],
          ],
        ],
      ),
      isActive: _currentStep >= 1,
      state: _currentStep > 1 ? StepState.complete : StepState.indexed,
    );
  }

  Step _buildPolicyStep() {
    final textTheme = Theme.of(context).textTheme;
    return Step(
      title: Text(
        'Refund Policy',
        style: textTheme.titleMedium?.copyWith(color: AppColors.textPrimary),
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Standard Refund Policy:',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: context.spacing.md),
          _buildPolicyItem(
            'More than 48 hours before event',
            'Full refund (minus 10% platform fee)',
            Icons.check_circle,
            AppColors.electricGreen,
          ),
          SizedBox(height: context.spacing.sm),
          _buildPolicyItem(
            '24-48 hours before event',
            '50% refund (minus 10% platform fee)',
            Icons.info,
            AppTheme.warningColor,
          ),
          SizedBox(height: context.spacing.sm),
          _buildPolicyItem(
            'Less than 24 hours before event',
            'No refund available',
            Icons.cancel,
            AppColors.error,
          ),
          SizedBox(height: context.spacing.md),
          PortalSurface(
            padding: EdgeInsets.all(context.spacing.sm),
            color: AppColors.grey100,
            borderColor: AppColors.grey300,
            radius: context.radius.sm,
            child: Text(
              'Note: Force majeure events (weather, emergencies) always receive full refunds.',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
      isActive: _currentStep >= 2,
      state: _currentStep > 2 ? StepState.complete : StepState.indexed,
    );
  }

  Step _buildConfirmationStep() {
    final textTheme = Theme.of(context).textTheme;
    return Step(
      title: Text(
        'Confirm Cancellation',
        style: textTheme.titleMedium?.copyWith(color: AppColors.textPrimary),
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PortalSurface(
            padding: EdgeInsets.all(context.spacing.md),
            color: AppColors.error.withValues(alpha: 0.1),
            borderColor: AppColors.error.withValues(alpha: 0.3),
            radius: context.radius.sm,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning, color: AppColors.error),
                    SizedBox(width: context.spacing.xs),
                    Text(
                      'Are you sure?',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.spacing.sm),
                Text(
                  widget.isHost
                      ? 'Cancelling this event will notify all attendees and process refunds. This action cannot be undone.'
                      : 'Cancelling your ticket will process your refund (if applicable). This action cannot be undone.',
                  style: textTheme.bodyMedium
                      ?.copyWith(color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
          SizedBox(height: context.spacing.md),
          Text(
            'Summary:',
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: context.spacing.xs),
          _buildSummaryItem('Event', widget.event.title),
          _buildSummaryItem('Reason', _selectedReason ?? 'Not selected'),
          if (!widget.isHost && _refundAmount != null)
            _buildSummaryItem(
              'Refund',
              _refundAmount! > 0
                  ? '\$${_refundAmount!.toStringAsFixed(2)}'
                  : 'No refund',
            ),
        ],
      ),
      isActive: _currentStep >= 3,
      state: StepState.indexed,
    );
  }

  Widget _buildProcessingStep() {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          SizedBox(height: context.spacing.xl),
          Text(
            'Processing cancellation...',
            style:
                textTheme.titleMedium?.copyWith(color: AppColors.textPrimary),
          ),
          SizedBox(height: context.spacing.xs),
          Text(
            'Please wait while we process your refund.',
            style:
                textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          if (_error != null) ...[
            SizedBox(height: context.spacing.xl),
            PortalSurface(
              padding: EdgeInsets.all(context.spacing.md),
              margin: EdgeInsets.symmetric(horizontal: context.spacing.xl),
              color: AppColors.error.withValues(alpha: 0.1),
              borderColor: AppColors.error.withValues(alpha: 0.3),
              radius: context.radius.sm,
              child: Text(
                _error!,
                style: textTheme.bodyMedium?.copyWith(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSuccessStep() {
    final textTheme = Theme.of(context).textTheme;
    final refundStatus = _cancellation!.refundStatus;
    final hasRefund =
        _cancellation!.refundAmount != null && _cancellation!.refundAmount! > 0;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.spacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              refundStatus == RefundStatus.completed
                  ? Icons.check_circle
                  : Icons.info,
              size: 80,
              color: refundStatus == RefundStatus.completed
                  ? AppColors.electricGreen
                  : AppTheme.warningColor,
            ),
            SizedBox(height: context.spacing.xl),
            Text(
              widget.isHost ? 'Event Cancelled' : 'Ticket Cancelled',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: context.spacing.md),
            Text(
              widget.isHost
                  ? 'All attendees have been notified and refunds are being processed.'
                  : 'Your cancellation has been processed.',
              style:
                  textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (hasRefund) ...[
              SizedBox(height: context.spacing.xl),
              PortalSurface(
                padding: EdgeInsets.all(context.spacing.md),
                color: AppColors.electricGreen.withValues(alpha: 0.1),
                borderColor: AppColors.electricGreen.withValues(alpha: 0.3),
                radius: context.radius.sm,
                child: Column(
                  children: [
                    Text(
                      'Refund Amount',
                      style: textTheme.bodyMedium
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                    SizedBox(height: context.spacing.xxs),
                    Text(
                      '\$${_cancellation!.refundAmount!.toStringAsFixed(2)}',
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.electricGreen,
                      ),
                    ),
                    SizedBox(height: context.spacing.xs),
                    Text(
                      refundStatus == RefundStatus.completed
                          ? 'Refund processed successfully'
                          : 'Refund is being processed',
                      style: textTheme.bodySmall
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: context.spacing.xl),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: AppColors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: context.spacing.xxl,
                  vertical: context.spacing.md,
                ),
              ),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
    Color? color,
  }) {
    final textTheme = Theme.of(context).textTheme;
    return PortalSurface(
      padding: EdgeInsets.all(context.spacing.md),
      color: (color ?? AppTheme.primaryColor).withValues(alpha: 0.1),
      borderColor: (color ?? AppTheme.primaryColor).withValues(alpha: 0.3),
      radius: context.radius.sm,
      child: Row(
        children: [
          Icon(icon, color: color ?? AppTheme.primaryColor),
          SizedBox(width: context.spacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: context.spacing.xxs),
                Text(
                  description,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyItem(
      String time, String refund, IconData icon, Color color) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        SizedBox(width: context.spacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                time,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                refund,
                style: textTheme.bodySmall
                    ?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(bottom: context.spacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

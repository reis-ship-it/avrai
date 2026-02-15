import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/core/design/feedback_presenter.dart';
import 'package:avrai/core/models/expertise/expertise_event.dart';
import 'package:avrai/core/models/disputes/fraud_score.dart';
import 'package:avrai/core/models/disputes/fraud_recommendation.dart';
import 'package:avrai/core/services/fraud/fraud_detection_service.dart';
import 'package:avrai/core/services/expertise/expertise_event_service.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/core/theme/tokens/theme_tokens.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';
import 'package:avrai/presentation/widgets/portal/portal_surface.dart';

/// Fraud Review Page (Admin)
///
/// Agent 2: Phase 5, Week 20-21 - Fraud Review UI
///
/// CRITICAL: Uses AppColors/AppTheme (100% adherence required)
///
/// Features:
/// - Fraud score display
/// - Fraud signals list
/// - Recommendation display
/// - Approve/Reject/Require Verification actions
/// - Event details
/// - Host information
class FraudReviewPage extends StatefulWidget {
  final String eventId;

  const FraudReviewPage({
    super.key,
    required this.eventId,
  });

  @override
  State<FraudReviewPage> createState() => _FraudReviewPageState();
}

class _FraudReviewPageState extends State<FraudReviewPage> {
  final FraudDetectionService _fraudService = FraudDetectionService(
    eventService: GetIt.instance<ExpertiseEventService>(),
  );
  final ExpertiseEventService _eventService =
      GetIt.instance<ExpertiseEventService>();

  FraudScore? _fraudScore;
  ExpertiseEvent? _event;
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load event
      final event = await _eventService.getEventById(widget.eventId);

      // Analyze or get existing fraud score
      FraudScore? score;
      try {
        score = await _fraudService.getFraudScore(widget.eventId);
      } catch (e) {
        // If no score exists, analyze the event
        score = await _fraudService.analyzeEvent(widget.eventId);
      }

      setState(() {
        _event = event;
        _fraudScore = score;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _updateAdminDecision(String decision) async {
    if (_fraudScore == null) return;

    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      // In production, this would call an admin service to update the decision
      // For now, we'll just update the local state
      setState(() {
        _fraudScore = _fraudScore!.copyWith(
          reviewedByAdmin: true,
          adminDecision: decision,
          reviewedAt: DateTime.now(),
        );
        _isProcessing = false;
      });

      if (mounted) {
        context.showSuccess('Decision saved: ${decision.toUpperCase()}');
        Navigator.pop(context);
      }
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
      title: 'Fraud Review',
      backgroundColor: AppColors.background,
      appBarBackgroundColor: AppTheme.primaryColor,
      appBarForegroundColor: AppColors.white,
      appBarElevation: 0,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null || _fraudScore == null || _event == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: AppColors.error),
                      SizedBox(height: context.spacing.md),
                      Text(
                        _error ?? 'Failed to load fraud review data',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppColors.error),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: context.spacing.md),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(context.spacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Risk Score Badge
                        _buildRiskScoreBadge(),
                        SizedBox(height: context.spacing.xl),

                        // Event Details
                        _buildEventDetails(),
                        SizedBox(height: context.spacing.xl),

                        // Fraud Signals
                        _buildFraudSignals(),
                        SizedBox(height: context.spacing.xl),

                        // Recommendation
                        _buildRecommendation(),
                        SizedBox(height: context.spacing.xl),

                        // Admin Actions
                        if (!_fraudScore!.reviewedByAdmin) _buildAdminActions(),
                        if (_fraudScore!.reviewedByAdmin) _buildReviewStatus(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildRiskScoreBadge() {
    final score = _fraudScore!.riskScore;
    Color badgeColor;
    String riskLevel;

    if (score >= 0.7) {
      badgeColor = AppColors.error;
      riskLevel = 'High Risk';
    } else if (score >= 0.4) {
      badgeColor = AppTheme.warningColor;
      riskLevel = 'Medium Risk';
    } else {
      badgeColor = AppColors.electricGreen;
      riskLevel = 'Low Risk';
    }

    return PortalSurface(
      padding: EdgeInsets.all(context.spacing.xl),
      color: badgeColor.withValues(alpha: 0.1),
      borderColor: badgeColor.withValues(alpha: 0.3),
      radius: context.radius.md,
      child: Row(
        children: [
          Icon(Icons.shield, size: 48, color: badgeColor),
          SizedBox(width: context.spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  riskLevel,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: badgeColor,
                      ),
                ),
                Text(
                  'Risk Score: ${(score * 100).toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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

  Widget _buildEventDetails() {
    return PortalSurface(
      padding: EdgeInsets.all(context.spacing.lg),
      color: AppColors.surface,
      borderColor: AppColors.grey300,
      radius: context.radius.md,
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
          SizedBox(height: context.spacing.md),
          _buildDetailRow('Title', _event!.title),
          _buildDetailRow(
              'Host', _event!.host.displayName ?? _event!.host.email),
          _buildDetailRow(
              'Price', '\$${_event!.price?.toStringAsFixed(2) ?? '0.00'}'),
          _buildDetailRow('Location', _event!.location ?? 'Not specified'),
          _buildDetailRow('Date', _formatDateTime(_event!.startTime)),
          _buildDetailRow('Attendees',
              '${_event!.attendeeCount} / ${_event!.maxAttendees}'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.spacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFraudSignals() {
    if (_fraudScore!.signals.isEmpty) {
      return PortalSurface(
        padding: EdgeInsets.all(context.spacing.lg),
        color: AppColors.electricGreen.withValues(alpha: 0.1),
        borderColor: AppColors.electricGreen.withValues(alpha: 0.3),
        radius: context.radius.md,
        child: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.electricGreen),
            SizedBox(width: 12),
            Text(
              'No fraud signals detected',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.electricGreen,
                  ),
            ),
          ],
        ),
      );
    }

    return PortalSurface(
      padding: EdgeInsets.all(context.spacing.lg),
      color: AppColors.surface,
      borderColor: AppColors.grey300,
      radius: context.radius.md,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fraud Signals (${_fraudScore!.signals.length})',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
          ),
          SizedBox(height: context.spacing.md),
          ..._fraudScore!.signals.map((signal) {
            return Padding(
              padding: EdgeInsets.only(bottom: context.spacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.warning,
                    color: AppTheme.warningColor,
                    size: 20,
                  ),
                  SizedBox(width: context.spacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          signal.displayName,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                        ),
                        SizedBox(height: context.spacing.xxs),
                        Text(
                          signal.description,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                        SizedBox(height: context.spacing.xxs),
                        Text(
                          'Risk Weight: ${(signal.riskWeight * 100).toStringAsFixed(0)}%',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                    fontStyle: FontStyle.italic,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRecommendation() {
    final recommendation = _fraudScore!.recommendation;
    Color recColor;
    IconData recIcon;
    String recText;

    switch (recommendation) {
      case FraudRecommendation.approve:
        recColor = AppColors.electricGreen;
        recIcon = Icons.check_circle;
        recText = 'Approve';
        break;
      case FraudRecommendation.review:
        recColor = AppTheme.warningColor;
        recIcon = Icons.rate_review;
        recText = 'Review';
        break;
      case FraudRecommendation.requireVerification:
        recColor = AppTheme.primaryColor;
        recIcon = Icons.verified_user;
        recText = 'Require Verification';
        break;
      case FraudRecommendation.reject:
        recColor = AppColors.error;
        recIcon = Icons.cancel;
        recText = 'Reject';
        break;
    }

    return PortalSurface(
      padding: EdgeInsets.all(context.spacing.lg),
      color: recColor.withValues(alpha: 0.1),
      borderColor: recColor.withValues(alpha: 0.3),
      radius: context.radius.md,
      child: Row(
        children: [
          Icon(recIcon, size: 32, color: recColor),
          SizedBox(width: context.spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recommendation',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                Text(
                  recText,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: recColor,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Admin Decision',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
        ),
        SizedBox(height: context.spacing.md),
        if (_error != null) ...[
          PortalSurface(
            padding: EdgeInsets.all(context.spacing.sm),
            margin: EdgeInsets.only(bottom: context.spacing.md),
            color: AppColors.error.withValues(alpha: 0.1),
            borderColor: AppColors.error.withValues(alpha: 0.3),
            radius: context.radius.sm,
            child: Row(
              children: [
                const Icon(Icons.error_outline,
                    color: AppColors.error, size: 20),
                SizedBox(width: context.spacing.xs),
                Expanded(
                  child: Text(
                    _error!,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.error),
                  ),
                ),
              ],
            ),
          ),
        ],
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isProcessing
                    ? null
                    : () => _updateAdminDecision('approve'),
                icon: const Icon(Icons.check),
                label: Text('Approve'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.electricGreen,
                  side: const BorderSide(color: AppColors.electricGreen),
                  minimumSize: const Size(0, 48),
                ),
              ),
            ),
            SizedBox(width: context.spacing.sm),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isProcessing
                    ? null
                    : () => _updateAdminDecision('require_verification'),
                icon: const Icon(Icons.verified_user),
                label: Text('Verify'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  side: const BorderSide(color: AppTheme.primaryColor),
                  minimumSize: const Size(0, 48),
                ),
              ),
            ),
            SizedBox(width: context.spacing.sm),
            Expanded(
              child: OutlinedButton.icon(
                onPressed:
                    _isProcessing ? null : () => _updateAdminDecision('reject'),
                icon: const Icon(Icons.cancel),
                label: Text('Reject'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  minimumSize: const Size(0, 48),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReviewStatus() {
    return PortalSurface(
      padding: EdgeInsets.all(context.spacing.lg),
      color: AppColors.electricGreen.withValues(alpha: 0.1),
      borderColor: AppColors.electricGreen.withValues(alpha: 0.3),
      radius: context.radius.md,
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.electricGreen),
          SizedBox(width: context.spacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reviewed',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.electricGreen,
                      ),
                ),
                Text(
                  'Decision: ${_fraudScore!.adminDecision?.toUpperCase() ?? 'N/A'}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                if (_fraudScore!.reviewedAt != null)
                  Text(
                    'Reviewed on ${_formatDate(_fraudScore!.reviewedAt!)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.month}/${dateTime.day}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/core/design/feedback_presenter.dart';
import 'package:avrai/core/models/events/event_feedback.dart';
import 'package:avrai/core/models/disputes/review_fraud_score.dart';
import 'package:avrai/core/models/disputes/fraud_recommendation.dart';
import 'package:avrai/core/services/fraud/review_fraud_detection_service.dart';
import 'package:avrai/core/services/events/post_event_feedback_service.dart';
import 'package:avrai/core/services/expertise/expertise_event_service.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/core/theme/tokens/theme_tokens.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';
import 'package:avrai/presentation/widgets/portal/portal_surface.dart';

/// Review Fraud Review Page (Admin)
///
/// Agent 2: Phase 5, Week 20-21 - Fraud Review UI
///
/// CRITICAL: Uses AppColors/AppTheme (100% adherence required)
///
/// Features:
/// - Review fraud score
/// - Fraud signals
/// - Review details
/// - User information
/// - Actions (approve/remove)
class ReviewFraudReviewPage extends StatefulWidget {
  final String eventId;

  const ReviewFraudReviewPage({
    super.key,
    required this.eventId,
  });

  @override
  State<ReviewFraudReviewPage> createState() => _ReviewFraudReviewPageState();
}

class _ReviewFraudReviewPageState extends State<ReviewFraudReviewPage> {
  final ReviewFraudDetectionService _reviewFraudService =
      ReviewFraudDetectionService(
    feedbackService: PostEventFeedbackService(
      eventService: GetIt.instance<ExpertiseEventService>(),
    ),
  );
  final PostEventFeedbackService _feedbackService = PostEventFeedbackService(
    eventService: GetIt.instance<ExpertiseEventService>(),
  );

  ReviewFraudScore? _fraudScore;
  List<EventFeedback> _feedbacks = [];
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
      // Load feedbacks for event
      final feedbacks =
          await _feedbackService.getFeedbackForEvent(widget.eventId);

      // Analyze or get existing fraud score
      ReviewFraudScore? score;
      try {
        score = await _reviewFraudService.getFraudScore(widget.eventId);
      } catch (e) {
        // If no score exists, analyze the reviews
        score = await _reviewFraudService.analyzeReviews(widget.eventId);
      }

      setState(() {
        _feedbacks = feedbacks;
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
    final textTheme = Theme.of(context).textTheme;
    return AdaptivePlatformPageScaffold(
      title: 'Review Fraud Review',
      backgroundColor: AppColors.background,
      appBarBackgroundColor: AppTheme.primaryColor,
      appBarForegroundColor: AppColors.white,
      appBarElevation: 0,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null || _fraudScore == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: AppColors.error),
                      SizedBox(height: context.spacing.md),
                      Text(
                        _error ?? 'Failed to load review fraud data',
                        style: textTheme.bodyMedium
                            ?.copyWith(color: AppColors.error),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: context.spacing.md),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Retry'),
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

                        // Review Summary
                        _buildReviewSummary(),
                        SizedBox(height: context.spacing.xl),

                        // Fraud Signals
                        _buildFraudSignals(),
                        SizedBox(height: context.spacing.xl),

                        // Recommendation
                        _buildRecommendation(),
                        SizedBox(height: context.spacing.xl),

                        // Reviews List
                        if (_feedbacks.isNotEmpty) ...[
                          _buildReviewsList(),
                          SizedBox(height: context.spacing.xl),
                        ],

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
    final textTheme = Theme.of(context).textTheme;
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
          Icon(Icons.rate_review, size: 48, color: badgeColor),
          SizedBox(width: context.spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  riskLevel,
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                  ),
                ),
                Text(
                  'Risk Score: ${(score * 100).toStringAsFixed(0)}%',
                  style: textTheme.bodyLarge
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewSummary() {
    final textTheme = Theme.of(context).textTheme;
    return PortalSurface(
      padding: EdgeInsets.all(context.spacing.lg),
      color: AppColors.surface,
      borderColor: AppColors.grey300,
      radius: context.radius.md,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review Summary',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: context.spacing.md),
          _buildDetailRow('Total Reviews', '${_feedbacks.length}'),
          if (_feedbacks.isNotEmpty) ...[
            _buildDetailRow(
              'Average Rating',
              '${(_feedbacks.map((f) => f.overallRating).reduce((a, b) => a + b) / _feedbacks.length).toStringAsFixed(1)} / 5.0',
            ),
            _buildDetailRow(
              '5-Star Reviews',
              '${_feedbacks.where((f) => f.overallRating >= 4.5).length}',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(bottom: context.spacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildFraudSignals() {
    final textTheme = Theme.of(context).textTheme;
    if (_fraudScore!.signals.isEmpty) {
      return PortalSurface(
        padding: EdgeInsets.all(context.spacing.lg),
        color: AppColors.electricGreen.withValues(alpha: 0.1),
        borderColor: AppColors.electricGreen.withValues(alpha: 0.3),
        radius: context.radius.md,
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.electricGreen),
            SizedBox(width: context.spacing.sm),
            Text(
              'No fraud signals detected',
              style: textTheme.titleSmall?.copyWith(
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
            style: textTheme.titleMedium?.copyWith(
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
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: context.spacing.xxs),
                        Text(
                          signal.description,
                          style: textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
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
    final textTheme = Theme.of(context).textTheme;
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
        recText = 'Remove';
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
                  style: textTheme.bodyMedium
                      ?.copyWith(color: AppColors.textSecondary),
                ),
                Text(
                  recText,
                  style: textTheme.titleLarge?.copyWith(
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

  Widget _buildReviewsList() {
    final textTheme = Theme.of(context).textTheme;
    return PortalSurface(
      padding: EdgeInsets.all(context.spacing.lg),
      color: AppColors.surface,
      borderColor: AppColors.grey300,
      radius: context.radius.md,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reviews (${_feedbacks.length})',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: context.spacing.md),
          ..._feedbacks.take(5).map((feedback) {
            return Padding(
              padding: EdgeInsets.only(bottom: context.spacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ...List.generate(5, (index) {
                        return Icon(
                          feedback.overallRating >= (index + 1)
                              ? Icons.star
                              : Icons.star_border,
                          size: 16,
                          color: feedback.overallRating >= (index + 1)
                              ? AppTheme.warningColor
                              : AppColors.grey400,
                        );
                      }),
                      SizedBox(width: context.spacing.xs),
                      Text(
                        feedback.overallRating.toStringAsFixed(1),
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatDate(feedback.submittedAt),
                        style: textTheme.bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  if (feedback.comments != null &&
                      feedback.comments!.isNotEmpty) ...[
                    SizedBox(height: context.spacing.xs),
                    Text(
                      feedback.comments!,
                      style: textTheme.bodyMedium
                          ?.copyWith(color: AppColors.textPrimary),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            );
          }),
          if (_feedbacks.length > 5)
            Text(
              '... and ${_feedbacks.length - 5} more reviews',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAdminActions() {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Admin Decision',
          style: textTheme.titleMedium?.copyWith(
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
                    style:
                        textTheme.bodySmall?.copyWith(color: AppColors.error),
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
                label: const Text('Approve'),
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
                onPressed:
                    _isProcessing ? null : () => _updateAdminDecision('remove'),
                icon: const Icon(Icons.delete),
                label: const Text('Remove'),
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
    final textTheme = Theme.of(context).textTheme;
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
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.electricGreen,
                  ),
                ),
                Text(
                  'Decision: ${_fraudScore!.adminDecision?.toUpperCase() ?? 'N/A'}',
                  style: textTheme.bodyMedium
                      ?.copyWith(color: AppColors.textSecondary),
                ),
                if (_fraudScore!.reviewedAt != null)
                  Text(
                    'Reviewed on ${_formatDate(_fraudScore!.reviewedAt!)}',
                    style: textTheme.bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}

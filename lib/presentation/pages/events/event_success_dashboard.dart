import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/core/models/expertise/expertise_event.dart';
import 'package:avrai/core/models/events/event_success_metrics.dart';
import 'package:avrai/core/models/events/event_success_level.dart';
import 'package:avrai/core/services/events/event_success_analysis_service.dart';
import 'package:avrai/core/services/expertise/expertise_event_service.dart';
import 'package:avrai/core/services/events/post_event_feedback_service.dart';
import 'package:avrai/core/services/payment/payment_service.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/core/theme/tokens/theme_tokens.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';
import 'package:avrai/presentation/widgets/portal/portal_surface.dart';

/// Event Success Dashboard
///
/// Agent 2: Phase 5, Week 17 - Success Dashboard UI
///
/// CRITICAL: Uses AppColors/AppTheme (100% adherence required)
///
/// Features:
/// - Success level badge
/// - Key metrics display (attendance, revenue, rating)
/// - NPS score display
/// - Success factors display
/// - Improvement areas display
/// - Partner satisfaction scores
/// - Comparison to similar events
/// - Actionable recommendations
class EventSuccessDashboard extends StatefulWidget {
  final ExpertiseEvent event;

  const EventSuccessDashboard({
    super.key,
    required this.event,
  });

  @override
  State<EventSuccessDashboard> createState() => _EventSuccessDashboardState();
}

class _EventSuccessDashboardState extends State<EventSuccessDashboard> {
  final EventSuccessAnalysisService _analysisService =
      EventSuccessAnalysisService(
    eventService: GetIt.instance<ExpertiseEventService>(),
    feedbackService: PostEventFeedbackService(
      eventService: GetIt.instance<ExpertiseEventService>(),
    ),
    paymentService: GetIt.instance<PaymentService>(),
  );

  EventSuccessMetrics? _metrics;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Try to get existing metrics first
      var metrics = await _analysisService.getEventMetrics(widget.event.id);

      // If no metrics exist, analyze the event
      metrics ??= await _analysisService.analyzeEventSuccess(widget.event.id);

      setState(() {
        _metrics = metrics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdaptivePlatformPageScaffold(
      title: 'Event Success Dashboard',
      constrainBody: false,
      backgroundColor: AppColors.background,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            SizedBox(height: context.spacing.md),
            Text(
              _error!,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: context.spacing.md),
            ElevatedButton(
              onPressed: _loadMetrics,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_metrics == null) {
      return const Center(
        child: Text('No metrics available'),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(context.spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Success Level Badge
            _buildSuccessLevelBadge(),
            SizedBox(height: context.spacing.xl),

            // Key Metrics
            _buildKeyMetrics(),
            SizedBox(height: context.spacing.xl),

            // NPS Score
            _buildNPSScore(),
            SizedBox(height: context.spacing.xl),

            // Success Factors
            if (_metrics!.successFactors.isNotEmpty) ...[
              _buildSuccessFactors(),
              SizedBox(height: context.spacing.xl),
            ],

            // Improvement Areas
            if (_metrics!.improvementAreas.isNotEmpty) ...[
              _buildImprovementAreas(),
              SizedBox(height: context.spacing.xl),
            ],

            // Partner Satisfaction
            if (_metrics!.partnerSatisfaction.isNotEmpty) ...[
              _buildPartnerSatisfaction(),
              SizedBox(height: context.spacing.xl),
            ],

            // Recommendations
            _buildRecommendations(),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessLevelBadge() {
    final level = _metrics!.successLevel;
    Color badgeColor;
    String badgeText;
    IconData badgeIcon;

    switch (level) {
      case EventSuccessLevel.exceptional:
        badgeColor = AppColors.electricGreen;
        badgeText = 'Exceptional Success';
        badgeIcon = Icons.emoji_events;
        break;
      case EventSuccessLevel.high:
        badgeColor = AppColors.electricGreen;
        badgeText = 'High Success';
        badgeIcon = Icons.check_circle;
        break;
      case EventSuccessLevel.medium:
        badgeColor = AppTheme.warningColor;
        badgeText = 'Moderate Success';
        badgeIcon = Icons.info;
        break;
      case EventSuccessLevel.low:
        badgeColor = AppColors.error;
        badgeText = 'Needs Improvement';
        badgeIcon = Icons.trending_down;
        break;
    }

    return PortalSurface(
      padding: EdgeInsets.all(context.spacing.xl),
      color: badgeColor.withValues(alpha: 0.1),
      borderColor: badgeColor.withValues(alpha: 0.3),
      radius: context.radius.md,
      child: Row(
        children: [
          Icon(badgeIcon, size: 48, color: badgeColor),
          SizedBox(width: context.spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  badgeText,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: badgeColor,
                      ),
                ),
                SizedBox(height: context.spacing.xxs),
                Text(
                  widget.event.title,
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

  Widget _buildKeyMetrics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Key Metrics',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
        ),
        SizedBox(height: context.spacing.md),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Attendance',
                '${_metrics!.actualAttendance}/${_metrics!.ticketsSold}',
                '${(_metrics!.attendanceRate * 100).toStringAsFixed(0)}%',
                Icons.people,
                AppTheme.primaryColor,
              ),
            ),
            SizedBox(width: context.spacing.sm),
            Expanded(
              child: _buildMetricCard(
                'Revenue',
                '\$${_metrics!.netRevenue.toStringAsFixed(0)}',
                'Net',
                Icons.attach_money,
                AppColors.electricGreen,
              ),
            ),
          ],
        ),
        SizedBox(height: context.spacing.sm),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Rating',
                _metrics!.averageRating.toStringAsFixed(1),
                'out of 5.0',
                Icons.star,
                AppTheme.warningColor,
              ),
            ),
            SizedBox(width: context.spacing.sm),
            Expanded(
              child: _buildMetricCard(
                'Feedback',
                '${(_metrics!.feedbackResponseRate * 100).toStringAsFixed(0)}%',
                'Response Rate',
                Icons.feedback,
                AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return PortalSurface(
      padding: EdgeInsets.all(context.spacing.md),
      color: AppColors.surface,
      borderColor: AppColors.grey300,
      radius: context.radius.sm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              SizedBox(width: context.spacing.xs),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ),
            ],
          ),
          SizedBox(height: context.spacing.xs),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
          ),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildNPSScore() {
    final nps = _metrics!.nps;
    Color npsColor;
    String npsLabel;

    if (nps >= 50) {
      npsColor = AppColors.electricGreen;
      npsLabel = 'Excellent';
    } else if (nps >= 0) {
      npsColor = AppTheme.primaryColor;
      npsLabel = 'Good';
    } else if (nps >= -50) {
      npsColor = AppTheme.warningColor;
      npsLabel = 'Needs Improvement';
    } else {
      npsColor = AppColors.error;
      npsLabel = 'Poor';
    }

    return PortalSurface(
      padding: EdgeInsets.all(context.spacing.lg),
      color: AppColors.surface,
      borderColor: AppColors.grey300,
      radius: context.radius.md,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: npsColor),
              SizedBox(width: context.spacing.xs),
              Text(
                'Net Promoter Score (NPS)',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
              ),
            ],
          ),
          SizedBox(height: context.spacing.md),
          Row(
            children: [
              Text(
                nps.toStringAsFixed(0),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: npsColor,
                    ),
              ),
              SizedBox(width: context.spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      npsLabel,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: npsColor,
                          ),
                    ),
                    SizedBox(height: context.spacing.xxs),
                    Text(
                      '${_metrics!.attendeesWhoWouldRecommend} would recommend',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: context.spacing.md),
          // NPS Scale
          Row(
            children: [
              const Expanded(
                child: SizedBox(
                  height: 8,
                  child: ClipRRect(
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                    child: ColoredBox(color: AppColors.error),
                  ),
                ),
              ),
              SizedBox(width: context.spacing.xxs),
              const Expanded(
                child: SizedBox(
                  height: 8,
                  child: ClipRRect(
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                    child: ColoredBox(color: AppTheme.warningColor),
                  ),
                ),
              ),
              SizedBox(width: context.spacing.xxs),
              const Expanded(
                child: SizedBox(
                  height: 8,
                  child: ClipRRect(
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                    child: ColoredBox(color: AppTheme.primaryColor),
                  ),
                ),
              ),
              SizedBox(width: context.spacing.xxs),
              const Expanded(
                child: SizedBox(
                  height: 8,
                  child: ClipRRect(
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                    child: ColoredBox(color: AppColors.electricGreen),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: context.spacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('-100',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.textSecondary)),
              Text('0',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.textSecondary)),
              Text('50',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.textSecondary)),
              Text('100',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessFactors() {
    return PortalSurface(
      padding: EdgeInsets.all(context.spacing.lg),
      color: AppColors.electricGreen.withValues(alpha: 0.1),
      borderColor: AppColors.electricGreen.withValues(alpha: 0.3),
      radius: context.radius.md,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.electricGreen),
              SizedBox(width: 8),
              Text(
                'Success Factors',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
              ),
            ],
          ),
          SizedBox(height: context.spacing.sm),
          ..._metrics!.successFactors.map((factor) {
            return Padding(
              padding: EdgeInsets.only(bottom: context.spacing.xs),
              child: Row(
                children: [
                  const Icon(Icons.check,
                      size: 16, color: AppColors.electricGreen),
                  SizedBox(width: context.spacing.xs),
                  Expanded(
                    child: Text(
                      factor,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textPrimary,
                          ),
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

  Widget _buildImprovementAreas() {
    return PortalSurface(
      padding: EdgeInsets.all(context.spacing.lg),
      color: AppTheme.warningColor.withValues(alpha: 0.1),
      borderColor: AppTheme.warningColor.withValues(alpha: 0.3),
      radius: context.radius.md,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: AppTheme.warningColor),
              SizedBox(width: 8),
              Text(
                'Improvement Areas',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
              ),
            ],
          ),
          SizedBox(height: context.spacing.sm),
          ..._metrics!.improvementAreas.map((area) {
            return Padding(
              padding: EdgeInsets.only(bottom: context.spacing.xs),
              child: Row(
                children: [
                  const Icon(Icons.arrow_forward,
                      size: 16, color: AppTheme.warningColor),
                  SizedBox(width: context.spacing.xs),
                  Expanded(
                    child: Text(
                      area,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textPrimary,
                          ),
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

  Widget _buildPartnerSatisfaction() {
    return PortalSurface(
      padding: EdgeInsets.all(context.spacing.lg),
      color: AppColors.surface,
      borderColor: AppColors.grey300,
      radius: context.radius.md,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.handshake, color: AppTheme.primaryColor),
              SizedBox(width: 8),
              Text(
                'Partner Satisfaction',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
              ),
            ],
          ),
          SizedBox(height: context.spacing.sm),
          ..._metrics!.partnerSatisfaction.entries.map((entry) {
            return Padding(
              padding: EdgeInsets.only(bottom: context.spacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Partner ${entry.key.substring(0, 8)}...',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textPrimary,
                          ),
                    ),
                  ),
                  Row(
                    children: [
                      ...List.generate(5, (index) {
                        return Icon(
                          entry.value >= (index + 1)
                              ? Icons.star
                              : Icons.star_border,
                          size: 16,
                          color: entry.value >= (index + 1)
                              ? AppTheme.warningColor
                              : AppColors.grey400,
                        );
                      }),
                      SizedBox(width: context.spacing.xs),
                      Text(
                        entry.value.toStringAsFixed(1),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
          if (_metrics!.partnersWouldCollaborateAgain) ...[
            SizedBox(height: context.spacing.sm),
            PortalSurface(
              padding: EdgeInsets.all(context.spacing.sm),
              color: AppColors.electricGreen.withValues(alpha: 0.1),
              borderColor: AppColors.electricGreen.withValues(alpha: 0.3),
              radius: context.radius.sm,
              child: Row(
                children: [
                  Icon(Icons.check_circle,
                      color: AppColors.electricGreen, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Partners would collaborate again',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.electricGreen,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecommendations() {
    final recommendations = _generateRecommendations();

    return PortalSurface(
      padding: EdgeInsets.all(context.spacing.lg),
      color: AppColors.surface,
      borderColor: AppColors.grey300,
      radius: context.radius.md,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: AppTheme.primaryColor),
              SizedBox(width: 8),
              Text(
                'Actionable Recommendations',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
              ),
            ],
          ),
          SizedBox(height: context.spacing.sm),
          ...recommendations.map((recommendation) {
            return Padding(
              padding: EdgeInsets.only(bottom: context.spacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.arrow_forward,
                      size: 16, color: AppTheme.primaryColor),
                  SizedBox(width: context.spacing.xs),
                  Expanded(
                    child: Text(
                      recommendation,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textPrimary,
                          ),
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

  List<String> _generateRecommendations() {
    final recommendations = <String>[];

    // Attendance recommendations
    if (_metrics!.attendanceRate < 0.8) {
      recommendations.add(
          'Consider sending reminder notifications to increase attendance');
    }

    // Rating recommendations
    if (_metrics!.averageRating < 4.0) {
      recommendations.add('Focus on improving event quality based on feedback');
    }

    // NPS recommendations
    if (_metrics!.nps < 0) {
      recommendations.add(
          'Work on improving attendee satisfaction to increase recommendations');
    }

    // Revenue recommendations
    if (_metrics!.revenueVsProjected < 0) {
      recommendations.add('Review pricing strategy to meet revenue goals');
    }

    // Feedback recommendations
    if (_metrics!.feedbackResponseRate < 0.5) {
      recommendations.add('Encourage more attendees to provide feedback');
    }

    // Improvement area recommendations
    if (_metrics!.improvementAreas.isNotEmpty) {
      recommendations.add(
          'Address improvement areas: ${_metrics!.improvementAreas.join(", ")}');
    }

    if (recommendations.isEmpty) {
      recommendations.add(
          'Keep up the great work! Continue focusing on what made this event successful.');
    }

    return recommendations;
  }
}

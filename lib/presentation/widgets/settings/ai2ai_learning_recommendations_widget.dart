/// AI2AI Learning Recommendations Widget
///
/// Phase 7, Week 38: AI2AI Learning Methods UI - Integration & Polish
///
/// Widget displaying learning recommendations:
/// - Optimal learning partners
/// - Learning topics
/// - Development areas
/// - Recommendation cards
///
/// Uses AppColors/AppTheme for 100% design token compliance.
library;

import 'package:flutter/material.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/services/ai_infrastructure/ai2ai_learning_service.dart';
import 'package:avrai/core/ai/ai2ai_learning.dart';
import 'package:avrai/core/theme/tokens/theme_tokens.dart';
import 'package:avrai/presentation/presentation_spacing.dart';

/// Widget displaying AI2AI learning recommendations
class AI2AILearningRecommendationsWidget extends StatefulWidget {
  /// User ID to show recommendations for
  final String userId;

  /// AI2AI learning service
  final AI2AILearning learningService;

  const AI2AILearningRecommendationsWidget({
    super.key,
    required this.userId,
    required this.learningService,
  });

  @override
  State<AI2AILearningRecommendationsWidget> createState() =>
      _AI2AILearningRecommendationsWidgetState();
}

class _AI2AILearningRecommendationsWidgetState
    extends State<AI2AILearningRecommendationsWidget> {
  AI2AILearningRecommendations? _recommendations;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get learning recommendations
      final recommendations = await widget.learningService
          .getLearningRecommendations(widget.userId);

      if (mounted) {
        setState(() {
          _recommendations = recommendations;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load recommendations: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Semantics(
        label: 'Loading learning recommendations',
        child: Card(
          margin: EdgeInsets.only(bottom: context.spacing.md),
          child: Padding(
            padding: EdgeInsets.all(context.spacing.xl),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Semantics(
        label: 'Error loading recommendations',
        child: Card(
          margin: EdgeInsets.only(bottom: context.spacing.md),
          child: Padding(
            padding: EdgeInsets.all(context.spacing.md),
            child: Column(
              children: [
                Icon(
                  Icons.error_outline,
                  color: AppColors.error,
                  size: 32,
                ),
                SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.error,
                      ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                TextButton(
                  onPressed: _loadRecommendations,
                  child: Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_recommendations == null) {
      return SizedBox.shrink();
    }

    return Semantics(
      label: 'AI2AI learning recommendations',
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.only(bottom: context.spacing.md),
        child: Padding(
          padding: EdgeInsets.all(context.spacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(context.spacing.xs),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.recommend,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Learning Recommendations',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                    ),
                  ),
                  if (_recommendations!.confidenceScore > 0)
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: kSpaceXs, vertical: kSpaceXxs),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${(_recommendations!.confidenceScore * 100).toStringAsFixed(0)}%',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.success,
                            ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 16),

              // Optimal Partners
              if (_recommendations!.optimalPartners.isNotEmpty) ...[
                _buildSectionTitle('Optimal Learning Partners'),
                SizedBox(height: 8),
                ..._recommendations!.optimalPartners
                    .map((partner) => _buildPartnerCard(partner)),
                SizedBox(height: 16),
              ],

              // Learning Topics
              if (_recommendations!.learningTopics.isNotEmpty) ...[
                _buildSectionTitle('Learning Topics'),
                SizedBox(height: 8),
                ..._recommendations!.learningTopics
                    .map((topic) => _buildTopicCard(topic)),
                SizedBox(height: 16),
              ],

              // Development Areas
              if (_recommendations!.developmentAreas.isNotEmpty) ...[
                _buildSectionTitle('Development Areas'),
                SizedBox(height: 8),
                ..._recommendations!.developmentAreas
                    .map((area) => _buildDevelopmentAreaCard(area)),
              ],

              // Empty State
              if (_recommendations!.optimalPartners.isEmpty &&
                  _recommendations!.learningTopics.isEmpty &&
                  _recommendations!.developmentAreas.isEmpty)
                _buildEmptyState(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
    );
  }

  Widget _buildPartnerCard(OptimalPartner partner) {
    return Container(
      margin: EdgeInsets.only(bottom: context.spacing.xs),
      padding: EdgeInsets.all(context.spacing.sm),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(context.spacing.xs),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.person_outline,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  partner.archetype,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                ),
                SizedBox(height: 4),
                LinearProgressIndicator(
                  value: partner.compatibility,
                  backgroundColor: AppColors.grey200,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  minHeight: 4,
                ),
              ],
            ),
          ),
          SizedBox(width: 8),
          Text(
            '${(partner.compatibility * 100).toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicCard(LearningTopic topic) {
    return Container(
      margin: EdgeInsets.only(bottom: context.spacing.xs),
      padding: EdgeInsets.all(context.spacing.sm),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(context.spacing.xs),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.topic,
              color: AppColors.success,
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  topic.topic,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                ),
                SizedBox(height: 4),
                LinearProgressIndicator(
                  value: topic.potential,
                  backgroundColor: AppColors.grey200,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.success),
                  minHeight: 4,
                ),
              ],
            ),
          ),
          SizedBox(width: 8),
          Text(
            '${(topic.potential * 100).toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildDevelopmentAreaCard(DevelopmentArea area) {
    return Container(
      margin: EdgeInsets.only(bottom: context.spacing.xs),
      padding: EdgeInsets.all(context.spacing.sm),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(context.spacing.xs),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.trending_up,
              color: AppColors.warning,
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  area.area,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                ),
                SizedBox(height: 4),
                LinearProgressIndicator(
                  value: area.priority,
                  backgroundColor: AppColors.grey200,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.warning),
                  minHeight: 4,
                ),
              ],
            ),
          ),
          SizedBox(width: 8),
          Text(
            '${(area.priority * 100).toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.warning,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: EdgeInsets.all(context.spacing.md),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.info_outline,
              color: AppColors.textSecondary,
              size: 48,
            ),
            SizedBox(height: 8),
            Text(
              'No recommendations yet',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            SizedBox(height: 4),
            Text(
              'Start AI2AI connections to get personalized recommendations',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textHint,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

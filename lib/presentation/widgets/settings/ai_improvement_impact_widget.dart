/// AI Improvement Impact Widget
///
/// Part of Feature Matrix Phase 2: Medium Priority UI/UX
/// Section 2.2: AI Self-Improvement Visibility
///
/// Widget explaining AI improvement impact:
/// - Explain improvement impact on user experience
/// - Show user benefits from improvements
/// - Transparency into AI evolution
/// - Real-world impact examples
///
/// Location: Settings/Account page
/// Uses AppColors and AppTheme for consistent styling per design token requirements.
library;

import 'package:flutter/material.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/services/ai_infrastructure/ai_improvement_tracking_service.dart';
import 'package:avrai/core/theme/tokens/theme_tokens.dart';

/// Widget displaying AI improvement impact explanation
class AIImprovementImpactWidget extends StatelessWidget {
  /// User ID to show impact for
  final String userId;

  /// Improvement tracking service
  final AIImprovementTrackingService trackingService;

  const AIImprovementImpactWidget({
    super.key,
    required this.userId,
    required this.trackingService,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    return Semantics(
      label: 'AI Improvement Impact Explanation',
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.only(bottom: spacing.md),
        child: Padding(
          padding: EdgeInsets.all(spacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 16),
              _buildImpactSummary(context),
              const SizedBox(height: 16),
              _buildBenefitsSection(context),
              const SizedBox(height: 16),
              _buildTransparencySection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final spacing = context.spacing;
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(spacing.xs),
          decoration: BoxDecoration(
            color: AppColors.electricGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.lightbulb_outline,
            color: AppColors.electricGreen,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'What This Means for You',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildImpactSummary(BuildContext context) {
    final spacing = context.spacing;
    return Container(
      padding: EdgeInsets.all(spacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.electricGreen.withValues(alpha: 0.1),
            AppColors.electricGreen.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.electricGreen.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: AppColors.electricGreen,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'AI Evolution Impact',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'As your AI improves, you experience:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 12),
          _buildImpactPoint(
            context: context,
            icon: Icons.recommend,
            title: 'Better Recommendations',
            description: 'More accurate spot suggestions matching your taste',
          ),
          _buildImpactPoint(
            context: context,
            icon: Icons.speed,
            title: 'Faster Responses',
            description: 'Quicker AI processing and instant suggestions',
          ),
          _buildImpactPoint(
            context: context,
            icon: Icons.psychology,
            title: 'Deeper Understanding',
            description: 'AI learns your preferences and patterns better',
          ),
        ],
      ),
    );
  }

  Widget _buildImpactPoint({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
  }) {
    final spacing = context.spacing;
    return Padding(
      padding: EdgeInsets.only(bottom: spacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(spacing.xxs),
            decoration: BoxDecoration(
              color: AppColors.electricGreen.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              color: AppColors.electricGreen,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
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

  Widget _buildBenefitsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.card_giftcard,
              size: 18,
              color: AppColors.electricGreen,
            ),
            SizedBox(width: 8),
            Text(
              'Your Benefits',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildBenefitCard(
          context: context,
          title: 'Personalization',
          description: 'AI adapts to your unique preferences',
          icon: Icons.person,
          color: AppColors.electricGreen,
        ),
        const SizedBox(height: 8),
        _buildBenefitCard(
          context: context,
          title: 'Discovery',
          description: 'Find hidden gems that match your vibe',
          icon: Icons.explore,
          color: AppColors.primary,
        ),
        const SizedBox(height: 8),
        _buildBenefitCard(
          context: context,
          title: 'Efficiency',
          description: 'Less time searching, more time enjoying',
          icon: Icons.flash_on,
          color: AppColors.warning,
        ),
        const SizedBox(height: 8),
        _buildBenefitCard(
          context: context,
          title: 'Community',
          description: 'Connect with like-minded people through AI',
          icon: Icons.people,
          color: AppColors.primary,
        ),
      ],
    );
  }

  Widget _buildBenefitCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    final spacing = context.spacing;
    return Container(
      padding: EdgeInsets.all(spacing.sm),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(spacing.xs),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
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
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
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

  Widget _buildTransparencySection(BuildContext context) {
    final spacing = context.spacing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.visibility,
              size: 18,
              color: AppColors.electricGreen,
            ),
            SizedBox(width: 8),
            Text(
              'Transparency & Control',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: EdgeInsets.all(spacing.md),
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTransparencyPoint(
                context: context,
                icon: Icons.check_circle_outline,
                text: 'You always know what your AI is learning',
              ),
              const SizedBox(height: 10),
              _buildTransparencyPoint(
                context: context,
                icon: Icons.check_circle_outline,
                text: 'All improvements are privacy-preserving',
              ),
              const SizedBox(height: 10),
              _buildTransparencyPoint(
                context: context,
                icon: Icons.check_circle_outline,
                text: 'You control learning participation',
              ),
              const SizedBox(height: 10),
              _buildTransparencyPoint(
                context: context,
                icon: Icons.check_circle_outline,
                text: 'Progress tracked in real-time',
              ),
              const SizedBox(height: 16),
              Center(
                child: Semantics(
                  label: 'Navigate to privacy settings',
                  button: true,
                  child: TextButton.icon(
                    onPressed: () {
                      // Navigate to privacy settings
                    },
                    icon: const Icon(
                      Icons.settings,
                      size: 18,
                    ),
                    label: Text('Privacy Settings'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.electricGreen,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTransparencyPoint({
    required BuildContext context,
    required IconData icon,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: AppColors.electricGreen,
          size: 18,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                ),
          ),
        ),
      ],
    );
  }
}

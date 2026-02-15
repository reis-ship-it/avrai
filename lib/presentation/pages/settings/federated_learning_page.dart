import 'package:flutter/material.dart';
import 'package:avrai/presentation/widgets/settings/federated_learning_settings_section.dart';
import 'package:avrai/presentation/widgets/settings/federated_learning_status_widget.dart';
import 'package:avrai/presentation/widgets/settings/privacy_metrics_widget.dart';
import 'package:avrai/presentation/widgets/settings/federated_participation_history_widget.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/tokens/theme_tokens.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';
import 'package:avrai/presentation/widgets/portal/portal_surface.dart';

/// Federated Learning Page
///
/// Phase 2.1: Complete federated learning UI in Settings
///
/// Combines all 4 federated learning widgets into a single comprehensive page:
/// 1. Settings & Explanation (opt-in/opt-out)
/// 2. Active Learning Rounds
/// 3. Privacy Metrics
/// 4. Participation History
class FederatedLearningPage extends StatelessWidget {
  const FederatedLearningPage({super.key});

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final textTheme = Theme.of(context).textTheme;

    return AdaptivePlatformPageScaffold(
      title: 'Federated Learning',
      constrainBody: false,
      body: ListView(
        padding: EdgeInsets.all(spacing.md),
        children: [
          // Header
          _buildHeader(context),
          SizedBox(height: spacing.lg),

          // Section 1: Settings & Explanation
          _buildSectionHeader(context, 'Settings & Participation'),
          SizedBox(height: spacing.sm),
          const FederatedLearningSettingsSection(),
          SizedBox(height: spacing.xl),

          // Section 2: Active Rounds
          _buildSectionHeader(context, 'Active Learning Rounds'),
          SizedBox(height: spacing.xs),
          Text(
            'See what your AI is learning right now',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: spacing.sm),
          const FederatedLearningStatusWidget(),
          SizedBox(height: spacing.xl),

          // Section 3: Privacy Metrics
          _buildSectionHeader(context, 'Your Privacy Metrics'),
          SizedBox(height: spacing.xs),
          Text(
            'See how your privacy is protected',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: spacing.sm),
          const PrivacyMetricsWidget(),
          SizedBox(height: spacing.xl),

          // Section 4: History
          _buildSectionHeader(context, 'Participation History'),
          SizedBox(height: spacing.xs),
          Text(
            'Your contributions to AI improvement',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: spacing.sm),
          const FederatedParticipationHistoryWidget(),
          SizedBox(height: spacing.lg),

          // Footer
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final spacing = context.spacing;
    final textTheme = Theme.of(context).textTheme;

    return PortalSurface(
      radius: context.radius.md,
      color: AppColors.electricGreen.withValues(alpha: 0.1),
      borderColor: AppColors.electricGreen.withValues(alpha: 0.24),
      child: Row(
        children: [
          CircleAvatar(
            radius: spacing.lg + spacing.xs,
            backgroundColor: AppColors.electricGreen.withValues(alpha: 0.2),
            child: const Icon(
              Icons.school,
              color: AppColors.electricGreen,
              size: 30,
            ),
          ),
          SizedBox(width: spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Privacy-Preserving AI Training',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: spacing.xxs),
                Text(
                  'Help improve AI without sharing your data',
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

  Widget _buildSectionHeader(BuildContext context, String title) {
    final textTheme = Theme.of(context).textTheme;

    return Text(
      title,
      style: textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final spacing = context.spacing;
    final textTheme = Theme.of(context).textTheme;

    return PortalSurface(
      radius: context.radius.md,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: AppColors.primary,
                size: 20,
              ),
              SizedBox(width: spacing.xs),
              Text(
                'Learn More',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.sm),
          Text(
            'Federated learning is a privacy-preserving approach to AI training. '
            'Your device trains a local model on your data, then sends only encrypted '
            'model updates (not your actual data) to be aggregated with others. '
            'The improved global model is then distributed back to all participants.',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          SizedBox(height: spacing.sm),
          Row(
            children: [
              const Icon(
                Icons.shield,
                color: AppColors.success,
                size: 16,
              ),
              SizedBox(width: spacing.xxs),
              Text(
                'Your data never leaves your device',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

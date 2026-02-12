import 'package:flutter/material.dart';
import 'package:avrai/presentation/widgets/settings/federated_learning_settings_section.dart';
import 'package:avrai/presentation/widgets/settings/federated_learning_status_widget.dart';
import 'package:avrai/presentation/widgets/settings/privacy_metrics_widget.dart';
import 'package:avrai/presentation/widgets/settings/federated_participation_history_widget.dart';
import 'package:avrai/core/theme/colors.dart';
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
    return AdaptivePlatformPageScaffold(
      title: 'Federated Learning',
      constrainBody: false,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          _buildHeader(context),
          const SizedBox(height: 24),

          // Section 1: Settings & Explanation
          _buildSectionHeader(context, 'Settings & Participation'),
          const SizedBox(height: 12),
          const FederatedLearningSettingsSection(),
          const SizedBox(height: 32),

          // Section 2: Active Rounds
          _buildSectionHeader(context, 'Active Learning Rounds'),
          const SizedBox(height: 8),
          const Text(
            'See what your AI is learning right now',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          const FederatedLearningStatusWidget(),
          const SizedBox(height: 32),

          // Section 3: Privacy Metrics
          _buildSectionHeader(context, 'Your Privacy Metrics'),
          const SizedBox(height: 8),
          const Text(
            'See how your privacy is protected',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          const PrivacyMetricsWidget(),
          const SizedBox(height: 32),

          // Section 4: History
          _buildSectionHeader(context, 'Participation History'),
          const SizedBox(height: 8),
          const Text(
            'Your contributions to AI improvement',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          const FederatedParticipationHistoryWidget(),
          const SizedBox(height: 24),

          // Footer
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return PortalSurface(
      color: AppColors.electricGreen.withValues(alpha: 0.1),
      borderColor: AppColors.electricGreen.withValues(alpha: 0.24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.electricGreen.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.school,
              color: AppColors.electricGreen,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Privacy-Preserving AI Training',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Help improve AI without sharing your data',
                  style: TextStyle(
                    fontSize: 14,
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
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return const PortalSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppColors.primary,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Learn More',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'Federated learning is a privacy-preserving approach to AI training. '
            'Your device trains a local model on your data, then sends only encrypted '
            'model updates (not your actual data) to be aggregated with others. '
            'The improved global model is then distributed back to all participants.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.shield,
                color: AppColors.success,
                size: 16,
              ),
              SizedBox(width: 4),
              Text(
                'Your data never leaves your device',
                style: TextStyle(
                  fontSize: 13,
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

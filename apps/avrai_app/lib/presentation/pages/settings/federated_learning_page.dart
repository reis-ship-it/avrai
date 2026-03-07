import 'package:flutter/material.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';
import 'package:avrai/presentation/widgets/common/app_info_banner.dart';
import 'package:avrai/presentation/widgets/common/app_page_header.dart';
import 'package:avrai/presentation/widgets/common/app_section.dart';
import 'package:avrai/presentation/widgets/common/app_surface.dart';
import 'package:avrai/presentation/widgets/settings/federated_learning_settings_section.dart';
import 'package:avrai/presentation/widgets/settings/federated_learning_status_widget.dart';
import 'package:avrai/presentation/widgets/settings/federated_participation_history_widget.dart';
import 'package:avrai/presentation/widgets/settings/privacy_metrics_widget.dart';

class FederatedLearningPage extends StatelessWidget {
  const FederatedLearningPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdaptivePlatformPageScaffold(
      title: 'Federated Learning',
      constrainBody: false,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          AppSurface(
            child: AppPageHeader(
              title: 'Federated Learning',
              subtitle:
                  'Help improve shared models without sending your raw data off-device.',
              leadingIcon: Icons.school_outlined,
              showDivider: false,
            ),
          ),
          SizedBox(height: 16),
          AppInfoBanner(
            title: 'Privacy-preserving training',
            body:
                'Federated learning sends encrypted model updates instead of your original data.',
            icon: Icons.shield_outlined,
          ),
          SizedBox(height: 24),
          AppSection(
            title: 'Settings & Participation',
            child: FederatedLearningSettingsSection(),
          ),
          SizedBox(height: 24),
          AppSection(
            title: 'Active Learning Rounds',
            subtitle: 'See what your AI is learning right now.',
            child: FederatedLearningStatusWidget(),
          ),
          SizedBox(height: 24),
          AppSection(
            title: 'Your Privacy Metrics',
            subtitle: 'See how your privacy is protected.',
            child: PrivacyMetricsWidget(),
          ),
          SizedBox(height: 24),
          AppSection(
            title: 'Participation History',
            subtitle: 'Review your contributions to model improvement.',
            child: FederatedParticipationHistoryWidget(),
          ),
          SizedBox(height: 24),
          AppInfoBanner(
            title: 'Learn more',
            body:
                'Your device trains locally and contributes encrypted model updates to a shared model. Raw personal data stays on-device.',
            icon: Icons.info_outline,
          ),
        ],
      ),
    );
  }
}

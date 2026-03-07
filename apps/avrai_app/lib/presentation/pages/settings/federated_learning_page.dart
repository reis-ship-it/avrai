import 'package:flutter/material.dart';
import 'package:avrai/presentation/schema_renderer/app_schema_page.dart';
import 'package:avrai/presentation/schemas/pages/federated_learning_page_schema.dart';
import 'package:avrai/presentation/widgets/settings/federated_learning_settings_section.dart';
import 'package:avrai/presentation/widgets/settings/federated_learning_status_widget.dart';
import 'package:avrai/presentation/widgets/settings/federated_participation_history_widget.dart';
import 'package:avrai/presentation/widgets/settings/privacy_metrics_widget.dart';

class FederatedLearningPage extends StatelessWidget {
  const FederatedLearningPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppSchemaPage(
      schema: buildFederatedLearningPageSchema(
        content: const Column(
          children: [
            _FederatedLearningSections(),
          ],
        ),
      ),
    );
  }
}

class _FederatedLearningSections extends StatelessWidget {
  const _FederatedLearningSections();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _LearningSection(
          title: 'Settings & Participation',
          child: FederatedLearningSettingsSection(),
        ),
        const SizedBox(height: 24),
        _LearningSection(
          title: 'Active Learning Rounds',
          subtitle: 'See what your AI is learning right now.',
          child: FederatedLearningStatusWidget(),
        ),
        const SizedBox(height: 24),
        _LearningSection(
          title: 'Your Privacy Metrics',
          subtitle: 'See how your privacy is protected.',
          child: PrivacyMetricsWidget(),
        ),
        const SizedBox(height: 24),
        _LearningSection(
          title: 'Participation History',
          subtitle: 'Review your contributions to model improvement.',
          child: FederatedParticipationHistoryWidget(),
        ),
      ],
    );
  }
}

class _LearningSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const _LearningSection({
    required this.title,
    required this.child,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    if (subtitle == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          child,
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 6),
        Text(
          subtitle!,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

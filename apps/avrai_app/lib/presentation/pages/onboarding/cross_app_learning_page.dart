import 'package:flutter/material.dart';
import 'package:avrai_core/models/misc/cross_app_learning_insight.dart';
import 'package:avrai/presentation/widgets/common/app_page_scaffold.dart';
import 'package:avrai/presentation/schema_renderer/app_schema_page.dart';
import 'package:avrai/presentation/schemas/pages/cross_app_learning_page_schema.dart';
import 'package:avrai_runtime_os/services/cross_app/cross_app_consent_service.dart';
import 'package:avrai/injection_container.dart' as di;

/// Dedicated onboarding page for cross-app learning.
class CrossAppLearningPage extends StatefulWidget {
  /// Callback when user proceeds
  final VoidCallback? onProceed;

  /// Callback when user skips
  final VoidCallback? onSkip;

  const CrossAppLearningPage({
    super.key,
    this.onProceed,
    this.onSkip,
  });

  @override
  State<CrossAppLearningPage> createState() => _CrossAppLearningPageState();
}

class _CrossAppLearningPageState extends State<CrossAppLearningPage> {
  late CrossAppConsentService _consentService;
  Map<CrossAppDataSource, bool> _consents = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _consentService = di.sl<CrossAppConsentService>();
    _loadConsents();
  }

  Future<void> _loadConsents() async {
    final consents = await _consentService.getAllConsents();
    if (mounted) {
      setState(() {
        _consents = consents;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleToggle(CrossAppDataSource source, bool enabled) async {
    setState(() {
      _consents[source] = enabled;
    });
    await _consentService.setEnabled(source, enabled);
  }

  Future<void> _enableAll() async {
    await _consentService.enableAll();
    await _loadConsents();
  }

  Future<void> _handleEnableAndProceed() async {
    await _enableAll();
    await _handleProceed();
  }

  Future<void> _handleSkip() async {
    await _consentService.completeOnboarding();
    widget.onSkip?.call();
  }

  Future<void> _handleProceed() async {
    await _consentService.completeOnboarding();
    widget.onProceed?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const AppPageScaffold(
        title: 'Cross-App Learning',
        subtitle:
            'Choose which signals AVRAI can use to improve recommendations.',
        leadingIcon: Icons.psychology_outlined,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return AppSchemaPage(
      actions: [
        TextButton(
          onPressed: _handleSkip,
          child: const Text('Skip'),
        ),
      ],
      schema: buildCrossAppLearningPageSchema(
        consents: _consents,
        onSourceToggled: _handleToggle,
        onEnableAll: _handleEnableAndProceed,
        onContinue: _handleProceed,
      ),
    );
  }
}

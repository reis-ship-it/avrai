import 'package:flutter/material.dart';

import 'package:avrai/presentation/schema_renderer/app_schema_page.dart';
import 'package:avrai/presentation/schemas/pages/welcome_page_schema.dart';

/// Welcome Page
///
/// First screen in onboarding flow.
class WelcomePage extends StatelessWidget {
  /// Callback when user continues
  final VoidCallback? onContinue;

  /// Callback when user skips onboarding step
  final VoidCallback? onSkip;

  const WelcomePage({
    super.key,
    this.onContinue,
    this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return AppSchemaPage(
      actions: onSkip == null
          ? null
          : [
              TextButton(
                onPressed: onSkip,
                child: const Text('Skip'),
              ),
            ],
      padding: const EdgeInsets.all(24),
      schema: buildWelcomePageSchema(
        onContinue: onContinue ?? () {},
      ),
    );
  }
}

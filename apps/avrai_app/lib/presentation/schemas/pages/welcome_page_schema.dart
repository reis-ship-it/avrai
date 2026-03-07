import 'package:flutter/material.dart';

import 'package:avrai/presentation/schemas/models/page_schema.dart';

PageSchema buildWelcomePageSchema({
  required VoidCallback onContinue,
}) {
  return PageSchema(
    title: 'Welcome',
    header: const PageHeaderSchema(
      title: 'Welcome to AVRAI',
      subtitle:
          'Set up a calm baseline so recommendations, planning, and AI guidance feel useful from the start.',
      leadingIcon: Icons.waving_hand_rounded,
    ),
    sections: [
      const BannerSectionSchema(
        title: 'What happens next',
        body:
            'You will set a few preferences, connect the signals you want to share, and confirm the controls that stay in your hands.',
        icon: Icons.flag_outlined,
      ),
      const TextSectionSchema(
        title: 'What to expect',
        paragraphs: [
          'The onboarding flow is short and focused on relevance, consent, and control.',
          'You can adjust these choices later in settings without losing your account.',
        ],
      ),
      CtaSectionSchema(
        title: 'Ready to begin',
        body:
            'Start the setup flow and move through the core preferences for your account.',
        primaryLabel: 'Continue',
        onPrimaryTap: onContinue,
      ),
    ],
  );
}

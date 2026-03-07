import 'package:flutter/material.dart';

import 'package:avrai/presentation/schemas/models/page_schema.dart';

PageSchema buildAILoadingPageSchema({
  required Widget setupSection,
  required Widget infoSection,
  required Widget continueSection,
}) {
  return PageSchema(
    title: 'Preparing Your Experience',
    header: const PageHeaderSchema(
      title: 'Preparing Your Experience',
      subtitle: 'We\'re setting up your personalized experience',
      leadingIcon: Icons.psychology,
    ),
    sections: [
      CustomSectionSchema(
        title: 'Setup',
        subtitle:
            'Your AI is generating recommendations and personalized lists.',
        child: setupSection,
      ),
      CustomSectionSchema(
        title: 'What happens next',
        child: infoSection,
      ),
      CustomSectionSchema(
        title: 'Continue',
        subtitle: 'You can move on as soon as setup reaches a stable state.',
        child: continueSection,
      ),
    ],
  );
}

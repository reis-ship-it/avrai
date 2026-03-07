import 'package:flutter/material.dart';

import 'package:avrai/presentation/schemas/models/page_schema.dart';

PageSchema buildValuesSharingPageSchema({
  required Widget progressSection,
  required Widget questionSection,
  required Widget navigationSection,
}) {
  return PageSchema(
    title: 'Values & Sharing',
    header: const PageHeaderSchema(
      title: 'Values & Sharing',
      subtitle: 'What matters most to you?',
      leadingIcon: Icons.favorite_border_outlined,
    ),
    sections: [
      const BannerSectionSchema(
        title: 'Value preferences',
        body:
            'Your answers shape recommendations toward places and interactions that match your priorities.',
        icon: Icons.handshake_outlined,
      ),
      CustomSectionSchema(
        title: 'Question progress',
        subtitle: 'Answer each prompt to move forward.',
        child: progressSection,
      ),
      CustomSectionSchema(
        title: 'Values questions',
        child: questionSection,
      ),
      CustomSectionSchema(
        title: 'Navigation',
        child: navigationSection,
      ),
    ],
  );
}

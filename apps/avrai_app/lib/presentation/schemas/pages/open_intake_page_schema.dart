import 'package:flutter/material.dart';

import 'package:avrai/presentation/schemas/models/page_schema.dart';

PageSchema buildOpenIntakePageSchema({
  required Widget questionsSection,
}) {
  return PageSchema(
    title: 'About You',
    header: const PageHeaderSchema(
      title: 'About You',
      subtitle:
          'A few short answers help AVRAI build a more relevant starting point.',
      leadingIcon: Icons.edit_note_outlined,
    ),
    sections: [
      const BannerSectionSchema(
        title: 'Local only',
        body:
            'These answers stay on your device and help seed personalization. You can skip anything that does not matter to you.',
        icon: Icons.lock_outline,
      ),
      const TextSectionSchema(
        title: 'Open prompts',
        subtitle:
            'Use short answers. This is only here to give onboarding a better starting point.',
        paragraphs: [
          'Share what you are comfortable with and leave the rest empty.',
          'These responses inform your initial recommendation baseline.',
        ],
      ),
      CustomSectionSchema(
        title: 'Responses',
        child: questionsSection,
      ),
    ],
  );
}

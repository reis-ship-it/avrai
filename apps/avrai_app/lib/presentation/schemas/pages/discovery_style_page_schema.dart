import 'package:flutter/material.dart';

import 'package:avrai/presentation/schemas/models/page_schema.dart';

PageSchema buildDiscoveryStylePageSchema({
  required Widget progressSection,
  required Widget questionSection,
  required Widget navigationSection,
}) {
  return PageSchema(
    title: 'Discovery Style',
    header: const PageHeaderSchema(
      title: 'How Do You Discover?',
      subtitle:
          'Tell us about your discovery style so recommendations reflect your pacing and interests.',
      leadingIcon: Icons.explore_outlined,
    ),
    sections: [
      const BannerSectionSchema(
        title: 'Discovery preferences',
        body:
            'Your answers help AVRAI prioritize places and events that fit your curiosity.',
        icon: Icons.explore,
        tone: SchemaTone.neutral,
      ),
      const TextSectionSchema(
        title: 'How it helps',
        paragraphs: [
          'Answer each prompt to improve suggestion quality.',
          'More responses allow cleaner ranking across spots, events, and communities.',
          'You can revisit these preferences later from settings.',
        ],
      ),
      CustomSectionSchema(
        title: 'Question progress',
        subtitle: 'Complete each prompt to continue.',
        child: progressSection,
      ),
      CustomSectionSchema(
        title: 'Question prompts',
        child: questionSection,
      ),
      CustomSectionSchema(
        title: 'Navigation',
        child: navigationSection,
      ),
    ],
  );
}

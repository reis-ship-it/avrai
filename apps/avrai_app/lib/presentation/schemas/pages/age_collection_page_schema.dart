import 'package:flutter/material.dart';

import 'package:avrai/presentation/schemas/models/page_schema.dart';

PageSchema buildAgeCollectionPageSchema({
  required Widget birthdayField,
  required Widget? ageSummary,
}) {
  final sections = <SectionSchema>[
    const BannerSectionSchema(
      title: 'Why we ask for this',
      body:
          'Your age is used to set age-appropriate defaults and legal guardrails for discovery and privacy.',
      icon: Icons.cake_outlined,
      tone: SchemaTone.neutral,
    ),
    const TextSectionSchema(
      title: 'What we store',
      paragraphs: [
        'We use your selected age only for safe product defaults.',
        'You can review all age-related controls from your legal and privacy settings.',
        'You can update your value anytime during onboarding.',
      ],
    ),
    CustomSectionSchema(
      title: 'Birthday',
      subtitle: 'You can change this at any time before continuing.',
      child: birthdayField,
    ),
  ];

  if (ageSummary != null) {
    sections.add(
      CustomSectionSchema(
        title: 'Estimated age profile',
        child: ageSummary,
      ),
    );
  }

  return PageSchema(
    title: 'Age Verification',
    header: const PageHeaderSchema(
      title: 'Age Verification',
      subtitle:
          'Use your birthday to apply age-appropriate defaults and legal guardrails.',
      leadingIcon: Icons.cake_outlined,
    ),
    sections: sections,
  );
}

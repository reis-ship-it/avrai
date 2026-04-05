import 'package:flutter/material.dart';

import 'package:avrai/presentation/schemas/models/page_schema.dart';

PageSchema buildEnergyAtmospherePageSchema({
  required Widget progressSection,
  required Widget questionSection,
  required Widget navigationSection,
}) {
  return PageSchema(
    title: 'Energy & Atmosphere',
    header: const PageHeaderSchema(
      title: 'Energy & Atmosphere',
      subtitle:
          "Share your energy and atmosphere preferences for better matching.",
      leadingIcon: Icons.bolt_outlined,
    ),
    sections: [
      const BannerSectionSchema(
        title: 'Activity profile',
        body:
            'These preferences tune suggested settings like crowd level, pace, and event tempo.',
        icon: Icons.speed_outlined,
        tone: SchemaTone.neutral,
      ),
      const TextSectionSchema(
        title: 'How it helps',
        paragraphs: [
          'Your profile helps prioritize recommendations that match your preferred energy.',
          'You can refine these preferences as you use AVRAI.',
          'No single answer is locked in; your recommendations improve over time.',
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

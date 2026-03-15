import 'package:flutter/material.dart';

import 'package:avrai/presentation/schemas/models/page_schema.dart';

PageSchema buildBaselineListsPageSchema({
  required bool isLoading,
  required Widget loadingSection,
  required Widget introSection,
  required Widget listSection,
}) {
  final sections = <SectionSchema>[
    const BannerSectionSchema(
      title: 'Starter lists',
      body:
          'These are suggested starting points. You can edit, keep, or remove them anytime.',
      icon: Icons.lightbulb_outline,
    ),
    CustomSectionSchema(
      title: isLoading ? 'Creating recommendations' : 'Getting started',
      child: isLoading ? loadingSection : introSection,
    ),
  ];

  if (!isLoading) {
    sections.add(
      CustomSectionSchema(
        title: 'Recommended lists',
        child: listSection,
      ),
    );
  }

  return PageSchema(
    title: 'Starter Lists',
    header: const PageHeaderSchema(
      title: 'Starter Lists',
      subtitle:
          'AVRAI creates a few useful lists from your onboarding profile. Keep what looks useful and remove the rest later.',
      leadingIcon: Icons.auto_awesome_outlined,
    ),
    sections: sections,
  );
}

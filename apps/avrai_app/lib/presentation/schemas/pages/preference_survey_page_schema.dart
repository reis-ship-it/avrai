import 'package:flutter/material.dart';

import 'package:avrai/presentation/schemas/models/page_schema.dart';

PageSchema buildPreferenceSurveyPageSchema({
  required Widget summarySection,
  required Widget searchSection,
  required Widget categoriesSection,
}) {
  return PageSchema(
    title: 'What do you love?',
    header: const PageHeaderSchema(
      title: 'What do you love?',
      subtitle:
          'Select your preferences to help us find the right spots for you.',
      leadingIcon: Icons.favorite_border_outlined,
    ),
    sections: [
      const BannerSectionSchema(
        title: 'Preference survey',
        body:
            'Pick what you care about so recommendations can stay relevant and avoid noise.',
        icon: Icons.filter_list,
      ),
      CustomSectionSchema(
        title: 'Selection target',
        subtitle: 'Choose 15 preferences (recommended)',
        child: summarySection,
      ),
      CustomSectionSchema(
        title: 'Search',
        child: searchSection,
      ),
      CustomSectionSchema(
        title: 'Categories',
        child: categoriesSection,
      ),
    ],
  );
}

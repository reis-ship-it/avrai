import 'package:flutter/material.dart';

import 'package:avrai/presentation/schemas/models/page_schema.dart';

PageSchema buildFavoritePlacesPageSchema({
  required Widget searchSection,
  required Widget selectionSection,
  required Widget placesSection,
}) {
  return PageSchema(
    title: 'Favorite Places',
    header: const PageHeaderSchema(
      title: 'Favorite Places',
      subtitle:
          'Choose neighborhoods and cities to improve local discovery from the start.',
      leadingIcon: Icons.place_outlined,
    ),
    sections: [
      const BannerSectionSchema(
        title: 'Starting point only',
        body:
            'Pick places you are comfortable with. You can add or remove selections anytime.',
        icon: Icons.info_outline,
        tone: SchemaTone.neutral,
      ),
      const TextSectionSchema(
        title: 'Why local context matters',
        paragraphs: [
          'Local selections help AVRAI start with strong anchors for recommendations.',
          'Broader selections provide broader discovery; focused selections reduce noise.',
        ],
      ),
      CustomSectionSchema(
        title: 'Search',
        child: searchSection,
      ),
      CustomSectionSchema(
        title: 'Current selections',
        child: selectionSection,
      ),
      CustomSectionSchema(
        title: 'Places',
        child: placesSection,
      ),
    ],
  );
}

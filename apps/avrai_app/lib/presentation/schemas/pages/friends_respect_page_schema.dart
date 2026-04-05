import 'package:flutter/material.dart';

import 'package:avrai/presentation/schemas/models/page_schema.dart';

PageSchema buildFriendsRespectPageSchema({
  required Widget listSection,
}) {
  return PageSchema(
    title: 'Starter Lists',
    header: const PageHeaderSchema(
      title: 'Starter Lists',
      subtitle: 'Select local public lists you want in your Spots experience.',
      leadingIcon: Icons.list_alt_outlined,
    ),
    sections: [
      const BannerSectionSchema(
        title: 'Local curation',
        body:
            'These lists are a starting point. You can change them later after onboarding.',
        icon: Icons.location_on_outlined,
        tone: SchemaTone.neutral,
      ),
      const TextSectionSchema(
        title: 'How we use these',
        paragraphs: [
          'Starter lists influence your first set of spots and communities.',
          'They keep your recommendations relevant while your preferences stabilize.',
        ],
      ),
      CustomSectionSchema(
        title: 'Local public lists',
        child: listSection,
      ),
    ],
  );
}

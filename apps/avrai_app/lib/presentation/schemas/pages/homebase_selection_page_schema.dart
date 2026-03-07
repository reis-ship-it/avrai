import 'package:flutter/material.dart';

import 'package:avrai/presentation/schemas/models/page_schema.dart';

PageSchema buildHomebaseSelectionPageSchema({
  required Widget mapSection,
}) {
  return PageSchema(
    title: 'Where\'s your homebase?',
    header: const PageHeaderSchema(
      title: 'Where\'s your homebase?',
      subtitle:
          'Position the marker over your homebase. Only the location name will appear on your profile.',
      leadingIcon: Icons.home_outlined,
    ),
    sections: [
      const BannerSectionSchema(
        title: 'Local display only',
        body:
            'This step stores a neighborhood-style homebase label for discovery and recommendations. You can change it later.',
        icon: Icons.location_on_outlined,
      ),
      CustomSectionSchema(
        title: 'Map',
        subtitle:
            'Use the fixed center marker to select the neighborhood you want to use as your homebase.',
        child: mapSection,
      ),
    ],
  );
}

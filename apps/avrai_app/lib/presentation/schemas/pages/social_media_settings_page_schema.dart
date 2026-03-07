import 'package:flutter/material.dart';

import 'package:avrai/presentation/schemas/models/page_schema.dart';

PageSchema buildSocialMediaSettingsPageSchema({
  required Widget content,
}) {
  return PageSchema(
    title: 'Social Media Connections',
    header: const PageHeaderSchema(
      title: 'Social Media Connections',
      subtitle:
          'Connect or disconnect public accounts used for profile enrichment and discovery.',
      leadingIcon: Icons.hub_outlined,
    ),
    sections: [
      const BannerSectionSchema(
        title: 'Discovery signals',
        body:
            'AVRAI uses selected social signals to improve profile matching without changing your privacy controls.',
        icon: Icons.travel_explore_outlined,
      ),
      CustomSectionSchema(
        title: 'Connected Platforms',
        child: content,
      ),
    ],
  );
}

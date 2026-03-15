import 'package:flutter/material.dart';

import 'package:avrai/presentation/schemas/models/page_schema.dart';

PageSchema buildCommunitiesDiscoverPageSchema({
  required Widget content,
}) {
  return PageSchema(
    title: 'Discover Communities',
    header: const PageHeaderSchema(
      title: 'Discover Communities',
      subtitle:
          'Browse communities ranked by compatibility, steadiness, and shared fit.',
      leadingIcon: Icons.group_outlined,
    ),
    sections: [
      const BannerSectionSchema(
        title: 'Compatibility-ranked',
        body:
            'Communities are ordered by overall fit so you can scan the strongest matches first.',
        icon: Icons.insights_outlined,
      ),
      CustomSectionSchema(
        title: 'Community results',
        child: content,
      ),
    ],
  );
}

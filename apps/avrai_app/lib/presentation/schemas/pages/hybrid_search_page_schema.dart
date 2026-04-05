import 'package:flutter/material.dart';

import 'package:avrai/presentation/schemas/models/page_schema.dart';

PageSchema buildHybridSearchPageSchema({
  required Widget content,
}) {
  return PageSchema(
    title: 'Hybrid Search',
    header: const PageHeaderSchema(
      title: 'Hybrid Search',
      subtitle:
          'Search community results first, with outside sources available when they add useful context.',
      leadingIcon: Icons.search,
    ),
    sections: [
      const BannerSectionSchema(
        title: 'Community-first ranking',
        body:
            'Search prioritizes local community knowledge and uses external sources only to fill clear gaps.',
        icon: Icons.info_outline,
      ),
      CustomSectionSchema(
        title: 'Search',
        child: content,
      ),
    ],
  );
}

import 'package:flutter/material.dart';

import 'package:avrai/presentation/schemas/models/page_schema.dart';

PageSchema buildSocialMediaConnectionPageSchema({
  required Widget platformsSection,
}) {
  return PageSchema(
    title: 'Connect Your Apps',
    header: const PageHeaderSchema(
      title: 'Connect Your Apps',
      subtitle:
          'Connect apps you already use to help AVRAI understand routines, interests, and activity patterns.',
      leadingIcon: Icons.apps_outlined,
    ),
    sections: [
      const BannerSectionSchema(
        title: 'Optional connections',
        body:
            'Every connection is optional. You can disconnect any source later in Settings.',
        icon: Icons.info_outline,
      ),
      CustomSectionSchema(
        title: 'Platform connections',
        child: platformsSection,
      ),
    ],
  );
}

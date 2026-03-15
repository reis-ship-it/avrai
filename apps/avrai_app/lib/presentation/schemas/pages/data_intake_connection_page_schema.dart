import 'package:flutter/material.dart';

import 'package:avrai/presentation/schemas/models/page_schema.dart';

PageSchema buildDataIntakeConnectionPageSchema({
  required Widget sourcesSection,
}) {
  return PageSchema(
    title: 'Data Intake & Privacy',
    header: const PageHeaderSchema(
      title: 'Data Connections',
      subtitle:
          'Connect optional sources that help AVRAI learn routines and preferences without sending raw content away from this device.',
      leadingIcon: Icons.link_outlined,
    ),
    sections: [
      const BannerSectionSchema(
        title: 'Local intake only',
        body:
            'Connected data is processed on-device first. The app uses summaries and patterns, not raw message history, to improve personalization.',
        icon: Icons.shield_outlined,
      ),
      CustomSectionSchema(
        title: 'Optional sources',
        subtitle:
            'Turn on only the sources you want AVRAI to use during onboarding.',
        child: sourcesSection,
      ),
    ],
  );
}

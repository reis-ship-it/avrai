import 'package:flutter/material.dart';

import 'package:avrai/presentation/schemas/models/page_schema.dart';

PageSchema buildCrossAppSettingsPageSchema({
  required Widget content,
}) {
  return PageSchema(
    title: 'AI Learning Sources',
    header: const PageHeaderSchema(
      title: 'AI Learning Sources',
      subtitle:
          'Choose which cross-app signals can contribute to local learning and recommendations.',
      leadingIcon: Icons.psychology_outlined,
    ),
    sections: [
      const BannerSectionSchema(
        title: 'Local processing',
        body:
            'Learning happens on-device. Use these controls to gate what data sources AVRAI can use.',
        icon: Icons.shield_outlined,
      ),
      CustomSectionSchema(
        title: 'Source controls and actions',
        child: content,
      ),
    ],
  );
}

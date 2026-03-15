import 'package:flutter/material.dart';

import 'package:avrai/presentation/schemas/models/page_schema.dart';

PageSchema buildMotionSettingsPageSchema({
  required Widget content,
}) {
  return PageSchema(
    title: 'Motion Settings',
    header: const PageHeaderSchema(
      title: 'Motion Settings',
      subtitle: 'Adjust motion-reactive visuals and related comfort settings.',
      leadingIcon: Icons.motion_photos_auto_outlined,
    ),
    sections: [
      CustomSectionSchema(
        title: 'Settings',
        child: content,
      ),
    ],
  );
}

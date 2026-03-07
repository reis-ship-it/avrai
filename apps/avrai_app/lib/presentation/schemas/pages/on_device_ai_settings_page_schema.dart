import 'package:flutter/material.dart';

import 'package:avrai/presentation/schemas/models/page_schema.dart';

PageSchema buildOnDeviceAISettingsPageSchema({
  required Widget content,
}) {
  return PageSchema(
    title: 'On-Device AI',
    header: const PageHeaderSchema(
      title: 'On-Device AI',
      subtitle:
          'Review device eligibility, local model setup, and offline learning controls.',
      leadingIcon: Icons.memory_outlined,
    ),
    sections: [
      const BannerSectionSchema(
        title: 'Local-first settings',
        body:
            'Manage on-device capabilities, local safety checks, and model behavior from one screen.',
        icon: Icons.shield_outlined,
      ),
      CustomSectionSchema(
        title: 'Controls and status',
        child: content,
      ),
    ],
  );
}

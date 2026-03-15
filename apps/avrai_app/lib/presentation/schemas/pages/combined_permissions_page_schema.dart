import 'package:flutter/material.dart';

import 'package:avrai/presentation/schemas/models/page_schema.dart';

PageSchema buildCombinedPermissionsPageSchema({
  required Widget corePermissionsSection,
  required Widget consentSection,
  required Widget statusActionsSection,
}) {
  return PageSchema(
    title: 'Permissions',
    header: const PageHeaderSchema(
      title: 'Permissions',
      subtitle:
          'Review the permissions AVRAI uses for local discovery, personalization, and nearby suggestions.',
      leadingIcon: Icons.security_outlined,
    ),
    sections: [
      const BannerSectionSchema(
        title: 'Local-first permission model',
        body:
            'The app requests only the capabilities needed for nearby discovery, local learning, and optional background suggestions.',
        icon: Icons.shield_outlined,
      ),
      CustomSectionSchema(
        title: 'Core permissions',
        subtitle:
            'Location is required. Bluetooth, Wi-Fi, and background access improve discovery and continuity.',
        child: corePermissionsSection,
      ),
      CustomSectionSchema(
        title: 'Learning sources',
        subtitle:
            'These optional sources help AVRAI learn preferences locally.',
        child: consentSection,
      ),
      CustomSectionSchema(
        title: 'Status and actions',
        child: statusActionsSection,
      ),
    ],
  );
}

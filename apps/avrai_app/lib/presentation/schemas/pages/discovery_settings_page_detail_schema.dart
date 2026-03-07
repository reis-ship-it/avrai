import 'package:flutter/material.dart';

import 'package:avrai/presentation/schemas/models/page_schema.dart';

PageSchema buildDiscoverySettingsDetailPageSchema({
  required Widget content,
}) {
  return PageSchema(
    title: 'Discovery Settings',
    header: const PageHeaderSchema(
      title: 'Device Discovery Configuration',
      subtitle:
          'Configure how often AVRAI scans for nearby devices and how long they remain visible.',
      leadingIcon: Icons.radar_outlined,
    ),
    sections: [
      const BannerSectionSchema(
        title: 'Discovery privacy summary',
        body:
            'Discovery uses anonymized compatibility signals only. You can stop discovery anytime from the AI2AI Network screen.',
        icon: Icons.privacy_tip_outlined,
      ),
      CustomSectionSchema(
        title: 'Configuration',
        child: content,
      ),
    ],
  );
}

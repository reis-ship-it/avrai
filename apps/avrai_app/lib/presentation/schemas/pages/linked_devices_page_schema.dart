import 'package:flutter/material.dart';

import 'package:avrai/presentation/schemas/models/page_schema.dart';

PageSchema buildLinkedDevicesPageSchema({
  required Widget content,
}) {
  return PageSchema(
    title: 'Linked Devices',
    header: const PageHeaderSchema(
      title: 'Linked Devices',
      subtitle:
          'Manage the devices that can access and sync your profile and preferences.',
      leadingIcon: Icons.devices_outlined,
    ),
    sections: [
      const BannerSectionSchema(
        title: 'Device sync',
        body:
            'Review active sessions and add a new device when you want cross-device sync.',
        icon: Icons.sync_outlined,
      ),
      CustomSectionSchema(
        title: 'Devices',
        child: content,
      ),
    ],
  );
}

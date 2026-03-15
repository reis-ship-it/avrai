import 'package:flutter/material.dart';

import 'package:avrai/presentation/schemas/models/page_schema.dart';

PageSchema buildNotificationsPageSchema({
  required bool isGranted,
  required Widget statusRow,
  required Widget? actionRow,
}) {
  final statusSectionItems = <SectionSchema>[
    CustomSectionSchema(
      title: 'Notification Status',
      child: statusRow,
    )
  ];

  final List<SectionSchema> sections = [
    const BannerSectionSchema(
      title: 'Optional permission',
      body:
          'Notifications help with reminders and activity updates, but you can skip them now and change this later in Settings.',
      icon: Icons.info_outline,
    ),
    const TextSectionSchema(
      title: 'What notifications are used for',
      paragraphs: [
        'Get reminders before plans and bookings.',
        'Receive updates from nearby communities and groups.',
        'See recommendations when something new fits your interests.',
        'Know when friends, groups, or communities reach out.',
      ],
    ),
    ...statusSectionItems,
  ];

  if (actionRow != null) {
    sections.add(
      CustomSectionSchema(
        title: 'Enable notifications',
        child: actionRow,
      ),
    );
  }

  return PageSchema(
    title: 'Notifications',
    header: const PageHeaderSchema(
      title: 'Notifications',
      subtitle:
          'Choose whether AVRAI can send reminders, messages, and useful updates.',
      leadingIcon: Icons.notifications_outlined,
    ),
    sections: sections,
  );
}

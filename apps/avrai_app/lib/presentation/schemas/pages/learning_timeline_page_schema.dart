import 'package:flutter/material.dart';

import 'package:avrai/presentation/schemas/models/page_schema.dart';

PageSchema buildLearningTimelinePageSchema({
  required Widget content,
}) {
  return PageSchema(
    title: 'Learning Timeline',
    header: const PageHeaderSchema(
      title: 'Learning Timeline',
      subtitle:
          'Review recent cross-app learning events and how source signals shaped recommendations.',
      leadingIcon: Icons.timeline,
    ),
    sections: [
      const BannerSectionSchema(
        title: 'Learning history',
        body: 'Events are grouped by source and can be filtered by channel.',
        icon: Icons.event_note_outlined,
      ),
      CustomSectionSchema(
        title: 'Timeline',
        child: content,
      ),
    ],
  );
}

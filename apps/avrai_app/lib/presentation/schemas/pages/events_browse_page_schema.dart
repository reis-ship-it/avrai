import 'package:flutter/material.dart';

import 'package:avrai/presentation/schemas/models/page_schema.dart';

PageSchema buildEventsBrowsePageSchema({
  required Widget content,
}) {
  return PageSchema(
    title: 'Events',
    header: const PageHeaderSchema(
      title: 'Browse Events',
      subtitle: 'Find nearby events and communities that match your routine.',
      leadingIcon: Icons.event_outlined,
    ),
    sections: [
      const BannerSectionSchema(
        title: 'Nearby first',
        body:
            'Browse events across your locality, communities, and matching scopes with restrained filters and clear ranking.',
        icon: Icons.travel_explore_outlined,
      ),
      CustomSectionSchema(
        title: 'Event discovery',
        child: content,
      ),
    ],
  );
}

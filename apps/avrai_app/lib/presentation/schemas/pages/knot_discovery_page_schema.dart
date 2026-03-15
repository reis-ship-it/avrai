import 'package:flutter/material.dart';

import 'package:avrai/presentation/schemas/models/page_schema.dart';

PageSchema buildKnotDiscoveryPageSchema({
  required Widget content,
}) {
  return PageSchema(
    title: 'Your Personality Knot',
    header: const PageHeaderSchema(
      title: 'Your Personality Knot',
      subtitle: 'Explore tribes and communities tied to your personality.',
      leadingIcon: Icons.psychology,
    ),
    sections: [
      CustomSectionSchema(
        title: 'Discovery',
        child: content,
      ),
    ],
  );
}

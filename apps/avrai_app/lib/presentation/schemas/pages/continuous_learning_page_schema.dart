import 'package:flutter/material.dart';

import 'package:avrai/presentation/schemas/models/page_schema.dart';

PageSchema buildContinuousLearningPageSchema({
  required Widget content,
}) {
  return PageSchema(
    title: 'Continuous Learning',
    header: const PageHeaderSchema(
      title: 'Continuous Learning',
      subtitle:
          'Track learning progress, data collection, and control settings in one place.',
      leadingIcon: Icons.auto_awesome_outlined,
    ),
    sections: [
      CustomSectionSchema(
        title: 'Overview',
        child: content,
      ),
    ],
  );
}

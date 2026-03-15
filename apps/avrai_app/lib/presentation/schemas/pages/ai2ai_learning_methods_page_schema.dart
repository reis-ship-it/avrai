import 'package:flutter/material.dart';

import 'package:avrai/presentation/schemas/models/page_schema.dart';

PageSchema buildAI2AILearningMethodsPageSchema({
  required Widget content,
}) {
  return PageSchema(
    title: 'AI2AI Learning Methods',
    header: const PageHeaderSchema(
      title: 'AI2AI Learning Methods',
      subtitle:
          'Review how your AI learns from anonymized exchange patterns and related recommendations.',
      leadingIcon: Icons.psychology_outlined,
    ),
    sections: [
      const BannerSectionSchema(
        title: 'Overview',
        body:
            'Your local AI learning configuration can be monitored and tuned without changing your consent model.',
        icon: Icons.visibility_outlined,
      ),
      CustomSectionSchema(
        title: 'Learning Methods',
        child: content,
      ),
    ],
  );
}

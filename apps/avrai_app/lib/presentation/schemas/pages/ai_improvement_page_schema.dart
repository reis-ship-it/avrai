import 'package:flutter/material.dart';

import 'package:avrai/presentation/schemas/models/page_schema.dart';

PageSchema buildAIImprovementPageSchema({
  required Widget content,
}) {
  return PageSchema(
    title: 'AI Improvement',
    header: const PageHeaderSchema(
      title: 'AI Improvement',
      subtitle:
          'Review how your AI improves over time across quality, progress, and impact.',
      leadingIcon: Icons.trending_up,
    ),
    sections: [
      const BannerSectionSchema(
        title: 'Improvement status',
        body:
            'Metrics reflect learning gains and recommendation quality while maintaining local-first behavior.',
        icon: Icons.insights_outlined,
      ),
      CustomSectionSchema(
        title: 'Improvement Panels',
        child: content,
      ),
    ],
  );
}

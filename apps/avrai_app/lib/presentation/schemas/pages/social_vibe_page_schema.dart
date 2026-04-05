import 'package:flutter/material.dart';

import 'package:avrai/presentation/schemas/models/page_schema.dart';

PageSchema buildSocialVibePageSchema({
  required Widget progressSection,
  required Widget questionSection,
  required Widget navigationSection,
}) {
  return PageSchema(
    title: 'Your Social Vibe',
    header: const PageHeaderSchema(
      title: 'Your Social Vibe',
      subtitle: 'How do you like to connect with others?',
      leadingIcon: Icons.people_alt_outlined,
    ),
    sections: [
      const BannerSectionSchema(
        title: 'Calibration flow',
        body:
            'Your answers shape how social and discovery recommendations are ranked.',
        icon: Icons.insights_outlined,
      ),
      CustomSectionSchema(
        title: 'Question progress',
        subtitle: 'Answer each prompt to move forward.',
        child: progressSection,
      ),
      CustomSectionSchema(
        title: 'Social vibe questions',
        child: questionSection,
      ),
      CustomSectionSchema(
        title: 'Navigation',
        child: navigationSection,
      ),
    ],
  );
}

import 'package:flutter/material.dart';

import 'package:avrai/presentation/schemas/models/page_schema.dart';

PageSchema buildAboutPageSchema({
  required VoidCallback openWebsite,
  required VoidCallback openPrinciples,
  required VoidCallback openPrivacy,
  required VoidCallback openTerms,
  required VoidCallback openSupport,
}) {
  return PageSchema(
    title: 'About AVRAI',
    header: const PageHeaderSchema(
      title: 'About AVRAI',
      subtitle:
          'A neutral product shell focused on belonging, privacy, and useful discovery.',
      leadingIcon: Icons.info_outline,
    ),
    sections: [
      const BannerSectionSchema(
        title: 'What AVRAI is for',
        body:
            'AVRAI helps people find places, experiences, and communities that feel genuinely right for them.',
      ),
      const TextSectionSchema(
        title: 'Principles',
        paragraphs: [
          'Belonging comes first. Recommendations should help people feel grounded, not nudged.',
          'Privacy and control stay with the user. AVRAI should be clear about what it uses and why.',
          'Useful discovery matters more than decorative product theater.',
        ],
      ),
      const KeyValueSectionSchema(
        title: 'App Information',
        items: [
          KeyValueItemSchema(label: 'Version', value: '1.0.0'),
          KeyValueItemSchema(label: 'Build', value: '100'),
          KeyValueItemSchema(label: 'Architecture', value: 'AI2AI learning'),
          KeyValueItemSchema(
              label: 'Frontend baseline', value: 'Neutral shell'),
        ],
      ),
      ActionListSectionSchema(
        title: 'Links',
        actions: [
          ActionSchema(
            title: 'Website',
            subtitle: 'avrai.org',
            icon: Icons.language,
            onTap: openWebsite,
          ),
          ActionSchema(
            title: 'Product Principles',
            subtitle: 'Read the product direction and values',
            icon: Icons.menu_book_outlined,
            onTap: openPrinciples,
          ),
          ActionSchema(
            title: 'Privacy Policy',
            subtitle: 'How AVRAI protects user data',
            icon: Icons.policy_outlined,
            onTap: openPrivacy,
          ),
          ActionSchema(
            title: 'Terms of Service',
            subtitle: 'Usage terms and expectations',
            icon: Icons.gavel_outlined,
            onTap: openTerms,
          ),
          ActionSchema(
            title: 'Support',
            subtitle: 'Get help from the team',
            icon: Icons.support_agent_outlined,
            onTap: openSupport,
          ),
        ],
      ),
    ],
  );
}

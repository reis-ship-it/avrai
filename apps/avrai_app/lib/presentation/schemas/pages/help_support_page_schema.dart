import 'package:flutter/material.dart';

import 'package:avrai/presentation/schemas/models/page_schema.dart';

PageSchema buildHelpSupportPageSchema({
  required VoidCallback gettingStarted,
  required VoidCallback creatingSpots,
  required VoidCallback managingLists,
  required VoidCallback privacyHelp,
  required VoidCallback aiLearningHelp,
  required VoidCallback sendFeedback,
  required VoidCallback reportBug,
  required VoidCallback emailSupport,
  required VoidCallback openCommunityForum,
  required VoidCallback openVideoTutorials,
  required VoidCallback openUserGuide,
  required VoidCallback showWhatsNew,
  required VoidCallback showPrinciples,
  required String platformName,
  required String supportId,
}) {
  return PageSchema(
    title: 'Help & Support',
    header: const PageHeaderSchema(
      title: 'Help & Support',
      subtitle:
          'Plain-language guidance, support entry points, and product references.',
      leadingIcon: Icons.support_agent_outlined,
    ),
    sections: [
      const BannerSectionSchema(
        title: 'Need something quickly?',
        body:
            'Use these sections to get oriented, troubleshoot, or contact the team without leaving the app.',
      ),
      ActionListSectionSchema(
        title: 'Quick Help',
        actions: [
          ActionSchema(
            title: 'Getting Started',
            subtitle: 'Learn the basics of using AVRAI',
            icon: Icons.play_circle_outline,
            onTap: gettingStarted,
          ),
          ActionSchema(
            title: 'Creating Spots',
            subtitle: 'How to add and edit places',
            icon: Icons.add_location_alt_outlined,
            onTap: creatingSpots,
          ),
          ActionSchema(
            title: 'Managing Lists',
            subtitle: 'Organize places into collections',
            icon: Icons.list_alt_outlined,
            onTap: managingLists,
          ),
          ActionSchema(
            title: 'Privacy & Settings',
            subtitle: 'Control your data and preferences',
            icon: Icons.privacy_tip_outlined,
            onTap: privacyHelp,
          ),
          ActionSchema(
            title: 'AI2AI Learning',
            subtitle: 'How AVRAI improves recommendations',
            icon: Icons.psychology_outlined,
            onTap: aiLearningHelp,
          ),
        ],
      ),
      ActionListSectionSchema(
        title: 'Contact Support',
        actions: [
          ActionSchema(
            title: 'Send Feedback',
            subtitle: 'Share product feedback and suggestions',
            icon: Icons.feedback_outlined,
            onTap: sendFeedback,
          ),
          ActionSchema(
            title: 'Report a Bug',
            subtitle: 'Help improve reliability',
            icon: Icons.bug_report_outlined,
            onTap: reportBug,
          ),
          ActionSchema(
            title: 'Email Support',
            subtitle: 'Get direct help from the team',
            icon: Icons.email_outlined,
            onTap: emailSupport,
          ),
          ActionSchema(
            title: 'Community Forum',
            subtitle: 'Connect with other AVRAI users',
            icon: Icons.forum_outlined,
            onTap: openCommunityForum,
          ),
        ],
      ),
      ActionListSectionSchema(
        title: 'Resources',
        actions: [
          ActionSchema(
            title: 'Video Tutorials',
            subtitle: 'Step-by-step guidance',
            icon: Icons.video_library_outlined,
            onTap: openVideoTutorials,
          ),
          ActionSchema(
            title: 'User Guide',
            subtitle: 'Reference documentation',
            icon: Icons.menu_book_outlined,
            onTap: openUserGuide,
          ),
          ActionSchema(
            title: 'What’s New',
            subtitle: 'Recent updates and changes',
            icon: Icons.new_releases_outlined,
            onTap: showWhatsNew,
          ),
          ActionSchema(
            title: 'Product Principles',
            subtitle: 'Read the product direction and values',
            icon: Icons.bookmarks_outlined,
            onTap: showPrinciples,
          ),
        ],
      ),
      KeyValueSectionSchema(
        title: 'System Information',
        items: [
          const KeyValueItemSchema(label: 'App Version', value: '1.0.0'),
          const KeyValueItemSchema(label: 'Build Number', value: '100'),
          KeyValueItemSchema(label: 'Platform', value: platformName),
          KeyValueItemSchema(label: 'Support ID', value: supportId),
        ],
      ),
    ],
  );
}

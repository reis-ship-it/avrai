import 'package:flutter/material.dart';

import 'package:avrai/presentation/schemas/models/page_schema.dart';

PageSchema buildProfileBasicsPageSchema({
  required Widget profilePhoto,
  required Widget displayNameField,
  required Widget profileHint,
}) {
  return PageSchema(
    title: 'Profile Basics',
    header: const PageHeaderSchema(
      title: 'Profile Basics',
      subtitle: 'Pick a name and photo you want to use during onboarding.',
      leadingIcon: Icons.person_outline,
    ),
    sections: [
      const BannerSectionSchema(
        title: 'You can change this later',
        body:
            'Your name and photo can be updated anytime in Settings after you finish onboarding.',
        icon: Icons.info_outline,
      ),
      CustomSectionSchema(
        title: 'Profile Photo',
        subtitle: 'Optional',
        child: profilePhoto,
      ),
      const TextSectionSchema(
        title: 'Display name',
        paragraphs: [
          'Set the name you want people in this account to see.',
        ],
      ),
      CustomSectionSchema(
        title: 'Display Name',
        subtitle: 'How you want to appear across the app.',
        child: displayNameField,
      ),
      CustomSectionSchema(
        title: 'Profile note',
        child: profileHint,
      ),
    ],
  );
}

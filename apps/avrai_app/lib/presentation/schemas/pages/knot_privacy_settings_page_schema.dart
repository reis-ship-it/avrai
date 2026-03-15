import 'package:flutter/material.dart';

import 'package:avrai/presentation/schemas/models/page_schema.dart';

PageSchema buildKnotPrivacySettingsPageSchema({
  required bool showKnotPublicly,
  required String friendContext,
  required String publicContext,
  required List<String> contextOptions,
  required ValueChanged<bool> onShowKnotPubliclyChanged,
  required ValueChanged<String?> onFriendContextChanged,
  required ValueChanged<String?> onPublicContextChanged,
}) {
  return PageSchema(
    title: 'Knot Privacy Settings',
    header: const PageHeaderSchema(
      title: 'Knot Privacy Settings',
      subtitle:
          'Control how your personality knot is shared and how much detail other people can see.',
      leadingIcon: Icons.hub_outlined,
    ),
    sections: [
      const BannerSectionSchema(
        title: 'Privacy note',
        body:
            'Use these controls to decide whether your knot is visible at all and how much context friends or the public can access.',
        icon: Icons.privacy_tip_outlined,
      ),
      SettingsGroupSectionSchema(
        title: 'Visibility Controls',
        items: [
          ToggleSettingItemSchema(
            title: 'Show Knot Publicly',
            subtitle: 'Allow other people to view your knot at all.',
            icon: Icons.visibility_outlined,
            value: showKnotPublicly,
            onChanged: onShowKnotPubliclyChanged,
          ),
          DropdownSettingItemSchema(
            title: 'Friend Context',
            subtitle: 'Choose the detail level available to friends.',
            icon: Icons.group_outlined,
            value: friendContext,
            options: contextOptions,
            onChanged: onFriendContextChanged,
          ),
          DropdownSettingItemSchema(
            title: 'Public Context',
            subtitle: 'Choose the detail level available to public viewers.',
            icon: Icons.public_outlined,
            value: publicContext,
            options: contextOptions,
            onChanged: onPublicContextChanged,
          ),
        ],
      ),
      const BulletListSectionSchema(
        title: 'Privacy Levels',
        items: [
          'Public: full knot visible.',
          'Friends: visible to accepted contacts only.',
          'Private: not shared.',
          'Anonymous: topology only with no personal details.',
        ],
      ),
    ],
  );
}

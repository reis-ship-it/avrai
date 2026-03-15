import 'package:flutter/material.dart';

import 'package:avrai/presentation/schemas/models/page_schema.dart';

PageSchema buildListPreferencesPageSchema({
  required Widget content,
}) {
  return PageSchema(
    title: 'List Preferences',
    header: const PageHeaderSchema(
      title: 'List Preferences',
      subtitle:
          'Choose when suggestions appear, how varied they are, and what categories are emphasized.',
      leadingIcon: Icons.tune_outlined,
    ),
    sections: [
      const BannerSectionSchema(
        title: 'Suggestion controls',
        body:
            'Tune timing, variety, categories, and notification behavior for list suggestions.',
        icon: Icons.list_alt_outlined,
      ),
      CustomSectionSchema(
        title: 'Preference controls',
        child: content,
      ),
    ],
  );
}

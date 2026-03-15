import 'dart:io';

import 'package:flutter/material.dart';
import 'package:avrai_core/models/misc/cross_app_learning_insight.dart';
import 'package:avrai/presentation/schemas/models/page_schema.dart';
import 'package:avrai/presentation/utils/cross_app_ui_extensions.dart';

PageSchema buildCrossAppLearningPageSchema({
  required Map<CrossAppDataSource, bool> consents,
  required void Function(CrossAppDataSource, bool) onSourceToggled,
  required VoidCallback onEnableAll,
  required VoidCallback onContinue,
}) {
  final sources = CrossAppDataSource.values
      .where((source) =>
          source != CrossAppDataSource.appUsage || Platform.isAndroid)
      .map((source) {
    return ToggleSettingItemSchema(
      title: source.displayName,
      subtitle: source.description,
      value: consents[source] ?? false,
      onChanged: (enabled) => onSourceToggled(source, enabled),
    );
  }).toList();

  return PageSchema(
    title: 'Cross-App Learning',
    header: const PageHeaderSchema(
      title: 'Cross-App Learning',
      subtitle:
          'Choose which signals AVRAI can use to improve recommendations.',
      leadingIcon: Icons.psychology_outlined,
    ),
    sections: [
      const BannerSectionSchema(
        title: 'How this helps',
        body:
            'AVRAI combines your selected signals to suggest places and events that fit your interests and lifestyle.',
        icon: Icons.auto_graph,
      ),
      const TextSectionSchema(
        title: 'Example signals',
        paragraphs: [
          'If your calendar opens, AVRAI can surface timely plans nearby.',
          'Favorite activity patterns can improve ranking for things that fit your habits.',
          'Preference signals help recommendations feel more relevant and calmer.',
        ],
      ),
      SettingsGroupSectionSchema(
        title: 'Choose data sources',
        items: sources,
      ),
      CtaSectionSchema(
        title: 'Ready to continue',
        body:
            'You can change these sources at any time while permission is available.',
        primaryLabel: 'Enable recommended sources',
        onPrimaryTap: onEnableAll,
        secondaryLabel: 'Continue with current choices',
        onSecondaryTap: onContinue,
      ),
    ],
  );
}

import 'package:flutter/material.dart';

enum SchemaTone { neutral, success, warning, error }

class PageSchema {
  final String title;
  final PageHeaderSchema header;
  final List<SectionSchema> sections;
  final bool showNavigationBar;

  const PageSchema({
    required this.title,
    required this.header,
    required this.sections,
    this.showNavigationBar = true,
  });
}

class PageHeaderSchema {
  final String title;
  final String? subtitle;
  final IconData? leadingIcon;

  const PageHeaderSchema({
    required this.title,
    this.subtitle,
    this.leadingIcon,
  });
}

sealed class SectionSchema {
  final String? title;
  final String? subtitle;

  const SectionSchema({
    this.title,
    this.subtitle,
  });
}

class BannerSectionSchema extends SectionSchema {
  final String body;
  final IconData icon;
  final SchemaTone tone;

  const BannerSectionSchema({
    required String title,
    required this.body,
    this.icon = Icons.info_outline,
    this.tone = SchemaTone.neutral,
  }) : super(title: title);
}

class TextSectionSchema extends SectionSchema {
  final List<String> paragraphs;

  const TextSectionSchema({
    required String title,
    super.subtitle,
    required this.paragraphs,
  }) : super(title: title);
}

class KeyValueItemSchema {
  final String label;
  final String value;

  const KeyValueItemSchema({
    required this.label,
    required this.value,
  });
}

class KeyValueSectionSchema extends SectionSchema {
  final List<KeyValueItemSchema> items;

  const KeyValueSectionSchema({
    required String title,
    super.subtitle,
    required this.items,
  }) : super(title: title);
}

class ActionSchema {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final VoidCallback? onTap;

  const ActionSchema({
    required this.title,
    this.subtitle,
    this.icon,
    this.onTap,
  });
}

class ActionListSectionSchema extends SectionSchema {
  final List<ActionSchema> actions;

  const ActionListSectionSchema({
    required String title,
    super.subtitle,
    required this.actions,
  }) : super(title: title);
}

sealed class SettingItemSchema {
  final String title;
  final String? subtitle;
  final IconData? icon;

  const SettingItemSchema({
    required this.title,
    this.subtitle,
    this.icon,
  });
}

class ToggleSettingItemSchema extends SettingItemSchema {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const ToggleSettingItemSchema({
    required super.title,
    super.subtitle,
    super.icon,
    required this.value,
    this.onChanged,
  });
}

class CheckboxSettingItemSchema extends SettingItemSchema {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const CheckboxSettingItemSchema({
    required super.title,
    super.subtitle,
    super.icon,
    required this.value,
    this.onChanged,
  });
}

class DropdownSettingItemSchema extends SettingItemSchema {
  final String value;
  final List<String> options;
  final ValueChanged<String?>? onChanged;

  const DropdownSettingItemSchema({
    required super.title,
    super.subtitle,
    super.icon,
    required this.value,
    required this.options,
    this.onChanged,
  });
}

class ActionSettingItemSchema extends SettingItemSchema {
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? emphasisColor;

  const ActionSettingItemSchema({
    required super.title,
    super.subtitle,
    super.icon,
    this.onTap,
    this.trailing,
    this.emphasisColor,
  });
}

class SettingsGroupSectionSchema extends SectionSchema {
  final List<SettingItemSchema> items;

  const SettingsGroupSectionSchema({
    required String title,
    super.subtitle,
    required this.items,
  }) : super(title: title);
}

class BulletListSectionSchema extends SectionSchema {
  final List<String> items;

  const BulletListSectionSchema({
    required String title,
    super.subtitle,
    required this.items,
  }) : super(title: title);
}

class MetricSchema {
  final String label;
  final String value;

  const MetricSchema({
    required this.label,
    required this.value,
  });
}

class MetricSectionSchema extends SectionSchema {
  final List<MetricSchema> metrics;

  const MetricSectionSchema({
    required String title,
    super.subtitle,
    required this.metrics,
  }) : super(title: title);
}

class CtaSectionSchema extends SectionSchema {
  final String body;
  final String primaryLabel;
  final VoidCallback? onPrimaryTap;
  final String? secondaryLabel;
  final VoidCallback? onSecondaryTap;

  const CtaSectionSchema({
    required String title,
    required this.body,
    required this.primaryLabel,
    this.onPrimaryTap,
    this.secondaryLabel,
    this.onSecondaryTap,
  }) : super(title: title);
}

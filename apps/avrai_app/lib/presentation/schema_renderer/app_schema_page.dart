import 'package:flutter/material.dart';

import 'package:avrai/presentation/schemas/models/page_schema.dart';
import 'package:avrai/presentation/widgets/common/app_info_banner.dart';
import 'package:avrai/presentation/widgets/common/app_list_row.dart';
import 'package:avrai/presentation/widgets/common/app_metric_row.dart';
import 'package:avrai/presentation/widgets/common/app_page_scaffold.dart';
import 'package:avrai/presentation/widgets/common/app_section.dart';
import 'package:avrai/presentation/widgets/common/app_button_primary.dart';
import 'package:avrai/presentation/widgets/common/app_button_secondary.dart';
import 'package:avrai/presentation/widgets/common/app_setting_row.dart';
import 'package:avrai/presentation/widgets/common/app_status_banner.dart';
import 'package:avrai/presentation/widgets/common/app_surface.dart';
import 'package:avrai/presentation/widgets/common/app_toggle_row.dart';
import 'package:avrai/theme/colors.dart';

class AppSchemaPage extends StatelessWidget {
  final PageSchema schema;

  const AppSchemaPage({
    super.key,
    required this.schema,
  });

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: schema.header.title,
      subtitle: schema.header.subtitle,
      leadingIcon: schema.header.leadingIcon,
      showNavigationBar: schema.showNavigationBar,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _buildSections(context),
      ),
    );
  }

  List<Widget> _buildSections(BuildContext context) {
    final widgets = <Widget>[];
    for (final section in schema.sections) {
      widgets.add(_buildSection(context, section));
      widgets.add(const SizedBox(height: 24));
    }
    if (widgets.isNotEmpty) {
      widgets.removeLast();
    }
    return widgets;
  }

  Widget _buildSection(BuildContext context, SectionSchema section) {
    if (section is BannerSectionSchema) {
      if (section.tone == SchemaTone.neutral) {
        return AppInfoBanner(
          title: section.title!,
          body: section.body,
          icon: section.icon,
        );
      }
      return AppStatusBanner(
        title: section.title!,
        body: section.body,
        tone: switch (section.tone) {
          SchemaTone.success => AppStatusTone.success,
          SchemaTone.warning => AppStatusTone.warning,
          SchemaTone.error => AppStatusTone.error,
          SchemaTone.neutral => AppStatusTone.neutral,
        },
      );
    }

    if (section is TextSectionSchema) {
      return AppSection(
        title: section.title!,
        subtitle: section.subtitle,
        child: AppSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < section.paragraphs.length; i++) ...[
                Text(section.paragraphs[i]),
                if (i != section.paragraphs.length - 1)
                  const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      );
    }

    if (section is KeyValueSectionSchema) {
      return AppSection(
        title: section.title!,
        subtitle: section.subtitle,
        child: AppSurface(
          child: Column(
            children: [
              for (var i = 0; i < section.items.length; i++) ...[
                AppMetricRow(
                  label: section.items[i].label,
                  value: section.items[i].value,
                ),
                if (i != section.items.length - 1) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                ],
              ],
            ],
          ),
        ),
      );
    }

    if (section is ActionListSectionSchema) {
      return AppSection(
        title: section.title!,
        subtitle: section.subtitle,
        child: AppSurface(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < section.actions.length; i++) ...[
                AppListRow(
                  title: section.actions[i].title,
                  subtitle: section.actions[i].subtitle,
                  leadingIcon: section.actions[i].icon,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: section.actions[i].onTap,
                ),
                if (i != section.actions.length - 1) const Divider(height: 1),
              ],
            ],
          ),
        ),
      );
    }

    if (section is SettingsGroupSectionSchema) {
      return AppSection(
        title: section.title!,
        subtitle: section.subtitle,
        child: AppSurface(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < section.items.length; i++) ...[
                _buildSettingItem(section.items[i]),
                if (i != section.items.length - 1) const Divider(height: 1),
              ],
            ],
          ),
        ),
      );
    }

    if (section is BulletListSectionSchema) {
      return AppSection(
        title: section.title!,
        subtitle: section.subtitle,
        child: AppSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final item in section.items) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• '),
                    Expanded(child: Text(item)),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      );
    }

    if (section is MetricSectionSchema) {
      return AppSection(
        title: section.title!,
        subtitle: section.subtitle,
        child: AppSurface(
          child: Column(
            children: [
              for (var i = 0; i < section.metrics.length; i++) ...[
                AppMetricRow(
                  label: section.metrics[i].label,
                  value: section.metrics[i].value,
                ),
                if (i != section.metrics.length - 1) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                ],
              ],
            ],
          ),
        ),
      );
    }

    if (section is CtaSectionSchema) {
      return AppSection(
        title: section.title!,
        child: AppSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(section.body),
              const SizedBox(height: 16),
              AppButtonPrimary(
                onPressed: section.onPrimaryTap,
                child: Text(section.primaryLabel),
              ),
              if (section.secondaryLabel != null) ...[
                const SizedBox(height: 8),
                AppButtonSecondary(
                  onPressed: section.onSecondaryTap,
                  child: Text(section.secondaryLabel!),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildSettingItem(SettingItemSchema item) {
    if (item is ToggleSettingItemSchema) {
      return AppToggleRow(
        title: item.title,
        subtitle: item.subtitle,
        value: item.value,
        onChanged: item.onChanged,
        leadingIcon: item.icon,
      );
    }

    if (item is CheckboxSettingItemSchema) {
      return CheckboxListTile(
        secondary: item.icon == null ? null : Icon(item.icon),
        title: Text(item.title),
        subtitle: item.subtitle == null ? null : Text(item.subtitle!),
        value: item.value,
        onChanged: item.onChanged == null
            ? null
            : (value) => item.onChanged!(value ?? false),
        controlAffinity: ListTileControlAffinity.leading,
      );
    }

    if (item is DropdownSettingItemSchema) {
      return AppSettingRow(
        title: item.title,
        subtitle: item.subtitle,
        leadingIcon: item.icon,
        control: DropdownButton<String>(
          value: item.value,
          onChanged: item.onChanged,
          underline: const SizedBox.shrink(),
          items: item.options
              .map((option) => DropdownMenuItem<String>(
                    value: option,
                    child: Text(option),
                  ))
              .toList(),
        ),
      );
    }

    if (item is ActionSettingItemSchema) {
      return ListTile(
        leading: item.icon == null
            ? null
            : Icon(item.icon, color: item.emphasisColor ?? AppColors.primary),
        title: Text(
          item.title,
          style: item.emphasisColor == null
              ? null
              : TextStyle(color: item.emphasisColor),
        ),
        subtitle: item.subtitle == null ? null : Text(item.subtitle!),
        trailing: item.trailing ?? const Icon(Icons.chevron_right),
        onTap: item.onTap,
      );
    }

    return const SizedBox.shrink();
  }
}

import 'package:flutter/material.dart';

import 'package:avrai/presentation/schemas/models/page_schema.dart';
import 'package:avrai/presentation/widgets/common/app_info_banner.dart';
import 'package:avrai/presentation/widgets/common/app_list_row.dart';
import 'package:avrai/presentation/widgets/common/app_metric_row.dart';
import 'package:avrai/presentation/widgets/common/app_page_scaffold.dart';
import 'package:avrai/presentation/widgets/common/app_section.dart';
import 'package:avrai/presentation/widgets/common/app_status_banner.dart';
import 'package:avrai/presentation/widgets/common/app_surface.dart';

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

    return const SizedBox.shrink();
  }
}

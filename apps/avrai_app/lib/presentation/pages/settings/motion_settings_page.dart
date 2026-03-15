import 'package:flutter/material.dart';

import 'package:avrai/presentation/schema_renderer/app_schema_page.dart';
import 'package:avrai/presentation/schemas/pages/motion_settings_page_schema.dart';
import 'package:avrai/presentation/widgets/settings/motion_settings_widget.dart';

class MotionSettingsPage extends StatelessWidget {
  const MotionSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppSchemaPage(
      schema:
          buildMotionSettingsPageSchema(content: const MotionSettingsWidget()),
    );
  }
}

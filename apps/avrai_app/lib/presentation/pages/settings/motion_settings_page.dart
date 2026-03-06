import 'package:flutter/material.dart';

import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';
import 'package:avrai/presentation/widgets/common/app_page_header.dart';
import 'package:avrai/presentation/widgets/common/app_surface.dart';
import 'package:avrai/presentation/widgets/settings/motion_settings_widget.dart';

class MotionSettingsPage extends StatelessWidget {
  const MotionSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdaptivePlatformPageScaffold(
      title: 'Motion Settings',
      constrainBody: false,
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSurface(
              child: AppPageHeader(
                title: 'Motion Settings',
                subtitle:
                    'Adjust motion-reactive visuals and related comfort settings.',
                leadingIcon: Icons.motion_photos_auto_outlined,
                showDivider: false,
              ),
            ),
            SizedBox(height: 24),
            MotionSettingsWidget(),
          ],
        ),
      ),
    );
  }
}

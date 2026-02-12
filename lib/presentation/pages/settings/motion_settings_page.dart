// Motion Settings Page
//
// Settings page for motion-reactive 3D visualizations.
// Part of Motion-Reactive 3D Visualization System.

import 'package:flutter/material.dart';
import 'package:avrai/core/theme/colors.dart';

import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';
import 'package:avrai/presentation/widgets/settings/motion_settings_widget.dart';

/// Page for motion-related settings
class MotionSettingsPage extends StatelessWidget {
  const MotionSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdaptivePlatformPageScaffold(
      title: 'Motion Settings',
      constrainBody: false,
      backgroundColor: AppColors.black,
      body: SingleChildScrollView(
        child: MotionSettingsWidget(),
      ),
    );
  }
}

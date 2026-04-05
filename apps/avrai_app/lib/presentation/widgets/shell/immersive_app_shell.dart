import 'package:flutter/material.dart';

import 'package:avrai/presentation/pages/bootloader_page.dart';
import 'package:avrai/presentation/widgets/portal/avrai_portal_layout.dart';
import 'package:avrai/theme/colors.dart';

/// Neutral immersive shell variant that preserves the future portal path.
class ImmersiveAppShell extends StatelessWidget {
  final Widget child;

  const ImmersiveAppShell({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BootloaderPage(
      child: AvraiPortalLayout(
        isDark: isDark,
        child: ColoredBox(
          color: AppColors.transparent,
          child: child,
        ),
      ),
    );
  }
}

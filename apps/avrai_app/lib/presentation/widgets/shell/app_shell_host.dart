import 'package:flutter/material.dart';

import 'package:avrai/presentation/widgets/shell/immersive_app_shell.dart';
import 'package:avrai/presentation/widgets/shell/standard_app_shell.dart';

enum AppShellVariant {
  standard,
  immersive,
}

/// Neutral root shell contract shared across app roots.
class AppShellHost extends StatelessWidget {
  final Widget child;
  final AppShellVariant variant;

  const AppShellHost({
    super.key,
    required this.child,
    required this.variant,
  });

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case AppShellVariant.immersive:
        return ImmersiveAppShell(child: child);
      case AppShellVariant.standard:
        return StandardAppShell(child: child);
    }
  }
}

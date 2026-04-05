import 'package:flutter/material.dart';

import 'package:avrai/presentation/widgets/common/app_surface.dart';

class AppDialogScaffold extends StatelessWidget {
  final Widget child;

  const AppDialogScaffold({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: AppSurface(
        borderColor: Colors.transparent,
        child: child,
      ),
    );
  }
}

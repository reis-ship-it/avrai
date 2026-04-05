import 'package:flutter/material.dart';

import 'package:avrai/presentation/widgets/common/app_surface.dart';

class AppBottomSheetScaffold extends StatelessWidget {
  final Widget child;

  const AppBottomSheetScaffold({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      radius: 20,
      child: child,
    );
  }
}

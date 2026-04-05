import 'package:flutter/material.dart';

import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';

class AppSplitPanel extends StatelessWidget {
  final Widget primary;
  final Widget? secondary;

  const AppSplitPanel({
    super.key,
    required this.primary,
    this.secondary,
  });

  @override
  Widget build(BuildContext context) {
    return AdaptivePaneLayout(
      primary: primary,
      secondary: secondary,
    );
  }
}

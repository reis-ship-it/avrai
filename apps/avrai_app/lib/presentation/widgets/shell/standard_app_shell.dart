import 'package:flutter/material.dart';

/// Neutral standard app shell for the current beta experience.
class StandardAppShell extends StatelessWidget {
  final Widget child;

  const StandardAppShell({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: child,
    );
  }
}

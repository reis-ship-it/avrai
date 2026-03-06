import 'package:flutter/material.dart';

class AppButtonTertiary extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;

  const AppButtonTertiary({
    super.key,
    required this.onPressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: child,
    );
  }
}

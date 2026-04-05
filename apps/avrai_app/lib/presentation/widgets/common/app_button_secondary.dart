import 'package:flutter/material.dart';

class AppButtonSecondary extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;

  const AppButtonSecondary({
    super.key,
    required this.onPressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      child: child,
    );
  }
}

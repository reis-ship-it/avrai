import 'package:flutter/material.dart';

class AppButtonPrimary extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;

  const AppButtonPrimary({
    super.key,
    required this.onPressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: child,
    );
  }
}

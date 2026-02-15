import 'package:flutter/material.dart';

/// Shared gradient scrim wrapper for top/bottom overlays.
class GradientScrim extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Alignment begin;
  final Alignment end;
  final List<Color> colors;

  const GradientScrim({
    super.key,
    required this.child,
    required this.padding,
    required this.begin,
    required this.end,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: begin,
          end: end,
          colors: colors,
        ),
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// A custom PageRoute that keeps the Glass Slate stationary while
/// the content inside dissolves and scales slightly.
class GlassContentTransition<T> extends PageRouteBuilder<T> {
  final Widget page;

  GlassContentTransition({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Dissolve
            final fadeAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            );

            // Scale (95% -> 100%)
            final scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
            );

            return FadeTransition(
              opacity: fadeAnimation,
              child: ScaleTransition(
                scale: scaleAnimation,
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 200),
          opaque:
              false, // Important: Allows background world to show through during transition
          barrierColor: Colors.transparent,
        );
}

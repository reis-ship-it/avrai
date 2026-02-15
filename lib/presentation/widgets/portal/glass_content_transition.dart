import 'package:flutter/material.dart';
import 'package:avrai/core/navigation/app_page_transitions.dart';

/// A custom PageRoute that keeps the Glass Slate stationary while
/// the content inside dissolves and scales slightly.
class GlassContentTransition<T> extends PageRouteBuilder<T> {
  final Widget page;

  GlassContentTransition({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return AppPageTransitions.buildPortalTransition(
              animation: animation,
              child: child,
            );
          },
          transitionDuration: AppPageTransitions.portalDuration,
          reverseTransitionDuration: AppPageTransitions.portalReverseDuration,
          opaque: false, // Allows background world to show through.
          barrierColor: Colors.transparent,
        );
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Centralized transition policy for app navigation.
///
/// Edit this file to change route motion behavior globally.
class AppPageTransitions {
  static const Duration standardDuration = Duration(milliseconds: 300);
  static const Duration standardReverseDuration = Duration(milliseconds: 220);
  static const Duration modalDuration = Duration(milliseconds: 320);
  static const Duration fadeDuration = Duration(milliseconds: 200);
  static const Duration scaleFadeDuration = Duration(milliseconds: 260);
  static const Duration portalDuration = Duration(milliseconds: 300);
  static const Duration portalReverseDuration = Duration(milliseconds: 200);

  static PageTransitionsTheme get pageTransitionsTheme =>
      const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.fuchsia: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        },
      );

  static bool get _isApplePlatform =>
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;

  static bool _reducedMotion(BuildContext context) {
    final media = MediaQuery.maybeOf(context);
    return media?.disableAnimations ?? false;
  }

  /// Standard page push/pop.
  ///
  /// On Apple platforms this uses [CupertinoPageRoute] for native interactive
  /// back-swipe behavior where the page follows the user's finger.
  static Route<T> standard<T extends Object?>(
    Widget page, {
    RouteSettings? settings,
    bool fullscreenDialog = false,
  }) {
    if (_isApplePlatform) {
      return CupertinoPageRoute<T>(
        builder: (_) => page,
        settings: settings,
        fullscreenDialog: fullscreenDialog,
      );
    }
    return MaterialPageRoute<T>(
      builder: (_) => page,
      settings: settings,
      fullscreenDialog: fullscreenDialog,
    );
  }

  /// Compatibility builder for migrating legacy `MaterialPageRoute(...)`
  /// calls to centralized transition policy with minimal code changes.
  static Route<T> material<T extends Object?>({
    required WidgetBuilder builder,
    RouteSettings? settings,
    bool maintainState = true,
    bool fullscreenDialog = false,
  }) {
    if (_isApplePlatform) {
      return CupertinoPageRoute<T>(
        builder: builder,
        settings: settings,
        fullscreenDialog: fullscreenDialog,
      );
    }
    return MaterialPageRoute<T>(
      builder: builder,
      settings: settings,
      maintainState: maintainState,
      fullscreenDialog: fullscreenDialog,
    );
  }

  /// Modal-style push.
  static Route<T> modal<T extends Object?>(
    Widget page, {
    RouteSettings? settings,
  }) {
    if (_isApplePlatform) {
      return standard<T>(page, settings: settings, fullscreenDialog: true);
    }
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (_, __, ___) => page,
      transitionDuration: modalDuration,
      reverseTransitionDuration: standardReverseDuration,
      transitionsBuilder: (context, animation, _, child) {
        if (_reducedMotion(context)) return child;
        final tween = Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }

  /// Fade route. Uses native standard route on Apple for swipe fidelity.
  static Route<T> fade<T extends Object?>(
    Widget page, {
    RouteSettings? settings,
  }) {
    if (_isApplePlatform) {
      return standard<T>(page, settings: settings);
    }
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (_, __, ___) => page,
      transitionDuration: fadeDuration,
      reverseTransitionDuration: standardReverseDuration,
      transitionsBuilder: (context, animation, _, child) {
        if (_reducedMotion(context)) return child;
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  /// Scale+fade route. Uses native standard route on Apple for swipe fidelity.
  static Route<T> scaleAndFade<T extends Object?>(
    Widget page, {
    RouteSettings? settings,
  }) {
    if (_isApplePlatform) {
      return standard<T>(page, settings: settings);
    }
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (_, __, ___) => page,
      transitionDuration: scaleFadeDuration,
      reverseTransitionDuration: standardReverseDuration,
      transitionsBuilder: (context, animation, _, child) {
        if (_reducedMotion(context)) return child;
        final scale = Tween<double>(
          begin: 0.96,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOutCubic));
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: animation.drive(scale), child: child),
        );
      },
    );
  }

  /// Portal content transition (glass-slate content dissolve + slight scale).
  ///
  /// This is intentionally non-opaque so the portal world stays visible.
  static Route<T> portalContent<T extends Object?>(
    Widget page, {
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (_, __, ___) => page,
      transitionDuration: portalDuration,
      reverseTransitionDuration: portalReverseDuration,
      opaque: false,
      barrierColor: Colors.transparent,
      transitionsBuilder: (context, animation, _, child) {
        if (_reducedMotion(context)) return child;
        return buildPortalTransition(
          animation: animation,
          child: child,
        );
      },
    );
  }

  static Widget buildPortalTransition({
    required Animation<double> animation,
    required Widget child,
  }) {
    final fadeAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOut,
    );
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
  }
}

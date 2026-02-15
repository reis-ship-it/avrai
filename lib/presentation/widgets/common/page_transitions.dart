import 'package:flutter/material.dart';
import 'package:avrai/core/navigation/app_page_transitions.dart';

/// Page Transition Utilities
/// Agent 2: Event Discovery & Hosting UI (Week 4, Task 2.12)
///
/// Provides smooth page transitions for better UX
class PageTransitions {
  /// Slide transition from right
  static Route<T> slideFromRight<T extends Object?>(
    Widget page, {
    RouteSettings? settings,
  }) {
    return AppPageTransitions.standard<T>(page, settings: settings);
  }

  /// Slide transition from bottom
  static Route<T> slideFromBottom<T extends Object?>(
    Widget page, {
    RouteSettings? settings,
  }) {
    return AppPageTransitions.modal<T>(page, settings: settings);
  }

  /// Fade transition
  static Route<T> fade<T extends Object?>(
    Widget page, {
    RouteSettings? settings,
  }) {
    return AppPageTransitions.fade<T>(page, settings: settings);
  }

  /// Scale and fade transition (for success/result pages)
  static Route<T> scaleAndFade<T extends Object?>(
    Widget page, {
    RouteSettings? settings,
  }) {
    return AppPageTransitions.scaleAndFade<T>(page, settings: settings);
  }
}

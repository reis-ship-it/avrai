import 'package:flutter/material.dart';
import 'package:avrai/core/navigation/app_page_transitions.dart';

/// Centralized navigation API for AVRAI.
///
/// Use these helpers instead of ad-hoc `Navigator.push*` calls so route
/// behavior remains uniform and editable from one place.
class AppNavigator {
  const AppNavigator._();

  static Future<T?> push<T extends Object?>(
    BuildContext context,
    Widget page, {
    RouteSettings? settings,
    bool fullscreenDialog = false,
  }) {
    return Navigator.of(context).push<T>(
      AppPageTransitions.standard<T>(
        page,
        settings: settings,
        fullscreenDialog: fullscreenDialog,
      ),
    );
  }

  static Future<T?> pushBuilder<T extends Object?>(
    BuildContext context, {
    required WidgetBuilder builder,
    RouteSettings? settings,
    bool fullscreenDialog = false,
  }) {
    return Navigator.of(context).push<T>(
      AppPageTransitions.material<T>(
        builder: builder,
        settings: settings,
        fullscreenDialog: fullscreenDialog,
      ),
    );
  }

  static Future<T?> replace<T extends Object?, TO extends Object?>(
    BuildContext context,
    Widget page, {
    RouteSettings? settings,
    bool fullscreenDialog = false,
    TO? result,
  }) {
    return Navigator.of(context).pushReplacement<T, TO>(
      AppPageTransitions.standard<T>(
        page,
        settings: settings,
        fullscreenDialog: fullscreenDialog,
      ),
      result: result,
    );
  }

  static Future<T?> replaceBuilder<T extends Object?, TO extends Object?>(
    BuildContext context, {
    required WidgetBuilder builder,
    RouteSettings? settings,
    bool fullscreenDialog = false,
    TO? result,
  }) {
    return Navigator.of(context).pushReplacement<T, TO>(
      AppPageTransitions.material<T>(
        builder: builder,
        settings: settings,
        fullscreenDialog: fullscreenDialog,
      ),
      result: result,
    );
  }

  static bool canPop(BuildContext context) => Navigator.of(context).canPop();

  static void pop<T extends Object?>(BuildContext context, [T? result]) {
    Navigator.of(context).pop<T>(result);
  }
}

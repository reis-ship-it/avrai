import 'package:flutter/material.dart';
import 'package:avrai/core/design/design_system.dart';
import 'package:avrai/core/design/component_tokens.dart';
import 'package:avrai/core/theme/colors.dart';

enum FeedbackKind { info, success, warning, error }

class FeedbackPresenter {
  const FeedbackPresenter._();

  static ScaffoldMessengerState _messenger(BuildContext context) =>
      ScaffoldMessenger.of(context);

  static void showSnack(
    BuildContext context, {
    required String message,
    FeedbackKind kind = FeedbackKind.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final tokens =
        Theme.of(context).extension<FeedbackTokens>() ?? const FeedbackTokens();
    final color = switch (kind) {
      FeedbackKind.info => tokens.infoColor,
      FeedbackKind.success => tokens.successColor,
      FeedbackKind.warning => tokens.warningColor,
      FeedbackKind.error => tokens.errorColor,
    };

    _messenger(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        backgroundColor: color,
      ),
    );
  }

  static Future<void> showErrorDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  static Widget banner({
    required BuildContext context,
    required String message,
    required FeedbackKind kind,
  }) {
    final spacing = context.spacing;
    final radii = context.radii;
    final bg = switch (kind) {
      FeedbackKind.info => AppColors.electricBlue.withValues(alpha: 0.16),
      FeedbackKind.success => AppColors.success.withValues(alpha: 0.16),
      FeedbackKind.warning => AppColors.warning.withValues(alpha: 0.16),
      FeedbackKind.error => AppColors.error.withValues(alpha: 0.16),
    };
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(spacing.sm),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radii.md),
      ),
      child: Text(message, style: context.text.bodyMedium),
    );
  }

  static void showCustomSnackBar(BuildContext context, SnackBar snackBar) {
    _messenger(context).showSnackBar(snackBar);
  }

  static void hideCurrentSnackBar(BuildContext context) {
    _messenger(context).hideCurrentSnackBar();
  }

  static void clearSnackBars(BuildContext context) {
    _messenger(context).clearSnackBars();
  }
}

extension FeedbackContext on BuildContext {
  void showInfo(String message) => FeedbackPresenter.showSnack(
        this,
        message: message,
        kind: FeedbackKind.info,
      );

  void showSuccess(String message) => FeedbackPresenter.showSnack(
        this,
        message: message,
        kind: FeedbackKind.success,
      );

  void showWarning(String message) => FeedbackPresenter.showSnack(
        this,
        message: message,
        kind: FeedbackKind.warning,
      );

  void showError(String message) => FeedbackPresenter.showSnack(
        this,
        message: message,
        kind: FeedbackKind.error,
      );

  void showCustomSnackBar(SnackBar snackBar) =>
      FeedbackPresenter.showCustomSnackBar(this, snackBar);

  void hideCurrentSnack() => FeedbackPresenter.hideCurrentSnackBar(this);

  void clearAllSnackBars() => FeedbackPresenter.clearSnackBars(this);
}

import 'dart:async';

import 'package:flutter/material.dart';

Future<void> showUndoableNegativeFeedback({
  required BuildContext context,
  required String message,
  required Future<void> Function() onCommit,
  VoidCallback? onOptimisticUpdate,
  VoidCallback? onUndo,
  bool replaceCurrentSnackBar = true,
  Duration duration = const Duration(seconds: 4),
}) async {
  onOptimisticUpdate?.call();

  final messenger = ScaffoldMessenger.of(context);
  if (replaceCurrentSnackBar) {
    messenger.hideCurrentSnackBar();
  }

  var wasUndone = false;
  final controller = messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      duration: duration,
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () {
          wasUndone = true;
          onUndo?.call();
        },
      ),
    ),
  );

  await Future<void>.delayed(duration);
  if (wasUndone) {
    return;
  }
  controller.close();
  await onCommit();
}

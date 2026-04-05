import 'package:flutter/material.dart';

import 'package:avrai/presentation/widgets/common/app_button_secondary.dart';
import 'package:avrai/presentation/widgets/common/app_empty_state.dart';

class AppErrorState extends StatelessWidget {
  final String title;
  final String body;
  final VoidCallback? onRetry;

  const AppErrorState({
    super.key,
    required this.title,
    required this.body,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      title: title,
      body: body,
      icon: Icons.error_outline,
      action: onRetry == null
          ? null
          : AppButtonSecondary(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
    );
  }
}

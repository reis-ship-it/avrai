import 'package:flutter/material.dart';

import 'package:avrai/presentation/widgets/common/app_surface.dart';
import 'package:avrai/theme/colors.dart';

enum AppStatusTone { neutral, success, warning, error }

class AppStatusBanner extends StatelessWidget {
  final String title;
  final String body;
  final AppStatusTone tone;

  const AppStatusBanner({
    super.key,
    required this.title,
    required this.body,
    this.tone = AppStatusTone.neutral,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      AppStatusTone.success => AppColors.success,
      AppStatusTone.warning => AppColors.warning,
      AppStatusTone.error => AppColors.error,
      AppStatusTone.neutral => AppColors.textSecondary,
    };

    return AppSurface(
      color: color.withValues(alpha: 0.08),
      borderColor: color.withValues(alpha: 0.16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(body),
        ],
      ),
    );
  }
}

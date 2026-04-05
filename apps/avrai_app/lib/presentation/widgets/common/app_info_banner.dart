import 'package:flutter/material.dart';

import 'package:avrai/presentation/widgets/common/app_surface.dart';
import 'package:avrai/theme/colors.dart';

class AppInfoBanner extends StatelessWidget {
  final String title;
  final String body;
  final IconData icon;

  const AppInfoBanner({
    super.key,
    required this.title,
    required this.body,
    this.icon = Icons.info_outline,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      color: AppColors.surfaceMuted,
      borderColor: AppColors.borderSubtle,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                Text(body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

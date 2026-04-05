import 'package:avrai_admin_app/theme/colors.dart';
import 'package:avrai_admin_app/ui/widgets/common/app_flow_scaffold.dart';
import 'package:flutter/material.dart';

class WorldPlanesPage extends StatelessWidget {
  const WorldPlanesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AppFlowScaffold(
      title: 'World Planes',
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'World-plane visualization is being migrated into the standalone admin package.',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'The admin app now owns the route and launch surface, but the deep world-plane rendering stack still needs a dedicated package extraction. '
            'Use this page as the stable placeholder while the visualization modules are split cleanly.',
            style: textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

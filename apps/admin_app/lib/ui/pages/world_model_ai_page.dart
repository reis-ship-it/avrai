import 'package:avrai_admin_app/navigation/admin_route_paths.dart';
import 'package:avrai_admin_app/theme/colors.dart';
import 'package:avrai_admin_app/ui/widgets/common/app_flow_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WorldModelAiPage extends StatelessWidget {
  const WorldModelAiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppFlowScaffold(
      title: 'World Model',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Admin-only world model oversight',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'World-model reasoning, locality context, and research guidance are now an admin/operator surface. They are intentionally disconnected from the BHAM consumer shell.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: const [
                      Chip(label: Text('Admin boundary')),
                      Chip(label: Text('Research + oversight')),
                      Chip(label: Text('Not in consumer beta gate')),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.psychology_alt_outlined),
              title: const Text('Reality Oversight'),
              subtitle: const Text(
                'Inspect locality, universe, and world-layer oversight surfaces.',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go(AdminRoutePaths.realitySystemReality),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.science_outlined),
              title: const Text('Research Center'),
              subtitle: const Text(
                'Review research feed, alerts, and operator-facing world-model work.',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go(AdminRoutePaths.researchCenter),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.chat_outlined),
              title: const Text('Communications'),
              subtitle: const Text(
                'Inspect pseudonymous route, delivery, and support summaries.',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go(AdminRoutePaths.communications),
            ),
          ),
        ],
      ),
    );
  }
}

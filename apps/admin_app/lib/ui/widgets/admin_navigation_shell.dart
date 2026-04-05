import 'package:avrai_admin_app/navigation/admin_route_paths.dart';
import 'package:avrai_admin_app/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminNavigationShell extends StatelessWidget {
  const AdminNavigationShell({
    super.key,
    required this.child,
    required this.currentLocation,
  });

  final Widget child;
  final String currentLocation;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 1100) {
          return child;
        }
        return Row(
          children: [
            Container(
              width: 280,
              decoration: BoxDecoration(
                color: AppColors.grey100.withValues(alpha: 0.4),
                border: Border(
                  right: BorderSide(
                      color: AppColors.grey300.withValues(alpha: 0.8)),
                ),
              ),
              child: SafeArea(
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    const _ShellTitle(),
                    const SizedBox(height: 12),
                    _NavTile(
                      icon: Icons.dashboard_customize_outlined,
                      label: 'Command Center',
                      route: AdminRoutePaths.commandCenter,
                      selected: _isActive(AdminRoutePaths.commandCenter),
                    ),
                    _NavTile(
                      icon: Icons.visibility_outlined,
                      label: 'Governance Audit',
                      route: AdminRoutePaths.governanceAudit,
                      selected: _isActive(AdminRoutePaths.governanceAudit),
                    ),
                    _NavTile(
                      icon: Icons.psychology_alt,
                      label: 'Reality Oversight',
                      route: AdminRoutePaths.realitySystemReality,
                      selected: _isActive(AdminRoutePaths.realitySystemReality),
                    ),
                    _NavTile(
                      icon: Icons.groups,
                      label: 'Universe Oversight',
                      route: AdminRoutePaths.realitySystemUniverse,
                      selected:
                          _isActive(AdminRoutePaths.realitySystemUniverse),
                    ),
                    _NavTile(
                      icon: Icons.public,
                      label: 'World Oversight',
                      route: AdminRoutePaths.realitySystemWorld,
                      selected: _isActive(AdminRoutePaths.realitySystemWorld),
                    ),
                    _NavTile(
                      icon: Icons.hub_outlined,
                      label: 'AI2AI Mesh',
                      route: AdminRoutePaths.ai2ai,
                      selected: _isActive(AdminRoutePaths.ai2ai),
                    ),
                    _NavTile(
                      icon: Icons.chat_outlined,
                      label: 'Communications',
                      route: AdminRoutePaths.communications,
                      selected: _isActive(AdminRoutePaths.communications),
                    ),
                    _NavTile(
                      icon: Icons.gpp_maybe_outlined,
                      label: 'Moderation',
                      route: AdminRoutePaths.moderation,
                      selected: _isActive(AdminRoutePaths.moderation),
                    ),
                    _NavTile(
                      icon: Icons.travel_explore,
                      label: 'Creation Explorer',
                      route: AdminRoutePaths.explorer,
                      selected: _isActive(AdminRoutePaths.explorer),
                    ),
                    _NavTile(
                      icon: Icons.feedback_outlined,
                      label: 'Beta Feedback',
                      route: AdminRoutePaths.betaFeedback,
                      selected: _isActive(AdminRoutePaths.betaFeedback),
                    ),
                    _NavTile(
                      icon: Icons.verified_user_outlined,
                      label: 'Launch Safety',
                      route: AdminRoutePaths.launchSafety,
                      selected: _isActive(AdminRoutePaths.launchSafety),
                    ),
                    _NavTile(
                      icon: Icons.health_and_safety_outlined,
                      label: 'Security Immune',
                      route: AdminRoutePaths.securityImmuneSystem,
                      selected: _isActive(AdminRoutePaths.securityImmuneSystem),
                    ),
                    _NavTile(
                      icon: Icons.monitor_heart_outlined,
                      label: 'Signature Health',
                      route: AdminRoutePaths.signatureHealth,
                      selected: _isActive(AdminRoutePaths.signatureHealth),
                    ),
                    _NavTile(
                      icon: Icons.settings_suggest,
                      label: 'URK Kernel',
                      route: AdminRoutePaths.urkKernels,
                      selected: _isActive(AdminRoutePaths.urkKernels),
                    ),
                    _NavTile(
                      icon: Icons.science_outlined,
                      label: 'Research Center',
                      route: AdminRoutePaths.researchCenter,
                      selected: _isActive(AdminRoutePaths.researchCenter),
                    ),
                    _NavTile(
                      icon: Icons.psychology_outlined,
                      label: 'World Model',
                      route: AdminRoutePaths.worldModel,
                      selected: _isActive(AdminRoutePaths.worldModel),
                    ),
                    _NavTile(
                      icon: Icons.travel_explore_outlined,
                      label: 'World Simulation Lab',
                      route: AdminRoutePaths.worldSimulationLab,
                      selected: _isActive(AdminRoutePaths.worldSimulationLab),
                    ),
                    const SizedBox(height: 20),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          'Privacy baseline: only agent identity and aggregate telemetry are shown.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(child: child),
          ],
        );
      },
    );
  }

  bool _isActive(String route) {
    return currentLocation == route || currentLocation.startsWith('$route/');
  }
}

class _ShellTitle extends StatelessWidget {
  const _ShellTitle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Admin Navigation',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Command-center routing shell',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.label,
    required this.route,
    required this.selected,
  });

  final IconData icon;
  final String label;
  final String route;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        dense: true,
        leading: Icon(icon, size: 20),
        title: Text(label),
        selected: selected,
        selectedTileColor: AppColors.electricGreen.withValues(alpha: 0.14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onTap: () => context.go(route),
      ),
    );
  }
}

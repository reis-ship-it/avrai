// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:v0.1.1
// Temporarily placed in legacy lib/ path to avoid import spaghetti during v0.1 Sandbox iteration.
// Must be moved to apps/avrai_app/lib/... during full 3-Prong migration.

import 'package:flutter/material.dart';
import 'package:avrai/theme/colors.dart';
import 'package:avrai/presentation/widgets/common/app_surface.dart';
import 'package:avrai/presentation/schema_renderer/app_schema_page.dart';
import 'package:avrai/presentation/schemas/pages/data_intake_connection_page_schema.dart';
import 'package:avrai_runtime_os/endpoints/intake/device_intake_router.dart';
import 'package:avrai_runtime_os/runtime_api.dart';

class DataIntakeConnectionPage extends StatefulWidget {
  final VoidCallback onComplete;

  const DataIntakeConnectionPage({
    super.key,
    required this.onComplete,
  });

  @override
  State<DataIntakeConnectionPage> createState() =>
      _DataIntakeConnectionPageState();
}

class _DataIntakeConnectionPageState extends State<DataIntakeConnectionPage> {
  bool _calendarConnected = false;
  bool _socialConnected = false;
  bool _notificationsConnected = false;

  // Dependency injection would normally handle this, but for the v0.1 sandbox
  // we instantiate the local intake pipeline directly here.
  late final DeviceIntakeRouter _intakeRouter;

  @override
  void initState() {
    super.initState();
    // Set up the local intake pipeline.
    final store = InMemorySemanticStore();
    final engine = TupleExtractionEngine(store);
    _intakeRouter = DeviceIntakeRouter(engine);
  }

  @override
  Widget build(BuildContext context) {
    return AppSchemaPage(
      schema: buildDataIntakeConnectionPageSchema(
        sourcesSection: _buildSourcesSection(),
      ),
      padding: const EdgeInsets.all(16),
    );
  }

  Widget _buildSourcesSection() {
    return Column(
      children: [
        _buildConnectionCard(
          title: 'Calendar',
          description:
              'Helps AVRAI learn routines, scheduling patterns, and availability.',
          icon: Icons.calendar_month_outlined,
          isConnected: _calendarConnected,
          onToggle: (val) {
            setState(() => _calendarConnected = val);
          },
        ),
        const SizedBox(height: 16),
        _buildConnectionCard(
          title: 'Notifications',
          description:
              'Uses notification summaries to learn communication patterns and timing preferences.',
          icon: Icons.notifications_outlined,
          isConnected: _notificationsConnected,
          onToggle: (val) {
            setState(() => _notificationsConnected = val);
            if (val) {
              _intakeRouter.onNotificationReceived(
                'Hey, do you want to grab coffee tomorrow morning?',
              );
            }
          },
        ),
        const SizedBox(height: 16),
        _buildConnectionCard(
          title: 'Social data exports',
          description:
              'Lets AVRAI learn broader interests and posting patterns from exported social activity.',
          icon: Icons.share_outlined,
          isConnected: _socialConnected,
          onToggle: (val) {
            setState(() => _socialConnected = val);
          },
        ),
      ],
    );
  }

  Widget _buildConnectionCard({
    required String title,
    required String description,
    required IconData icon,
    required bool isConnected,
    required ValueChanged<bool> onToggle,
  }) {
    return AppSurface(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isConnected ? AppColors.surfaceMuted : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color:
                  isConnected ? AppColors.textPrimary : AppColors.textSecondary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.grey500,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isConnected,
            onChanged: onToggle,
            activeTrackColor: AppColors.textPrimary,
          ),
        ],
      ),
    );
  }
}

// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:v0.1.1
// Temporarily placed in legacy lib/ path to avoid import spaghetti during v0.1 Sandbox iteration.
// Must be moved to apps/avrai_app/lib/... during full 3-Prong migration.

import 'package:flutter/material.dart';
import 'package:avrai/theme/colors.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';
import 'package:avrai/presentation/widgets/portal/portal_surface.dart';
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
  // we instantiate the Air Gap architecture directly here.
  late final DeviceIntakeRouter _intakeRouter;

  @override
  void initState() {
    super.initState();
    // Set up the Air Gap pipeline
    final store = InMemorySemanticStore();
    final engine = TupleExtractionEngine(store);
    _intakeRouter = DeviceIntakeRouter(engine);
  }

  void _completeStep() {
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return AdaptivePlatformPageScaffold(
      title: 'Data Intake & Privacy',
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'The Privacy Air Gap',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Unlike other AI apps, AVRAI operates a strict Air Gap. When you connect your data, your raw emails, texts, and calendars never leave this phone.\n\n'
              'Instead, our Local AI scrubs them locally, extracts only the abstract meaning (e.g., "Prefers Coffee in Mornings"), and permanently destroys the raw text.',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            _buildConnectionCard(
              title: 'Apple Calendar / Google Calendar',
              description:
                  'Allows AVRAI to learn your routines and availability.',
              icon: Icons.calendar_month,
              isConnected: _calendarConnected,
              onToggle: (val) {
                setState(() => _calendarConnected = val);
              },
            ),
            const SizedBox(height: 16),
            _buildConnectionCard(
              title: 'Notification Listener',
              description:
                  'Allows AVRAI to read incoming texts and emails to learn your communication style and preferences. (Raw text is instantly burned).',
              icon: Icons.notifications_active,
              isConnected: _notificationsConnected,
              onToggle: (val) {
                setState(() => _notificationsConnected = val);
                if (val) {
                  // Simulate an incoming OS text message hitting the intake router
                  _intakeRouter.onNotificationReceived(
                      "Hey, do you want to grab coffee at Starbucks tomorrow morning?");
                }
              },
            ),
            const SizedBox(height: 16),
            _buildConnectionCard(
              title: 'Social Media Feeds',
              description:
                  'Connect Instagram/Twitter data exports so the AI can understand your online vibe.',
              icon: Icons.share,
              isConnected: _socialConnected,
              onToggle: (val) {
                setState(() => _socialConnected = val);
              },
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _completeStep,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Continue',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionCard({
    required String title,
    required String description,
    required IconData icon,
    required bool isConnected,
    required ValueChanged<bool> onToggle,
  }) {
    return PortalSurface(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isConnected
                  ? AppColors.electricGreen.withValues(alpha: 0.1)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isConnected
                  ? AppColors.electricGreen
                  : AppColors.textSecondary,
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
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isConnected,
            onChanged: onToggle,
            activeThumbColor: AppColors.electricGreen,
          ),
        ],
      ),
    );
  }
}

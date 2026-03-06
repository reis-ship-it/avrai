import 'package:flutter/material.dart';
import 'package:avrai/theme/colors.dart';
import 'package:avrai/presentation/widgets/common/app_surface.dart';

import 'package:permission_handler/permission_handler.dart';

/// Step 9: Notifications permission page.
///
/// This is an optional step - users can skip it.
/// Requests notification permission and explains the benefits.
class NotificationsPage extends StatefulWidget {
  /// Callback when notification permission status changes
  final ValueChanged<bool> onNotificationStatusChanged;

  const NotificationsPage({
    super.key,
    required this.onNotificationStatusChanged,
  });

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _isLoading = false;
  bool? _isGranted;

  @override
  void initState() {
    super.initState();
    _checkCurrentStatus();
  }

  Future<void> _checkCurrentStatus() async {
    try {
      final status = await Permission.notification.status;
      if (mounted) {
        setState(() {
          _isGranted = status.isGranted;
        });
        widget.onNotificationStatusChanged(status.isGranted);
      }
    } catch (e) {
      // Permission not available on this platform
    }
  }

  Future<void> _requestNotificationPermission() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final status = await Permission.notification.request();

      if (mounted) {
        setState(() {
          _isGranted = status.isGranted;
        });
        widget.onNotificationStatusChanged(status.isGranted);

        if (status.isPermanentlyDenied) {
          _showSettingsDialog();
        }
      }
    } catch (e) {
      // Permission not available on this platform
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enable Notifications'),
        content: const Text(
          'To enable notifications, please allow them in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 40),

          // Icon
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_active,
              size: 64,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 32),

          // Title
          Text(
            'Stay in the Loop',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Subtitle
          Text(
            "We'll keep you updated about the things that matter to you.",
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),

          // Benefits list
          _buildBenefitItem(
            context: context,
            icon: Icons.calendar_today,
            title: 'Reservation Reminders',
            description: "Never miss a reservation with timely reminders",
          ),
          const SizedBox(height: 16),
          _buildBenefitItem(
            context: context,
            icon: Icons.groups,
            title: 'Community Updates',
            description: "Stay connected with events and activities near you",
          ),
          const SizedBox(height: 16),
          _buildBenefitItem(
            context: context,
            icon: Icons.auto_awesome,
            title: 'AI Recommendations',
            description:
                "Get personalized suggestions when something great is nearby",
          ),
          const SizedBox(height: 16),
          _buildBenefitItem(
            context: context,
            icon: Icons.message,
            title: 'Messages',
            description: "Know when friends or communities reach out",
          ),

          const SizedBox(height: 40),

          // Status indicator
          if (_isGranted != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isGranted!
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.grey100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isGranted! ? AppColors.success : AppColors.grey300,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isGranted! ? Icons.check_circle : Icons.notifications_off,
                    color: _isGranted!
                        ? AppColors.success
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _isGranted!
                        ? 'Notifications enabled!'
                        : 'Notifications are off',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: _isGranted!
                          ? AppColors.success
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 24),

          // Enable button
          if (_isGranted != true)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _requestNotificationPermission,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.notifications),
                label:
                    Text(_isLoading ? 'Enabling...' : 'Enable Notifications'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Skip hint
          Text(
            'You can change this anytime in Settings',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
  }) {
    final theme = Theme.of(context);

    return AppSurface(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

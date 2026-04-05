import 'package:flutter/material.dart';

import 'package:avrai/presentation/schema_renderer/app_schema_page.dart';
import 'package:avrai/presentation/schemas/pages/notifications_page_schema.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:avrai/theme/colors.dart';

/// Optional notification permission step in onboarding.
class NotificationsPage extends StatefulWidget {
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
      if (!mounted) return;
      setState(() {
        _isGranted = status.isGranted;
      });
      widget.onNotificationStatusChanged(status.isGranted);
    } catch (_) {
      // Permission may not exist on this platform.
    }
  }

  Future<void> _requestNotificationPermission() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final status = await Permission.notification.request();
      if (!mounted) return;

      setState(() {
        _isGranted = status.isGranted;
      });
      widget.onNotificationStatusChanged(status.isGranted);

      if (status.isPermanentlyDenied) {
        _showSettingsDialog();
      }
    } catch (_) {
      // Permission may not exist on this platform.
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSettingsDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enable Notifications'),
        content: const Text(
          'To enable notifications, allow them in your device settings.',
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

    return AppSchemaPage(
      padding: const EdgeInsets.all(16),
      schema: buildNotificationsPageSchema(
        isGranted: _isGranted == true,
        statusRow: _buildStatusRow(theme),
        actionRow: _buildActionRow(),
      ),
    );
  }

  Widget _buildStatusRow(ThemeData theme) {
    if (_isGranted == null) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          _isGranted! ? Icons.check_circle : Icons.notifications_off,
          color: _isGranted! ? AppColors.success : AppColors.textSecondary,
        ),
        const SizedBox(width: 12),
        Text(
          _isGranted!
              ? 'Notifications are enabled'
              : 'Notifications are currently off',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: _isGranted! ? AppColors.success : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget? _buildActionRow() {
    if (_isGranted == true) {
      return null;
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _requestNotificationPermission,
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Enable Notifications'),
      ),
    );
  }
}

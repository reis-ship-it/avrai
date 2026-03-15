import 'package:flutter/material.dart';
import 'package:avrai/theme/colors.dart';
import 'package:avrai/presentation/schema_renderer/app_schema_page.dart';
import 'package:avrai/presentation/schemas/pages/notifications_settings_page_schema.dart';
import 'package:avrai_runtime_os/services/messaging/bham_notification_policy_service.dart';
import 'package:get_it/get_it.dart';

class NotificationsSettingsPage extends StatefulWidget {
  const NotificationsSettingsPage({super.key});

  @override
  State<NotificationsSettingsPage> createState() =>
      _NotificationsSettingsPageState();
}

class _NotificationsSettingsPageState extends State<NotificationsSettingsPage> {
  final _notificationPolicyService =
      GetIt.instance<BhamNotificationPolicyService>();
  bool _dailyDrop = true;
  bool _contextNudges = true;
  bool _ai2aiCompatibility = true;
  bool _humanMessages = true;
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _quietHours = true;

  TimeOfDay _quietStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _quietEnd = const TimeOfDay(hour: 6, minute: 0);

  @override
  Widget build(BuildContext context) {
    return AppSchemaPage(
      schema: buildNotificationsSettingsPageSchema(
        dailyDrop: _dailyDrop,
        contextNudges: _contextNudges,
        ai2aiCompatibility: _ai2aiCompatibility,
        humanMessages: _humanMessages,
        pushNotifications: _pushNotifications,
        emailNotifications: _emailNotifications,
        quietHours: _quietHours,
        quietStartLabel: _quietStart.format(context),
        quietEndLabel: _quietEnd.format(context),
        maxCappedPerDay: _notificationPolicyService.policy.maxPerDay,
        onDailyDropChanged: (value) => setState(() => _dailyDrop = value),
        onContextNudgesChanged: (value) =>
            setState(() => _contextNudges = value),
        onAi2aiCompatibilityChanged: (value) =>
            setState(() => _ai2aiCompatibility = value),
        onHumanMessagesChanged: (value) =>
            setState(() => _humanMessages = value),
        onPushNotificationsChanged: (value) =>
            setState(() => _pushNotifications = value),
        onEmailNotificationsChanged: (value) =>
            setState(() => _emailNotifications = value),
        onQuietHoursChanged: (value) => setState(() => _quietHours = value),
        onSelectQuietStart: () => _selectTime(context, true),
        onSelectQuietEnd: () => _selectTime(context, false),
        onSendTestNotification: _sendTestNotification,
      ),
    );
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _quietStart : _quietEnd,
    );

    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _quietStart = picked;
        } else {
          _quietEnd = picked;
        }
      });
    }
  }

  void _sendTestNotification() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Test notification sent. Check your notification panel.'),
        backgroundColor: AppColors.success,
      ),
    );
  }
}

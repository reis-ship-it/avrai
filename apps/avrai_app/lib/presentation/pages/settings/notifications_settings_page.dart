import 'package:flutter/material.dart';
import 'package:avrai/presentation/schema_renderer/app_schema_page.dart';
import 'package:avrai/presentation/schemas/pages/notifications_settings_page_schema.dart';
import 'package:avrai/theme/app_theme.dart';

class NotificationsSettingsPage extends StatefulWidget {
  const NotificationsSettingsPage({super.key});

  @override
  State<NotificationsSettingsPage> createState() =>
      _NotificationsSettingsPageState();
}

class _NotificationsSettingsPageState extends State<NotificationsSettingsPage> {
  bool _spotRecommendations = true;
  bool _listRespects = true;
  bool _communityActivity = false;
  bool _nearbySpots = true;
  bool _aiLearningUpdates = false;
  bool _weeklyDigest = true;
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _quietHours = true;

  TimeOfDay _quietStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _quietEnd = const TimeOfDay(hour: 7, minute: 0);

  @override
  Widget build(BuildContext context) {
    return AppSchemaPage(
      schema: buildNotificationsSettingsPageSchema(
        spotRecommendations: _spotRecommendations,
        listRespects: _listRespects,
        communityActivity: _communityActivity,
        nearbySpots: _nearbySpots,
        aiLearningUpdates: _aiLearningUpdates,
        weeklyDigest: _weeklyDigest,
        pushNotifications: _pushNotifications,
        emailNotifications: _emailNotifications,
        quietHours: _quietHours,
        quietStartLabel: _quietStart.format(context),
        quietEndLabel: _quietEnd.format(context),
        onSpotRecommendationsChanged: (value) =>
            setState(() => _spotRecommendations = value),
        onListRespectsChanged: (value) => setState(() => _listRespects = value),
        onCommunityActivityChanged: (value) =>
            setState(() => _communityActivity = value),
        onNearbySpotsChanged: (value) => setState(() => _nearbySpots = value),
        onAiLearningUpdatesChanged: (value) =>
            setState(() => _aiLearningUpdates = value),
        onWeeklyDigestChanged: (value) => setState(() => _weeklyDigest = value),
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
        backgroundColor: AppTheme.successColor,
      ),
    );
  }
}

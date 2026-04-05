import 'package:flutter/material.dart';

import 'package:avrai/presentation/schemas/models/page_schema.dart';

PageSchema buildNotificationsSettingsPageSchema({
  required bool dailyDrop,
  required bool contextNudges,
  required bool ai2aiCompatibility,
  required bool humanMessages,
  required bool pushNotifications,
  required bool emailNotifications,
  required bool quietHours,
  required String quietStartLabel,
  required String quietEndLabel,
  required int maxCappedPerDay,
  required ValueChanged<bool> onDailyDropChanged,
  required ValueChanged<bool> onContextNudgesChanged,
  required ValueChanged<bool> onAi2aiCompatibilityChanged,
  required ValueChanged<bool> onHumanMessagesChanged,
  required ValueChanged<bool> onPushNotificationsChanged,
  required ValueChanged<bool> onEmailNotificationsChanged,
  required ValueChanged<bool> onQuietHoursChanged,
  required VoidCallback onSelectQuietStart,
  required VoidCallback onSelectQuietEnd,
  required VoidCallback onSendTestNotification,
}) {
  final quietHoursItems = <SettingItemSchema>[
    ToggleSettingItemSchema(
      title: 'Enable Quiet Hours',
      subtitle: 'Pause notifications during a chosen overnight window.',
      icon: Icons.bedtime_outlined,
      value: quietHours,
      onChanged: onQuietHoursChanged,
    ),
    if (quietHours)
      ActionSettingItemSchema(
        title: 'Start Time',
        subtitle: quietStartLabel,
        icon: Icons.access_time,
        onTap: onSelectQuietStart,
      ),
    if (quietHours)
      ActionSettingItemSchema(
        title: 'End Time',
        subtitle: quietEndLabel,
        icon: Icons.access_time,
        onTap: onSelectQuietEnd,
      ),
  ];

  return PageSchema(
    title: 'Notifications',
    header: const PageHeaderSchema(
      title: 'Notifications',
      subtitle: 'Choose which updates you receive and how they should arrive.',
      leadingIcon: Icons.notifications_outlined,
    ),
    sections: [
      const BannerSectionSchema(
        title: 'Notification controls',
        body:
            'You control delivery methods, quiet hours, and how AVRAI uses activity signals for updates.',
        icon: Icons.tune_outlined,
      ),
      SettingsGroupSectionSchema(
        title: 'Notification Types',
        items: [
          ToggleSettingItemSchema(
            title: 'Daily Drop',
            subtitle:
                'Part of the BHAM capped suggestion budget ($maxCappedPerDay/day total).',
            icon: Icons.calendar_view_day_outlined,
            value: dailyDrop,
            onChanged: onDailyDropChanged,
          ),
          ToggleSettingItemSchema(
            title: 'Context Nudges',
            subtitle:
                'Part of the BHAM capped suggestion budget ($maxCappedPerDay/day total).',
            icon: Icons.wb_twilight_outlined,
            value: contextNudges,
            onChanged: onContextNudgesChanged,
          ),
          ToggleSettingItemSchema(
            title: 'AI2AI Compatibility',
            subtitle:
                'Part of the BHAM capped suggestion budget ($maxCappedPerDay/day total).',
            icon: Icons.hub_outlined,
            value: ai2aiCompatibility,
            onChanged: onAi2aiCompatibilityChanged,
          ),
          ToggleSettingItemSchema(
            title: 'Human Messages',
            subtitle:
                'Uncapped by BHAM suggestion policy; still respects device-level mute settings.',
            icon: Icons.chat_bubble_outline,
            value: humanMessages,
            onChanged: onHumanMessagesChanged,
          ),
        ],
      ),
      SettingsGroupSectionSchema(
        title: 'Delivery Methods',
        items: [
          ToggleSettingItemSchema(
            title: 'Push Notifications',
            subtitle: 'Receive updates directly on this device.',
            icon: Icons.notifications_active_outlined,
            value: pushNotifications,
            onChanged: onPushNotificationsChanged,
          ),
          ToggleSettingItemSchema(
            title: 'Email Notifications',
            subtitle: 'Receive updates by email.',
            icon: Icons.email_outlined,
            value: emailNotifications,
            onChanged: onEmailNotificationsChanged,
          ),
        ],
      ),
      SettingsGroupSectionSchema(
        title: 'Quiet Hours',
        items: quietHoursItems,
      ),
      CtaSectionSchema(
        title: 'Test Notifications',
        body:
            'Send a test notification to confirm your current delivery settings.',
        primaryLabel: 'Send Test Notification',
        onPrimaryTap: onSendTestNotification,
      ),
    ],
  );
}

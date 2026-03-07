import 'package:flutter/material.dart';

import 'package:avrai/presentation/schemas/models/page_schema.dart';

PageSchema buildNotificationsSettingsPageSchema({
  required bool spotRecommendations,
  required bool listRespects,
  required bool communityActivity,
  required bool nearbySpots,
  required bool aiLearningUpdates,
  required bool weeklyDigest,
  required bool pushNotifications,
  required bool emailNotifications,
  required bool quietHours,
  required String quietStartLabel,
  required String quietEndLabel,
  required ValueChanged<bool> onSpotRecommendationsChanged,
  required ValueChanged<bool> onListRespectsChanged,
  required ValueChanged<bool> onCommunityActivityChanged,
  required ValueChanged<bool> onNearbySpotsChanged,
  required ValueChanged<bool> onAiLearningUpdatesChanged,
  required ValueChanged<bool> onWeeklyDigestChanged,
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
            title: 'Spot Recommendations',
            subtitle: 'Get notified about places you might like.',
            icon: Icons.location_on_outlined,
            value: spotRecommendations,
            onChanged: onSpotRecommendationsChanged,
          ),
          ToggleSettingItemSchema(
            title: 'List Respects',
            subtitle: 'Know when someone respects your lists.',
            icon: Icons.favorite_outline,
            value: listRespects,
            onChanged: onListRespectsChanged,
          ),
          ToggleSettingItemSchema(
            title: 'Nearby Spots',
            subtitle: 'Receive local discovery suggestions.',
            icon: Icons.near_me_outlined,
            value: nearbySpots,
            onChanged: onNearbySpotsChanged,
          ),
          ToggleSettingItemSchema(
            title: 'Community Activity',
            subtitle: 'Receive updates from your community network.',
            icon: Icons.group_outlined,
            value: communityActivity,
            onChanged: onCommunityActivityChanged,
          ),
          ToggleSettingItemSchema(
            title: 'Learning Updates',
            subtitle: 'See when AVRAI improves your recommendations.',
            icon: Icons.psychology_outlined,
            value: aiLearningUpdates,
            onChanged: onAiLearningUpdatesChanged,
          ),
          ToggleSettingItemSchema(
            title: 'Weekly Digest',
            subtitle: 'Receive a weekly summary of recent activity.',
            icon: Icons.mail_outline,
            value: weeklyDigest,
            onChanged: onWeeklyDigestChanged,
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

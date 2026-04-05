import 'package:flutter/material.dart';

import 'package:avrai/presentation/schemas/models/page_schema.dart';

PageSchema buildPrivacySettingsPageSchema({
  required bool shareLocation,
  required bool ai2aiLearning,
  required bool userRuntimeLearning,
  required bool communityRecommendations,
  required bool publicProfile,
  required bool publicLists,
  required bool analyticsOptIn,
  required bool personalizedAds,
  required bool cloudSyncEnabled,
  required bool isSyncing,
  required String profileVisibility,
  required String locationSharing,
  required String dataRetention,
  required List<String> profileOptions,
  required List<String> locationOptions,
  required List<String> retentionOptions,
  required ValueChanged<String?> onProfileVisibilityChanged,
  required ValueChanged<String?> onLocationSharingChanged,
  required ValueChanged<String?> onDataRetentionChanged,
  required ValueChanged<bool> onShareLocationChanged,
  required ValueChanged<bool> onAi2AiLearningChanged,
  required ValueChanged<bool> onUserRuntimeLearningChanged,
  required ValueChanged<bool> onCommunityRecommendationsChanged,
  required ValueChanged<bool> onCloudSyncChanged,
  required ValueChanged<bool> onPublicProfileChanged,
  required ValueChanged<bool> onPublicListsChanged,
  required ValueChanged<bool> onAnalyticsOptInChanged,
  required ValueChanged<bool> onPersonalizedAdsChanged,
  required VoidCallback onSyncNow,
  required VoidCallback onExportData,
  required VoidCallback onDeleteAccount,
  required VoidCallback onOpenPrivacyPolicy,
  required VoidCallback onResetPrivacySettings,
}) {
  final learningItems = <SettingItemSchema>[
    ToggleSettingItemSchema(
      title: 'AI2AI Learning',
      subtitle: 'Allow anonymized preference signals to improve matching.',
      icon: Icons.psychology_outlined,
      value: ai2aiLearning,
      onChanged: onAi2AiLearningChanged,
    ),
    ToggleSettingItemSchema(
      title: 'On-Device Learning',
      subtitle: 'Let your device adapt recommendations from local behavior.',
      icon: Icons.memory_outlined,
      value: userRuntimeLearning,
      onChanged: onUserRuntimeLearningChanged,
    ),
    ToggleSettingItemSchema(
      title: 'Community Recommendations',
      subtitle: 'Use community patterns to personalize discovery.',
      icon: Icons.group_outlined,
      value: communityRecommendations,
      onChanged: onCommunityRecommendationsChanged,
    ),
    ToggleSettingItemSchema(
      title: 'Sync Profile Across Devices',
      subtitle:
          'Encrypt and sync your profile so it is available on your signed-in devices.',
      icon: Icons.cloud_sync_outlined,
      value: cloudSyncEnabled,
      onChanged: onCloudSyncChanged,
    ),
    if (cloudSyncEnabled)
      ActionSettingItemSchema(
        title: 'Sync now',
        subtitle: isSyncing
            ? 'Syncing your profile now.'
            : 'Start a manual encrypted sync.',
        icon: Icons.sync,
        onTap: isSyncing ? null : onSyncNow,
        trailing: isSyncing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.chevron_right),
      ),
  ];

  return PageSchema(
    title: 'Privacy Settings',
    header: const PageHeaderSchema(
      title: 'Privacy Settings',
      subtitle:
          'Choose how your profile, location, and learning data are shared or retained.',
      leadingIcon: Icons.privacy_tip_outlined,
    ),
    sections: [
      const BannerSectionSchema(
        title: 'Privacy commitment',
        body:
            'You own your data, you control your experience, and you decide what AVRAI can share or retain.',
        icon: Icons.verified_user_outlined,
      ),
      const BannerSectionSchema(
        title: 'What AVRAI shares',
        body:
            'AI2AI learning exchanges anonymized signals, not raw chat content or private notes.',
        icon: Icons.visibility_outlined,
      ),
      SettingsGroupSectionSchema(
        title: 'Core Privacy Controls',
        items: [
          DropdownSettingItemSchema(
            title: 'Profile Visibility',
            subtitle: 'Who can see your profile and activity.',
            icon: Icons.person_outline,
            value: profileVisibility,
            options: profileOptions,
            onChanged: onProfileVisibilityChanged,
          ),
          DropdownSettingItemSchema(
            title: 'Location Sharing',
            subtitle: 'How precise location sharing should be.',
            icon: Icons.location_on_outlined,
            value: locationSharing,
            options: locationOptions,
            onChanged: onLocationSharingChanged,
          ),
          ToggleSettingItemSchema(
            title: 'Share Location Data',
            subtitle: 'Allow location-based recommendations.',
            icon: Icons.share_location_outlined,
            value: shareLocation,
            onChanged: onShareLocationChanged,
          ),
        ],
      ),
      SettingsGroupSectionSchema(
        title: 'Learning Controls',
        subtitle:
            'Control how AVRAI learns from your behavior and preferences.',
        items: learningItems,
      ),
      SettingsGroupSectionSchema(
        title: 'Public Sharing',
        items: [
          ToggleSettingItemSchema(
            title: 'Public Profile',
            subtitle: 'Make your profile visible to everyone.',
            icon: Icons.public_outlined,
            value: publicProfile,
            onChanged: onPublicProfileChanged,
          ),
          ToggleSettingItemSchema(
            title: 'Default Public Lists',
            subtitle: 'Make newly created lists public by default.',
            icon: Icons.format_list_bulleted_outlined,
            value: publicLists,
            onChanged: onPublicListsChanged,
          ),
        ],
      ),
      SettingsGroupSectionSchema(
        title: 'Data and Analytics',
        items: [
          DropdownSettingItemSchema(
            title: 'Data Retention',
            subtitle: 'How long AVRAI keeps your activity history.',
            icon: Icons.schedule_outlined,
            value: dataRetention,
            options: retentionOptions,
            onChanged: onDataRetentionChanged,
          ),
          ToggleSettingItemSchema(
            title: 'Usage Analytics',
            subtitle: 'Share anonymous product usage to improve AVRAI.',
            icon: Icons.analytics_outlined,
            value: analyticsOptIn,
            onChanged: onAnalyticsOptInChanged,
          ),
          ToggleSettingItemSchema(
            title: 'Personalized Ads',
            subtitle: 'Allow ads tailored to your interests.',
            icon: Icons.ad_units_outlined,
            value: personalizedAds,
            onChanged: onPersonalizedAdsChanged,
          ),
        ],
      ),
      ActionListSectionSchema(
        title: 'Your Data Rights',
        actions: [
          ActionSchema(
            title: 'Export My Data',
            subtitle: 'Download a copy of your AVRAI data.',
            icon: Icons.download_outlined,
            onTap: onExportData,
          ),
          ActionSchema(
            title: 'Delete My Account',
            subtitle: 'Permanently remove your account and stored data.',
            icon: Icons.delete_forever_outlined,
            onTap: onDeleteAccount,
          ),
          ActionSchema(
            title: 'Privacy Policy',
            subtitle: 'Read the full privacy policy.',
            icon: Icons.policy_outlined,
            onTap: onOpenPrivacyPolicy,
          ),
        ],
      ),
      CtaSectionSchema(
        title: 'Reset Privacy Settings',
        body: 'Restore all privacy controls to their default values.',
        primaryLabel: 'Reset to defaults',
        onPrimaryTap: onResetPrivacySettings,
      ),
    ],
  );
}

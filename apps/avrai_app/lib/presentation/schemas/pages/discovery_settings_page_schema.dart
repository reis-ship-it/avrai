import 'package:flutter/material.dart';

import 'package:avrai/presentation/schemas/models/page_schema.dart';

PageSchema buildDiscoverySettingsPageSchema({
  required bool discoveryEnabled,
  required bool eventModeEnabled,
  required bool sharePersonalityData,
  required bool discoverWiFi,
  required bool discoverBluetooth,
  required bool discoverMultipeer,
  required bool autoDiscovery,
  required ValueChanged<bool> onDiscoveryEnabledChanged,
  required ValueChanged<bool> onEventModeChanged,
  required ValueChanged<bool> onSharePersonalityDataChanged,
  required ValueChanged<bool> onDiscoverWiFiChanged,
  required ValueChanged<bool> onDiscoverBluetoothChanged,
  required ValueChanged<bool> onDiscoverMultipeerChanged,
  required ValueChanged<bool> onAutoDiscoveryChanged,
  required VoidCallback onShowPrivacyInfo,
}) {
  final sections = <SectionSchema>[
    const BannerSectionSchema(
      title: 'Device Discovery',
      body:
          'Find nearby AVRAI-enabled devices while keeping discovery settings and privacy controls in one place.',
      icon: Icons.radar_outlined,
    ),
    SettingsGroupSectionSchema(
      title: 'Discovery',
      items: [
        ToggleSettingItemSchema(
          title: 'Enable Discovery',
          subtitle: discoveryEnabled
              ? 'Your device is actively discoverable nearby.'
              : 'Discovery is currently turned off.',
          icon: discoveryEnabled ? Icons.radar : Icons.radar_outlined,
          value: discoveryEnabled,
          onChanged: onDiscoveryEnabledChanged,
        ),
        if (discoveryEnabled)
          ToggleSettingItemSchema(
            title: 'Event Mode',
            subtitle: eventModeEnabled
                ? 'Use broadcast-first discovery for short check-in windows.'
                : 'Use normal discovery behavior.',
            icon: eventModeEnabled
                ? Icons.local_activity
                : Icons.local_activity_outlined,
            value: eventModeEnabled,
            onChanged: onEventModeChanged,
          ),
      ],
    ),
  ];

  if (discoveryEnabled) {
    sections.addAll([
      SettingsGroupSectionSchema(
        title: 'Discovery Methods',
        items: [
          ToggleSettingItemSchema(
            title: 'Wi-Fi Direct',
            subtitle: 'Discover devices over Wi-Fi.',
            icon: Icons.wifi,
            value: discoverWiFi,
            onChanged: onDiscoverWiFiChanged,
          ),
          ToggleSettingItemSchema(
            title: 'Bluetooth',
            subtitle: 'Discover devices using Bluetooth.',
            icon: Icons.bluetooth,
            value: discoverBluetooth,
            onChanged: onDiscoverBluetoothChanged,
          ),
          ToggleSettingItemSchema(
            title: 'Multipeer',
            subtitle: 'Use Multipeer Connectivity on supported devices.',
            icon: Icons.devices_outlined,
            value: discoverMultipeer,
            onChanged: onDiscoverMultipeerChanged,
          ),
        ],
      ),
      SettingsGroupSectionSchema(
        title: 'Privacy Settings',
        items: [
          ToggleSettingItemSchema(
            title: 'Share Personality Data',
            subtitle:
                'Share anonymized preference signals during discovery.',
            icon: Icons.psychology_outlined,
            value: sharePersonalityData,
            onChanged: onSharePersonalityDataChanged,
          ),
          ActionSettingItemSchema(
            title: 'Privacy Information',
            subtitle: 'Learn how discovery protects your privacy.',
            icon: Icons.info_outline,
            onTap: onShowPrivacyInfo,
          ),
        ],
      ),
      SettingsGroupSectionSchema(
        title: 'Advanced',
        items: [
          ToggleSettingItemSchema(
            title: 'Auto-Discovery',
            subtitle: 'Start discovery automatically when the app opens.',
            icon: Icons.autorenew,
            value: autoDiscovery,
            onChanged: onAutoDiscoveryChanged,
          ),
        ],
      ),
    ]);
  }

  sections.add(
    const BulletListSectionSchema(
      title: 'About Discovery',
      items: [
        'Discovery uses device radios and may affect battery life.',
        'Only AVRAI-enabled devices can be discovered.',
        'Shared discovery data is anonymized and encrypted.',
        'You can stop discovery at any time.',
        'Some platforms require location permission for discovery.',
      ],
    ),
  );

  return PageSchema(
    title: 'Discovery Settings',
    header: const PageHeaderSchema(
      title: 'Discovery Settings',
      subtitle: 'Control when your device can be discovered nearby.',
      leadingIcon: Icons.radar_outlined,
    ),
    sections: sections,
  );
}

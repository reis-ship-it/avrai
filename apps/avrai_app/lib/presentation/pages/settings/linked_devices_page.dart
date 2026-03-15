import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

import 'package:avrai/presentation/widgets/common/app_empty_state.dart';
import 'package:avrai/presentation/widgets/common/app_info_banner.dart';
import 'package:avrai/presentation/widgets/common/app_status_pill.dart';
import 'package:avrai/presentation/widgets/common/app_surface.dart';
import 'package:avrai/presentation/widgets/common/app_button_primary.dart';
import 'package:avrai/presentation/widgets/common/app_loading_state.dart';
import 'package:avrai/presentation/schema_renderer/app_schema_page.dart';
import 'package:avrai/presentation/schemas/pages/linked_devices_page_schema.dart';
import 'package:avrai/theme/colors.dart';
import 'package:avrai_runtime_os/crypto/signal/device_registration_service.dart';

class LinkedDevicesPage extends StatefulWidget {
  const LinkedDevicesPage({super.key});

  @override
  State<LinkedDevicesPage> createState() => _LinkedDevicesPageState();
}

class _LinkedDevicesPageState extends State<LinkedDevicesPage> {
  final DeviceRegistrationService _deviceService =
      GetIt.I<DeviceRegistrationService>();

  List<RegisteredDevice> _devices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    setState(() => _isLoading = true);

    final currentDevice = _deviceService.currentDevice;
    if (currentDevice != null) {
      final devices = await _deviceService.loadDevicesFromCloud(
        currentDevice.userId,
      );
      setState(() {
        _devices = devices;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppSchemaPage(
      schema: buildLinkedDevicesPageSchema(
        content: _isLoading
            ? const AppLoadingState(label: 'Loading linked devices')
            : _buildBody(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadDevices,
        ),
      ],
      scrollable: false,
    );
  }

  Widget _buildBody() {
    if (_devices.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const AppInfoBanner(
              title: 'Device sync',
              body:
                  'Link a device to access your account and synced profile across supported platforms.',
              icon: Icons.sync_outlined,
            ),
            const SizedBox(height: 24),
            const AppEmptyState(
              title: 'No devices linked',
              body: 'Link a device to sync your data across platforms.',
              icon: Icons.devices_outlined,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: AppButtonPrimary(
                onPressed: () => _showLinkDeviceOptions(context),
                child: const Text('Link Device'),
              ),
            ),
          ],
        ),
      );
    }

    final currentDeviceId = _deviceService.currentDevice?.deviceId;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const AppInfoBanner(
          title: 'Device access',
          body:
              'Active devices can continue syncing. Revoke or remove devices you no longer use.',
          icon: Icons.security_outlined,
        ),
        const SizedBox(height: 16),
        for (final device in _devices) ...[
          _DeviceCard(
            device: device,
            isCurrentDevice: device.deviceId == currentDeviceId,
            onRevoke: () => _revokeDevice(device),
            onRemove: () => _removeDevice(device),
          ),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: AppButtonPrimary(
            onPressed: () => _showLinkDeviceOptions(context),
            child: const Text('Link Device'),
          ),
        ),
      ],
    );
  }

  void _showLinkDeviceOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.pin),
              title: const Text('Show Pairing Code'),
              subtitle: const Text('Display a code to enter on a new device'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/device-link/code');
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Send Push to New Device'),
              subtitle: const Text('Approve the link from a notification'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/device-link/push');
              },
            ),
            ListTile(
              leading: const Icon(Icons.warning_amber),
              title: const Text('Lost Device Recovery'),
              subtitle: const Text('Link a new device without the old one'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/device-link/bypass');
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _revokeDevice(RegisteredDevice device) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke Device?'),
        content: const Text(
          'This device will no longer receive new messages. Existing messages on the device will remain.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.warning),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _deviceService.revokeDevice(device.deviceId);
      await _loadDevices();
    }
  }

  Future<void> _removeDevice(RegisteredDevice device) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Device?'),
        content: Text(
          'This will permanently remove "${device.deviceName}" from your account. The device will need to be linked again to sync.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _deviceService.removeDevice(device.deviceId);
      await _loadDevices();
    }
  }
}

class _DeviceCard extends StatelessWidget {
  final RegisteredDevice device;
  final bool isCurrentDevice;
  final VoidCallback onRevoke;
  final VoidCallback onRemove;

  const _DeviceCard({
    required this.device,
    required this.isCurrentDevice,
    required this.onRevoke,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final lastSeen = DateFormat.yMMMd().add_jm().format(device.lastSeenAt);
    final isActive = device.status == DeviceStatus.active;

    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDeviceIcon(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          device.deviceName,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        if (isCurrentDevice)
                          const AppStatusPill(label: 'This Device'),
                        if (device.isPrimary)
                          const AppStatusPill(
                            label: 'Primary',
                            color: AppColors.warning,
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${device.platform.toUpperCase()} • ${device.deviceModel ?? 'Unknown'}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              AppStatusPill(
                label: isActive ? 'Active' : device.status.name,
                color: isActive ? AppColors.success : AppColors.error,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Last seen: $lastSeen',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textHint,
                    ),
              ),
              if (!isCurrentDevice)
                Row(
                  children: [
                    if (isActive)
                      TextButton(
                        onPressed: onRevoke,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.warning,
                        ),
                        child: const Text('Revoke'),
                      ),
                    TextButton(
                      onPressed: onRemove,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.error,
                      ),
                      child: const Text('Remove'),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceIcon() {
    IconData icon;
    switch (device.platform) {
      case 'ios':
        icon = Icons.phone_iphone;
        break;
      case 'android':
        icon = Icons.phone_android;
        break;
      case 'macos':
        icon = Icons.laptop_mac;
        break;
      case 'windows':
        icon = Icons.laptop_windows;
        break;
      case 'web':
        icon = Icons.web;
        break;
      default:
        icon = Icons.devices;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: AppColors.textSecondary),
    );
  }
}

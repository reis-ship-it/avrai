import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

import 'package:avrai_runtime_os/crypto/signal/device_registration_service.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';
import 'package:avrai/presentation/widgets/common/app_surface.dart';
import 'package:avrai/theme/colors.dart';

/// Linked Devices Page
///
/// Displays all devices linked to the user's account with management options.
///
/// Phase 26: Multi-Device Sync - Device Management UI
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
    return AdaptivePlatformPageScaffold(
      title: 'Linked Devices',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadDevices,
        ),
      ],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildDeviceList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showLinkDeviceOptions(context),
        icon: const Icon(Icons.add_link),
        label: const Text('Link Device'),
      ),
    );
  }

  Widget _buildDeviceList() {
    if (_devices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.devices,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No devices linked',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Link a device to sync your data across platforms',
              style: TextStyle(color: AppColors.textHint),
            ),
          ],
        ),
      );
    }

    final currentDeviceId = _deviceService.currentDevice?.deviceId;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _devices.length,
      itemBuilder: (context, index) {
        final device = _devices[index];
        final isCurrentDevice = device.deviceId == currentDeviceId;

        return _DeviceCard(
          device: device,
          isCurrentDevice: isCurrentDevice,
          onRevoke: () => _revokeDevice(device),
          onRemove: () => _removeDevice(device),
        );
      },
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
              subtitle: const Text('Display a code to enter on new device'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/device-link/code');
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Send Push to New Device'),
              subtitle: const Text('Approve via notification'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/device-link/push');
              },
            ),
            ListTile(
              leading: const Icon(Icons.warning_amber),
              title: const Text('Lost Device Recovery'),
              subtitle: const Text('Link new device without old one'),
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
        content: Text(
          'This device will no longer be able to receive new messages. '
          'Existing messages on the device will remain.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
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
          'This will permanently remove "${device.deviceName}" from your account. '
          'The device will need to be linked again to sync.',
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
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildDeviceIcon(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          device.deviceName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (isCurrentDevice) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'This Device',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                        if (device.isPrimary) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.star,
                              size: 16, color: AppColors.warning),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${device.platform.toUpperCase()} • ${device.deviceModel ?? 'Unknown'}',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(isActive),
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
                style: TextStyle(
                  fontSize: 12,
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: AppColors.textSecondary),
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.success.withValues(alpha: 0.1)
            : AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive ? AppColors.success : AppColors.error,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            isActive ? 'Active' : device.status.name,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? AppColors.success : AppColors.error,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

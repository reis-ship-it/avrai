import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

import 'package:avrai/core/crypto/signal/device_registration_service.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/tokens/theme_tokens.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';
import 'package:avrai/presentation/widgets/portal/portal_surface.dart';

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
          : _buildDeviceList(context),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showLinkDeviceOptions(context),
        icon: const Icon(Icons.add_link),
        label: const Text('Link Device'),
      ),
    );
  }

  Widget _buildDeviceList(BuildContext context) {
    final spacing = context.spacing;
    final textTheme = Theme.of(context).textTheme;

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
            SizedBox(height: spacing.md),
            Text(
              'No devices linked',
              style: textTheme.titleLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: spacing.xs),
            Text(
              'Link a device to sync your data across platforms',
              style: textTheme.bodyMedium?.copyWith(color: AppColors.textHint),
            ),
          ],
        ),
      );
    }

    final currentDeviceId = _deviceService.currentDevice?.deviceId;

    return ListView.builder(
      padding: EdgeInsets.all(spacing.md),
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
    final spacing = context.spacing;
    final textTheme = Theme.of(context).textTheme;
    final lastSeen = DateFormat.yMMMd().add_jm().format(device.lastSeenAt);
    final isActive = device.status == DeviceStatus.active;

    return PortalSurface(
      margin: EdgeInsets.only(bottom: spacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildDeviceIcon(context),
              SizedBox(width: spacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          device.deviceName,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (isCurrentDevice) ...[
                          SizedBox(width: spacing.xs),
                          Chip(
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            side: BorderSide.none,
                            backgroundColor:
                                AppColors.primary.withValues(alpha: 0.1),
                            labelPadding: EdgeInsets.zero,
                            label: Text(
                              'This Device',
                              style: textTheme.bodySmall?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                        if (device.isPrimary) ...[
                          SizedBox(width: spacing.xs),
                          const Icon(Icons.star,
                              size: 16, color: AppColors.warning),
                        ],
                      ],
                    ),
                    SizedBox(height: spacing.xxs),
                    Text(
                      '${device.platform.toUpperCase()} • ${device.deviceModel ?? 'Unknown'}',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(context, isActive),
            ],
          ),
          SizedBox(height: spacing.sm),
          const Divider(height: 1),
          SizedBox(height: spacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Last seen: $lastSeen',
                style: textTheme.bodySmall?.copyWith(
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

  Widget _buildDeviceIcon(BuildContext context) {
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

    final spacing = context.spacing;

    return SizedBox(
      width: spacing.xl,
      height: spacing.xl,
      child: PortalSurface(
        padding: EdgeInsets.zero,
        color: AppColors.surface,
        borderColor: AppColors.grey300,
        radius: context.radius.sm,
        child: Icon(icon, color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, bool isActive) {
    final textTheme = Theme.of(context).textTheme;
    return Chip(
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      side: BorderSide.none,
      backgroundColor: isActive
          ? AppColors.success.withValues(alpha: 0.1)
          : AppColors.error.withValues(alpha: 0.1),
      labelPadding: EdgeInsets.zero,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 4,
            backgroundColor: isActive ? AppColors.success : AppColors.error,
          ),
          SizedBox(width: context.spacing.xxs),
          Text(
            isActive ? 'Active' : device.status.name,
            style: textTheme.bodySmall?.copyWith(
              color: isActive ? AppColors.success : AppColors.error,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

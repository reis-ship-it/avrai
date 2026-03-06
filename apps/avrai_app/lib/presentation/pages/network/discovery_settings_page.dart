/// Discovery Settings Page
///
/// Part of Feature Matrix Phase 1: Critical UI/UX Features
///
/// Allows users to configure device discovery settings:
/// - Scan interval (how often to scan for devices)
/// - Device timeout (how long before removing stale devices)
///
/// Uses AppColors and AppTheme for consistent styling per design token requirements.
library;

import 'package:flutter/material.dart';
import 'package:avrai/theme/colors.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai_network/network/device_discovery.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';
import 'package:avrai/presentation/widgets/common/app_page_header.dart';
import 'package:avrai/presentation/widgets/common/app_surface.dart';

/// Page for configuring device discovery settings
class DiscoverySettingsPage extends StatefulWidget {
  const DiscoverySettingsPage({super.key});

  @override
  State<DiscoverySettingsPage> createState() => _DiscoverySettingsPageState();
}

class _DiscoverySettingsPageState extends State<DiscoverySettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _scanIntervalController = TextEditingController();
  final _deviceTimeoutController = TextEditingController();
  final _storageService = StorageService.instance;

  static const String _scanIntervalKey = 'discovery_scan_interval';
  static const String _deviceTimeoutKey = 'discovery_device_timeout';

  // Default values
  static const int defaultScanInterval = 5; // seconds
  static const int defaultDeviceTimeout = 2; // minutes

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _scanIntervalController.dispose();
    _deviceTimeoutController.dispose();
    super.dispose();
  }

  void _loadSettings() {
    final scanInterval =
        _storageService.getInt(_scanIntervalKey) ?? defaultScanInterval;
    final deviceTimeout =
        _storageService.getInt(_deviceTimeoutKey) ?? defaultDeviceTimeout;

    _scanIntervalController.text = scanInterval.toString();
    _deviceTimeoutController.text = deviceTimeout.toString();
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final scanInterval = int.parse(_scanIntervalController.text);
      final deviceTimeout = int.parse(_deviceTimeoutController.text);
      var transportApplyWarning = false;

      // Save to storage
      await _storageService.setInt(_scanIntervalKey, scanInterval);
      await _storageService.setInt(_deviceTimeoutKey, deviceTimeout);

      // Apply to discovery service if it's running
      try {
        final discoveryService = GetIt.instance<DeviceDiscoveryService>();
        // Stop and restart with new settings
        discoveryService.stopDiscovery();
        await discoveryService.startDiscovery(
          scanInterval: Duration(seconds: scanInterval),
          deviceTimeout: Duration(minutes: deviceTimeout),
        );
      } catch (_) {
        // Settings are saved locally even if live transport apply fails.
        transportApplyWarning = true;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              transportApplyWarning
                  ? 'Settings saved. Transport service will use them on next discovery start.'
                  : 'Settings saved successfully',
            ),
            backgroundColor:
                transportApplyWarning ? AppColors.warning : AppColors.success,
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String? _validateScanInterval(String? value) {
    if (value == null || value.isEmpty) {
      return 'Scan interval is required';
    }
    final interval = int.tryParse(value);
    if (interval == null) {
      return 'Must be a valid number';
    }
    if (interval < 1) {
      return 'Must be at least 1 second';
    }
    if (interval > 300) {
      return 'Must be at most 300 seconds';
    }
    return null;
  }

  String? _validateDeviceTimeout(String? value) {
    if (value == null || value.isEmpty) {
      return 'Device timeout is required';
    }
    final timeout = int.tryParse(value);
    if (timeout == null) {
      return 'Must be a valid number';
    }
    if (timeout < 1) {
      return 'Must be at least 1 minute';
    }
    if (timeout > 60) {
      return 'Must be at most 60 minutes';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AdaptivePlatformPageScaffold(
      title: 'Discovery Settings',
      appBarBackgroundColor: AppColors.black,
      appBarForegroundColor: AppColors.white,
      constrainBody: false,
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppPageHeader(
                title: 'Device Discovery Configuration',
                subtitle:
                    'Configure how often AVRAI scans for nearby devices and how long they remain in the list.',
                leadingIcon: Icons.radar_outlined,
                showDivider: false,
              ),
              const SizedBox(height: 16),
              AppSurface(
                radius: 10,
                color: AppColors.primary.withValues(alpha: 0.05),
                padding: const EdgeInsets.all(12),
                child: Semantics(
                  label: 'Discovery privacy summary',
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.privacy_tip, color: AppColors.primary),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Discovery uses anonymized compatibility signals only. '
                          'You can stop discovery anytime from the AI2AI Network screen.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              AppSurface(
                radius: 12,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Scan Interval',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'How often to scan for nearby devices (in seconds)',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _scanIntervalController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Seconds',
                        hintText: '5',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: AppColors.grey100,
                      ),
                      validator: _validateScanInterval,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Recommended: 5-10 seconds for active discovery',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textHint,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppSurface(
                radius: 12,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Device Timeout',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'How long to keep discovered devices before removing them (in minutes)',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _deviceTimeoutController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Minutes',
                        hintText: '2',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: AppColors.grey100,
                      ),
                      validator: _validateDeviceTimeout,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Recommended: 2-5 minutes to balance freshness and stability',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textHint,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Semantics(
                button: true,
                label: 'Save discovery settings',
                hint: 'Applies scan interval and device timeout values.',
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveSettings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(48, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Save',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:avrai/presentation/widgets/common/app_button_primary.dart';
import 'package:avrai/presentation/widgets/common/app_button_secondary.dart';
import 'package:avrai_core/models/misc/cross_app_learning_insight.dart'
    hide PermissionStatus;
import 'package:avrai_runtime_os/services/cross_app/cross_app_consent_service.dart';
import 'package:avrai/injection_container.dart' as di;
import 'package:avrai/presentation/widgets/common/app_surface.dart';
import 'package:avrai/presentation/schema_renderer/app_schema_page.dart';
import 'package:avrai/presentation/schemas/pages/combined_permissions_page_schema.dart';
import 'package:avrai/theme/colors.dart';

/// Step 3: Combined Permissions page.
///
/// Requests ALL required permissions at once:
/// - Location (REQUIRED - blocking)
/// - Bluetooth/WiFi for AI2AI (MANDATORY - no opt-out, but non-blocking)
/// - Background location (RECOMMENDED)
class CombinedPermissionsPage extends StatefulWidget {
  /// Callback when permission status changes
  final ValueChanged<Map<Permission, PermissionStatus>> onPermissionsChanged;

  /// Callback when location permission is granted (enables proceeding)
  final ValueChanged<bool> onLocationGranted;

  const CombinedPermissionsPage({
    super.key,
    required this.onPermissionsChanged,
    required this.onLocationGranted,
  });

  @override
  State<CombinedPermissionsPage> createState() =>
      _CombinedPermissionsPageState();
}

class _CombinedPermissionsPageState extends State<CombinedPermissionsPage> {
  Map<Permission, PermissionStatus> _statuses = {};
  bool _isLoading = false;
  bool _hasCheckedPermissions = false;

  // Cross-app consent state (opt-out model - all enabled by default)
  CrossAppConsentService? _consentService;
  Map<CrossAppDataSource, bool> _crossAppConsents = {
    CrossAppDataSource.calendar: true,
    CrossAppDataSource.health: true,
    CrossAppDataSource.media: true,
    CrossAppDataSource.appUsage: true,
  };

  @override
  void initState() {
    super.initState();
    _checkCurrentPermissions();
    _initCrossAppConsent();
  }

  @override
  void dispose() {
    // Complete cross-app onboarding when leaving this page
    _completeCrossAppOnboarding();
    super.dispose();
  }

  Future<void> _initCrossAppConsent() async {
    try {
      if (di.sl.isRegistered<CrossAppConsentService>()) {
        _consentService = di.sl<CrossAppConsentService>();
        await _consentService!.initialize();

        // Load current consent states (defaults to enabled for opt-out model)
        final consents = await _consentService!.getAllConsents();
        if (mounted) {
          setState(() {
            _crossAppConsents = consents;
          });
        }
      }
    } catch (e) {
      // Non-blocking - consent service initialization is optional
    }
  }

  Future<void> _handleCrossAppConsentChange(
      CrossAppDataSource source, bool enabled) async {
    setState(() {
      _crossAppConsents[source] = enabled;
    });

    if (_consentService != null) {
      await _consentService!.setEnabled(source, enabled);
    }
  }

  Future<void> _completeCrossAppOnboarding() async {
    if (_consentService != null) {
      // Save all consent choices
      for (final entry in _crossAppConsents.entries) {
        await _consentService!.setEnabled(entry.key, entry.value);
      }
      // Mark onboarding as completed
      await _consentService!.completeOnboarding();
    }
  }

  Future<void> _checkCurrentPermissions() async {
    if (kIsWeb) {
      setState(() {
        _hasCheckedPermissions = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final statuses = <Permission, PermissionStatus>{};

      // Check location permissions
      if (Platform.isMacOS || Platform.isIOS) {
        final permission = await Geolocator.checkPermission();
        statuses[Permission.locationWhenInUse] =
            _geolocatorToPermissionStatus(permission);
        statuses[Permission.locationAlways] =
            permission == LocationPermission.always
                ? PermissionStatus.granted
                : PermissionStatus.denied;
      } else {
        statuses[Permission.locationWhenInUse] =
            await Permission.locationWhenInUse.status;
        statuses[Permission.locationAlways] =
            await Permission.locationAlways.status;
      }

      // Check Bluetooth permissions
      // Note: On macOS, Bluetooth is granted via entitlements, not runtime permissions
      if (Platform.isMacOS) {
        // macOS: Bluetooth is handled via entitlements (already configured)
        // Mark as granted since entitlements are set
        for (final p in [
          Permission.bluetooth,
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
          Permission.bluetoothAdvertise,
        ]) {
          statuses[p] = PermissionStatus.granted;
        }
        // WiFi/Local Network on macOS is also entitlement-based
        statuses[Permission.nearbyWifiDevices] = PermissionStatus.granted;
      } else {
        for (final p in [
          Permission.bluetooth,
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
          Permission.bluetoothAdvertise,
        ]) {
          try {
            statuses[p] = await p.status;
          } catch (e) {
            statuses[p] = PermissionStatus.denied;
          }
        }

        // Check WiFi permission
        try {
          statuses[Permission.nearbyWifiDevices] =
              await Permission.nearbyWifiDevices.status;
        } catch (e) {
          statuses[Permission.nearbyWifiDevices] = PermissionStatus.denied;
        }
      }

      if (mounted) {
        setState(() {
          _statuses = statuses;
          _hasCheckedPermissions = true;
        });
        widget.onPermissionsChanged(statuses);
        widget.onLocationGranted(_isLocationGranted);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  PermissionStatus _geolocatorToPermissionStatus(
      LocationPermission permission) {
    switch (permission) {
      case LocationPermission.always:
      case LocationPermission.whileInUse:
        return PermissionStatus.granted;
      case LocationPermission.deniedForever:
        return PermissionStatus.permanentlyDenied;
      case LocationPermission.denied:
      case LocationPermission.unableToDetermine:
        return PermissionStatus.denied;
    }
  }

  bool get _isLocationGranted {
    final status = _statuses[Permission.locationWhenInUse];
    return status?.isGranted ?? false;
  }

  bool get _isAI2AIFullyGranted {
    final bluetoothPermissions = [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
    ];
    final wifiGranted =
        _statuses[Permission.nearbyWifiDevices]?.isGranted ?? false;
    final bluetoothGranted = bluetoothPermissions.every(
      (p) => _statuses[p]?.isGranted ?? false,
    );
    return bluetoothGranted && wifiGranted;
  }

  Future<void> _requestAllPermissions() async {
    if (kIsWeb) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Request location first
      if (Platform.isMacOS || Platform.isIOS) {
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Please enable Location Services in your device settings.'),
              duration: Duration(seconds: 4),
            ),
          );
        }

        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }

        if (permission == LocationPermission.deniedForever && mounted) {
          // On macOS, openAppSettings() is not supported - use our custom method
          await _openSettings();
        }
      } else {
        // Android
        await Permission.locationWhenInUse.request();

        // Request locationAlways after locationWhenInUse is granted
        final whenInUseStatus = await Permission.locationWhenInUse.status;
        if (whenInUseStatus.isGranted) {
          await Permission.locationAlways.request();
        }
      }

      // 2. Request Bluetooth permissions (mandatory but non-blocking)
      // Note: On macOS, Bluetooth/WiFi are entitlement-based, not runtime permissions
      if (!Platform.isMacOS) {
        for (final p in [
          Permission.bluetooth,
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
          Permission.bluetoothAdvertise,
        ]) {
          try {
            await p.request();
          } catch (e) {
            // Continue even if individual permission fails
          }
        }

        // 3. Request WiFi permission
        try {
          await Permission.nearbyWifiDevices.request();
        } catch (e) {
          // Continue even if WiFi permission fails
        }
      }
      // On macOS, Bluetooth and WiFi are already granted via entitlements

      // Refresh statuses
      await _checkCurrentPermissions();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openSettings() async {
    if (Platform.isMacOS) {
      // macOS: Open System Settings > Privacy & Security > Location Services
      // Note: openAppSettings() is not supported on macOS
      final uri = Uri.parse(
          'x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices');
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          // Fallback: try to open general Privacy settings
          final fallbackUri = Uri.parse(
              'x-apple.systempreferences:com.apple.preference.security?Privacy');
          if (await canLaunchUrl(fallbackUri)) {
            await launchUrl(fallbackUri);
          }
        }
      } catch (e) {
        // Show manual instructions if URL launch fails
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Please open System Settings > Privacy & Security > Location Services'),
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    } else {
      await openAppSettings();
    }

    // Check permissions again after returning from settings
    await Future.delayed(const Duration(milliseconds: 500));
    await _checkCurrentPermissions();
  }

  @override
  Widget build(BuildContext context) {
    return AppSchemaPage(
      schema: buildCombinedPermissionsPageSchema(
        corePermissionsSection: _buildCorePermissionsSection(),
        consentSection: _buildCrossAppConsentSection(context),
        statusActionsSection: _buildStatusActionsSection(),
      ),
      padding: const EdgeInsets.all(16),
    );
  }

  Widget _buildCorePermissionsSection() {
    return Column(
      children: [
        _buildPermissionGroup(
          icon: Icons.location_on,
          title: 'Location Access',
          subtitle: 'Show nearby spots and set your homebase',
          status: _getPermissionGroupStatus([Permission.locationWhenInUse]),
          isRequired: true,
          permissions: [Permission.locationWhenInUse],
        ),
        const SizedBox(height: 16),
        _buildPermissionGroup(
          icon: Icons.bluetooth,
          title: 'AI Network (Bluetooth)',
          subtitle: 'Enable your AI to learn from nearby AIs',
          status: _getPermissionGroupStatus([
            Permission.bluetooth,
            Permission.bluetoothScan,
            Permission.bluetoothConnect,
            Permission.bluetoothAdvertise,
          ]),
          isMandatory: true,
          permissions: [
            Permission.bluetooth,
            Permission.bluetoothScan,
            Permission.bluetoothConnect,
            Permission.bluetoothAdvertise,
          ],
        ),
        const SizedBox(height: 16),
        _buildPermissionGroup(
          icon: Icons.wifi,
          title: 'Enhanced Discovery (WiFi)',
          subtitle: 'Improve AI network connectivity',
          status: _getPermissionGroupStatus([Permission.nearbyWifiDevices]),
          isMandatory: true,
          permissions: [Permission.nearbyWifiDevices],
        ),
        const SizedBox(height: 16),
        _buildPermissionGroup(
          icon: Icons.my_location,
          title: 'Background Location',
          subtitle: 'Get proactive recommendations even when app is closed',
          status: _getPermissionGroupStatus([Permission.locationAlways]),
          isRecommended: true,
          permissions: [Permission.locationAlways],
        ),
      ],
    );
  }

  Widget _buildStatusActionsSection() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_hasCheckedPermissions)
          AppSurface(
            borderColor:
                _isLocationGranted ? AppColors.success : AppColors.warning,
            child: Row(
              children: [
                Icon(
                  _isLocationGranted ? Icons.check_circle : Icons.info_outline,
                  color: _isLocationGranted
                      ? AppColors.success
                      : AppColors.warning,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _isLocationGranted
                        ? (_isAI2AIFullyGranted
                            ? 'All permissions granted. Your AI is ready!'
                            : 'Location granted. AI network may have limited connectivity.')
                        : 'Location access is required to continue.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: _isLocationGranted
                          ? AppColors.success
                          : AppColors.warning,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (_hasCheckedPermissions &&
            _isLocationGranted &&
            !_isAI2AIFullyGranted)
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.35),
              ),
            ),
            child: Semantics(
              label: 'AI2AI permissions guidance',
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: AppColors.warning),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'You can continue with location access, but AI2AI discovery may be limited until Bluetooth and WiFi permissions are granted.',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 24),
        if (!_isLocationGranted || !_isAI2AIFullyGranted)
          Semantics(
            button: true,
            label: 'Enable all required permissions',
            hint:
                'Requests location, Bluetooth, and WiFi permissions for AI2AI functionality.',
            child: SizedBox(
              width: double.infinity,
              child: AppButtonPrimary(
                onPressed: _isLoading ? null : _requestAllPermissions,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Enable All Permissions'),
              ),
            ),
          ),
        const SizedBox(height: 12),
        Semantics(
          button: true,
          label: 'Open system settings for permissions',
          child: SizedBox(
            width: double.infinity,
            child: AppButtonSecondary(
              onPressed: _openSettings,
              child: const Text('Open System Settings'),
            ),
          ),
        ),
        if (Platform.isMacOS || Platform.isIOS)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    Platform.isMacOS
                        ? 'On macOS, Bluetooth and WiFi permissions may require configuration in System Settings > Privacy & Security.'
                        : 'Some permissions may require configuration in Settings > Privacy.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPermissionGroup({
    required IconData icon,
    required String title,
    required String subtitle,
    required _PermissionGroupStatus status,
    required List<Permission> permissions,
    bool isRequired = false,
    bool isMandatory = false,
    bool isRecommended = false,
  }) {
    final theme = Theme.of(context);

    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status) {
      case _PermissionGroupStatus.granted:
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle;
        statusText = 'Granted';
      case _PermissionGroupStatus.partial:
        statusColor = AppColors.warning;
        statusIcon = Icons.warning_amber;
        statusText = 'Partial';
      case _PermissionGroupStatus.denied:
        statusColor = isRequired ? AppColors.error : AppColors.textSecondary;
        statusIcon = isRequired ? Icons.error : Icons.radio_button_unchecked;
        statusText = isRequired ? 'Required' : 'Not granted';
    }

    return AppSurface(
      padding: EdgeInsets.zero,
      borderColor: status == _PermissionGroupStatus.granted
          ? AppColors.success.withValues(alpha: 0.5)
          : AppColors.borderSubtle,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.textSecondary),
        ),
        title: Row(
          children: [
            Text(
              title,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (isRequired)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Required',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            if (isMandatory && !isRequired)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Mandatory',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            if (isRecommended)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.grey600.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Recommended',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.grey600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(statusIcon, color: statusColor, size: 20),
            const SizedBox(width: 4),
            Text(
              statusText,
              style: theme.textTheme.bodySmall?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCrossAppConsentSection(BuildContext context) {
    return AppSurface(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _buildConsentToggle(
            context: context,
            source: CrossAppDataSource.calendar,
            icon: Icons.calendar_today,
            title: 'Calendar',
            subtitle: 'Learn from your schedule and event types',
          ),
          const Divider(height: 1),
          _buildConsentToggle(
            context: context,
            source: CrossAppDataSource.health,
            icon: Icons.favorite,
            title: 'Health & Fitness',
            subtitle: 'Understand your activity and energy levels',
          ),
          const Divider(height: 1),
          _buildConsentToggle(
            context: context,
            source: CrossAppDataSource.media,
            icon: Icons.music_note,
            title: 'Music & Media',
            subtitle: 'Detect your mood from what you listen to',
          ),
          if (Platform.isAndroid) ...[
            const Divider(height: 1),
            _buildConsentToggle(
              context: context,
              source: CrossAppDataSource.appUsage,
              icon: Icons.phone_android,
              title: 'App Usage',
              subtitle: 'Learn from your app usage patterns',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConsentToggle({
    required BuildContext context,
    required CrossAppDataSource source,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);
    final isEnabled = _crossAppConsents[source] ?? true;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isEnabled ? AppColors.surfaceMuted : AppColors.grey200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isEnabled ? AppColors.textPrimary : AppColors.grey500,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
          color: isEnabled ? null : AppColors.grey600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      trailing: Switch.adaptive(
        value: isEnabled,
        onChanged: (value) => _handleCrossAppConsentChange(source, value),
        activeTrackColor: AppColors.textPrimary,
      ),
    );
  }

  _PermissionGroupStatus _getPermissionGroupStatus(
      List<Permission> permissions) {
    if (!_hasCheckedPermissions) {
      return _PermissionGroupStatus.denied;
    }

    int grantedCount = 0;
    for (final p in permissions) {
      if (_statuses[p]?.isGranted ?? false) {
        grantedCount++;
      }
    }

    if (grantedCount == permissions.length) {
      return _PermissionGroupStatus.granted;
    } else if (grantedCount > 0) {
      return _PermissionGroupStatus.partial;
    } else {
      return _PermissionGroupStatus.denied;
    }
  }
}

enum _PermissionGroupStatus {
  granted,
  partial,
  denied,
}

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:avrai/core/design/feedback_presenter.dart';
import 'package:avrai/core/theme/colors.dart';

import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:avrai/core/services/cross_app/cross_app_consent_service.dart';
import 'package:avrai/injection_container.dart' as di;
import 'package:avrai/presentation/widgets/portal/portal_surface.dart';
import 'package:avrai/core/theme/tokens/theme_tokens.dart';

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
          FeedbackPresenter.showSnack(
            context,
            message: 'Please enable Location Services in your device settings.',
            kind: FeedbackKind.warning,
            duration: const Duration(seconds: 4),
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
          FeedbackPresenter.showSnack(
            context,
            message:
                'Please open System Settings > Privacy & Security > Location Services',
            kind: FeedbackKind.warning,
            duration: const Duration(seconds: 5),
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
    final theme = Theme.of(context);
    final spacing = context.spacing;

    return SingleChildScrollView(
      padding: EdgeInsets.all(spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Enable Your AI',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: spacing.xs),
          Text(
            'avrai needs a few permissions to personalize your experience and connect you with the AI network.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: spacing.lg),

          // Privacy Card
          PortalSurface(
            padding: EdgeInsets.all(spacing.md),
            color: AppColors.primaryLight.withValues(alpha: 0.1),
            borderColor: AppColors.primaryLight.withValues(alpha: 0.3),
            radius: context.radius.md,
            child: Row(
              children: [
                Icon(Icons.shield, color: AppColors.primary),
                SizedBox(width: spacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Privacy is Protected',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: spacing.xxs),
                      Text(
                        'All AI learning happens on-device. Your personal data is never shared.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: spacing.xl),

          // Permission Groups
          _buildPermissionGroup(
            context: context,
            icon: Icons.location_on,
            title: 'Location Access',
            subtitle: 'Show nearby spots and set your homebase',
            status: _getPermissionGroupStatus([Permission.locationWhenInUse]),
            isRequired: true,
            permissions: [Permission.locationWhenInUse],
          ),

          SizedBox(height: spacing.md),

          _buildPermissionGroup(
            context: context,
            icon: Icons.bluetooth,
            title: 'AI Network (Bluetooth)',
            subtitle: 'Enable your AI to learn from nearby AIs',
            status: _getPermissionGroupStatus([
              Permission.bluetooth,
              Permission.bluetoothScan,
              Permission.bluetoothConnect,
              Permission.bluetoothAdvertise,
            ]),
            isRequired: false,
            isMandatory: true,
            permissions: [
              Permission.bluetooth,
              Permission.bluetoothScan,
              Permission.bluetoothConnect,
              Permission.bluetoothAdvertise,
            ],
          ),

          SizedBox(height: spacing.md),

          _buildPermissionGroup(
            context: context,
            icon: Icons.wifi,
            title: 'Enhanced Discovery (WiFi)',
            subtitle: 'Improve AI network connectivity',
            status: _getPermissionGroupStatus([Permission.nearbyWifiDevices]),
            isRequired: false,
            isMandatory: true,
            permissions: [Permission.nearbyWifiDevices],
          ),

          SizedBox(height: spacing.md),

          _buildPermissionGroup(
            context: context,
            icon: Icons.my_location,
            title: 'Background Location',
            subtitle: 'Get proactive recommendations even when app is closed',
            status: _getPermissionGroupStatus([Permission.locationAlways]),
            isRequired: false,
            isRecommended: true,
            permissions: [Permission.locationAlways],
          ),

          SizedBox(height: spacing.xl),

          // Cross-App AI Learning Sources Section
          _buildCrossAppConsentSection(context),

          SizedBox(height: spacing.xl),

          // Status Summary
          if (_hasCheckedPermissions)
            PortalSurface(
              padding: EdgeInsets.all(spacing.md),
              color: _isLocationGranted
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.warning.withValues(alpha: 0.1),
              borderColor:
                  _isLocationGranted ? AppColors.success : AppColors.warning,
              radius: context.radius.md,
              child: Row(
                children: [
                  Icon(
                    _isLocationGranted
                        ? Icons.check_circle
                        : Icons.info_outline,
                    color: _isLocationGranted
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                  SizedBox(width: spacing.sm),
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

          SizedBox(height: spacing.lg),

          // Action Buttons
          if (!_isLocationGranted || !_isAI2AIFullyGranted)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _requestAllPermissions,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.security),
                label: Text(
                    _isLoading ? 'Requesting...' : 'Enable All Permissions'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: spacing.md),
                ),
              ),
            ),

          SizedBox(height: spacing.sm),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openSettings,
              icon: const Icon(Icons.settings),
              label: const Text('Open System Settings'),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: spacing.md),
              ),
            ),
          ),

          // Platform-specific note
          if (Platform.isMacOS || Platform.isIOS)
            Padding(
              padding: EdgeInsets.only(top: spacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(width: spacing.xs),
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
      ),
    );
  }

  Widget _buildPermissionGroup({
    required BuildContext context,
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
    final spacing = context.spacing;

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

    return PortalSurface(
      padding: EdgeInsets.zero,
      borderColor: status == _PermissionGroupStatus.granted
          ? AppColors.success.withValues(alpha: 0.5)
          : AppColors.grey300,
      child: ListTile(
        contentPadding:
            EdgeInsets.symmetric(horizontal: spacing.md, vertical: spacing.xs),
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.primaryLight.withValues(alpha: 0.2),
          child: Icon(icon, color: AppColors.primary),
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
                padding: EdgeInsets.only(left: spacing.xs),
                child: Chip(
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  side: BorderSide.none,
                  backgroundColor: AppColors.error.withValues(alpha: 0.1),
                  labelPadding: EdgeInsets.zero,
                  label: Text(
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
                padding: EdgeInsets.only(left: spacing.xs),
                child: Chip(
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  side: BorderSide.none,
                  backgroundColor: AppColors.warning.withValues(alpha: 0.1),
                  labelPadding: EdgeInsets.zero,
                  label: Text(
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
                padding: EdgeInsets.only(left: spacing.xs),
                child: Chip(
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  side: BorderSide.none,
                  backgroundColor: AppColors.grey600.withValues(alpha: 0.1),
                  labelPadding: EdgeInsets.zero,
                  label: Text(
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
            SizedBox(width: spacing.xxs),
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
    final theme = Theme.of(context);
    final spacing = context.spacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          children: [
            Icon(Icons.apps, color: AppColors.primary, size: 24),
            SizedBox(width: spacing.xs),
            Text(
              'AI Learning Sources',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Chip(
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              side: BorderSide.none,
              backgroundColor: AppColors.grey200,
              labelPadding: EdgeInsets.zero,
              label: Text(
                'Optional',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.grey600,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: spacing.xs),
        Text(
          'Your AI can learn from these sources to better understand your preferences. All processing happens on-device.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: spacing.md),

        // Cross-App Consent Toggles
        PortalSurface(
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
              // App Usage - Android only
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
        ),
      ],
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
    final spacing = context.spacing;
    final isEnabled = _crossAppConsents[source] ?? true;

    return ListTile(
      contentPadding:
          EdgeInsets.symmetric(horizontal: spacing.md, vertical: spacing.xxs),
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: isEnabled
            ? AppColors.primaryLight.withValues(alpha: 0.2)
            : AppColors.grey200,
        child: Icon(
          icon,
          color: isEnabled ? AppColors.primary : AppColors.grey500,
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
        activeTrackColor: AppColors.primary,
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

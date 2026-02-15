/// Discovery Settings Page
///
/// Part of Feature Matrix Phase 1: Critical UI/UX
/// Section 1.2: Device Discovery UI
///
/// Allows users to control device discovery settings and privacy preferences.
///
/// Features:
/// - Enable/disable discovery toggle
/// - Discovery method preferences (WiFi, Bluetooth, etc.)
/// - Privacy settings (personality data sharing)
/// - Auto-discovery options
/// - Discovery range settings
/// - Privacy explanations
///
/// Uses AppColors and AppTheme for consistent styling per design token requirements.
library;

import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avrai/core/services/infrastructure/storage_service.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/tokens/theme_tokens.dart';
import 'package:avrai/core/ai/personality_learning.dart';
import 'package:avrai/core/ai2ai/connection_orchestrator.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';
import 'package:avrai/presentation/widgets/portal/portal_surface.dart';

/// Settings page for device discovery configuration
class DiscoverySettingsPage extends StatefulWidget {
  const DiscoverySettingsPage({super.key});

  @override
  State<DiscoverySettingsPage> createState() => _DiscoverySettingsPageState();
}

class _DiscoverySettingsPageState extends State<DiscoverySettingsPage> {
  final _storageService = StorageService.instance;
  static const String _logName = 'DiscoverySettingsPage';

  // Discovery settings
  bool _discoveryEnabled = false;
  bool _autoDiscovery = false;
  bool _sharePersonalityData = true;
  bool _discoverWiFi = true;
  bool _discoverBluetooth = true;
  bool _discoverMultipeer = true;
  bool _eventModeEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    setState(() {
      _discoveryEnabled = _storageService.getBool('discovery_enabled') ?? false;
      _autoDiscovery = _storageService.getBool('auto_discovery') ?? false;
      _sharePersonalityData =
          _storageService.getBool('share_personality_data') ?? true;
      _discoverWiFi = _storageService.getBool('discover_wifi') ?? true;
      _discoverBluetooth =
          _storageService.getBool('discover_bluetooth') ?? true;
      _discoverMultipeer =
          _storageService.getBool('discover_multipeer') ?? true;
      _eventModeEnabled =
          _storageService.getBool('event_mode_enabled') ?? false;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    await _storageService.setBool(key, value);
  }

  Future<void> _applyDiscoveryRuntime(bool enabled) async {
    try {
      final orchestrator = GetIt.instance<VibeConnectionOrchestrator>();
      if (!enabled) {
        await orchestrator.shutdown();
        return;
      }

      final authState = context.read<AuthBloc>().state;
      if (authState is! Authenticated) return;

      final userId = authState.user.id;
      final personalityLearning = GetIt.instance<PersonalityLearning>();
      final profile = await personalityLearning.getCurrentPersonality(userId) ??
          await personalityLearning.initializePersonality(userId);
      await orchestrator.initializeOrchestration(userId, profile);
    } catch (e, st) {
      developer.log(
        'Failed to apply discovery runtime',
        name: _logName,
        error: e,
        stackTrace: st,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdaptivePlatformPageScaffold(
      title: 'Discovery Settings',
      constrainBody: false,
      body: ListView(
        children: [
          _buildHeaderSection(),
          _buildMainToggle(),
          if (_discoveryEnabled) ...[
            _buildEventModeToggle(),
            _buildDiscoveryMethodsSection(),
            _buildPrivacySection(),
            _buildAdvancedSection(),
          ],
          _buildInfoSection(),
        ],
      ),
    );
  }

  Widget _buildEventModeToggle() {
    final spacing = context.spacing;
    final textTheme = Theme.of(context).textTheme;
    return PortalSurface(
      margin:
          EdgeInsets.symmetric(horizontal: spacing.md, vertical: spacing.xs),
      padding: EdgeInsets.zero,
      child: SwitchListTile(
        title: Text(
          'Event Mode (Broadcast-First)',
          style: textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          _eventModeEnabled
              ? 'Uses connectionless room sensing; deep sync only in short check-in windows'
              : 'Normal discovery behavior',
          style: textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        value: _eventModeEnabled,
        onChanged: (value) async {
          setState(() {
            _eventModeEnabled = value;
          });
          await _saveSetting('event_mode_enabled', value);
        },
        activeThumbColor: AppColors.electricGreen,
        secondary: Icon(
          _eventModeEnabled
              ? Icons.local_activity
              : Icons.local_activity_outlined,
          color:
              _eventModeEnabled ? AppColors.electricGreen : AppColors.grey300,
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    final spacing = context.spacing;
    final textTheme = Theme.of(context).textTheme;
    return PortalSurface(
      padding: EdgeInsets.all(spacing.md + spacing.xs),
      margin: EdgeInsets.all(spacing.md),
      color: AppColors.electricGreen.withValues(alpha: 0.1),
      borderColor: AppColors.electricGreen.withValues(alpha: 0.24),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.white,
            child: Icon(
              Icons.radar,
              size: 32,
              color: AppColors.electricGreen,
            ),
          ),
          SizedBox(width: spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Device Discovery',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: spacing.xxs),
                Text(
                  'Find nearby avrai-enabled devices',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainToggle() {
    final spacing = context.spacing;
    final textTheme = Theme.of(context).textTheme;
    return PortalSurface(
      margin:
          EdgeInsets.symmetric(horizontal: spacing.md, vertical: spacing.xs),
      padding: EdgeInsets.zero,
      child: SwitchListTile(
        title: Text(
          'Enable Discovery',
          style: textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          _discoveryEnabled
              ? 'Actively discovering nearby devices'
              : 'Discovery is turned off',
          style: textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        value: _discoveryEnabled,
        onChanged: (value) async {
          setState(() {
            _discoveryEnabled = value;
          });
          await _saveSetting('discovery_enabled', value);
          await _applyDiscoveryRuntime(value);
        },
        activeThumbColor: AppColors.electricGreen,
        secondary: Icon(
          _discoveryEnabled ? Icons.radar : Icons.radar_outlined,
          color:
              _discoveryEnabled ? AppColors.electricGreen : AppColors.grey300,
        ),
      ),
    );
  }

  Widget _buildDiscoveryMethodsSection() {
    final spacing = context.spacing;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
              spacing.xl, spacing.lg, spacing.xl, spacing.sm),
          child: Text(
            'Discovery Methods',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        PortalSurface(
          margin: EdgeInsets.symmetric(horizontal: spacing.md),
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('WiFi Direct'),
                subtitle: const Text('Discover devices over WiFi'),
                value: _discoverWiFi,
                onChanged: (value) async {
                  setState(() {
                    _discoverWiFi = value;
                  });
                  await _saveSetting('discover_wifi', value);
                },
                activeThumbColor: AppColors.electricGreen,
                secondary: const Icon(Icons.wifi, color: AppColors.primary),
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('Bluetooth'),
                subtitle: const Text('Discover devices via Bluetooth'),
                value: _discoverBluetooth,
                onChanged: (value) async {
                  setState(() {
                    _discoverBluetooth = value;
                  });
                  await _saveSetting('discover_bluetooth', value);
                },
                activeThumbColor: AppColors.electricGreen,
                secondary:
                    const Icon(Icons.bluetooth, color: AppColors.primary),
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('Multipeer'),
                subtitle: const Text('iOS Multipeer Connectivity'),
                value: _discoverMultipeer,
                onChanged: (value) async {
                  setState(() {
                    _discoverMultipeer = value;
                  });
                  await _saveSetting('discover_multipeer', value);
                },
                activeThumbColor: AppColors.electricGreen,
                secondary: const Icon(Icons.devices, color: AppColors.primary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrivacySection() {
    final spacing = context.spacing;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
              spacing.xl, spacing.lg, spacing.xl, spacing.sm),
          child: Row(
            children: [
              Text(
                'Privacy Settings',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(width: spacing.xs),
              const Icon(
                Icons.lock_outline,
                size: 20,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
        PortalSurface(
          margin: EdgeInsets.symmetric(horizontal: spacing.md),
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Share Personality Data'),
                subtitle: const Text(
                  'Allow AI personality data to be discoverable (anonymized)',
                ),
                value: _sharePersonalityData,
                onChanged: (value) async {
                  setState(() {
                    _sharePersonalityData = value;
                  });
                  await _saveSetting('share_personality_data', value);
                },
                activeThumbColor: AppColors.electricGreen,
                secondary: const Icon(
                  Icons.psychology,
                  color: AppColors.primary,
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(
                  Icons.info_outline,
                  color: AppColors.primary,
                ),
                title: const Text('Privacy Information'),
                subtitle: const Text('Learn about data sharing and privacy'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _showPrivacyInfoDialog,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdvancedSection() {
    final spacing = context.spacing;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
              spacing.xl, spacing.lg, spacing.xl, spacing.sm),
          child: Text(
            'Advanced',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        PortalSurface(
          margin: EdgeInsets.symmetric(horizontal: spacing.md),
          padding: EdgeInsets.zero,
          child: SwitchListTile(
            title: const Text('Auto-Discovery'),
            subtitle: const Text(
              'Automatically start discovery when app opens',
            ),
            value: _autoDiscovery,
            onChanged: (value) async {
              setState(() {
                _autoDiscovery = value;
              });
              await _saveSetting('auto_discovery', value);
            },
            activeThumbColor: AppColors.electricGreen,
            secondary: const Icon(
              Icons.autorenew,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection() {
    final spacing = context.spacing;
    final textTheme = Theme.of(context).textTheme;

    return PortalSurface(
      margin: EdgeInsets.all(spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_outline,
                size: 20,
                color: AppColors.warning,
              ),
              SizedBox(width: spacing.xs),
              Text(
                'About Discovery',
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.sm),
          Text(
            '• Discovery uses device radios (WiFi/Bluetooth) and may affect battery life\n'
            '• Only avrai-enabled devices can be discovered\n'
            '• All data shared is anonymized and encrypted\n'
            '• You can stop discovery at any time\n'
            '• Discovery requires location permissions on some platforms',
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  void _showPrivacyInfoDialog() {
    final spacing = context.spacing;
    final textTheme = Theme.of(context).textTheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(
              Icons.lock_outline,
              color: AppColors.electricGreen,
            ),
            SizedBox(width: spacing.sm),
            Text(
              'Privacy & Security',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'How Discovery Protects Your Privacy:',
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: spacing.sm),
              _buildPrivacyPoint(
                Icons.shield_outlined,
                'Anonymization',
                'No personal information (name, email, phone) is ever shared during discovery.',
              ),
              SizedBox(height: spacing.sm),
              _buildPrivacyPoint(
                Icons.lock,
                'Encryption',
                'All discovery data is encrypted using end-to-end encryption.',
              ),
              SizedBox(height: spacing.sm),
              _buildPrivacyPoint(
                Icons.psychology,
                'AI Personality Only',
                'Only anonymized AI personality patterns are shared - never your actual conversations or data.',
              ),
              SizedBox(height: spacing.sm),
              _buildPrivacyPoint(
                Icons.verified_user,
                'You Control Discovery',
                'Discovery can be turned on/off anytime. When off, your device is invisible to others.',
              ),
              SizedBox(height: spacing.md),
              PortalSurface(
                padding: EdgeInsets.all(spacing.sm),
                color: AppColors.electricGreen.withValues(alpha: 0.1),
                borderColor: AppColors.electricGreen.withValues(alpha: 0.3),
                radius: context.radius.sm,
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: AppColors.electricGreen,
                      size: 20,
                    ),
                    SizedBox(width: spacing.xs),
                    Expanded(
                      child: Text(
                        'All discovery follows ai2ai privacy principles from OUR_GUTS.md',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyPoint(IconData icon, String title, String description) {
    final spacing = context.spacing;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.primary,
        ),
        SizedBox(width: spacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: spacing.xxs),
              Text(
                description,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

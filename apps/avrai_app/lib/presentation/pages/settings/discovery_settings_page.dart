library;

import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/presentation/schema_renderer/app_schema_page.dart';
import 'package:avrai/presentation/schemas/pages/discovery_settings_page_schema.dart';
import 'package:avrai/theme/colors.dart';
import 'package:avrai_runtime_os/ai/personality_learning.dart';
import 'package:avrai_runtime_os/ai2ai/connection_orchestrator.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';

class DiscoverySettingsPage extends StatefulWidget {
  const DiscoverySettingsPage({super.key});

  @override
  State<DiscoverySettingsPage> createState() => _DiscoverySettingsPageState();
}

class _DiscoverySettingsPageState extends State<DiscoverySettingsPage> {
  final _storageService = StorageService.instance;
  static const String _logName = 'DiscoverySettingsPage';

  bool _discoveryEnabled = false;
  bool _autoDiscovery = false;
  bool _sharePersonalityData = true;
  bool _discoverWiFi = false;
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
      _discoverWiFi = _storageService.getBool('discover_wifi') ?? false;
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
    return AppSchemaPage(
      schema: buildDiscoverySettingsPageSchema(
        discoveryEnabled: _discoveryEnabled,
        eventModeEnabled: _eventModeEnabled,
        sharePersonalityData: _sharePersonalityData,
        discoverWiFi: _discoverWiFi,
        discoverBluetooth: _discoverBluetooth,
        discoverMultipeer: _discoverMultipeer,
        autoDiscovery: _autoDiscovery,
        onDiscoveryEnabledChanged: (value) async {
          setState(() {
            _discoveryEnabled = value;
          });
          await _saveSetting('discovery_enabled', value);
          await _applyDiscoveryRuntime(value);
        },
        onEventModeChanged: (value) async {
          setState(() {
            _eventModeEnabled = value;
          });
          await _saveSetting('event_mode_enabled', value);
        },
        onSharePersonalityDataChanged: (value) async {
          setState(() {
            _sharePersonalityData = value;
          });
          await _saveSetting('share_personality_data', value);
        },
        onDiscoverWiFiChanged: (value) async {
          setState(() {
            _discoverWiFi = value;
          });
          await _saveSetting('discover_wifi', value);
        },
        onDiscoverBluetoothChanged: (value) async {
          setState(() {
            _discoverBluetooth = value;
          });
          await _saveSetting('discover_bluetooth', value);
        },
        onDiscoverMultipeerChanged: (value) async {
          setState(() {
            _discoverMultipeer = value;
          });
          await _saveSetting('discover_multipeer', value);
        },
        onAutoDiscoveryChanged: (value) async {
          setState(() {
            _autoDiscovery = value;
          });
          await _saveSetting('auto_discovery', value);
        },
        onShowPrivacyInfo: _showPrivacyInfoDialog,
      ),
    );
  }

  void _showPrivacyInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(
              Icons.lock_outline,
              color: AppColors.primary,
            ),
            SizedBox(width: 12),
            Text('Privacy & Security'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'How Discovery Protects Your Privacy:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildPrivacyPoint(
                Icons.shield_outlined,
                'Anonymization',
                'No personal information is shared during discovery.',
              ),
              const SizedBox(height: 12),
              _buildPrivacyPoint(
                Icons.lock,
                'Encryption',
                'Discovery data is encrypted end to end.',
              ),
              const SizedBox(height: 12),
              _buildPrivacyPoint(
                Icons.psychology,
                'Preference Signals Only',
                'AVRAI only exchanges anonymized preference signals, never raw conversations or private notes.',
              ),
              const SizedBox(height: 12),
              _buildPrivacyPoint(
                Icons.verified_user,
                'You Control Discovery',
                'You can turn discovery on or off at any time. When off, your device is not discoverable.',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Discovery only shares anonymized signals and never raw personal content.',
                        style: TextStyle(
                          fontSize: 12,
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 13,
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

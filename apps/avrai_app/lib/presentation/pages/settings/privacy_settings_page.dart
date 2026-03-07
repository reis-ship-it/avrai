// MIGRATION_SHIM: LEGACY_PATH_GUARD TEMPORARY UNTIL TARGET-ROOT MIGRATION
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage_x/flutter_secure_storage_x.dart';
import 'package:avrai/injection_container.dart' as di;
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/presentation/schema_renderer/app_schema_page.dart';
import 'package:avrai/presentation/schemas/pages/privacy_settings_page_schema.dart';
import 'package:avrai/theme/colors.dart';
import 'package:avrai_runtime_os/controllers/sync_controller.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:avrai_runtime_os/services/matching/personality_sync_service.dart';

class PrivacySettingsPage extends StatefulWidget {
  const PrivacySettingsPage({super.key});

  @override
  State<PrivacySettingsPage> createState() => _PrivacySettingsPageState();
}

class _PrivacySettingsPageState extends State<PrivacySettingsPage> {
  bool _shareLocation = true;
  bool _ai2aiLearning = true;
  bool _userRuntimeLearning = true;
  bool _communityRecommendations = true;
  bool _publicProfile = false;
  bool _publicLists = false;
  bool _analyticsOptIn = false;
  bool _personalizedAds = false;
  bool _cloudSyncEnabled = false;

  late PersonalitySyncService _syncService;
  late SyncController _syncController;
  final _storageService = di.sl<StorageService>();
  String? _currentUserId;
  bool _isSyncing = false;

  String _profileVisibility = 'Friends Only';
  String _locationSharing = 'Precise';
  String _dataRetention = '1 Year';

  final List<String> _profileOptions = ['Private', 'Friends Only', 'Public'];
  final List<String> _locationOptions = [
    'Precise',
    'Approximate',
    'City Only',
    'Disabled',
  ];
  final List<String> _retentionOptions = [
    '3 Months',
    '6 Months',
    '1 Year',
    '2 Years',
    'Forever',
  ];

  @override
  void initState() {
    super.initState();
    _syncService = di.sl<PersonalitySyncService>();
    _syncController = di.sl<SyncController>();
    _loadCloudSyncSetting();
    _loadAi2AiLearningSetting();
    _loadUserRuntimeLearningSetting();
  }

  void _loadAi2AiLearningSetting() {
    try {
      final enabled = _storageService.getBool('ai2ai_learning_enabled') ?? true;
      _ai2aiLearning = enabled;
    } catch (e, st) {
      developer.log(
        'Failed to load AI2AI learning preference, defaulting to enabled',
        name: 'PrivacySettingsPage',
        error: e,
        stackTrace: st,
      );
      _ai2aiLearning = true;
    }
  }

  void _handleAi2AiLearningToggle(bool value) {
    setState(() => _ai2aiLearning = value);
    Future<void>(() async {
      try {
        await _storageService.setBool('ai2ai_learning_enabled', value);
      } catch (e, st) {
        developer.log(
          'Failed to persist AI2AI learning preference',
          name: 'PrivacySettingsPage',
          error: e,
          stackTrace: st,
        );
      }
    });
  }

  void _loadUserRuntimeLearningSetting() {
    try {
      final enabled =
          _storageService.getBool('user_runtime_learning_enabled') ?? true;
      _userRuntimeLearning = enabled;
    } catch (e, st) {
      developer.log(
        'Failed to load user runtime learning preference, defaulting to enabled',
        name: 'PrivacySettingsPage',
        error: e,
        stackTrace: st,
      );
      _userRuntimeLearning = true;
    }
  }

  void _handleUserRuntimeLearningToggle(bool value) {
    setState(() => _userRuntimeLearning = value);
    Future<void>(() async {
      try {
        await _storageService.setBool('user_runtime_learning_enabled', value);
      } catch (e, st) {
        developer.log(
          'Failed to persist user runtime learning preference',
          name: 'PrivacySettingsPage',
          error: e,
          stackTrace: st,
        );
      }
    });
  }

  Future<void> _loadCloudSyncSetting() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      _currentUserId = authState.user.id;
      final enabled = await _syncService.isCloudSyncEnabled(_currentUserId!);
      if (mounted) {
        setState(() {
          _cloudSyncEnabled = enabled;
        });
      }
    }
  }

  Future<void> _handleCloudSyncToggle(bool value) async {
    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to enable cloud sync'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (value) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Enable Cloud Sync'),
          content: const Text(
            'This will encrypt and sync your profile to the cloud so it is available on your signed-in devices. Only you can decrypt the synced data.\n\nDo you want to enable cloud sync?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Enable'),
            ),
          ],
        ),
      );

      if (confirmed != true) {
        return;
      }
    }

    try {
      await _syncService.setCloudSyncEnabled(value);
      if (mounted) {
        setState(() {
          _cloudSyncEnabled = value;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value
                  ? 'Cloud sync enabled. Your profile will stay in sync across devices.'
                  : 'Cloud sync disabled.',
            ),
            backgroundColor: value ? AppColors.success : AppColors.grey600,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating cloud sync: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleSyncNow() async {
    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to sync your data'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    String? password;
    try {
      const secureStorage = FlutterSecureStorage();
      password = await secureStorage.read(
        key: 'user_password_session_$_currentUserId',
      );
    } catch (e) {
      developer.log(
        'Password not available in secure storage',
        name: 'PrivacySettingsPage',
        error: e,
      );
    }

    if (password == null || password.isEmpty) {
      password = await _promptForPassword();
      if (password == null || password.isEmpty) {
        return;
      }
    }

    setState(() {
      _isSyncing = true;
    });

    try {
      final result = await _syncController.syncUserData(
        userId: _currentUserId!,
        password: password,
        scope: SyncScope.personality,
      );

      if (mounted) {
        setState(() {
          _isSyncing = false;
        });

        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sync completed successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sync failed: ${result.error ?? "Unknown error"}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error syncing: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<String?> _promptForPassword() async {
    final passwordController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Password'),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Password',
            hintText: 'Enter your password to sync',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (passwordController.text.isNotEmpty) {
                Navigator.pop(context, passwordController.text);
              }
            },
            child: const Text('Sync'),
          ),
        ],
      ),
    );

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return AppSchemaPage(
      schema: buildPrivacySettingsPageSchema(
        shareLocation: _shareLocation,
        ai2aiLearning: _ai2aiLearning,
        userRuntimeLearning: _userRuntimeLearning,
        communityRecommendations: _communityRecommendations,
        publicProfile: _publicProfile,
        publicLists: _publicLists,
        analyticsOptIn: _analyticsOptIn,
        personalizedAds: _personalizedAds,
        cloudSyncEnabled: _cloudSyncEnabled,
        isSyncing: _isSyncing,
        profileVisibility: _profileVisibility,
        locationSharing: _locationSharing,
        dataRetention: _dataRetention,
        profileOptions: _profileOptions,
        locationOptions: _locationOptions,
        retentionOptions: _retentionOptions,
        onProfileVisibilityChanged: (value) {
          if (value != null) {
            setState(() => _profileVisibility = value);
          }
        },
        onLocationSharingChanged: (value) {
          if (value != null) {
            setState(() => _locationSharing = value);
          }
        },
        onDataRetentionChanged: (value) {
          if (value != null) {
            setState(() => _dataRetention = value);
          }
        },
        onShareLocationChanged: (value) =>
            setState(() => _shareLocation = value),
        onAi2AiLearningChanged: _handleAi2AiLearningToggle,
        onUserRuntimeLearningChanged: _handleUserRuntimeLearningToggle,
        onCommunityRecommendationsChanged: (value) =>
            setState(() => _communityRecommendations = value),
        onCloudSyncChanged: _handleCloudSyncToggle,
        onPublicProfileChanged: (value) =>
            setState(() => _publicProfile = value),
        onPublicListsChanged: (value) => setState(() => _publicLists = value),
        onAnalyticsOptInChanged: (value) =>
            setState(() => _analyticsOptIn = value),
        onPersonalizedAdsChanged: (value) =>
            setState(() => _personalizedAds = value),
        onSyncNow: _handleSyncNow,
        onExportData: _exportData,
        onDeleteAccount: _showDeleteAccountDialog,
        onOpenPrivacyPolicy: _openPrivacyPolicy,
        onResetPrivacySettings: _resetPrivacySettings,
      ),
    );
  }

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Data export initiated. You will receive an email with download instructions.',
        ),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to permanently delete your account? This action cannot be undone and will remove all your data, spots, and lists.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Account deletion requires additional verification. Check your email.',
                  ),
                  backgroundColor: AppColors.error,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }

  void _openPrivacyPolicy() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening privacy policy...'),
      ),
    );
  }

  void _resetPrivacySettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Privacy Settings'),
        content: const Text(
          'This will reset all privacy settings to their default values. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _shareLocation = true;
                _ai2aiLearning = true;
                _userRuntimeLearning = true;
                _communityRecommendations = true;
                _publicProfile = false;
                _publicLists = false;
                _analyticsOptIn = false;
                _personalizedAds = false;
                _profileVisibility = 'Friends Only';
                _locationSharing = 'Precise';
                _dataRetention = '1 Year';
              });
              Navigator.pop(context);
              Future<void>(() async {
                try {
                  await _storageService.setBool('ai2ai_learning_enabled', true);
                  await _storageService.setBool(
                    'user_runtime_learning_enabled',
                    true,
                  );
                } catch (e, st) {
                  developer.log(
                    'Failed to persist reset privacy defaults',
                    name: 'PrivacySettingsPage',
                    error: e,
                    stackTrace: st,
                  );
                }
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Privacy settings reset to defaults'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}

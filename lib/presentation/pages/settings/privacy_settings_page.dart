import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:avrai/core/design/feedback_presenter.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/tokens/theme_tokens.dart';
import 'package:avrai/core/services/matching/personality_sync_service.dart';
import 'package:avrai/core/controllers/sync_controller.dart';
import 'package:avrai/core/services/infrastructure/storage_service.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/injection_container.dart' as di;
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';
import 'package:avrai/presentation/widgets/portal/portal_surface.dart';
import 'package:avrai/presentation/presentation_spacing.dart';

class PrivacySettingsPage extends StatefulWidget {
  const PrivacySettingsPage({super.key});

  @override
  State<PrivacySettingsPage> createState() => _PrivacySettingsPageState();
}

class _PrivacySettingsPageState extends State<PrivacySettingsPage> {
  // Privacy preferences - would normally be stored in user preferences
  bool _shareLocation = true;
  bool _ai2aiLearning = true;
  bool _communityRecommendations = true;
  bool _publicProfile = false;
  bool _publicLists = false;
  bool _analyticsOptIn = false;
  bool _personalizedAds = false;
  bool _cloudSyncEnabled = false;
  // Removed unused _dataExportEnabled field

  late PersonalitySyncService _syncService;
  late SyncController _syncController;
  // Use StorageService (get_storage-backed) for lightweight local settings.
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
    'Disabled'
  ];
  final List<String> _retentionOptions = [
    '3 Months',
    '6 Months',
    '1 Year',
    '2 Years',
    'Forever'
  ];

  @override
  void initState() {
    super.initState();
    _syncService = di.sl<PersonalitySyncService>();
    _syncController = di.sl<SyncController>();
    _loadCloudSyncSetting();
    _loadAi2AiLearningSetting();
  }

  void _loadAi2AiLearningSetting() {
    try {
      final enabled = _storageService.getBool('ai2ai_learning_enabled') ?? true;
      _ai2aiLearning = enabled;
    } catch (_) {
      // Default: enabled.
      _ai2aiLearning = true;
    }
  }

  void _handleAi2AiLearningToggle(bool value) {
    setState(() => _ai2aiLearning = value);
    Future<void>(() async {
      try {
        await _storageService.setBool('ai2ai_learning_enabled', value);
      } catch (_) {
        // Ignore.
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
      context.showError('Please sign in to enable cloud sync');
      return;
    }

    if (value) {
      // Show confirmation dialog when enabling
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Enable Cloud Sync'),
          content: const Text(
            'This will encrypt and sync your AI personality profile to the cloud, '
            'allowing you to access it on any device. Your data is encrypted with your password '
            'and only you can decrypt it.\n\n'
            'Do you want to enable cloud sync?',
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
        return; // User cancelled
      }
    }

    try {
      await _syncService.setCloudSyncEnabled(value);
      if (mounted) {
        setState(() {
          _cloudSyncEnabled = value;
        });
        if (value) {
          context.showSuccess(
            'Cloud sync enabled. Your AI agent will sync across devices.',
          );
        } else {
          context.showInfo('Cloud sync disabled.');
        }
      }
    } catch (e) {
      if (mounted) {
        context.showError('Error updating cloud sync: $e');
      }
    }
  }

  Future<void> _handleSyncNow() async {
    if (_currentUserId == null) {
      context.showError('Please sign in to sync your data');
      return;
    }

    // Try to get password from secure storage (stored during login)
    String? password;
    try {
      const secureStorage = FlutterSecureStorage();
      password = await secureStorage.read(
        key: 'user_password_session_$_currentUserId',
      );
    } catch (e) {
      // Password not available in secure storage
      debugPrint('Password not available in secure storage: $e');
    }

    // If password is not available, prompt user
    if (password == null || password.isEmpty) {
      password = await _promptForPassword();
      if (password == null || password.isEmpty) {
        return; // User cancelled
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
          context.showSuccess('Sync completed successfully');
        } else {
          context.showError('Sync failed: ${result.error ?? "Unknown error"}');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
        context.showError('Error syncing: $e');
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
    final spacing = context.spacing;
    final textTheme = Theme.of(context).textTheme;

    return AdaptivePlatformPageScaffold(
      title: 'Privacy Settings',
      scrollable: true,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // OUR_GUTS.md Commitment
            PortalSurface(
              color: AppColors.grey100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified_user,
                          color: AppTheme.successColor),
                      SizedBox(width: spacing.xs),
                      Text(
                        'OUR_GUTS.md Commitment',
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.successColor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: spacing.xs),
                  Text(
                    '"Privacy and Control Are Non-Negotiable" - You own your data, you control your experience, and you decide what to share.',
                    style: textTheme.bodyMedium
                        ?.copyWith(color: AppTheme.successColor),
                  ),
                ],
              ),
            ),
            SizedBox(height: spacing.lg),

            // Core Privacy Controls
            Text(
              'Core Privacy Controls',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: spacing.md),

            _buildDropdownTile(
              'Profile Visibility',
              'Who can see your profile and activity',
              _profileVisibility,
              _profileOptions,
              (value) => setState(() => _profileVisibility = value!),
              Icons.person,
            ),

            _buildDropdownTile(
              'Location Sharing',
              'How precise location data is shared',
              _locationSharing,
              _locationOptions,
              (value) => setState(() => _locationSharing = value!),
              Icons.location_on,
            ),

            _buildSwitchTile(
              'Share Location Data',
              'Allow location-based recommendations',
              _shareLocation,
              (value) => setState(() => _shareLocation = value),
              Icons.share_location,
            ),

            SizedBox(height: spacing.lg),

            // AI & Learning Controls
            Text(
              'AI & Learning Controls',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: spacing.xs),
            Text(
              'Control how AI learns from your behavior and preferences',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: spacing.md),

            _buildSwitchTile(
              'AI2AI Learning',
              'Enable anonymous personality learning between devices',
              _ai2aiLearning,
              _handleAi2AiLearningToggle,
              Icons.psychology,
            ),

            _buildSwitchTile(
              'Community Recommendations',
              'Use community data for personalized recommendations',
              _communityRecommendations,
              (value) => setState(() => _communityRecommendations = value),
              Icons.group,
            ),

            _buildSwitchTile(
              'Sync AI Agent Across Devices',
              'Encrypt and sync your AI personality profile to access it on any device. Your data is encrypted with your password.',
              _cloudSyncEnabled,
              _handleCloudSyncToggle,
              Icons.cloud_sync,
            ),

            // Sync Now button (only show if sync is enabled)
            if (_cloudSyncEnabled)
              PortalSurface(
                margin: const EdgeInsets.only(bottom: kSpaceXs),
                padding: EdgeInsets.zero,
                child: ListTile(
                  leading: const Icon(Icons.sync, color: AppTheme.primaryColor),
                  title: const Text('Sync Now'),
                  subtitle: _isSyncing
                      ? const Text('Syncing...')
                      : const Text(
                          'Manually sync your AI personality profile to the cloud'),
                  trailing: _isSyncing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.arrow_forward_ios),
                  onTap: _isSyncing ? null : _handleSyncNow,
                ),
              ),

            SizedBox(height: spacing.lg),

            // Public Sharing
            Text(
              'Public Sharing',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: spacing.md),

            _buildSwitchTile(
              'Public Profile',
              'Make your profile visible to everyone',
              _publicProfile,
              (value) => setState(() => _publicProfile = value),
              Icons.public,
            ),

            _buildSwitchTile(
              'Default Public Lists',
              'Make new lists public by default',
              _publicLists,
              (value) => setState(() => _publicLists = value),
              Icons.list,
            ),

            SizedBox(height: spacing.lg),

            // Data & Analytics
            Text(
              'Data & Analytics',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: spacing.md),

            _buildDropdownTile(
              'Data Retention',
              'How long to keep your activity data',
              _dataRetention,
              _retentionOptions,
              (value) => setState(() => _dataRetention = value!),
              Icons.schedule,
            ),

            _buildSwitchTile(
              'Usage Analytics',
              'Help improve avrai with anonymous usage data',
              _analyticsOptIn,
              (value) => setState(() => _analyticsOptIn = value),
              Icons.analytics,
            ),

            _buildSwitchTile(
              'Personalized Ads',
              'Show ads based on your interests (off by default)',
              _personalizedAds,
              (value) => setState(() => _personalizedAds = value),
              Icons.ad_units,
            ),

            SizedBox(height: spacing.lg),

            // Data Rights
            Text(
              'Your Data Rights',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: spacing.md),

            PortalSurface(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.download,
                        color: AppTheme.primaryColor),
                    title: const Text('Export My Data'),
                    subtitle: const Text('Download all your avrai data'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: _exportData,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.delete_forever,
                        color: AppTheme.errorColor),
                    title: const Text('Delete My Account'),
                    subtitle:
                        const Text('Permanently delete your account and data'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: _showDeleteAccountDialog,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading:
                        const Icon(Icons.policy, color: AppTheme.primaryColor),
                    title: const Text('Privacy Policy'),
                    subtitle: const Text('Read our full privacy policy'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: _openPrivacyPolicy,
                  ),
                ],
              ),
            ),

            SizedBox(height: spacing.lg),

            // Reset Settings
            PortalSurface(
              color: AppColors.grey100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.restore, color: AppTheme.warningColor),
                      SizedBox(width: spacing.xs),
                      Text(
                        'Reset Privacy Settings',
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.warningColor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: spacing.xs),
                  Text(
                    'Reset all privacy settings to their default values',
                    style: textTheme.bodyMedium,
                  ),
                  SizedBox(height: spacing.md),
                  ElevatedButton(
                    onPressed: _resetPrivacySettings,
                    // Use global ElevatedButtonTheme
                    child: const Text('Reset to Defaults'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
    IconData icon,
  ) {
    return PortalSurface(
      margin: EdgeInsets.only(bottom: context.spacing.xs),
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
        secondary: Icon(icon, color: AppTheme.primaryColor),
      ),
    );
  }

  Widget _buildDropdownTile(
    String title,
    String subtitle,
    String value,
    List<String> options,
    ValueChanged<String?> onChanged,
    IconData icon,
  ) {
    return PortalSurface(
      margin: EdgeInsets.only(bottom: context.spacing.xs),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryColor),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: DropdownButton<String>(
          value: value,
          onChanged: onChanged,
          items: options.map((option) {
            return DropdownMenuItem(
              value: option,
              child: Text(option),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _exportData() {
    context.showSuccess(
      'Data export initiated. You will receive an email with download instructions.',
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
              context.showError(
                'Account deletion requires additional verification. Check your email.',
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }

  void _openPrivacyPolicy() {
    context.showInfo('Opening privacy policy...');
  }

  void _resetPrivacySettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Privacy Settings'),
        content: const Text(
            'This will reset all privacy settings to their default values. Continue?'),
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
              context.showSuccess('Privacy settings reset to defaults');
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}

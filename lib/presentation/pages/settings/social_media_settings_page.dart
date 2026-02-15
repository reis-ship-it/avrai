import 'package:flutter/material.dart';
import 'package:avrai/core/design/feedback_presenter.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/tokens/theme_tokens.dart';
import 'package:go_router/go_router.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';
import 'package:avrai/presentation/widgets/portal/portal_surface.dart';

/// Social Media Settings Page
/// Allows users to manage their social media connections
/// Users can connect, disconnect, and view connection status
class SocialMediaSettingsPage extends StatefulWidget {
  const SocialMediaSettingsPage({super.key});

  @override
  State<SocialMediaSettingsPage> createState() =>
      _SocialMediaSettingsPageState();
}

class _SocialMediaSettingsPageState extends State<SocialMediaSettingsPage> {
  // TODO: Replace with actual service call when Phase 12 backend is ready
  final Map<String, bool> _connectedPlatforms = {
    'Instagram': false,
    'Facebook': false,
    'Twitter': false,
    'Google': false,
    'Reddit': false,
    'TikTok': false,
    'Tumblr': false,
    'YouTube': false,
    'Pinterest': false,
    'Are.na': false,
    'LinkedIn': false,
  };

  bool _isConnecting = false;
  String? _connectingPlatform;

  @override
  void initState() {
    super.initState();
    _loadConnections();
  }

  Future<void> _loadConnections() async {
    // TODO: Load actual connections from SocialMediaConnectionService
    // For now, this is a placeholder
    setState(() {
      // In real implementation, this would fetch from service
    });
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final textTheme = Theme.of(context).textTheme;
    return AdaptivePlatformPageScaffold(
      title: 'Social Media Connections',
      constrainBody: false,
      body: Padding(
        padding: EdgeInsets.all(spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Manage Social Media Connections',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: spacing.xs),
            Text(
              'Connect your social accounts to enhance your AI personality and discover friends who use avrai.',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.grey600,
              ),
            ),
            SizedBox(height: spacing.md),
            // Friend Discovery Link
            PortalSurface(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              padding: EdgeInsets.zero,
              child: InkWell(
                onTap: () => context.go('/friends/discover'),
                child: Padding(
                  padding: EdgeInsets.all(spacing.md),
                  child: Row(
                    children: [
                      const Icon(Icons.people, color: AppTheme.primaryColor),
                      SizedBox(width: spacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Find Friends on avrai',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            SizedBox(height: spacing.xxs),
                            Text(
                              'Discover friends who use avrai from your social connections',
                              style: textTheme.bodySmall?.copyWith(
                                color: AppColors.grey700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios,
                          size: 16, color: AppTheme.primaryColor),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: spacing.lg),
            Expanded(
              child: ListView(
                children: _connectedPlatforms.entries.map((entry) {
                  final platform = entry.key;
                  final isConnected = entry.value;
                  return PortalSurface(
                    margin: EdgeInsets.only(bottom: spacing.sm),
                    padding: EdgeInsets.zero,
                    child: ListTile(
                      leading: _getPlatformIcon(platform),
                      title: Text(platform),
                      subtitle: Text(
                        isConnected
                            ? 'Connected • Enhancing your AI personality'
                            : 'Not connected • Tap to connect',
                        style: textTheme.bodySmall?.copyWith(
                          color: isConnected
                              ? AppColors.success
                              : AppColors.grey600,
                        ),
                      ),
                      trailing: _isConnecting && _connectingPlatform == platform
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Switch(
                              value: isConnected,
                              onChanged: _isConnecting
                                  ? null
                                  : (value) {
                                      if (value) {
                                        _connectPlatform(platform);
                                      } else {
                                        _disconnectPlatform(platform);
                                      }
                                    },
                            ),
                    ),
                  );
                }).toList(),
              ),
            ),
            SizedBox(height: spacing.md),
            PortalSurface(
              color: AppColors.electricBlue.withValues(alpha: 0.1),
              borderColor: AppColors.electricBlue,
              radius: context.radius.sm,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppColors.electricBlue,
                      ),
                      SizedBox(width: spacing.xs),
                      Text(
                        'Privacy & Data Usage',
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.electricBlue,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: spacing.xs),
                  Text(
                    '• We only use your social data to enhance your AI personality\n'
                    '• Your data is stored locally and encrypted\n'
                    '• You can disconnect anytime\n'
                    '• We never share your social data with third parties',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getPlatformIcon(String platform) {
    IconData icon;
    Color color;
    switch (platform) {
      case 'Instagram':
        icon = Icons.camera_alt;
        color = Colors.purple;
        break;
      case 'Facebook':
        icon = Icons.facebook;
        color = Colors.blue;
        break;
      case 'Twitter':
        icon = Icons.chat_bubble_outline;
        color = Colors.lightBlue;
        break;
      case 'TikTok':
        icon = Icons.music_note;
        color = Colors.black;
        break;
      case 'LinkedIn':
        icon = Icons.business;
        color = Colors.blue.shade700;
        break;
      case 'Google':
        icon = Icons.search;
        color = Colors.blue;
        break;
      case 'Reddit':
        icon = Icons.forum;
        color = Colors.orange;
        break;
      case 'Tumblr':
        icon = Icons.auto_stories;
        color = Colors.blue.shade900;
        break;
      case 'YouTube':
        icon = Icons.play_circle;
        color = Colors.red;
        break;
      case 'Pinterest':
        icon = Icons.push_pin;
        color = Colors.red.shade700;
        break;
      case 'Are.na':
        icon = Icons.grid_view;
        color = Colors.black;
        break;
      default:
        icon = Icons.link;
        color = AppTheme.primaryColor;
    }
    return Icon(icon, color: color, size: 32);
  }

  Future<void> _connectPlatform(String platform) async {
    setState(() {
      _isConnecting = true;
      _connectingPlatform = platform;
    });

    try {
      // TODO: Implement actual OAuth connection when Phase 12 backend is ready
      // This will use SocialMediaConnectionService.connectPlatform()
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        setState(() {
          _connectedPlatforms[platform] = true;
          _isConnecting = false;
          _connectingPlatform = null;
        });

        FeedbackPresenter.showSnack(
          context,
          message: '$platform connected successfully',
          kind: FeedbackKind.success,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnecting = false;
          _connectingPlatform = null;
        });

        context.showError('Failed to connect $platform: $e');
      }
    }
  }

  Future<void> _disconnectPlatform(String platform) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Disconnect $platform?'),
        content: Text(
          'Disconnecting $platform will stop using your social data to enhance your AI personality. You can reconnect anytime.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // TODO: Call SocialMediaConnectionService.disconnectPlatform()
      setState(() {
        _connectedPlatforms[platform] = false;
      });

      FeedbackPresenter.showSnack(
        context,
        message: '$platform disconnected',
        kind: FeedbackKind.warning,
        duration: const Duration(seconds: 2),
      );
    }
  }
}

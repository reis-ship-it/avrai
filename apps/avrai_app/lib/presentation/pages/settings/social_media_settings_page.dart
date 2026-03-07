import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:avrai/presentation/widgets/common/app_info_banner.dart';
import 'package:avrai/presentation/widgets/common/app_section.dart';
import 'package:avrai/presentation/widgets/common/app_status_pill.dart';
import 'package:avrai/presentation/widgets/common/app_surface.dart';
import 'package:avrai/presentation/schema_renderer/app_schema_page.dart';
import 'package:avrai/presentation/schemas/pages/social_media_settings_page_schema.dart';
import 'package:avrai/theme/app_theme.dart';
import 'package:avrai/theme/colors.dart';

class SocialMediaSettingsPage extends StatefulWidget {
  const SocialMediaSettingsPage({super.key});

  @override
  State<SocialMediaSettingsPage> createState() =>
      _SocialMediaSettingsPageState();
}

class _SocialMediaSettingsPageState extends State<SocialMediaSettingsPage> {
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
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AppSchemaPage(
      schema: buildSocialMediaSettingsPageSchema(
        content: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSurface(
                padding: EdgeInsets.zero,
                child: InkWell(
                  onTap: () => context.go('/friends/discover'),
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.people_outline),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Find Friends on AVRAI',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Discover people you already know through connected public accounts.',
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const AppSection(
                title: 'Connected Platforms',
                subtitle: 'Manage which services AVRAI can reference.',
                child: SizedBox.shrink(),
              ),
              ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: _connectedPlatforms.entries.map((entry) {
                  final platform = entry.key;
                  final isConnected = entry.value;
                  return AppSurface(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: EdgeInsets.zero,
                    child: ListTile(
                      leading: _getPlatformIcon(platform),
                      title: Text(platform),
                      subtitle: Text(
                        isConnected
                            ? 'Connected and available for profile enrichment.'
                            : 'Not connected.',
                      ),
                      trailing: _isConnecting && _connectingPlatform == platform
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AppStatusPill(
                                  label: isConnected ? 'Connected' : 'Off',
                                  color: isConnected
                                      ? AppColors.success
                                      : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 8),
                                Switch(
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
                              ],
                            ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const AppInfoBanner(
                title: 'Privacy & Data Usage',
                body:
                    'Connected account data is used only for profile enrichment and friend discovery. You can disconnect at any time.',
                icon: Icons.privacy_tip_outlined,
              ),
            ],
          ),
        ),
      ),
      scrollable: false,
    );
  }

  Widget _getPlatformIcon(String platform) {
    IconData icon;
    switch (platform) {
      case 'Instagram':
        icon = Icons.camera_alt_outlined;
        break;
      case 'Facebook':
        icon = Icons.facebook;
        break;
      case 'Twitter':
        icon = Icons.chat_bubble_outline;
        break;
      case 'TikTok':
        icon = Icons.music_note_outlined;
        break;
      case 'LinkedIn':
        icon = Icons.business_outlined;
        break;
      case 'Google':
        icon = Icons.search;
        break;
      case 'Reddit':
        icon = Icons.forum_outlined;
        break;
      case 'Tumblr':
        icon = Icons.auto_stories_outlined;
        break;
      case 'YouTube':
        icon = Icons.play_circle_outline;
        break;
      case 'Pinterest':
        icon = Icons.push_pin_outlined;
        break;
      case 'Are.na':
        icon = Icons.grid_view_outlined;
        break;
      default:
        icon = Icons.link_outlined;
    }
    return Icon(icon, color: AppColors.textSecondary, size: 28);
  }

  Future<void> _connectPlatform(String platform) async {
    setState(() {
      _isConnecting = true;
      _connectingPlatform = platform;
    });

    try {
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        setState(() {
          _connectedPlatforms[platform] = true;
          _isConnecting = false;
          _connectingPlatform = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$platform connected'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnecting = false;
          _connectingPlatform = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect $platform: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _disconnectPlatform(String platform) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Disconnect $platform?'),
        content: Text(
          'Disconnecting $platform will stop using that account for profile enrichment. You can reconnect at any time.',
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
      setState(() {
        _connectedPlatforms[platform] = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$platform disconnected'),
          backgroundColor: AppColors.warning,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}

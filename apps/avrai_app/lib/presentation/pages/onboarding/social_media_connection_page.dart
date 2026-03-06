import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:avrai/theme/app_theme.dart';
import 'package:avrai/theme/colors.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/presentation/widgets/common/app_surface.dart';
import 'package:avrai/injection_container.dart' as di;
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';
import 'package:avrai_runtime_os/services/social_media/social_media_connection_service.dart';

class _PlatformInfo {
  final String name;
  final String description;
  final IconData icon;
  final Color iconColor;

  const _PlatformInfo({
    required this.name,
    required this.description,
    required this.icon,
    required this.iconColor,
  });
}

const _spotifyOrange = Color(0xFF1DB954);
const _instagramPink = Color(0xFFE1306C);
const _facebookBlue = Color(0xFF1877F2);
const _googleBlue = Color(0xFF4285F4);
const _stravaOrange = Color(0xFFFC4C02);

const List<_PlatformInfo> _platforms = [
  _PlatformInfo(
    name: 'Spotify',
    description:
        'Music taste helps your AI find events and people with similar vibes',
    icon: Icons.music_note_rounded,
    iconColor: _spotifyOrange,
  ),
  _PlatformInfo(
    name: 'Instagram',
    description:
        'Photo activity helps your AI understand your interests and aesthetics',
    icon: Icons.camera_alt_rounded,
    iconColor: _instagramPink,
  ),
  _PlatformInfo(
    name: 'Facebook',
    description: 'Social connections help discover friends who also use avrai',
    icon: Icons.facebook_rounded,
    iconColor: _facebookBlue,
  ),
  _PlatformInfo(
    name: 'Google',
    description: 'Calendar and maps data help your AI learn your routines',
    icon: Icons.g_mobiledata_rounded,
    iconColor: _googleBlue,
  ),
  _PlatformInfo(
    name: 'Apple',
    description: 'Health and calendar data for activity-based recommendations',
    icon: Icons.apple_rounded,
    iconColor: AppColors.grey700,
  ),
  _PlatformInfo(
    name: 'Strava',
    description:
        'Fitness activities help find outdoor spots and active communities',
    icon: Icons.directions_run_rounded,
    iconColor: _stravaOrange,
  ),
];

/// App connection page for onboarding and settings.
///
/// Lets users connect external apps (Spotify, Instagram, etc.)
/// so the AI can learn lifestyle patterns, music taste, fitness
/// habits, and social connections.
class SocialMediaConnectionPage extends StatefulWidget {
  final Map<String, bool> connectedPlatforms;
  final Function(Map<String, bool>) onConnectionsChanged;
  final bool isOnboarding;

  const SocialMediaConnectionPage({
    super.key,
    required this.connectedPlatforms,
    required this.onConnectionsChanged,
    this.isOnboarding = true,
  });

  @override
  State<SocialMediaConnectionPage> createState() =>
      _SocialMediaConnectionPageState();
}

class _SocialMediaConnectionPageState extends State<SocialMediaConnectionPage> {
  late Map<String, bool> _connectedPlatforms;
  bool _isConnecting = false;
  // ignore: unused_field — retained for programmatic batch-connect from settings
  bool _isBatchConnecting = false;
  String? _connectingPlatform;

  @override
  void initState() {
    super.initState();
    _connectedPlatforms = Map<String, bool>.from(widget.connectedPlatforms);
    for (final p in _platforms) {
      _connectedPlatforms.putIfAbsent(p.name, () => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Connect Your Apps',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Connect apps you use to help your AI understand your lifestyle. '
          'You can always change these in settings.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.grey500,
              ),
        ),
        const SizedBox(height: 24),
        for (final platform in _platforms) _buildPlatformCard(platform),
      ],
    );
  }

  Widget _buildPlatformCard(_PlatformInfo info) {
    final isConnected = _connectedPlatforms[info.name] == true;
    final isLoading = _isConnecting && _connectingPlatform == info.name;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppSurface(
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: info.iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(info.icon, color: info.iconColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    info.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    info.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.grey500,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (isConnected)
              TextButton(
                onPressed:
                    _isConnecting ? null : () => _disconnectPlatform(info.name),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.success,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Connected'),
              )
            else
              FilledButton(
                onPressed:
                    _isConnecting ? null : () => _connectPlatform(info.name),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: AppColors.black,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Connect'),
              ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Service integration
  // ---------------------------------------------------------------------------

  // ignore: unused_element — kept for programmatic batch-connect from settings
  Future<void> _connectBatch() async {
    final unconnected = _platforms
        .where((p) => _connectedPlatforms[p.name] != true)
        .map((p) => p.name)
        .toList();
    if (unconnected.isEmpty) return;

    setState(() => _isBatchConnecting = true);

    try {
      final authBloc = context.read<AuthBloc>();
      final authState = authBloc.state;
      if (authState is! Authenticated) {
        throw Exception('User not authenticated');
      }

      final userId = authState.user.id;
      final agentIdService = di.sl<AgentIdService>();
      final agentId = await agentIdService.getUserAgentId(userId);

      final socialMediaService = di.sl<SocialMediaConnectionService>();
      final platforms = unconnected.map((p) => p.toLowerCase()).toList();
      final connections = await socialMediaService.connectPlatformsBatch(
        platforms: platforms,
        agentId: agentId,
        userId: userId,
      );

      if (!mounted) return;

      for (final connection in connections) {
        final platformName = connection.platform[0].toUpperCase() +
            connection.platform.substring(1);
        _connectedPlatforms[platformName] = true;
      }

      setState(() => _isBatchConnecting = false);
      widget.onConnectionsChanged(Map<String, bool>.from(_connectedPlatforms));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Connected ${connections.length} platform(s) successfully'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isBatchConnecting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to connect platforms: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _connectPlatform(String platform) async {
    setState(() {
      _isConnecting = true;
      _connectingPlatform = platform;
    });

    try {
      final authBloc = context.read<AuthBloc>();
      final authState = authBloc.state;
      if (authState is! Authenticated) {
        throw Exception('User not authenticated');
      }

      final userId = authState.user.id;
      final agentIdService = di.sl<AgentIdService>();
      final agentId = await agentIdService.getUserAgentId(userId);

      final socialMediaService = di.sl<SocialMediaConnectionService>();
      await socialMediaService.connectPlatform(
        platform: platform.toLowerCase(),
        agentId: agentId,
        userId: userId,
      );

      if (!mounted) return;

      setState(() {
        _connectedPlatforms[platform] = true;
        _isConnecting = false;
        _connectingPlatform = null;
      });

      widget.onConnectionsChanged(Map<String, bool>.from(_connectedPlatforms));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$platform connected successfully'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;

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

  Future<void> _disconnectPlatform(String platform) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Disconnect $platform?'),
        content: Text(
          'This will stop using your $platform data to personalise '
          'your AI. You can reconnect anytime.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final authBloc = context.read<AuthBloc>();
      final authState = authBloc.state;
      if (authState is! Authenticated) {
        throw Exception('User not authenticated');
      }

      final userId = authState.user.id;
      final agentIdService = di.sl<AgentIdService>();
      final agentId = await agentIdService.getUserAgentId(userId);

      final socialMediaService = di.sl<SocialMediaConnectionService>();
      await socialMediaService.disconnectPlatform(
        platform: platform.toLowerCase(),
        agentId: agentId,
      );

      if (!mounted) return;
      setState(() => _connectedPlatforms[platform] = false);
      widget.onConnectionsChanged(Map<String, bool>.from(_connectedPlatforms));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$platform disconnected'),
          backgroundColor: AppColors.warning,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to disconnect $platform: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }
}

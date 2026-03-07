import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avrai_runtime_os/services/analytics/public_profile_analysis_service.dart';
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/presentation/widgets/common/app_button_primary.dart';
import 'package:avrai/presentation/widgets/common/app_button_secondary.dart';
import 'package:avrai/presentation/widgets/common/app_form_field.dart';
import 'package:avrai/theme/app_theme.dart';
import 'package:avrai/theme/colors.dart';
import 'package:avrai/injection_container.dart' as di;
import 'package:avrai/presentation/widgets/common/app_section.dart';
import 'package:avrai/presentation/widgets/common/app_surface.dart';
import 'package:avrai/presentation/schema_renderer/app_schema_page.dart';
import 'package:avrai/presentation/schemas/pages/public_handles_page_schema.dart';
import 'package:avrai/presentation/widgets/common/app_info_banner.dart';

/// Public Handles Page
///
/// Allows users to optionally provide public social media handles
/// for profile analysis (with explicit consent).
///
/// **Privacy:** All analysis is opt-in and user-controlled.
class PublicHandlesPage extends StatefulWidget {
  const PublicHandlesPage({super.key});

  @override
  State<PublicHandlesPage> createState() => _PublicHandlesPageState();
}

class _PublicHandlesPageState extends State<PublicHandlesPage> {
  final PublicProfileAnalysisService _analysisService =
      di.sl<PublicProfileAnalysisService>();
  final AgentIdService _agentIdService = di.sl<AgentIdService>();

  final Map<String, TextEditingController> _controllers = {};
  bool _consentGiven = false;
  bool _isLoading = false;
  bool _hasStoredHandles = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadStoredHandles();
  }

  void _initializeControllers() {
    _controllers['instagram'] = TextEditingController();
    _controllers['tiktok'] = TextEditingController();
    _controllers['twitter'] = TextEditingController();
  }

  Future<void> _loadStoredHandles() async {
    try {
      final authBloc = context.read<AuthBloc>();
      final authState = authBloc.state;
      if (authState is! Authenticated) return;

      final userId = authState.user.id;
      final agentId = await _agentIdService.getUserAgentId(userId);

      final handles = await _analysisService.getStoredHandles(agentId);
      final hasConsent = await _analysisService.hasConsent(agentId);

      if (mounted) {
        setState(() {
          _hasStoredHandles = handles.isNotEmpty;
          _consentGiven = hasConsent;
          handles.forEach((platform, handle) {
            if (_controllers.containsKey(platform)) {
              _controllers[platform]!.text = handle;
            }
          });
        });
      }
    } catch (e) {
      // Ignore errors when loading
    }
  }

  Future<void> _saveHandles() async {
    if (!_consentGiven) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide consent to analyze public profiles'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authBloc = context.read<AuthBloc>();
      final authState = authBloc.state;
      if (authState is! Authenticated) {
        throw Exception('User not authenticated');
      }

      final userId = authState.user.id;
      final agentId = await _agentIdService.getUserAgentId(userId);
      if (!mounted) return;

      // Collect handles (only non-empty)
      final handles = <String, String>{};
      _controllers.forEach((platform, controller) {
        final handle = controller.text.trim();
        if (handle.isNotEmpty) {
          handles[platform] = handle;
        }
      });

      if (handles.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please provide at least one handle'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final success = await _analysisService.storeHandlesWithConsent(
        agentId: agentId,
        handles: handles,
        consentGiven: _consentGiven,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasStoredHandles = success;
        });

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Handles saved and analysis started!'),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save handles'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _revokeConsent() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke Consent?'),
        content: const Text(
          'This will delete all stored handles and analysis results. You can add handles again later if you change your mind.',
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
            child: const Text('Revoke'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      if (!mounted) return;
      final authBloc = context.read<AuthBloc>();
      final authState = authBloc.state;
      if (authState is! Authenticated) return;

      final userId = authState.user.id;
      final agentId = await _agentIdService.getUserAgentId(userId);

      final success = await _analysisService.revokeConsent(agentId);

      if (mounted) {
        setState(() {
          _consentGiven = false;
          _hasStoredHandles = false;
          _controllers.forEach((_, controller) => controller.clear());
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(success ? 'Consent revoked' : 'Failed to revoke consent'),
            backgroundColor: success ? AppColors.warning : AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Widget _getPlatformIcon(String platform) {
    IconData icon;
    switch (platform.toLowerCase()) {
      case 'instagram':
        icon = Icons.camera_alt;
        break;
      case 'tiktok':
        icon = Icons.music_note;
        break;
      case 'twitter':
        icon = Icons.chat_bubble_outline;
        break;
      default:
        icon = Icons.link;
    }
    return Icon(icon, color: AppColors.textSecondary);
  }

  @override
  void dispose() {
    _controllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppSchemaPage(
      schema: buildPublicHandlesPageSchema(
        content: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppInfoBanner(
                title: 'Consent required',
                body:
                    'Public profile analysis is optional. AVRAI only analyzes public posts, bios, and interests after you opt in.',
                icon: Icons.privacy_tip_outlined,
              ),
              const SizedBox(height: 24),
              AppSection(
                title: 'Consent',
                subtitle:
                    'Confirm that AVRAI can analyze public profile signals you choose to share.',
                child: AppSurface(
                  color: AppColors.surfaceMuted,
                  borderColor: _consentGiven
                      ? AppColors.borderStrong
                      : AppColors.borderSubtle,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _consentGiven,
                        onChanged: (value) {
                          setState(() {
                            _consentGiven = value ?? false;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'I consent to public profile analysis',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'AVRAI may analyze the public posts, bios, and interests tied to the handles below. You can revoke consent and remove this data at any time.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              AppSection(
                title: 'Public Handles',
                subtitle:
                    'Enter public usernames without the @ symbol. Leave any field blank if you do not want to use it.',
                child: Column(
                  children: [
                    _buildHandleField(
                      platform: 'instagram',
                      label: 'Instagram Username',
                    ),
                    const SizedBox(height: 12),
                    _buildHandleField(
                      platform: 'tiktok',
                      label: 'TikTok Username',
                    ),
                    const SizedBox(height: 12),
                    _buildHandleField(
                      platform: 'twitter',
                      label: 'Twitter/X Username',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              AppSection(
                title: 'Actions',
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: AppButtonPrimary(
                        onPressed:
                            _isLoading || !_consentGiven ? null : _saveHandles,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Save Handles'),
                      ),
                    ),
                    if (_hasStoredHandles) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: AppButtonSecondary(
                          onPressed: _revokeConsent,
                          child: const Text('Revoke Consent and Delete Data'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const AppInfoBanner(
                title: 'Privacy & Analysis',
                body:
                    'AVRAI only analyzes public content you choose to share. You stay in control of consent, and you can remove the saved handles whenever you want.',
                icon: Icons.info_outline,
              ),
            ],
          ),
        ),
      ),
      scrollable: false,
    );
  }

  Widget _buildHandleField({
    required String platform,
    required String label,
  }) {
    return AppSurface(
      child: Row(
        children: [
          _getPlatformIcon(platform),
          const SizedBox(width: 12),
          Expanded(
            child: AppFormField(
              controller: _controllers[platform],
              labelText: label,
              hintText: 'username',
              enabled: _consentGiven,
            ),
          ),
        ],
      ),
    );
  }
}

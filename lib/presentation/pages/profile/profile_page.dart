import 'package:flutter/material.dart';
import 'package:avrai/core/navigation/app_navigator.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/tokens/theme_tokens.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/presentation/pages/settings/notifications_settings_page.dart';
import 'package:avrai/presentation/pages/settings/privacy_settings_page.dart';
import 'package:avrai/presentation/pages/settings/social_media_settings_page.dart';
import 'package:avrai/presentation/pages/settings/help_support_page.dart';
import 'package:avrai/presentation/pages/settings/about_page.dart';
import 'package:avrai/presentation/pages/tax/tax_profile_page.dart';
import 'package:avrai/presentation/pages/tax/tax_documents_page.dart';
import 'package:avrai/presentation/pages/legal/terms_of_service_page.dart';
import 'package:avrai/presentation/pages/legal/privacy_policy_page.dart';
import 'package:avrai/presentation/pages/verification/identity_verification_page.dart';
// Phase 1 Integration: Device Discovery & AI2AI
import 'package:go_router/go_router.dart';
// Phase 4.5: Partnership Profile Visibility
import 'package:avrai/presentation/widgets/profile/partnership_display_widget.dart';
import 'package:avrai/core/models/user/user_partnership.dart';
// Admin: God Mode Access
import 'package:avrai/presentation/pages/admin/god_mode_login_page.dart';
import 'package:avrai/presentation/pages/profile/edit_profile_page.dart';
import 'package:avrai/core/models/user/user.dart' show UserRole;
// Phase 4: Dynamic Knots
import 'package:get_it/get_it.dart';
import 'dart:developer' as developer;
import 'package:avrai/core/services/user/agent_id_service.dart';
import 'package:avrai_knot/services/knot/knot_storage_service.dart';
import 'package:avrai_knot/services/knot/dynamic_knot_service.dart';
import 'package:avrai/core/services/device/wearable_data_service.dart';
import 'package:avrai_knot/models/dynamic_knot.dart';
import 'package:avrai/presentation/widgets/knot/dynamic_knot_widget.dart';
import 'package:avrai/presentation/pages/knot/knot_meditation_page.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';
import 'package:avrai/presentation/widgets/portal/portal_surface.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // These services are provided via DI in the app. In widget tests or partial
  // runtimes, they may not be registered, so we resolve them defensively.
  AgentIdService? _agentIdService;
  KnotStorageService? _knotStorageService;
  DynamicKnotService? _dynamicKnotService;
  WearableDataService? _wearableDataService;

  DynamicKnot? _dynamicKnot;
  bool _isLoadingKnot = false;

  @override
  void initState() {
    super.initState();
    _tryResolveKnotServices();
    _loadDynamicKnot();
  }

  void _tryResolveKnotServices() {
    try {
      _agentIdService = GetIt.instance<AgentIdService>();
    } catch (e, st) {
      developer.log(
        'AgentIdService not registered; dynamic knot disabled',
        name: 'ProfilePage',
        error: e,
        stackTrace: st,
      );
    }
    try {
      _knotStorageService = GetIt.instance<KnotStorageService>();
    } catch (e, st) {
      developer.log(
        'KnotStorageService not registered; dynamic knot disabled',
        name: 'ProfilePage',
        error: e,
        stackTrace: st,
      );
    }
    try {
      _dynamicKnotService = GetIt.instance<DynamicKnotService>();
    } catch (e, st) {
      developer.log(
        'DynamicKnotService not registered; dynamic knot disabled',
        name: 'ProfilePage',
        error: e,
        stackTrace: st,
      );
    }
    try {
      _wearableDataService = GetIt.instance<WearableDataService>();
    } catch (e, st) {
      developer.log(
        'WearableDataService not registered; dynamic knot disabled',
        name: 'ProfilePage',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> _loadDynamicKnot() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) return;

    if (_agentIdService == null ||
        _knotStorageService == null ||
        _dynamicKnotService == null ||
        _wearableDataService == null) {
      return;
    }

    setState(() {
      _isLoadingKnot = true;
    });

    try {
      final userId = authState.user.id;
      final agentId = await _agentIdService!.getUserAgentId(userId);

      // Load knot from storage
      final knot = await _knotStorageService!.loadKnot(agentId);

      if (knot != null) {
        // Get mood/energy/stress from wearables, fallback to defaults
        final mood = await _wearableDataService!.getCurrentMood();
        final energy = await _wearableDataService!.getCurrentEnergy();
        final stress = await _wearableDataService!.getCurrentStress();

        // Create dynamic knot
        final dynamicKnot = _dynamicKnotService!.updateKnotWithCurrentState(
          baseKnot: knot,
          mood: mood,
          energy: energy,
          stress: stress,
        );

        if (mounted) {
          setState(() {
            _dynamicKnot = dynamicKnot;
            _isLoadingKnot = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingKnot = false;
          });
        }
      }
    } catch (e, st) {
      developer.log(
        'Error loading dynamic knot',
        error: e,
        stackTrace: st,
        name: 'ProfilePage',
      );
      if (mounted) {
        setState(() {
          _isLoadingKnot = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return AdaptivePlatformPageScaffold(
      title: 'Profile',
      scrollable: true,
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is Authenticated) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Info Card
                PortalSurface(
                  child: Padding(
                    padding: EdgeInsets.all(spacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Dynamic Knot Avatar (Phase 4)
                            if (_isLoadingKnot)
                              const SizedBox(
                                width: 60,
                                height: 60,
                                child:
                                    Center(child: CircularProgressIndicator()),
                              )
                            else if (_dynamicKnot != null)
                              DynamicKnotWidget(
                                knot: _dynamicKnot!,
                                size: 60.0,
                                animated: true,
                              )
                            else
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: AppTheme.primaryColor,
                                child: Text(
                                  state.user.displayName
                                          ?.substring(0, 1)
                                          .toUpperCase() ??
                                      state.user.email
                                          .substring(0, 1)
                                          .toUpperCase(),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: AppColors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                            SizedBox(width: spacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    state.user.displayName ?? 'User',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall,
                                  ),
                                  Text(
                                    state.user.email,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: AppTheme.offlineColor,
                                        ),
                                  ),
                                  SizedBox(height: spacing.xs),
                                  Row(
                                    children: [
                                      Icon(
                                        state.isOffline
                                            ? Icons.wifi_off
                                            : Icons.wifi,
                                        size: 16,
                                        color: state.isOffline
                                            ? AppTheme.offlineColor
                                            : AppTheme.successColor,
                                      ),
                                      SizedBox(width: spacing.xxs),
                                      Text(
                                        state.isOffline ? 'Offline' : 'Online',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: state.isOffline
                                                  ? AppTheme.offlineColor
                                                  : AppTheme.successColor,
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                final authBloc = context.read<AuthBloc>();
                                AppNavigator.pushBuilder(
                                  context,
                                  builder: (context) => EditProfilePage(
                                    user: state.user,
                                  ),
                                ).then((_) {
                                  // Refresh auth state to get updated user
                                  if (mounted) {
                                    authBloc.add(AuthCheckRequested());
                                  }
                                });
                              },
                              tooltip: 'Edit Profile',
                            ),
                          ],
                        ),
                        // Phase 4: Knot Meditation Link
                        if (_dynamicKnot != null) ...[
                          SizedBox(height: spacing.md),
                          const Divider(),
                          SizedBox(height: spacing.xs),
                          InkWell(
                            onTap: () {
                              if (!mounted) return;
                              AppNavigator.pushBuilder(
                                context,
                                builder: (context) =>
                                    const KnotMeditationPage(),
                              );
                            },
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.self_improvement,
                                  color: AppTheme.primaryColor,
                                ),
                                SizedBox(width: spacing.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Knot Meditation',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                      Text(
                                        'Breathe with your personality knot',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppTheme.offlineColor,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios, size: 16),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                SizedBox(height: spacing.lg),

                // Partnerships Section (Phase 4.5)
                _buildPartnershipsSection(context, state.user.id),

                SizedBox(height: spacing.lg),

                // Settings Section
                Text(
                  'Settings',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                SizedBox(height: spacing.md),

                // Settings Items
                _buildSettingsItem(
                  context,
                  icon: Icons.notifications,
                  title: 'Notifications',
                  subtitle: 'Manage your notifications',
                  onTap: () {
                    AppNavigator.pushBuilder(
                      context,
                      builder: (context) => const NotificationsSettingsPage(),
                    );
                  },
                ),
                _buildSettingsItem(
                  context,
                  icon: Icons.privacy_tip,
                  title: 'Privacy',
                  subtitle: 'Manage your privacy settings',
                  onTap: () {
                    AppNavigator.pushBuilder(
                      context,
                      builder: (context) => const PrivacySettingsPage(),
                    );
                  },
                ),
                _buildSettingsItem(
                  context,
                  icon: Icons.link,
                  title: 'Social Media',
                  subtitle: 'Connect and manage social accounts',
                  onTap: () {
                    AppNavigator.pushBuilder(
                      context,
                      builder: (context) => const SocialMediaSettingsPage(),
                    );
                  },
                ),
                // Phase 10: Public Profile Analysis
                _buildSettingsItem(
                  context,
                  icon: Icons.public,
                  title: 'Public Profile Analysis',
                  subtitle: 'Analyze public handles (optional)',
                  onTap: () {
                    context.go('/settings/public-handles');
                  },
                ),
                // Phase 4: Expertise Dashboard Navigation
                _buildSettingsItem(
                  context,
                  icon: Icons.school,
                  title: 'Expertise Dashboard',
                  subtitle: 'View your expertise profile and progress',
                  onTap: () {
                    context.go('/profile/expertise-dashboard');
                  },
                ),
                // Phase 1 Integration: New settings links
                _buildSettingsItem(
                  context,
                  icon: Icons.radar,
                  title: 'Device Discovery',
                  subtitle: 'View nearby avrai-enabled devices',
                  onTap: () {
                    context.go('/device-discovery');
                  },
                ),
                _buildSettingsItem(
                  context,
                  icon: Icons.psychology,
                  title: 'AI2AI Connections',
                  subtitle: 'Manage AI personality connections',
                  onTap: () {
                    context.go('/ai2ai-connections');
                  },
                ),
                _buildSettingsItem(
                  context,
                  icon: Icons.settings_input_antenna,
                  title: 'Discovery Settings',
                  subtitle: 'Configure discovery preferences',
                  onTap: () {
                    context.go('/discovery-settings');
                  },
                ),
                // Phase 2.1: Federated Learning
                _buildSettingsItem(
                  context,
                  icon: Icons.school,
                  title: 'Federated Learning',
                  subtitle: 'Privacy-preserving AI training',
                  onTap: () {
                    context.go('/federated-learning');
                  },
                ),
                _buildSettingsItem(
                  context,
                  icon: Icons.smart_toy_outlined,
                  title: 'On-Device AI',
                  subtitle: 'Offline LLM + scheduled learning (device-gated)',
                  onTap: () {
                    context.go('/on-device-ai');
                  },
                ),
                if (kDebugMode)
                  _buildSettingsItem(
                    context,
                    icon: Icons.fact_check_outlined,
                    title: 'Proof Run (debug)',
                    subtitle: 'Video + logs + ledger receipts exporter',
                    onTap: () {
                      context.go('/proof-run');
                    },
                  ),
                _buildSettingsItem(
                  context,
                  icon: Icons.receipt,
                  title: 'Receipts',
                  subtitle: 'View verifiable receipts (audit trail)',
                  onTap: () {
                    context.go('/profile/receipts');
                  },
                ),
                // Phase 7, Week 37: AI Self-Improvement Visibility
                _buildSettingsItem(
                  context,
                  icon: Icons.trending_up,
                  title: 'AI Improvement',
                  subtitle: 'See how your AI is improving',
                  onTap: () {
                    context.go('/ai-improvement');
                  },
                ),
                // Phase 7, Week 38: AI2AI Learning Methods UI
                _buildSettingsItem(
                  context,
                  icon: Icons.psychology,
                  title: 'AI2AI Learning Methods',
                  subtitle: 'See how your AI learns from other AIs',
                  onTap: () {
                    context.go('/ai2ai-learning-methods');
                  },
                ),
                // Phase 7, Section 39: Continuous Learning UI
                _buildSettingsItem(
                  context,
                  icon: Icons.auto_awesome,
                  title: 'Continuous Learning',
                  subtitle: 'See how your AI continuously learns',
                  onTap: () {
                    context.go('/continuous-learning');
                  },
                ),
                // Tax & Legal Section
                _buildSettingsItem(
                  context,
                  icon: Icons.verified_user,
                  title: 'Identity Verification',
                  subtitle: 'Verify your identity for high earnings',
                  onTap: () {
                    AppNavigator.pushBuilder(
                      context,
                      builder: (context) => const IdentityVerificationPage(),
                    );
                  },
                ),
                _buildSettingsItem(
                  context,
                  icon: Icons.receipt_long,
                  title: 'Tax Profile',
                  subtitle: 'Manage W-9 and tax information',
                  onTap: () {
                    AppNavigator.pushBuilder(
                      context,
                      builder: (context) => const TaxProfilePage(),
                    );
                  },
                ),
                _buildSettingsItem(
                  context,
                  icon: Icons.description,
                  title: 'Tax Documents',
                  subtitle: 'View and download tax forms',
                  onTap: () {
                    AppNavigator.pushBuilder(
                      context,
                      builder: (context) => const TaxDocumentsPage(),
                    );
                  },
                ),
                _buildSettingsItem(
                  context,
                  icon: Icons.gavel,
                  title: 'Terms of Service',
                  subtitle: 'View terms and conditions',
                  onTap: () {
                    AppNavigator.pushBuilder(
                      context,
                      builder: (context) => const TermsOfServicePage(),
                    );
                  },
                ),
                _buildSettingsItem(
                  context,
                  icon: Icons.privacy_tip,
                  title: 'Privacy Policy',
                  subtitle: 'View privacy policy',
                  onTap: () {
                    AppNavigator.pushBuilder(
                      context,
                      builder: (context) => const PrivacyPolicyPage(),
                    );
                  },
                ),
                _buildSettingsItem(
                  context,
                  icon: Icons.help,
                  title: 'Help & Support',
                  subtitle: 'Get help and contact support',
                  onTap: () {
                    AppNavigator.pushBuilder(
                      context,
                      builder: (context) => const HelpSupportPage(),
                    );
                  },
                ),
                _buildSettingsItem(
                  context,
                  icon: Icons.info,
                  title: 'About',
                  subtitle: 'App version and information',
                  onTap: () {
                    AppNavigator.pushBuilder(
                      context,
                      builder: (context) => const AboutPage(),
                    );
                  },
                ),

                // Admin Section (only visible to admins)
                // ignore: unrelated_type_equality_checks - UserRole from different packages
                if (state.user.role == UserRole.admin) ...[
                  SizedBox(height: spacing.lg),
                  const Divider(),
                  SizedBox(height: spacing.md),
                  Text(
                    'Admin',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  SizedBox(height: spacing.md),
                  _buildSettingsItem(
                    context,
                    icon: Icons.admin_panel_settings,
                    title: 'God Mode Admin',
                    subtitle: 'Access admin dashboard',
                    onTap: () {
                      AppNavigator.pushBuilder(
                        context,
                        builder: (context) => const GodModeLoginPage(),
                      );
                    },
                  ),
                ],

                SizedBox(height: spacing.lg),

                // Sign Out Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _showSignOutDialog(context);
                    },
                    // Use global ElevatedButtonTheme; color implied by theme
                    child: Text('Sign Out'),
                  ),
                ),
              ],
            );
          } else {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }

  Widget _buildSettingsItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final spacing = context.spacing;
    return PortalSurface(
      margin: EdgeInsets.only(bottom: spacing.xs),
      padding: EdgeInsets.zero,
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryColor),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildPartnershipsSection(BuildContext context, String userId) {
    // TODO: Replace with actual PartnershipProfileService once Agent 1 completes it
    // For now, using FutureBuilder with empty list
    // The service will be: sl<PartnershipProfileService>().getActivePartnerships(userId)

    return FutureBuilder<List<UserPartnership>>(
      future: _loadPartnerships(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox
              .shrink(); // Don't show loading, just skip if not ready
        }

        final partnerships = snapshot.data ?? [];

        if (partnerships.isEmpty) {
          return const SizedBox
              .shrink(); // Don't show empty state on profile page
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PartnershipDisplayWidget(
              partnerships: partnerships,
              maxDisplayCount: 3,
              onViewAllTap: (_) {
                context.go('/profile/partnerships');
              },
              onPartnershipTap: (partnership) {
                // Navigate to partnership details if needed
                // For now, just navigate to partnerships page
                context.go('/profile/partnerships');
              },
            ),
          ],
        );
      },
    );
  }

  Future<List<UserPartnership>> _loadPartnerships(String userId) async {
    // TODO: Replace with actual service call once PartnershipProfileService is available
    // Example:
    // final service = sl<PartnershipProfileService>();
    // return await service.getActivePartnerships(userId);

    // For now, return empty list
    // This will be replaced when Agent 1 completes PartnershipProfileService
    return [];
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Sign Out'),
          content: Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<AuthBloc>().add(SignOutRequested());
              },
              // Use global ElevatedButtonTheme
              child: Text('Sign Out'),
            ),
          ],
        );
      },
    );
  }
}

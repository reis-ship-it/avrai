// MIGRATION_SHIM: LEGACY_PATH_GUARD TEMPORARY UNTIL TARGET-ROOT MIGRATION
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:avrai/theme/colors.dart';
import 'package:avrai/theme/tokens/theme_tokens.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/theme/app_theme.dart';
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
import 'package:avrai_core/models/user/user_partnership.dart';
// Admin: God Mode Access
import 'package:avrai/presentation/pages/admin/admin_desktop_handoff_page.dart';
import 'package:avrai/presentation/pages/profile/edit_profile_page.dart';
import 'package:avrai_core/models/user/user.dart' show UserRole;
// Phase 4: Dynamic Knots
import 'package:get_it/get_it.dart';
import 'package:get_storage/get_storage.dart';
import 'dart:developer' as developer;
import 'package:avrai_runtime_os/ai/personality_learning.dart';
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';
import 'package:avrai_runtime_os/runtime_api.dart';
import 'package:avrai_runtime_os/services/community/community_service.dart';
import 'package:avrai_runtime_os/services/community/club_service.dart';
import 'package:avrai_runtime_os/services/device/wearable_data_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai_runtime_os/services/recommendations/recommendation_feedback_service.dart';
import 'package:avrai_runtime_os/services/recommendations/saved_discovery_service.dart';
import 'package:avrai_core/models/discovery/discovery_models.dart';
import 'package:avrai/presentation/widgets/knot/dynamic_knot_widget.dart';
import 'package:avrai/presentation/pages/knot/knot_meditation_page.dart';
import 'package:avrai/presentation/widgets/common/app_flow_scaffold.dart';
import 'package:avrai/presentation/widgets/common/app_surface.dart';
import 'package:avrai_runtime_os/config/bham_beta_defaults.dart';

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
  SharedPreferencesCompat? _prefs;
  final SavedDiscoveryService _savedDiscoveryService = SavedDiscoveryService();
  final RecommendationFeedbackService _feedbackService =
      RecommendationFeedbackService();
  final CommunityService _communityService = CommunityService();
  final ClubService _clubService = ClubService();
  PersonalityLearning? _personalityLearning;
  final Map<String, bool> _betaControls = <String, bool>{
    'ai2ai_participation': true,
    'ble_discovery': true,
    'background_sensing': true,
    'health_bridge': false,
    'calendar_bridge': false,
    'social_bridge': false,
    'notification_categories': true,
    'direct_user_matching': true,
    'prefer_offline_ai': true,
    'strong_air_gap': true,
  };
  int _savedItemsCount = 0;
  int _positiveSignalCount = 0;
  int _negativeSignalCount = 0;
  int _ai2aiDailySuccessCount = 0;

  @override
  void initState() {
    super.initState();
    _tryResolveKnotServices();
    _loadDynamicKnot();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadWave4ProfileSurface();
    });
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
    try {
      _prefs = GetIt.instance<SharedPreferencesCompat>();
    } catch (_) {
      _prefs = null;
    }
    try {
      _personalityLearning = GetIt.instance<PersonalityLearning>();
    } catch (_) {
      _personalityLearning = null;
    }
  }

  Future<void> _loadWave4ProfileSurface() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) {
      return;
    }

    final userId = authState.user.id;
    final savedItems = await _savedDiscoveryService.listAll(userId);
    final feedbackEvents = await _feedbackService.listEvents(userId);
    for (final key in _betaControls.keys.toList()) {
      _betaControls[key] =
          _prefs?.getBool(_controlKey(key)) ?? _betaControls[key]!;
    }
    final today = DateTime.now();
    final ai2aiDailySuccessCount = feedbackEvents.where((event) {
      final sameDay = event.occurredAtUtc.year == today.year &&
          event.occurredAtUtc.month == today.month &&
          event.occurredAtUtc.day == today.day;
      return sameDay &&
          (event.action == RecommendationFeedbackAction.meaningful ||
              event.action == RecommendationFeedbackAction.fun);
    }).length;

    if (!mounted) {
      return;
    }
    setState(() {
      _savedItemsCount = savedItems.length;
      _positiveSignalCount = feedbackEvents
          .where((event) => event.action == RecommendationFeedbackAction.save)
          .length;
      _negativeSignalCount = feedbackEvents
          .where((event) =>
              event.action == RecommendationFeedbackAction.dismiss ||
              event.action == RecommendationFeedbackAction.lessLikeThis)
          .length;
      _ai2aiDailySuccessCount = ai2aiDailySuccessCount;
    });
  }

  Future<void> _setControlFlag(String key, bool value) async {
    await _prefs?.setBool(_controlKey(key), value);
    if (!mounted) {
      return;
    }
    setState(() {
      _betaControls[key] = value;
    });
  }

  String _controlKey(String key) => 'bham:profile_controls:v1:$key';

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

  Future<void> _resetRecommendations(String userId) async {
    await _feedbackService.clearAll(userId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recommendation feedback reset.')),
      );
    }
    await _loadWave4ProfileSurface();
  }

  Future<void> _resetAgentFromLocalityBaseline(String userId) async {
    await _personalityLearning?.resetPersonality(userId);
    final agentId = _agentIdService != null
        ? await _agentIdService!.getUserAgentId(userId)
        : null;
    if (agentId != null && _knotStorageService != null) {
      await _knotStorageService!.deleteKnot(agentId);
    }
    await _loadDynamicKnot();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agent reset to locality baseline.'),
        ),
      );
    }
  }

  Future<void> _disconnectBridges() async {
    await _setControlFlag('health_bridge', false);
    await _setControlFlag('calendar_bridge', false);
    await _setControlFlag('social_bridge', false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('External bridges disconnected.')),
      );
    }
  }

  Future<void> _clearChatHistory() async {
    await GetStorage('friend_chat_messages').erase();
    await GetStorage('friend_chat_outbox').erase();
    await GetStorage('community_chat_messages').erase();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Local chat history cleared.')),
      );
    }
  }

  Future<void> _leaveGroups(String userId) async {
    final communities = await _communityService.getAllCommunities();
    for (final community in communities) {
      if (community.isMember(userId) && !community.isFounder(userId)) {
        await _communityService.removeMember(community, userId);
      }
    }

    final clubs = await _clubService.getAllClubs();
    for (final club in clubs) {
      await _clubService.leaveClub(clubId: club.id, userId: userId);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Left eligible clubs and communities.')),
      );
    }
  }

  Future<void> _clearSavedItems(String userId) async {
    await _savedDiscoveryService.clearAll(userId);
    await _loadWave4ProfileSurface();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved items cleared.')),
      );
    }
  }

  Widget _buildBhamSummarySection(BuildContext context, String displayName) {
    final summaryText =
        '$displayName is currently operating on the Birmingham beta loop with $_savedItemsCount saved objects and $_ai2aiDailySuccessCount positive AI2AI outcomes today.';
    final timeline = <String>[
      'Saved discovery objects: $_savedItemsCount',
      'Positive recommendation signals: $_positiveSignalCount',
      'Negative recommendation signals: $_negativeSignalCount',
    ];

    return AppSurface(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'BHAM Beta Summary',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            summaryText,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _summaryPill('AI2AI daily success $_ai2aiDailySuccessCount'),
              _summaryPill(
                  'Pheromone +$_positiveSignalCount / -$_negativeSignalCount'),
              _summaryPill('Saved $_savedItemsCount'),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Behavior Timeline',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ...timeline.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.timeline,
                    color: AppColors.textSecondary,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBhamControlSurface() {
    return AppSurface(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'BHAM Controls',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ..._betaControls.entries.map(
            (entry) => SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: entry.value,
              onChanged: (value) => _setControlFlag(entry.key, value),
              title: Text(_controlLabel(entry.key)),
              subtitle: Text(_controlDescription(entry.key)),
            ),
          ),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.notifications_active_outlined),
            title: const Text('Notification categories'),
            subtitle: const Text('Open the detailed settings surfaces.'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsSettingsPage(),
                ),
              );
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy and delete-account flow'),
            subtitle:
                const Text('Detailed privacy controls and account deletion.'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PrivacySettingsPage(),
                ),
              );
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.bluetooth_searching_outlined),
            title: const Text('Discovery and AI settings'),
            subtitle: const Text(
                'BLE discovery, federated learning, and on-device AI.'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => context.go('/discovery-settings'),
          ),
        ],
      ),
    );
  }

  Widget _buildDestructiveActions(String userId) {
    return AppSurface(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reset And Cleanup',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: () => _resetRecommendations(userId),
                child: const Text('Reset recommendations'),
              ),
              OutlinedButton(
                onPressed: () => _resetAgentFromLocalityBaseline(userId),
                child: const Text('Reset agent'),
              ),
              OutlinedButton(
                onPressed: _disconnectBridges,
                child: const Text('Disconnect bridges'),
              ),
              OutlinedButton(
                onPressed: _clearChatHistory,
                child: const Text('Clear chat history'),
              ),
              OutlinedButton(
                onPressed: () => _leaveGroups(userId),
                child: const Text('Leave groups'),
              ),
              OutlinedButton(
                onPressed: () => _clearSavedItems(userId),
                child: const Text('Clear saved items'),
              ),
              FilledButton.tonal(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PrivacySettingsPage(),
                    ),
                  );
                },
                child: const Text('Delete account'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _controlLabel(String key) {
    return switch (key) {
      'ai2ai_participation' => 'AI2AI participation',
      'ble_discovery' => 'BLE discovery',
      'background_sensing' => 'Background sensing',
      'health_bridge' => 'Health bridge',
      'calendar_bridge' => 'Calendar bridge',
      'social_bridge' => 'Social bridge',
      'notification_categories' => 'Notification categories',
      'direct_user_matching' => 'Direct user matching',
      'prefer_offline_ai' => 'Prefer offline AI',
      'strong_air_gap' => 'Strong air-gap model',
      _ => key,
    };
  }

  String _controlDescription(String key) {
    return switch (key) {
      'ai2ai_participation' =>
        'Allow the beta to participate in AI-to-AI recommendation and relay flows.',
      'ble_discovery' => 'Allow nearby discovery for local device encounters.',
      'background_sensing' =>
        'Permit passive context collection needed for the BHAM loop.',
      'health_bridge' => 'Allow health data bridge inputs when enabled.',
      'calendar_bridge' => 'Allow calendar bridge inputs when enabled.',
      'social_bridge' => 'Allow social bridge inputs when enabled.',
      'notification_categories' =>
        'Control whether recommendation nudges stay active.',
      'direct_user_matching' =>
        'Allow explicit direct-match style introductions.',
      'prefer_offline_ai' => 'Prefer on-device and offline AI behavior first.',
      'strong_air_gap' => 'Use stronger privacy boundaries for shared outputs.',
      _ => '',
    };
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return AppFlowScaffold(
      title: 'Profile',
      scrollable: true,
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is Authenticated) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Info Card
                AppSurface(
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
                                  style: const TextStyle(
                                    color: AppColors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            SizedBox(width: spacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        state.user.displayName ?? 'User',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall,
                                      ),
                                      if (state.user.isBetaTester) ...[
                                        SizedBox(width: spacing.xs),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary
                                                .withValues(alpha: 0.2),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            border: Border.all(
                                                color: AppColors.primary
                                                    .withValues(alpha: 0.5)),
                                          ),
                                          child: const Text(
                                            'BETA PIONEER',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
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
                                        style: TextStyle(
                                          color: state.isOffline
                                              ? AppTheme.offlineColor
                                              : AppTheme.successColor,
                                          fontSize: 12,
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
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditProfilePage(
                                      user: state.user,
                                    ),
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
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const KnotMeditationPage(),
                                ),
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

                if (BhamBetaDefaults.enablePartnershipSurfaces) ...[
                  SizedBox(height: spacing.lg),
                  _buildPartnershipsSection(context, state.user.id),
                ],
                SizedBox(height: spacing.lg),

                _buildBhamSummarySection(
                  context,
                  state.user.displayName ?? 'User',
                ),
                _buildBhamControlSurface(),
                _buildDestructiveActions(state.user.id),

                // Beta Feedback (Prominent)
                AppSurface(
                  margin: EdgeInsets.only(bottom: spacing.md),
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    leading:
                        const Icon(Icons.bug_report, color: AppColors.primary),
                    title: const Text('Beta Feedback',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text(
                        'Share your thoughts, ideas, or report bugs'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      context.go('/profile/beta-feedback');
                    },
                  ),
                ),

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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationsSettingsPage(),
                      ),
                    );
                  },
                ),
                _buildSettingsItem(
                  context,
                  icon: Icons.privacy_tip,
                  title: 'Privacy',
                  subtitle: 'Manage your privacy settings',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PrivacySettingsPage(),
                      ),
                    );
                  },
                ),
                _buildSettingsItem(
                  context,
                  icon: Icons.link,
                  title: 'Social Media',
                  subtitle: 'Connect and manage social accounts',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SocialMediaSettingsPage(),
                      ),
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
                  subtitle:
                      'On-device language + scheduled learning (device-gated)',
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const IdentityVerificationPage(),
                      ),
                    );
                  },
                ),
                _buildSettingsItem(
                  context,
                  icon: Icons.receipt_long,
                  title: 'Tax Profile',
                  subtitle: 'Manage W-9 and tax information',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TaxProfilePage(),
                      ),
                    );
                  },
                ),
                _buildSettingsItem(
                  context,
                  icon: Icons.description,
                  title: 'Tax Documents',
                  subtitle: 'View and download tax forms',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TaxDocumentsPage(),
                      ),
                    );
                  },
                ),
                _buildSettingsItem(
                  context,
                  icon: Icons.gavel,
                  title: 'Terms of Service',
                  subtitle: 'View terms and conditions',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TermsOfServicePage(),
                      ),
                    );
                  },
                ),
                _buildSettingsItem(
                  context,
                  icon: Icons.privacy_tip,
                  title: 'Privacy Policy',
                  subtitle: 'View privacy policy',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PrivacyPolicyPage(),
                      ),
                    );
                  },
                ),
                _buildSettingsItem(
                  context,
                  icon: Icons.help,
                  title: 'Help & Support',
                  subtitle: 'Get help and contact support',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HelpSupportPage(),
                      ),
                    );
                  },
                ),
                _buildSettingsItem(
                  context,
                  icon: Icons.info,
                  title: 'About',
                  subtitle: 'App version and information',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AboutPage(),
                      ),
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminDesktopHandoffPage(
                            requestedSurfaceTitle: 'God Mode Admin',
                            requestedPath: '/admin/command-center',
                          ),
                        ),
                      );
                    },
                  ),
                  _buildSettingsItem(
                    context,
                    icon: Icons.hub_outlined,
                    title: 'URK Kernel Console',
                    subtitle: 'Kernel runtime governance and activation map',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminDesktopHandoffPage(
                            requestedSurfaceTitle: 'URK Kernel Console',
                            requestedPath: '/admin/urk-kernels',
                          ),
                        ),
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
                    child: const Text('Sign Out'),
                  ),
                ),
              ],
            );
          } else {
            return const Center(
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
    return AppSurface(
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
          title: const Text('Sign Out'),
          content: const Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<AuthBloc>().add(SignOutRequested());
              },
              // Use global ElevatedButtonTheme
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );
  }
}

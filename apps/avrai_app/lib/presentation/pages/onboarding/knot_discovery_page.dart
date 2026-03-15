// Knot Discovery Page
//
// Onboarding page for discovering knot tribes and onboarding groups.
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:avrai_core/models/personality_knot.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai_runtime_os/ai/personality_learning.dart';
import 'package:avrai_runtime_os/runtime_api.dart';
import 'package:avrai/theme/colors.dart';
import 'package:avrai/theme/tokens/theme_tokens.dart';
import 'package:avrai/presentation/schema_renderer/app_schema_page.dart';
import 'package:avrai/presentation/schemas/pages/knot_discovery_page_schema.dart';
import 'package:avrai/presentation/widgets/common/app_button_primary.dart';
import 'package:avrai/presentation/widgets/common/app_button_secondary.dart';
import 'package:avrai/presentation/widgets/onboarding/knot_tribe_finder_widget.dart';
import 'package:avrai/presentation/widgets/onboarding/onboarding_knot_group_widget.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

/// Onboarding page for knot discovery.
///
/// Shows the user's personality knot, finds knot tribes, and suggests
/// onboarding groups.
class KnotDiscoveryPage extends StatefulWidget {
  final PersonalityProfile? personalityProfile;
  final String? userId;
  final String? knotBirthOutcome;
  final String? knotBirthReason;

  const KnotDiscoveryPage({
    super.key,
    this.personalityProfile,
    this.userId,
    this.knotBirthOutcome,
    this.knotBirthReason,
  });

  @override
  State<KnotDiscoveryPage> createState() => _KnotDiscoveryPageState();
}

class _KnotDiscoveryPageState extends State<KnotDiscoveryPage> {
  static const String _logName = 'KnotDiscoveryPage';

  final KnotCommunityService _knotCommunityService =
      GetIt.instance<KnotCommunityService>();
  final KnotStorageService _knotStorageService =
      GetIt.instance<KnotStorageService>();
  final PersonalityKnotService _personalityKnotService =
      GetIt.instance<PersonalityKnotService>();
  final PersonalityLearning _personalityLearning =
      GetIt.instance<PersonalityLearning>();

  bool _hasShownKnotBirthFallbackNotice = false;
  PersonalityKnot? _userKnot;
  List<KnotCommunity> _tribes = [];
  List<PersonalityProfile> _onboardingGroup = [];
  bool _isLoadingKnot = true;
  bool _isLoadingTribes = false;
  bool _isLoadingGroup = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserKnot();
  }

  Future<void> _loadUserKnot() async {
    setState(() {
      _isLoadingKnot = true;
      _error = null;
    });

    try {
      PersonalityProfile? profile = widget.personalityProfile;
      if (profile == null && widget.userId != null) {
        try {
          profile =
              await _personalityLearning.getCurrentPersonality(widget.userId!);
        } catch (e) {
          // Profile might not exist yet; continue with knot loading.
        }
      }

      if (profile == null) {
        setState(() {
          _isLoadingKnot = false;
          _error = 'Personality profile not available';
        });
        return;
      }

      final agentId = profile.agentId;
      final knot = await _knotStorageService.loadKnot(agentId);

      if (knot != null) {
        setState(() {
          _userKnot = knot;
          _isLoadingKnot = false;
        });
        await _loadTribes();
        await _loadOnboardingGroup(profile);
      } else {
        try {
          final newKnot = await _personalityKnotService.generateKnot(profile);
          await _knotStorageService.saveKnot(agentId, newKnot);
          setState(() {
            _userKnot = newKnot;
            _isLoadingKnot = false;
          });
          await _loadTribes();
          await _loadOnboardingGroup(profile);
        } catch (e, st) {
          developer.log(
            'Knot runtime unavailable; continuing without knot: $e',
            name: _logName,
            error: e,
            stackTrace: st,
          );
          setState(() {
            _userKnot = null;
            _isLoadingKnot = false;
            _error = null;
          });
          await _loadOnboardingGroup(profile);
        }
      }
    } catch (e) {
      setState(() {
        _isLoadingKnot = false;
        _error = 'Failed to load knot: $e';
      });
    }
  }

  Future<void> _loadTribes() async {
    if (_userKnot == null) return;

    setState(() => _isLoadingTribes = true);

    try {
      final tribes = await _knotCommunityService.findKnotTribe(
        userKnot: _userKnot!,
        maxResults: 10,
      );
      setState(() {
        _tribes = tribes;
        _isLoadingTribes = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingTribes = false;
      });
    }
  }

  Future<void> _loadOnboardingGroup(PersonalityProfile profile) async {
    setState(() => _isLoadingGroup = true);

    try {
      final group = await _knotCommunityService.createOnboardingKnotGroup(
        newUserProfile: profile,
        maxGroupSize: 5,
      );
      setState(() {
        _onboardingGroup = group;
        _isLoadingGroup = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingGroup = false;
      });
    }
  }

  void _handleContinue() {
    context.go('/home');
  }

  void _handleExploreWorldPlanes() {
    context.go('/world-planes');
  }

  void _showFallbackNotice() {
    if (_hasShownKnotBirthFallbackNotice) return;
    _hasShownKnotBirthFallbackNotice = true;

    if (!mounted) return;
    if (widget.knotBirthOutcome == null ||
        widget.knotBirthOutcome == 'completed') {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Knot birth used fallback mode (${widget.knotBirthReason ?? widget.knotBirthOutcome}).',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showFallbackNotice();
    });

    final pageContent = _isLoadingKnot
        ? _buildLoadingState()
        : _error != null
            ? _buildErrorState()
            : _userKnot == null
                ? _buildNoKnotState()
                : _buildContent();

    return AppSchemaPage(
      schema: buildKnotDiscoveryPageSchema(content: pageContent),
      padding: const EdgeInsets.all(16),
    );
  }

  Widget _buildLoadingState() {
    final spacing = context.spacing;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(spacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.textSecondary),
            SizedBox(height: spacing.md),
            Text(
              'Finding your knot profile',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    final spacing = context.spacing;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(spacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            SizedBox(height: spacing.md),
            Text(
              'Error Loading Knot',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: AppColors.textPrimary),
            ),
            SizedBox(height: spacing.xs),
            Text(
              _error ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            SizedBox(height: spacing.lg),
            AppButtonSecondary(
              onPressed: _handleContinue,
              child: const Text('Continue Anyway'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoKnotState() {
    final spacing = context.spacing;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(spacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.category_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: spacing.md),
            Text(
              'Knot Not Available',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: AppColors.textPrimary),
            ),
            SizedBox(height: spacing.xs),
            Text(
              'Your personality knot will be generated soon',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            SizedBox(height: spacing.lg),
            AppButtonPrimary(
              onPressed: _handleContinue,
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        _buildTabSection(),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: AppButtonPrimary(
            onPressed: _handleContinue,
            child: const Text('Continue to avrai'),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: AppButtonSecondary(
            onPressed: _handleExploreWorldPlanes,
            child: const Text('Explore World Planes'),
          ),
        ),
      ],
    );
  }

  Widget _buildTabSection() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Knot Tribes', icon: Icon(Icons.group)),
              Tab(text: 'Onboarding Group', icon: Icon(Icons.people)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 470,
            child: TabBarView(
              children: [
                KnotTribeFinderWidget(
                  userKnot: _userKnot!,
                  tribes: _tribes,
                  isLoading: _isLoadingTribes,
                  onRefresh: _loadTribes,
                  onTribeSelected: (tribe) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Selected: ${tribe.community.name}'),
                      ),
                    );
                  },
                ),
                _onboardingGroup.isEmpty && !_isLoadingGroup
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.people_outline,
                                size: 64,
                                color: AppColors.textSecondary,
                              ),
                              SizedBox(height: context.spacing.md),
                              Text(
                                'No onboarding group yet',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),
                              SizedBox(height: context.spacing.xs),
                              Text(
                                'Your onboarding group will be created as more people join',
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _isLoadingGroup
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.textSecondary,
                            ),
                          )
                        : OnboardingKnotGroupWidget(
                            groupMembers: _onboardingGroup,
                            currentUserId: widget.userId,
                          ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Knot Discovery Page
//
// Onboarding page for discovering knot tribes and onboarding groups
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Phase 3: Onboarding Integration

import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:avrai/core/design/feedback_presenter.dart';
import 'package:avrai_core/models/personality_knot.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai_knot/models/knot/knot_community.dart';
import 'package:avrai_knot/services/knot/knot_community_service.dart';
import 'package:avrai_knot/services/knot/knot_storage_service.dart';
import 'package:avrai_knot/services/knot/personality_knot_service.dart';
import 'package:avrai/core/ai/personality_learning.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/tokens/theme_tokens.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';
import 'package:avrai/presentation/widgets/onboarding/knot_tribe_finder_widget.dart';
import 'package:avrai/presentation/widgets/onboarding/onboarding_knot_group_widget.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

/// Onboarding page for knot discovery
///
/// Shows user's personality knot, finds knot tribes, and suggests onboarding groups
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

  PersonalityKnot? _userKnot;
  List<KnotCommunity> _tribes = [];
  List<PersonalityProfile> _onboardingGroup = [];
  bool _isLoadingKnot = true;
  bool _isLoadingTribes = false;
  bool _isLoadingGroup = false;
  bool _hasShownKnotBirthNotice = false;
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
      // Load personality profile if not provided
      PersonalityProfile? profile = widget.personalityProfile;
      if (profile == null && widget.userId != null) {
        try {
          profile =
              await _personalityLearning.getCurrentPersonality(widget.userId!);
        } catch (e) {
          // Profile might not exist yet, continue with knot loading
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

      // Try to load existing knot
      final knot = await _knotStorageService.loadKnot(agentId);

      if (knot != null) {
        setState(() {
          _userKnot = knot;
          _isLoadingKnot = false;
        });
        // Load tribes and group after knot is loaded
        _loadTribes();
        _loadOnboardingGroup(profile);
      } else {
        // Generate knot if it doesn't exist
        try {
          final newKnot = await _personalityKnotService.generateKnot(profile);
          await _knotStorageService.saveKnot(agentId, newKnot);
          setState(() {
            _userKnot = newKnot;
            _isLoadingKnot = false;
          });
          // Load tribes and group after knot is generated
          _loadTribes();
          _loadOnboardingGroup(profile);
        } catch (e, st) {
          // Knot generation is best-effort; onboarding must stay unblocked.
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
          // Group is optional and may still work without a knot.
          _loadOnboardingGroup(profile);
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
        // Don't set error - tribes are optional
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
        // Don't set error - group is optional
      });
    }
  }

  void _handleContinue() {
    // Navigate to home
    context.go('/home');
  }

  void _handleExploreWorldPlanes() {
    context.go('/world-planes');
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_hasShownKnotBirthNotice) return;
      if (widget.knotBirthOutcome == null ||
          widget.knotBirthOutcome == 'completed') {
        return;
      }
      _hasShownKnotBirthNotice = true;
      context.showWarning(
        'Knot birth used fallback mode (${widget.knotBirthReason ?? widget.knotBirthOutcome}).',
      );
    });

    return AdaptivePlatformPageScaffold(
      title: 'Your Personality Knot',
      automaticallyImplyLeading: false,
      body: _isLoadingKnot
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _userKnot == null
                  ? _buildNoKnotState()
                  : _buildContent(),
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
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                  ),
            ),
            SizedBox(height: spacing.xs),
            Text(
              _error ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            SizedBox(height: spacing.lg),
            ElevatedButton(
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
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                  ),
            ),
            SizedBox(height: spacing.xs),
            Text(
              'Your personality knot will be generated soon',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            SizedBox(height: spacing.lg),
            ElevatedButton(
              onPressed: _handleContinue,
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final spacing = context.spacing;
    return Column(
      children: [
        // Tab bar for switching between tribes and group
        DefaultTabController(
          length: 2,
          child: Column(
            children: [
              const TabBar(
                tabs: [
                  Tab(text: 'Knot Tribes', icon: Icon(Icons.group)),
                  Tab(text: 'Onboarding Group', icon: Icon(Icons.people)),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    // Tribes tab
                    KnotTribeFinderWidget(
                      userKnot: _userKnot!,
                      tribes: _tribes,
                      isLoading: _isLoadingTribes,
                      onRefresh: _loadTribes,
                      onTribeSelected: (tribe) {
                        // TODO: Navigate to community page or show details
                        context.showInfo('Selected: ${tribe.community.name}');
                      },
                    ),
                    // Group tab
                    _onboardingGroup.isEmpty && !_isLoadingGroup
                        ? Center(
                            child: Padding(
                              padding: EdgeInsets.all(spacing.xxl),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.people_outline,
                                    size: 64,
                                    color: AppColors.textSecondary,
                                  ),
                                  SizedBox(height: spacing.md),
                                  Text(
                                    'No onboarding group yet',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                  ),
                                  SizedBox(height: spacing.xs),
                                  Text(
                                    'Your onboarding group will be created as more people join',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : _isLoadingGroup
                            ? const Center(child: CircularProgressIndicator())
                            : OnboardingKnotGroupWidget(
                                groupMembers: _onboardingGroup,
                                currentUserId: widget.userId,
                              ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Continue button
        Padding(
          padding: EdgeInsets.all(spacing.md),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleContinue,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: spacing.md),
                  ),
                  child: const Text('Continue to avrai'),
                ),
              ),
              SizedBox(height: spacing.xs),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _handleExploreWorldPlanes,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Explore World Planes'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

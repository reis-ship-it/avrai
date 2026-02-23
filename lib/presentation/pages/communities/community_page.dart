import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avrai/core/models/community/community.dart';
import 'package:avrai/core/services/community/community_service.dart';
import 'package:avrai/core/services/user/agent_id_service.dart';
import 'package:avrai/core/ai/event_logger.dart';
import 'package:avrai/core/ai/memory/episodic/episodic_memory_store.dart';
import 'package:avrai/core/ai/memory/episodic/episodic_tuple.dart';
import 'package:avrai/core/ai/memory/episodic/outcome_taxonomy.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/injection_container.dart' as di;
import 'package:avrai_knot/models/knot/community_metrics.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/presentation/pages/events/create_community_event_page.dart';
import 'package:avrai/presentation/widgets/clubs/expertise_coverage_widget.dart';
import 'package:avrai/presentation/widgets/clubs/expansion_timeline_widget.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Community Page
/// Agent 2: Frontend & UX Specialist (Phase 6)
///
/// CRITICAL: Uses AppColors/AppTheme (100% adherence required - NO direct Colors.* usage)
///
/// Features:
/// - Display community information (name, description, founder, members, events, metrics)
/// - Community actions (join/leave, view members, view events, create event)
/// - Philosophy: Show doors (communities) that users can open
class CommunityPage extends StatefulWidget {
  /// Community ID (will be replaced with Community model when available)
  final String communityId;

  const CommunityPage({
    super.key,
    required this.communityId,
  });

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  final CommunityService _communityService = di.sl<CommunityService>();
  late EventLogger _eventLogger;
  DateTime? _viewStartTime;
  String? _currentUserId;
  bool _isLoggerInitialized = false;
  bool _hasFollowUpAction = false;

  bool _isLoading = true;
  bool _isMember = false;
  bool _isJoining = false;
  String? _error;
  Community? _community;
  CommunityMetrics? _communityMetrics;
  double? _weaveFit;

  @override
  void initState() {
    super.initState();
    _initializeEventLogger();
    _viewStartTime = DateTime.now();
    _loadCommunity();
  }

  Future<void> _initializeEventLogger() async {
    try {
      _eventLogger = di.sl<EventLogger>();
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser != null) {
        _currentUserId = currentUser.id;
        await _eventLogger.initialize(userId: currentUser.id);
        _eventLogger.updateScreen('community_details');
      }
      _isLoggerInitialized = true;
    } catch (_) {
      _isLoggerInitialized = false;
    }
  }

  Future<void> _loadCommunity() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authState = context.read<AuthBloc>().state;
      final community =
          await _communityService.getCommunityById(widget.communityId);

      if (community == null) {
        setState(() {
          _error = 'Community not found';
          _isLoading = false;
        });
        return;
      }

      // Check if user is member
      bool isMember = false;
      CommunityMetrics? metrics;
      double? weaveFit;
      if (authState is Authenticated) {
        isMember = _communityService.isMember(community, authState.user.id);

        // Best-effort: pull fabric-derived health + "your weave fit".
        metrics = await _communityService.getCommunityHealth(community.id);
        weaveFit = await _communityService.calculateUserCommunityWeaveFit(
          communityId: community.id,
          userId: authState.user.id,
        );
      }

      if (!mounted) return;
      setState(() {
        _community = community;
        _isMember = isMember;
        _communityMetrics = metrics;
        _weaveFit = weaveFit;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load community: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _joinCommunity() async {
    _hasFollowUpAction = true;
    if (_community == null) return;

    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to join communities'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isJoining = true;
      _error = null;
    });

    try {
      await _communityService.addMember(_community!, authState.user.id);

      // Reload community to get updated data
      await _loadCommunity();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully joined community!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to join community: $e';
        _isJoining = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _leaveCommunity() async {
    _hasFollowUpAction = true;
    if (_community == null) return;

    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) return;

    setState(() {
      _isJoining = true;
      _error = null;
    });

    try {
      await _communityService.removeMember(_community!, authState.user.id);

      // Reload community to get updated data
      await _loadCommunity();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Left community'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to leave community: $e';
        _isJoining = false;
      });
    }
  }

  void _viewMembers() {
    _hasFollowUpAction = true;
    // TODO: Navigate to members page when created
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Members page coming soon'),
      ),
    );
  }

  void _viewEvents() {
    _hasFollowUpAction = true;
    // TODO: Navigate to community events page when created
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Community events page coming soon'),
      ),
    );
  }

  void _createEvent() {
    _hasFollowUpAction = true;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateCommunityEventPage(),
      ),
    );
  }

  @override
  void dispose() {
    if (_isLoggerInitialized && _viewStartTime != null && !_hasFollowUpAction) {
      final duration = DateTime.now().difference(_viewStartTime!);
      _eventLogger.logBrowseNoAction(
        entityType: 'community',
        entityId: widget.communityId,
        browseDurationMs: duration.inMilliseconds,
        surface: 'community_details',
      );
      unawaited(_recordBrowseNoActionTuple(duration.inMilliseconds));
    }
    super.dispose();
  }

  Future<void> _recordBrowseNoActionTuple(int durationMs) async {
    try {
      if (!di.sl.isRegistered<EpisodicMemoryStore>() ||
          !di.sl.isRegistered<AgentIdService>()) {
        return;
      }
      final userId = _currentUserId;
      final community = _community;
      if (userId == null || userId.isEmpty || community == null) return;
      final agentIdService = di.sl<AgentIdService>();
      final episodicStore = di.sl<EpisodicMemoryStore>();
      final outcomeTaxonomy = const OutcomeTaxonomy();
      final agentId = await agentIdService.getUserAgentId(userId);

      final tuple = EpisodicTuple(
        agentId: agentId,
        stateBefore: {
          'phase_ref': '1.2.19',
          'surface': 'community_details',
          'entity_type': 'community',
          'entity_id': community.id,
        },
        actionType: 'browse_entity',
        actionPayload: {
          'entity_type': 'community',
          'entity_id': community.id,
          'entity_features': {
            'community_id': community.id,
            'member_count': community.memberCount,
            'event_count': community.eventCount,
            'engagement_score': community.engagementScore,
            'diversity_score': community.diversityScore,
          },
          'no_action': true,
          'browse_context': {
            'duration_ms': durationMs,
            'surface': 'community_details',
          },
        },
        nextState: const {
          'no_action': true,
          'browse_session_complete': true,
        },
        outcome: outcomeTaxonomy.classify(
          eventType: 'no_action',
          parameters: {
            'entity_type': 'community',
            'entity_id': community.id,
            'duration_ms': durationMs,
            'surface': 'community_details',
          },
        ),
        metadata: const {
          'phase_ref': '1.2.19',
          'pipeline': 'community_page',
        },
      );
      await episodicStore.writeTuple(tuple);
    } catch (_) {
      // Non-critical on teardown.
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdaptivePlatformPageScaffold(
      title: _community?.name ?? 'Community',
      constrainBody: false,
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading community...',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Semantics(
                          label: 'Error loading community',
                          child: const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: AppColors.error,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Unable to load community',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _loadCommunity,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: AppColors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadCommunity,
                  color: AppTheme.primaryColor,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWideScreen = constraints.maxWidth > 600;
                      return SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: isWideScreen ? 24.0 : 0.0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header Section
                                _buildHeaderSection(),

                                // Actions Section
                                _buildActionsSection(),

                                // Information Section
                                _buildInformationSection(),

                                // Metrics Section
                                _buildMetricsSection(),

                                // Geographic Section
                                if (_community != null &&
                                    (_community!.originalLocality.isNotEmpty ||
                                        _community!
                                            .currentLocalities.isNotEmpty))
                                  _buildGeographicSection(),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildHeaderSection() {
    if (_community == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _community!.name,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          if (_community!.description != null &&
              _community!.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              _community!.description!,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                Icons.person,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    Text(
                      'Founded by ${_community!.founderId.substring(0, 8)}...',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    // TODO: Check if founder is golden expert using GoldenExpertAIInfluenceService
                    // if (isFounderGoldenExpert) ...[
                    //   const SizedBox(width: 8),
                    //   GoldenExpertIndicator(
                    //     userId: _community!.founderId,
                    //     locality: _community!.originalLocality.isNotEmpty
                    //         ? _community!.originalLocality
                    //         : null,
                    //     displayStyle: GoldenExpertDisplayStyle.badge,
                    //     size: 16,
                    //   ),
                    // ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              label: _isMember ? 'Leave community' : 'Join community',
              button: true,
              child: ElevatedButton.icon(
                onPressed: _isJoining
                    ? null
                    : (_isMember ? _leaveCommunity : _joinCommunity),
                icon: _isJoining
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(AppColors.white),
                        ),
                      )
                    : Icon(_isMember ? Icons.exit_to_app : Icons.person_add),
                label: Text(_isJoining
                    ? (_isMember ? 'Leaving...' : 'Joining...')
                    : (_isMember ? 'Leave' : 'Join')),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _isMember ? AppColors.grey200 : AppTheme.primaryColor,
                  foregroundColor:
                      _isMember ? AppColors.textPrimary : AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Semantics(
              label: 'View community members',
              button: true,
              child: OutlinedButton.icon(
                onPressed: _viewMembers,
                icon: const Icon(Icons.people),
                label: Text('Members (${_community?.memberCount ?? 0})'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInformationSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Information',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            icon: Icons.event,
            title: 'Events',
            value: '${_community?.eventCount ?? 0} events',
            onTap: _viewEvents,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.people,
            title: 'Members',
            value: '${_community?.memberCount ?? 0} members',
            onTap: _viewMembers,
          ),
          if (_isMember) ...[
            const SizedBox(height: 12),
            _buildInfoCard(
              icon: Icons.add_circle,
              title: 'Create Event',
              value: 'Host a community event',
              onTap: _createEvent,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    VoidCallback? onTap,
  }) {
    return Semantics(
      label: '$title: $value',
      button: onTap != null,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.grey300),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: AppTheme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textSecondary,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Metrics',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'Engagement',
                  value:
                      '${((_community?.engagementScore ?? 0.0) * 100).toStringAsFixed(0)}%',
                  icon: Icons.trending_up,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: 'Diversity',
                  value:
                      '${((_community?.diversityScore ?? 0.0) * 100).toStringAsFixed(0)}%',
                  icon: Icons.diversity_3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'Knot Cohesion',
                  value: _communityMetrics == null
                      ? '—'
                      : '${(_communityMetrics!.cohesion * 100).toStringAsFixed(0)}%',
                  icon: Icons.hub,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: 'Your Weave Fit',
                  value: _weaveFit == null
                      ? '—'
                      : '${(_weaveFit! * 100).toStringAsFixed(0)}%',
                  icon: Icons.auto_awesome,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildMetricCard(
            title: 'Activity Level',
            value: _community?.getActivityLevelDisplayName().toUpperCase() ??
                'ACTIVE',
            icon: Icons.trending_up,
            fullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    bool fullWidth = false,
  }) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeographicSection() {
    if (_community == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Geographic Coverage',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          // Expertise Coverage Widget (with expansion tracking)
          ExpertiseCoverageWidget(
            originalLocality: _community!.originalLocality,
            currentLocalities: _community!.currentLocalities,
            // TODO: Add coverageData when GeographicExpansionService is available
            coverageData: const {},
            localityCoverage: const {},
          ),
          const SizedBox(height: 24),
          // Expansion Timeline
          ExpansionTimelineWidget(
            originalLocality: _community!.originalLocality,
            // TODO: Add expansion history when GeographicExpansionService is available
            expansionHistory: const [],
            coverageMilestones: const [],
            eventsByLocality: const {},
            commutePatterns: const {},
            coverageOverTime: const {},
          ),
          const SizedBox(height: 24),
          // Expansion Progress Summary
          _buildExpansionProgressSummary(),
        ],
      ),
    );
  }

  Widget _buildExpansionProgressSummary() {
    if (_community == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.trending_up,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Expansion Progress',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildLocationCard(
            icon: Icons.location_on,
            title: 'Original Locality',
            value: _community!.originalLocality,
          ),
          if (_community!.currentLocalities.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildLocationCard(
              icon: Icons.map,
              title: 'Current Localities',
              value: _community!.currentLocalities.join(', '),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Active in ${_community!.currentLocalities.length} locality(ies)',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey300),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

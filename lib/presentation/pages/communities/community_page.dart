import 'package:flutter/material.dart';
import 'package:avrai/core/navigation/app_navigator.dart';
import 'package:avrai/core/design/feedback_presenter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avrai/core/models/community/community.dart';
import 'package:avrai/core/services/community/community_service.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/core/theme/tokens/theme_tokens.dart';
import 'package:avrai/injection_container.dart' as di;
import 'package:avrai_knot/models/knot/community_metrics.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/presentation/pages/events/create_community_event_page.dart';
import 'package:avrai/presentation/widgets/clubs/expertise_coverage_widget.dart';
import 'package:avrai/presentation/widgets/clubs/expansion_timeline_widget.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';
import 'package:avrai/presentation/widgets/portal/portal_surface.dart';
import 'package:avrai/presentation/presentation_spacing.dart';

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
    _loadCommunity();
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
    if (_community == null) return;

    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) {
      context.showError('Please sign in to join communities');
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
        context.showSuccess('Successfully joined community!');
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to join community: $e';
        _isJoining = false;
      });

      if (mounted) {
        context.showError('Error: $e');
      }
    }
  }

  Future<void> _leaveCommunity() async {
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
        context.showSuccess('Left community');
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to leave community: $e';
        _isJoining = false;
      });
    }
  }

  void _viewMembers() {
    // TODO: Navigate to members page when created
    context.showInfo('Members page coming soon');
  }

  void _viewEvents() {
    // TODO: Navigate to community events page when created
    context.showInfo('Community events page coming soon');
  }

  void _createEvent() {
    AppNavigator.pushBuilder(
      context,
      builder: (context) => const CreateCommunityEventPage(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdaptivePlatformPageScaffold(
      title: _community?.name ?? 'Community',
      constrainBody: false,
      backgroundColor: AppColors.background,
      body: _isLoading
          ? Center(
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
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(context.spacing.xl),
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
                        SizedBox(height: context.spacing.md),
                        Text(
                          'Unable to load community',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: context.spacing.xs),
                        Text(
                          _error!,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: context.spacing.xl),
                        ElevatedButton.icon(
                          onPressed: _loadCommunity,
                          icon: const Icon(Icons.refresh),
                          label: Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: AppColors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: kSpaceLg,
                              vertical: kSpaceSm,
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
                              horizontal: isWideScreen ? kSpaceLg : kSpaceNone,
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
      padding: EdgeInsets.all(context.spacing.lg),
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _community!.name,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
          ),
          if (_community!.description != null &&
              _community!.description!.isNotEmpty) ...[
            SizedBox(height: context.spacing.sm),
            Text(
              _community!.description!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
          SizedBox(height: context.spacing.md),
          Row(
            children: [
              const Icon(
                Icons.person,
                size: 16,
                color: AppColors.textSecondary,
              ),
              SizedBox(width: context.spacing.xs),
              Expanded(
                child: Row(
                  children: [
                    Text(
                      'Founded by ${_community!.founderId.substring(0, 8)}...',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    // TODO: Check if founder is golden expert using GoldenExpertAIInfluenceService
                    // if (isFounderGoldenExpert) ...[
                    //   SizedBox(width: context.spacing.xs),
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
      padding: EdgeInsets.all(context.spacing.md),
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
                  padding: EdgeInsets.symmetric(vertical: context.spacing.sm),
                ),
              ),
            ),
          ),
          SizedBox(width: context.spacing.sm),
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
                  padding: EdgeInsets.symmetric(vertical: context.spacing.sm),
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
      padding: EdgeInsets.symmetric(horizontal: context.spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Information',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
          ),
          SizedBox(height: context.spacing.md),
          _buildInfoCard(
            icon: Icons.event,
            title: 'Events',
            value: '${_community?.eventCount ?? 0} events',
            onTap: _viewEvents,
          ),
          SizedBox(height: context.spacing.sm),
          _buildInfoCard(
            icon: Icons.people,
            title: 'Members',
            value: '${_community?.memberCount ?? 0} members',
            onTap: _viewMembers,
          ),
          if (_isMember) ...[
            SizedBox(height: context.spacing.sm),
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
        child: PortalSurface(
          padding: EdgeInsets.all(context.spacing.md),
          color: AppColors.surface,
          borderColor: AppColors.grey300,
          radius: context.radius.md,
          child: Row(
            children: [
              Icon(
                icon,
                color: AppTheme.primaryColor,
                size: 24,
              ),
              SizedBox(width: context.spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    SizedBox(height: context.spacing.xxs),
                    Text(
                      value,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
      padding: EdgeInsets.all(context.spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Metrics',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
          ),
          SizedBox(height: context.spacing.md),
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
              SizedBox(width: context.spacing.sm),
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
          SizedBox(height: context.spacing.sm),
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
              SizedBox(width: context.spacing.sm),
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
          SizedBox(height: context.spacing.sm),
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
    final card = PortalSurface(
      padding: EdgeInsets.all(context.spacing.md),
      color: AppColors.surface,
      borderColor: AppColors.grey300,
      radius: context.radius.md,
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
              SizedBox(width: context.spacing.xs),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
          SizedBox(height: context.spacing.xs),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
          ),
        ],
      ),
    );

    if (fullWidth) {
      return SizedBox(width: double.infinity, child: card);
    }
    return card;
  }

  Widget _buildGeographicSection() {
    if (_community == null) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(context.spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Geographic Coverage',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
          ),
          SizedBox(height: context.spacing.md),
          // Expertise Coverage Widget (with expansion tracking)
          ExpertiseCoverageWidget(
            originalLocality: _community!.originalLocality,
            currentLocalities: _community!.currentLocalities,
            // TODO: Add coverageData when GeographicExpansionService is available
            coverageData: const {},
            localityCoverage: const {},
          ),
          SizedBox(height: context.spacing.xl),
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
          SizedBox(height: context.spacing.xl),
          // Expansion Progress Summary
          _buildExpansionProgressSummary(),
        ],
      ),
    );
  }

  Widget _buildExpansionProgressSummary() {
    if (_community == null) return const SizedBox.shrink();

    return PortalSurface(
      padding: EdgeInsets.all(context.spacing.md),
      color: AppColors.surface,
      borderColor: AppColors.grey300,
      radius: context.radius.md,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.trending_up,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Expansion Progress',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
              ),
            ],
          ),
          SizedBox(height: context.spacing.md),
          _buildLocationCard(
            icon: Icons.location_on,
            title: 'Original Locality',
            value: _community!.originalLocality,
          ),
          if (_community!.currentLocalities.isNotEmpty) ...[
            SizedBox(height: context.spacing.sm),
            _buildLocationCard(
              icon: Icons.map,
              title: 'Current Localities',
              value: _community!.currentLocalities.join(', '),
            ),
            SizedBox(height: context.spacing.sm),
            PortalSurface(
              padding: EdgeInsets.all(context.spacing.sm),
              color: AppColors.grey100,
              borderColor: AppColors.grey300,
              radius: context.radius.sm,
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(width: context.spacing.xs),
                  Expanded(
                    child: Text(
                      'Active in ${_community!.currentLocalities.length} locality(ies)',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
    return PortalSurface(
      padding: EdgeInsets.all(context.spacing.md),
      color: AppColors.surface,
      borderColor: AppColors.grey300,
      radius: context.radius.md,
      child: Row(
        children: [
          Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 24,
          ),
          SizedBox(width: context.spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                SizedBox(height: context.spacing.xxs),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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

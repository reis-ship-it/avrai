import 'package:flutter/material.dart';
import 'package:avrai/core/navigation/app_navigator.dart';
import 'package:avrai/core/design/feedback_presenter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avrai/core/models/community/club.dart';
import 'package:avrai/core/models/community/club_hierarchy.dart';
import 'package:avrai/core/services/community/club_service.dart';
import 'package:avrai/core/services/community/community_service.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/core/theme/tokens/theme_tokens.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/presentation/pages/events/create_community_event_page.dart';
import 'package:avrai/presentation/widgets/clubs/expertise_coverage_widget.dart';
import 'package:avrai/presentation/widgets/clubs/expansion_timeline_widget.dart';
import 'package:avrai/presentation/widgets/golden_expert_indicator.dart';
import 'package:avrai/presentation/widgets/boundaries/border_visualization_widget.dart';
import 'package:avrai/presentation/widgets/boundaries/border_management_widget.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';
import 'package:avrai/presentation/widgets/portal/portal_surface.dart';
import 'package:avrai/presentation/presentation_spacing.dart';

/// Club Page
/// Agent 2: Frontend & UX Specialist (Phase 6, Week 29)
///
/// CRITICAL: Uses AppColors/AppTheme (100% adherence required - NO direct Colors.* usage)
///
/// Features:
/// - Display club information (name, description, leaders, admins, members, events, metrics)
/// - Club actions (join/leave, view members, view events, create event, manage members/roles)
/// - Organizational structure display (hierarchy, roles, permissions)
/// - Philosophy: Show doors (clubs) that users can open
class ClubPage extends StatefulWidget {
  /// Club ID (will be replaced with Club model when available)
  final String clubId;

  const ClubPage({
    super.key,
    required this.clubId,
  });

  @override
  State<ClubPage> createState() => _ClubPageState();
}

class _ClubPageState extends State<ClubPage> {
  final ClubService _clubService = ClubService();
  final CommunityService _communityService = CommunityService();

  bool _isLoading = true;
  bool _isMember = false;
  bool _isLeader = false;
  bool _isAdmin = false;
  bool _isJoining = false;
  String? _error;
  Club? _club;
  ClubRole? _userRole;

  @override
  void initState() {
    super.initState();
    _loadClub();
  }

  Future<void> _loadClub() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final club = await _clubService.getClubById(widget.clubId);

      if (club == null) {
        setState(() {
          _error = 'Club not found';
          _isLoading = false;
        });
        return;
      }

      // Check if user is member/leader/admin
      if (!mounted) return;
      final authState = context.read<AuthBloc>().state;
      bool isMember = false;
      bool isLeader = false;
      bool isAdmin = false;
      ClubRole? userRole;

      if (authState is Authenticated) {
        final userId = authState.user.id;
        isMember = club.isMember(userId);
        isLeader = _clubService.isLeader(club, userId);
        isAdmin = _clubService.isAdmin(club, userId);
        userRole = _clubService.getMemberRole(club, userId);
      }

      setState(() {
        _club = club;
        _isMember = isMember;
        _isLeader = isLeader;
        _isAdmin = isAdmin;
        _userRole = userRole;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load club: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _joinClub() async {
    if (_club == null) return;

    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) {
      context.showError('Please sign in to join clubs');
      return;
    }

    setState(() {
      _isJoining = true;
      _error = null;
    });

    try {
      // Use CommunityService to add member (Club extends Community)
      await _communityService.addMember(_club!, authState.user.id);

      // Reload club to get updated data
      await _loadClub();

      if (mounted) {
        context.showSuccess('Successfully joined club!');
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to join club: $e';
        _isJoining = false;
      });

      if (mounted) {
        context.showError('Error: $e');
      }
    }
  }

  Future<void> _leaveClub() async {
    if (_club == null) return;

    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) return;

    setState(() {
      _isJoining = true;
      _error = null;
    });

    try {
      // Use CommunityService to remove member (Club extends Community)
      await _communityService.removeMember(_club!, authState.user.id);

      // Reload club to get updated data
      await _loadClub();

      if (mounted) {
        context.showSuccess('Left club');
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to leave club: $e';
        _isJoining = false;
      });
    }
  }

  void _viewMembers() {
    // TODO: Navigate to members page when created
    context.showInfo('Members page coming soon');
  }

  void _viewEvents() {
    // TODO: Navigate to club events page when created
    context.showInfo('Club events page coming soon');
  }

  void _createEvent() {
    AppNavigator.pushBuilder(
      context,
      builder: (context) => const CreateCommunityEventPage(),
    );
  }

  void _manageMembers() {
    // TODO: Navigate to member management page when created
    context.showInfo('Member management page coming soon');
  }

  bool _hasPermission(String permission) {
    if (_club == null) return false;

    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) return false;

    return _clubService.hasPermission(_club!, authState.user.id, permission);
  }

  @override
  Widget build(BuildContext context) {
    return AdaptivePlatformPageScaffold(
      title: _club?.name ?? 'Club',
      backgroundColor: AppColors.background,
      appBarBackgroundColor: AppTheme.primaryColor,
      appBarForegroundColor: AppColors.white,
      appBarElevation: 0,
      constrainBody: false,
      actions: [
        if (_isLeader || _isAdmin)
          Semantics(
            label: 'Manage club settings',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.settings),
              onPressed: _manageMembers,
              tooltip: 'Manage Club',
            ),
          ),
      ],
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
                    'Loading club...',
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: AppColors.textSecondary),
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
                          label: 'Error loading club',
                          child: const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: AppColors.error,
                          ),
                        ),
                        SizedBox(height: context.spacing.md),
                        Text(
                          'Unable to load club',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: context.spacing.xs),
                        Text(
                          _error!,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: context.spacing.xl),
                        ElevatedButton.icon(
                          onPressed: _loadClub,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: AppColors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: context.spacing.xl,
                              vertical: context.spacing.sm,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadClub,
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

                                // Organizational Structure Section
                                _buildOrganizationalStructureSection(),

                                // Information Section
                                _buildInformationSection(),

                                // Metrics Section
                                _buildMetricsSection(),

                                // Expertise Coverage Section (prepared for Week 30)
                                if (_club != null &&
                                    (_club!.originalLocality.isNotEmpty ||
                                        _club!.currentLocalities.isNotEmpty))
                                  _buildExpertiseCoverageSection(),
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
    return Container(
      padding: EdgeInsets.all(context.spacing.lg),
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _club?.name ?? 'Club',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary),
                ),
              ),
              Chip(
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                side: BorderSide(color: AppTheme.primaryColor),
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                labelPadding: EdgeInsets.zero,
                label: Text(
                  'CLUB',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                ),
              ),
            ],
          ),
          if (_club?.description != null && _club!.description!.isNotEmpty) ...[
            SizedBox(height: context.spacing.sm),
            Text(
              _club!.description!,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ],
          if (_userRole != null) ...[
            SizedBox(height: context.spacing.md),
            Chip(
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              side: BorderSide.none,
              backgroundColor: AppColors.grey200,
              labelPadding: EdgeInsets.zero,
              label: Text(
                'Your Role: ${_userRole!.getDisplayName()}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
            ),
          ],
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
              label: _isMember ? 'Leave club' : 'Join club',
              button: true,
              child: ElevatedButton.icon(
                onPressed:
                    _isJoining ? null : (_isMember ? _leaveClub : _joinClub),
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
              label: 'View club members',
              button: true,
              child: OutlinedButton.icon(
                onPressed: _viewMembers,
                icon: const Icon(Icons.people),
                label: Text('Members (${_club?.memberCount ?? 0})'),
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

  Widget _buildOrganizationalStructureSection() {
    return Container(
      padding: EdgeInsets.all(context.spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Organizational Structure',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          SizedBox(height: context.spacing.md),
          if (_club != null) ...[
            if (_club!.leaders.isNotEmpty)
              _buildRoleSection(
                title: 'Leaders',
                memberIds: _club!.leaders,
                icon: Icons.star,
                color: AppTheme.primaryColor,
              ),
            if (_club!.adminTeam.isNotEmpty) ...[
              if (_club!.leaders.isNotEmpty)
                SizedBox(height: context.spacing.sm),
              _buildRoleSection(
                title: 'Admins',
                memberIds: _club!.adminTeam,
                icon: Icons.admin_panel_settings,
                color: AppColors.textSecondary,
              ),
            ],
            if (_club!.memberCount > 0) ...[
              SizedBox(height: context.spacing.sm),
              _buildRoleSection(
                title: 'Members',
                memberIds: _club!.memberIds.take(10).toList(), // Show first 10
                icon: Icons.people,
                color: AppColors.textSecondary,
                showCount: true,
                totalCount: _club!.memberCount,
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildRoleSection({
    required String title,
    required List<String> memberIds,
    required IconData icon,
    required Color color,
    bool showCount = false,
    int? totalCount,
  }) {
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
              Icon(icon, color: color, size: 20),
              SizedBox(width: context.spacing.xs),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              if (showCount && totalCount != null) ...[
                SizedBox(width: context.spacing.xs),
                Text(
                  '($totalCount)',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ],
          ),
          if (memberIds.isNotEmpty) ...[
            SizedBox(height: context.spacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: memberIds.take(10).map((memberId) {
                // TODO: Load member names from user service
                return Chip(
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  side: BorderSide.none,
                  backgroundColor: AppColors.grey200,
                  labelPadding: EdgeInsets.zero,
                  label: Text(
                    'User ${memberId.substring(0, 8)}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textPrimary),
                  ),
                );
              }).toList(),
            ),
          ] else
            Text(
              'No $title',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
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
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          SizedBox(height: context.spacing.md),
          _buildInfoCard(
            icon: Icons.event,
            title: 'Events',
            value: '${_club?.eventCount ?? 0} events',
            onTap: _viewEvents,
          ),
          SizedBox(height: context.spacing.sm),
          _buildInfoCard(
            icon: Icons.people,
            title: 'Members',
            value: '${_club?.memberCount ?? 0} members',
            onTap: _viewMembers,
          ),
          if (_isMember && _hasPermission('canCreateEvents')) ...[
            SizedBox(height: context.spacing.sm),
            _buildInfoCard(
              icon: Icons.add_circle,
              title: 'Create Event',
              value: 'Host a club event',
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
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary),
                    ),
                    SizedBox(height: context.spacing.xxs),
                    Text(
                      value,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppColors.textSecondary),
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
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          SizedBox(height: context.spacing.md),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'Maturity',
                  value:
                      '${((_club?.organizationalMaturity ?? 0.0) * 100).toStringAsFixed(0)}%',
                  icon: Icons.trending_up,
                ),
              ),
              SizedBox(width: context.spacing.sm),
              Expanded(
                child: _buildMetricCard(
                  title: 'Stability',
                  value:
                      '${((_club?.leadershipStability ?? 0.0) * 100).toStringAsFixed(0)}%',
                  icon: Icons.verified,
                ),
              ),
            ],
          ),
          SizedBox(height: context.spacing.sm),
          _buildMetricCard(
            title: 'Engagement',
            value:
                '${((_club?.engagementScore ?? 0.0) * 100).toStringAsFixed(0)}%',
            icon: Icons.favorite,
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
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          SizedBox(height: context.spacing.xs),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
        ],
      ),
    );

    if (fullWidth) {
      return SizedBox(width: double.infinity, child: card);
    }
    return card;
  }

  Widget _buildExpertiseCoverageSection() {
    if (_club == null) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(context.spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Expertise Coverage',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          SizedBox(height: context.spacing.md),
          ExpertiseCoverageWidget(
            originalLocality: _club!.originalLocality,
            currentLocalities: _club!.currentLocalities,
            coverageData: _club!.coveragePercentage,
            // TODO: Add localityCoverage when GeographicExpansionService is available
            localityCoverage: const {},
          ),
          SizedBox(height: context.spacing.xl),
          // Expansion Timeline
          ExpansionTimelineWidget(
            originalLocality: _club!.originalLocality,
            // TODO: Add expansion history when GeographicExpansionService is available
            expansionHistory: const [],
            coverageMilestones: const [],
            eventsByLocality: const {},
            commutePatterns: const {},
            coverageOverTime: const {},
          ),
          SizedBox(height: context.spacing.xl),
          // Border Visualization (Week 32 - Neighborhood Boundaries)
          if (_club!.originalLocality.isNotEmpty ||
              _club!.currentLocalities.isNotEmpty)
            _buildBorderVisualizationSection(),
          SizedBox(height: context.spacing.xl),
          // Leader Expertise Display
          if (_club!.leaders.isNotEmpty) _buildLeaderExpertiseSection(),
        ],
      ),
    );
  }

  Widget _buildBorderVisualizationSection() {
    if (_club == null) return const SizedBox.shrink();

    // Get city from locality (simplified - in production, extract from locality data)
    final city = _club!.originalLocality.isNotEmpty
        ? _extractCityFromLocality(_club!.originalLocality)
        : 'New York'; // Default

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Neighborhood Boundaries',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        SizedBox(height: context.spacing.xs),
        Text(
          'View boundaries between localities to understand community connections',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppColors.textSecondary),
        ),
        SizedBox(height: context.spacing.md),
        // Border Visualization Widget
        SizedBox(
          height: 300,
          child: PortalSurface(
            padding: EdgeInsets.zero,
            color: AppColors.surface,
            borderColor: AppColors.grey300,
            radius: context.radius.sm,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(context.radius.sm),
              child: BorderVisualizationWidget(
                city: city,
                locality: _club!.originalLocality.isNotEmpty
                    ? _club!.originalLocality
                    : null,
                showSoftBorderSpots: true,
                showRefinementIndicators: true,
                onBorderTapped: (locality1, locality2) {
                  // Show border management dialog
                  _showBorderManagementDialog(
                      context, locality1, locality2, city);
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _extractCityFromLocality(String locality) {
    // Simplified extraction - in production, use geographic hierarchy service
    // For now, return common cities based on locality patterns
    final lowerLocality = locality.toLowerCase();
    if (lowerLocality.contains('brooklyn') ||
        lowerLocality.contains('manhattan') ||
        lowerLocality.contains('queens') ||
        lowerLocality.contains('bronx')) {
      return 'New York';
    }
    if (lowerLocality.contains('hollywood') ||
        lowerLocality.contains('santa monica') ||
        lowerLocality.contains('venice')) {
      return 'Los Angeles';
    }
    if (lowerLocality.contains('loop') ||
        lowerLocality.contains('river north') ||
        lowerLocality.contains('wicker park')) {
      return 'Chicago';
    }
    return 'New York'; // Default
  }

  void _showBorderManagementDialog(
    BuildContext context,
    String locality1,
    String locality2,
    String city,
  ) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(context.spacing.md),
                color: AppColors.grey100,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Border: $locality1 / $locality2',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Border Management Widget
              Expanded(
                child: BorderManagementWidget(
                  locality1: locality1,
                  locality2: locality2,
                  city: city,
                  showRefinementHistory: true,
                  showSoftBorderSpots: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderExpertiseSection() {
    if (_club == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Leader Expertise',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        SizedBox(height: context.spacing.md),
        ..._club!.leaders.map((leaderId) {
          return Padding(
            padding: EdgeInsets.only(bottom: context.spacing.sm),
            child: _buildLeaderExpertiseCard(leaderId: leaderId),
          );
        }),
      ],
    );
  }

  Widget _buildLeaderExpertiseCard({required String leaderId}) {
    // TODO: Load leader expertise from ClubService when available
    // TODO: Check if leader is golden expert using GoldenExpertAIInfluenceService
    // For now, show placeholder with golden expert indicator support
    const isGoldenExpert = false; // TODO: Check golden expert status
    final locality = _club?.originalLocality; // TODO: Get leader's locality

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
              CircleAvatar(
                radius: context.radius.lg,
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                child: const Icon(
                  Icons.star,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
              SizedBox(width: context.spacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Leader ${leaderId.substring(0, 8)}...',
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary),
                        ),
                        // ignore: dead_code - Reserved for future golden expert feature
                        if (isGoldenExpert && locality != null) ...[
                          SizedBox(width: context.spacing.xs),
                          GoldenExpertIndicator(
                            userId: leaderId,
                            locality: locality,
                            displayStyle: GoldenExpertDisplayStyle.badge,
                            size: 18,
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: context.spacing.xxs),
                    Text(
                      'Expertise gained through club expansion',
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
          SizedBox(height: context.spacing.sm),
          // TODO: Show actual expertise levels when available
          PortalSurface(
            padding: EdgeInsets.all(context.spacing.sm),
            color: AppColors.grey100,
            borderColor: AppColors.grey300,
            radius: context.radius.sm,
            child: Row(
              children: [
                const Icon(
                  Icons.location_on,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                SizedBox(width: context.spacing.xs),
                Expanded(
                  child: Text(
                    'Expertise in ${_club!.currentLocalities.length} locality(ies)',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
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

/// User Reservation Analytics Page
///
/// Phase 7.1: User Reservation Analytics
/// Enhanced with Full Knot/String/Fabric/Worldsheet/Quantum/AI2AI Integration
///
/// Comprehensive analytics dashboard for user reservations including:
/// - Basic metrics (history, patterns, rates)
/// - Knot string evolution patterns (recurring reservations)
/// - Fabric stability analytics (group reservations)
/// - Worldsheet evolution tracking (temporal patterns)
/// - Quantum compatibility history
/// - AI2AI mesh learning insights
///
/// Uses AppColors/AppTheme for 100% design token compliance.
library;

import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avrai/core/services/reservation/reservation_analytics_service.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/core/theme/tokens/theme_tokens.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/injection_container.dart' as di;
import 'package:fl_chart/fl_chart.dart';
import 'package:avrai_knot/services/knot/knot_evolution_string_service.dart'
    show TrendType;
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';
import 'package:avrai/presentation/widgets/portal/portal_surface.dart';

/// User Reservation Analytics Page
class UserReservationAnalyticsPage extends StatefulWidget {
  const UserReservationAnalyticsPage({super.key});

  @override
  State<UserReservationAnalyticsPage> createState() =>
      _UserReservationAnalyticsPageState();
}

class _UserReservationAnalyticsPageState
    extends State<UserReservationAnalyticsPage> {
  late final ReservationAnalyticsService _analyticsService;
  UserReservationAnalytics? _analytics;
  bool _isLoading = true;
  String? _error;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _analyticsService = di.sl<ReservationAnalyticsService>();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) {
      setState(() {
        _isLoading = false;
        _error = 'Not authenticated';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final analytics = await _analyticsService.getUserAnalytics(
        userId: authState.user.id,
        startDate: _startDate,
        endDate: _endDate,
      );

      setState(() {
        _analytics = analytics;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      developer.log(
        'Error loading reservation analytics: $e',
        name: 'UserReservationAnalyticsPage',
        error: e,
        stackTrace: stackTrace,
      );
      setState(() {
        _error = _getUserFriendlyErrorMessage(e);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdaptivePlatformPageScaffold(
      title: 'Reservation Analytics',
      appBarBackgroundColor: AppTheme.primaryColor,
      appBarForegroundColor: AppColors.white,
      constrainBody: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadAnalytics,
          tooltip: 'Refresh',
        ),
        IconButton(
          icon: const Icon(Icons.date_range),
          onPressed: _showDateRangePicker,
          tooltip: 'Select Date Range',
        ),
      ],
      body: _isLoading
          ? Semantics(
              label: 'Loading reservation analytics',
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppTheme.primaryColor,
                ),
              ),
            )
          : _error != null
              ? _buildErrorState()
              : _analytics == null
                  ? _buildEmptyState()
                  : _buildAnalyticsContent(),
    );
  }

  Widget _buildErrorState() {
    return Semantics(
      label: 'Error loading analytics: $_error',
      liveRegion: true,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Semantics(
              label: 'Error icon',
              child: Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.error,
              ),
            ),
            SizedBox(height: context.spacing.md),
            Text(
              _error!,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: context.spacing.md),
            Semantics(
              label: 'Retry loading analytics',
              button: true,
              child: ElevatedButton(
                onPressed: _loadAnalytics,
                child: Text('Retry'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 64,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: context.spacing.md),
          Text(
            'No reservation data available',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: context.spacing.xs),
          Text(
            'Your reservation analytics will appear here once you make reservations',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(context.spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          _buildSummaryCards(),
          SizedBox(height: context.spacing.xl),

          // Favorite Spots
          if (_analytics!.favoriteSpots.isNotEmpty) ...[
            _buildSectionTitle('Favorite Spots'),
            SizedBox(height: context.spacing.xs),
            _buildFavoriteSpots(),
            SizedBox(height: context.spacing.xl),
          ],

          // Reservation Patterns
          _buildSectionTitle('Reservation Patterns'),
          SizedBox(height: context.spacing.xs),
          _buildPatternsSection(),
          SizedBox(height: context.spacing.xl),

          // Modification Patterns
          if (_analytics!.modificationPatterns.totalModifications > 0) ...[
            _buildSectionTitle('Modification Patterns'),
            SizedBox(height: context.spacing.xs),
            _buildModificationPatterns(),
            SizedBox(height: context.spacing.xl),
          ],

          // Waitlist History
          if (_analytics!.waitlistHistory.totalWaitlistJoins > 0) ...[
            _buildSectionTitle('Waitlist History'),
            SizedBox(height: context.spacing.xs),
            _buildWaitlistHistory(),
            SizedBox(height: context.spacing.xl),
          ],

          // Knot String Evolution Patterns (Phase 7.1 Enhancement)
          if (_analytics!.stringEvolutionPatterns != null) ...[
            Semantics(
              label: 'Knot string evolution patterns section',
              header: true,
              child: _buildSectionTitle(
                  'Recurring Patterns (Knot String Evolution)'),
            ),
            SizedBox(height: context.spacing.xs),
            Semantics(
              label:
                  'Recurring reservation patterns based on knot string evolution',
              child: _buildStringEvolutionPatterns(),
            ),
            SizedBox(height: context.spacing.xl),
          ],

          // Fabric Stability Analytics (Phase 7.1 Enhancement)
          if (_analytics!.fabricStabilityAnalytics != null) ...[
            Semantics(
              label: 'Fabric stability analytics section',
              header: true,
              child:
                  _buildSectionTitle('Group Compatibility (Fabric Stability)'),
            ),
            SizedBox(height: context.spacing.xs),
            Semantics(
              label:
                  'Group reservation compatibility based on fabric stability',
              child: _buildFabricStabilityAnalytics(),
            ),
            SizedBox(height: context.spacing.xl),
          ],

          // Worldsheet Evolution Analytics (Phase 7.1 Enhancement)
          if (_analytics!.worldsheetEvolutionAnalytics != null) ...[
            Semantics(
              label: 'Worldsheet evolution analytics section',
              header: true,
              child: _buildSectionTitle('Temporal Evolution (4D Worldsheets)'),
            ),
            SizedBox(height: context.spacing.xs),
            Semantics(
              label:
                  'Temporal evolution patterns based on 4D worldsheet analysis',
              child: _buildWorldsheetEvolutionAnalytics(),
            ),
            SizedBox(height: context.spacing.xl),
          ],

          // Quantum Compatibility History (Phase 7.1 Enhancement)
          if (_analytics!.quantumCompatibilityHistory != null) ...[
            Semantics(
              label: 'Quantum compatibility history section',
              header: true,
              child: _buildSectionTitle('Quantum Compatibility History'),
            ),
            SizedBox(height: context.spacing.xs),
            Semantics(
              label: 'Historical quantum compatibility scores for reservations',
              child: _buildQuantumCompatibilityHistory(),
            ),
            SizedBox(height: context.spacing.xl),
          ],

          // AI2AI Learning Insights (Phase 7.1 Enhancement)
          if (_analytics!.ai2aiLearningInsights != null) ...[
            Semantics(
              label: 'AI2AI mesh learning insights section',
              header: true,
              child: _buildSectionTitle('AI2AI Mesh Learning Insights'),
            ),
            SizedBox(height: context.spacing.xs),
            Semantics(
              label:
                  'AI2AI mesh network learning insights and propagation statistics',
              child: _buildAI2AILearningInsights(),
            ),
            SizedBox(height: context.spacing.xl),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            title: 'Total',
            value: '${_analytics!.totalReservations}',
            icon: Icons.event,
            color: AppTheme.primaryColor,
          ),
        ),
        SizedBox(width: context.spacing.sm),
        Expanded(
          child: _buildSummaryCard(
            title: 'Completed',
            value: '${_analytics!.completedReservations}',
            icon: Icons.check_circle,
            color: AppColors.success,
          ),
        ),
        SizedBox(width: context.spacing.sm),
        Expanded(
          child: _buildSummaryCard(
            title: 'Completion Rate',
            value: '${(_analytics!.completionRate * 100).toStringAsFixed(0)}%',
            icon: Icons.trending_up,
            color: AppTheme.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return PortalSurface(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(context.spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            SizedBox(height: context.spacing.xs),
            Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold, color: color),
            ),
            SizedBox(height: context.spacing.xxs),
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context)
          .textTheme
          .titleLarge
          ?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildFavoriteSpots() {
    return PortalSurface(
      padding: EdgeInsets.zero,
      child: Column(
        children: _analytics!.favoriteSpots.map((spot) {
          return ListTile(
            leading:
                const Icon(Icons.location_on, color: AppTheme.primaryColor),
            title: Text(spot.spotName),
            subtitle: Text('${spot.reservationCount} reservations'),
            trailing: Chip(
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              side: BorderSide.none,
              backgroundColor: AppColors.success.withValues(alpha: 0.1),
              labelPadding: EdgeInsets.zero,
              label: Text(
                '${(spot.averageCompatibility * 100).toStringAsFixed(0)}% match',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600, color: AppColors.success),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPatternsSection() {
    return PortalSurface(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(context.spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_analytics!.patterns.preferredHour != null)
              _buildPatternItem(
                icon: Icons.access_time,
                label: 'Preferred Hour',
                value: '${_analytics!.patterns.preferredHour}:00',
              ),
            if (_analytics!.patterns.preferredDayOfWeek != null) ...[
              SizedBox(height: context.spacing.sm),
              _buildPatternItem(
                icon: Icons.calendar_today,
                label: 'Preferred Day',
                value: _getDayName(_analytics!.patterns.preferredDayOfWeek!),
              ),
            ],
            if (_analytics!.patterns.preferredType != null) ...[
              SizedBox(height: context.spacing.sm),
              _buildPatternItem(
                icon: Icons.category,
                label: 'Preferred Type',
                value: _analytics!.patterns.preferredType!.name.toUpperCase(),
              ),
            ],
            SizedBox(height: context.spacing.sm),
            _buildPatternItem(
              icon: Icons.people,
              label: 'Average Party Size',
              value: _analytics!.patterns.averagePartySize.toStringAsFixed(1),
            ),
            SizedBox(height: context.spacing.md),
            // Hour distribution chart
            if (_analytics!.patterns.hourDistribution.isNotEmpty) ...[
              Text(
                'Hour Distribution',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: context.spacing.xs),
              SizedBox(
                height: 200,
                child: _buildHourDistributionChart(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPatternItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryColor),
        SizedBox(width: context.spacing.xs),
        Text(
          '$label: ',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildHourDistributionChart() {
    final hourData = _analytics!.patterns.hourDistribution;
    final maxCount = hourData.values.reduce((a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxCount.toDouble(),
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final hour = value.toInt();
                if (hour % 4 == 0) {
                  return Text('$hour:00',
                      style: Theme.of(context).textTheme.labelSmall);
                }
                return Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(24, (hour) {
          final count = hourData[hour] ?? 0;
          return BarChartGroupData(
            x: hour,
            barRods: [
              BarChartRodData(
                toY: count.toDouble(),
                color: AppTheme.primaryColor,
                width: 12,
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildModificationPatterns() {
    return PortalSurface(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(context.spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatItem(
              'Total Modifications',
              '${_analytics!.modificationPatterns.totalModifications}',
            ),
            SizedBox(height: context.spacing.sm),
            _buildStatItem(
              'Max Modifications Reached',
              '${_analytics!.modificationPatterns.maxModificationsReached}',
            ),
            if (_analytics!
                .modificationPatterns.modificationReasons.isNotEmpty) ...[
              SizedBox(height: context.spacing.md),
              Text(
                'Modification Reasons',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: context.spacing.xs),
              ..._analytics!.modificationPatterns.modificationReasons.entries
                  .map((entry) => Padding(
                        padding: EdgeInsets.only(bottom: context.spacing.xxs),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(entry.key),
                            Text(
                              '${entry.value}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWaitlistHistory() {
    return PortalSurface(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(context.spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatItem(
              'Total Waitlist Joins',
              '${_analytics!.waitlistHistory.totalWaitlistJoins}',
            ),
            SizedBox(height: context.spacing.sm),
            _buildStatItem(
              'Conversions',
              '${_analytics!.waitlistHistory.totalWaitlistConversions}',
            ),
            SizedBox(height: context.spacing.sm),
            _buildStatItem(
              'Conversion Rate',
              '${(_analytics!.waitlistHistory.conversionRate * 100).toStringAsFixed(1)}%',
            ),
            if (_analytics!.waitlistHistory.recentEntries.isNotEmpty) ...[
              SizedBox(height: context.spacing.md),
              Text(
                'Recent Waitlist Entries',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: context.spacing.xs),
              ..._analytics!.waitlistHistory.recentEntries.map((entry) {
                return ListTile(
                  dense: true,
                  leading: Icon(
                    entry.converted ? Icons.check_circle : Icons.schedule,
                    color:
                        entry.converted ? AppColors.success : AppColors.warning,
                  ),
                  title: Text(
                    entry.converted ? 'Converted' : 'Pending',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: entry.converted
                            ? AppColors.success
                            : AppColors.warning),
                  ),
                  subtitle: Text(
                    'Joined: ${_formatDateTime(entry.joinTime)}',
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStringEvolutionPatterns() {
    final patterns = _analytics!.stringEvolutionPatterns!;
    return PortalSurface(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(context.spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (patterns.recurringPatterns.isNotEmpty) ...[
              Text(
                'Recurring Patterns',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: context.spacing.xs),
              ...patterns.recurringPatterns.map((pattern) {
                return ListTile(
                  dense: true,
                  leading:
                      const Icon(Icons.repeat, color: AppTheme.primaryColor),
                  title: Text(
                    '${pattern.patternType.toUpperCase()} pattern',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  subtitle: pattern.nextOccurrence != null
                      ? Text(
                          'Next: ${_formatDateTime(pattern.nextOccurrence!)}')
                      : null,
                  trailing: Chip(
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    side: BorderSide.none,
                    backgroundColor:
                        AppTheme.primaryColor.withValues(alpha: 0.1),
                    labelPadding: EdgeInsets.zero,
                    label: Text(
                      '${(pattern.confidence * 100).toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor),
                    ),
                  ),
                );
              }),
              SizedBox(height: context.spacing.md),
            ],
            if (patterns.cycles.isNotEmpty) ...[
              Text(
                'Evolution Cycles',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: context.spacing.xs),
              ...patterns.cycles.map((cycle) {
                return ListTile(
                  dense: true,
                  leading:
                      const Icon(Icons.repeat, color: AppTheme.primaryColor),
                  title: Text(
                    '${cycle.period.inDays} day cycle',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${_formatDateTime(cycle.startTime)} - ${_formatDateTime(cycle.endTime)}',
                  ),
                );
              }),
              SizedBox(height: context.spacing.md),
            ],
            if (patterns.trends.isNotEmpty) ...[
              Text(
                'Evolution Trends',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: context.spacing.xs),
              ...patterns.trends.map((trend) {
                return ListTile(
                  dense: true,
                  leading: Icon(
                    trend.type == TrendType.increasing
                        ? Icons.trending_up
                        : trend.type == TrendType.decreasing
                            ? Icons.trending_down
                            : Icons.trending_flat,
                    color: trend.type == TrendType.increasing
                        ? AppColors.success
                        : trend.type == TrendType.decreasing
                            ? AppColors.error
                            : AppColors.textSecondary,
                  ),
                  title: Text(
                    trend.type == TrendType.increasing
                        ? 'Increasing'
                        : trend.type == TrendType.decreasing
                            ? 'Decreasing'
                            : 'Stable',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Magnitude: ${trend.magnitude.toStringAsFixed(2)}',
                  ),
                );
              }),
              SizedBox(height: context.spacing.md),
            ],
            if (patterns.predictedTimes.isNotEmpty) ...[
              Text(
                'Predicted Future Reservations',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: context.spacing.xs),
              ...patterns.predictedTimes.map((time) {
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.calendar_today,
                      color: AppTheme.primaryColor),
                  title: Text(
                    _formatDateTime(time),
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text('Based on string evolution patterns'),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFabricStabilityAnalytics() {
    final fabric = _analytics!.fabricStabilityAnalytics!;
    return PortalSurface(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(context.spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatItem(
              'Average Fabric Stability',
              '${(fabric.averageStability * 100).toStringAsFixed(1)}%',
            ),
            if (fabric.mostStableGroups.isNotEmpty) ...[
              SizedBox(height: context.spacing.md),
              Text(
                'Most Stable Groups',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: context.spacing.xs),
              ...fabric.mostStableGroups.map((group) {
                return ListTile(
                  dense: true,
                  leading:
                      const Icon(Icons.group, color: AppTheme.primaryColor),
                  title: Text(
                    '${group.userIds.length} members',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text('${group.reservationCount} reservations'),
                  trailing: Chip(
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    side: BorderSide.none,
                    backgroundColor: AppColors.success.withValues(alpha: 0.1),
                    labelPadding: EdgeInsets.zero,
                    label: Text(
                      '${(group.stability * 100).toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.success),
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWorldsheetEvolutionAnalytics() {
    final worldsheet = _analytics!.worldsheetEvolutionAnalytics!;
    return PortalSurface(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(context.spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (worldsheet.evolutionHistory.isNotEmpty) ...[
              Text(
                'Evolution History',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: context.spacing.xs),
              SizedBox(
                height: 200,
                child: _buildEvolutionHistoryChart(worldsheet.evolutionHistory),
              ),
              SizedBox(height: context.spacing.md),
            ],
            if (worldsheet.predictions.isNotEmpty) ...[
              Text(
                'Future Predictions',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: context.spacing.xs),
              ...worldsheet.predictions.map((prediction) {
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.auto_awesome,
                      color: AppTheme.primaryColor),
                  title: Text(
                    _formatDateTime(prediction.predictedTime),
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Predicted stability: ${(prediction.predictedStability * 100).toStringAsFixed(1)}%',
                  ),
                  trailing: Text(
                    '${(prediction.confidence * 100).toStringAsFixed(0)}%',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                );
              }),
              SizedBox(height: context.spacing.md),
            ],
            if (worldsheet.stabilityTrends.isNotEmpty) ...[
              Text(
                'Stability Trends',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: context.spacing.xs),
              ...worldsheet.stabilityTrends.map((trend) {
                return ListTile(
                  dense: true,
                  leading: Icon(
                    trend.trend == TrendType.increasing
                        ? Icons.trending_up
                        : trend.trend == TrendType.decreasing
                            ? Icons.trending_down
                            : Icons.trending_flat,
                    color: trend.trend == TrendType.increasing
                        ? AppColors.success
                        : trend.trend == TrendType.decreasing
                            ? AppColors.error
                            : AppColors.textSecondary,
                  ),
                  title: Text(
                    '${_formatDateTime(trend.startTime)} - ${_formatDateTime(trend.endTime)}',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Change: ${(trend.stabilityChange * 100).toStringAsFixed(1)}%',
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEvolutionHistoryChart(
    List<WorldsheetEvolutionPoint> history,
  ) {
    final spots = history
        .map((point) => FlSpot(
              point.timestamp.millisecondsSinceEpoch.toDouble(),
              point.evolutionScore,
            ))
        .toList();

    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(enabled: true),
        gridData: const FlGridData(show: true),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                return Text(
                  '${date.month}/${date.day}',
                  style: Theme.of(context).textTheme.labelSmall,
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppTheme.primaryColor,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantumCompatibilityHistory() {
    final quantum = _analytics!.quantumCompatibilityHistory!;
    return PortalSurface(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(context.spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatItem(
              'Average Compatibility',
              '${(quantum.averageCompatibility * 100).toStringAsFixed(1)}%',
            ),
            if (quantum.topCompatibility.isNotEmpty) ...[
              SizedBox(height: context.spacing.md),
              Text(
                'Highest Compatibility Reservations',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: context.spacing.xs),
              ...quantum.topCompatibility.map((reservation) {
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.star, color: AppColors.warning),
                  title: Text(
                    _formatDateTime(reservation.reservationTime),
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                      'Target: ${reservation.targetId.substring(0, 10)}...'),
                  trailing: Chip(
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    side: BorderSide.none,
                    backgroundColor: AppColors.success.withValues(alpha: 0.1),
                    labelPadding: EdgeInsets.zero,
                    label: Text(
                      '${(reservation.compatibility * 100).toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.success),
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAI2AILearningInsights() {
    final ai2ai = _analytics!.ai2aiLearningInsights!;
    return PortalSurface(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(context.spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatItem(
              'Total Insights',
              '${ai2ai.totalInsights}',
            ),
            SizedBox(height: context.spacing.sm),
            _buildStatItem(
              'Average Learning Quality',
              '${(ai2ai.averageLearningQuality * 100).toStringAsFixed(1)}%',
            ),
            if (ai2ai.improvedDimensions.isNotEmpty) ...[
              SizedBox(height: context.spacing.md),
              Text(
                'Improved Dimensions',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: context.spacing.xs),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ai2ai.improvedDimensions.map((dimension) {
                  return Chip(
                    label: Text(dimension),
                    backgroundColor:
                        AppTheme.primaryColor.withValues(alpha: 0.1),
                  );
                }).toList(),
              ),
            ],
            SizedBox(height: context.spacing.md),
            Text(
              'Mesh Propagation Stats',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: context.spacing.xs),
            _buildStatItem(
              'Insights Received',
              '${ai2ai.propagationStats.insightsReceived}',
            ),
            SizedBox(height: context.spacing.xs),
            _buildStatItem(
              'Insights Shared',
              '${ai2ai.propagationStats.insightsShared}',
            ),
            SizedBox(height: context.spacing.xs),
            _buildStatItem(
              'Average Hop Count',
              ai2ai.propagationStats.averageHopCount.toStringAsFixed(1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.inDays == 0) {
      return 'Today at ${_formatTime(dateTime)}';
    } else if (difference.inDays == 1) {
      return 'Tomorrow at ${_formatTime(dateTime)}';
    } else if (difference.inDays < 7) {
      return '${_getDayName(dateTime.weekday)} at ${_formatTime(dateTime)}';
    } else {
      return '${dateTime.month}/${dateTime.day}/${dateTime.year} at ${_formatTime(dateTime)}';
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
  }

  String _getDayName(int weekday) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[weekday - 1];
  }

  Future<void> _showDateRangePicker() async {
    final now = DateTime.now();
    final initialStartDate =
        _startDate ?? now.subtract(const Duration(days: 30));
    final initialEndDate = _endDate ?? now;

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: DateTimeRange(
        start: initialStartDate,
        end: initialEndDate,
      ),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadAnalytics();
    }
  }

  /// Get user-friendly error message from exception
  /// Phase 9.2: Error handling improvements
  String _getUserFriendlyErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    // Network errors
    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Connection error. Analytics data is available offline.';
    }

    // Service unavailable errors
    if (errorString.contains('service') &&
        errorString.contains('unavailable')) {
      return 'Analytics service temporarily unavailable. Please try again later.';
    }

    // Knot/quantum/AI2AI service errors
    if (errorString.contains('knot') ||
        errorString.contains('quantum') ||
        errorString.contains('ai2ai')) {
      return 'Advanced analytics temporarily unavailable. Basic analytics are still available.';
    }

    // Generic error
    return 'Failed to load analytics. Please try again.';
  }
}

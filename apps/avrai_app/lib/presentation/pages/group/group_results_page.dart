// Group Results Page
//
// UI for displaying group-matched spots with quantum compatibility scores
// Part of Phase 19.18: Quantum Group Matching System
// Section GM.6: Group Results UI
//
// **Features:**
// - Group summary (members, formation method, atomic time sync)
// - Matched spots sorted by group compatibility
// - Individual member compatibility breakdown
// - Quantum visualization

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avrai/theme/colors.dart';
import 'package:avrai/presentation/blocs/group_matching_bloc.dart';
import 'package:avrai_core/models/quantum/group_matching_result.dart';
import 'package:avrai/presentation/pages/spots/spot_details_page.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';
import 'package:avrai/presentation/widgets/common/app_surface.dart';

/// Group Results Page
///
/// Displays matched spots for a group with quantum compatibility scores.
/// Shows group summary, matched spots list, and individual member breakdowns.
class GroupResultsPage extends StatefulWidget {
  final String? sessionId;

  const GroupResultsPage({
    super.key,
    this.sessionId,
  });

  @override
  State<GroupResultsPage> createState() => _GroupResultsPageState();
}

class _GroupResultsPageState extends State<GroupResultsPage> {
  final Map<String, bool> _expandedSpots = {}; // spotId -> isExpanded

  @override
  Widget build(BuildContext context) {
    return AdaptivePlatformPageScaffold(
      title: 'Group Matches',
      appBarBackgroundColor: AppColors.primary,
      appBarForegroundColor: AppColors.white,
      constrainBody: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            // TODO: Implement refresh when retry is implemented in BLoC
          },
          tooltip: 'Refresh results',
        ),
      ],
      body: BlocBuilder<GroupMatchingBloc, GroupMatchingState>(
        builder: (context, state) {
          if (state is GroupMatchingLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            );
          }

          if (state is GroupMatchingError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                    ),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          if (state is GroupMatchingResults) {
            return _buildResultsContent(context, state);
          }

          // If we have a GroupFormed state, we should trigger search
          if (state is GroupFormed) {
            // This should have been handled in GroupFormationPage
            // But if we navigate here directly, show a message
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 64,
                    color: AppColors.grey400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No results yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please start a group search from the formation page',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return const Center(child: Text('Unknown state'));
        },
      ),
    );
  }

  /// Build results content
  Widget _buildResultsContent(
    BuildContext context,
    GroupMatchingResults state,
  ) {
    final matchedSpots = state.matchedSpots;

    if (matchedSpots.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 64,
              color: AppColors.grey400,
            ),
            const SizedBox(height: 16),
            Text(
              'No matches found',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search criteria or forming a different group',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Group Summary Section
        _buildGroupSummary(context, state),

        // Matched Spots List
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              // TODO: Implement refresh when retry is implemented
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: matchedSpots.length,
              itemBuilder: (context, index) {
                final matchedSpot = matchedSpots[index];
                return _buildMatchedSpotCard(
                  context,
                  matchedSpot,
                  index + 1, // Rank
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  /// Build group summary section
  Widget _buildGroupSummary(
    BuildContext context,
    GroupMatchingResults state,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        border: Border(
          bottom: BorderSide(
            color: AppColors.grey300,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.people,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Group Match Results',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildSummaryChip(
                context,
                icon: Icons.location_on,
                label: '${state.matchedSpots.length} spots',
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              _buildSummaryChip(
                context,
                icon: Icons.people_outline,
                label: '${state.matchingResult.groupSize} members',
                color: AppColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build summary chip
  Widget _buildSummaryChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  /// Build matched spot card
  Widget _buildMatchedSpotCard(
    BuildContext context,
    GroupMatchedSpot matchedSpot,
    int rank,
  ) {
    final spot = matchedSpot.spot;
    final isExpanded = _expandedSpots[spot.id] ?? false;
    final compatibility = matchedSpot.groupCompatibility;
    final compatibilityPercent = (compatibility * 100).toStringAsFixed(0);

    return AppSurface(
      margin: const EdgeInsets.only(bottom: 16),
      radius: 12,
      borderColor: AppColors.primary.withValues(alpha: 0.3),
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () {
          setState(() {
            _expandedSpots[spot.id] = !isExpanded;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Rank and Compatibility Score
              Row(
                children: [
                  // Rank badge
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '#$rank',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Spot name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          spot.name,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        if (spot.category.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            spot.category,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Compatibility score
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.favorite,
                            size: 20,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$compatibilityPercent%',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      _buildCompatibilityBar(compatibility),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Spot description
              if (spot.description.isNotEmpty) ...[
                Text(
                  spot.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: isExpanded ? null : 2,
                  overflow: isExpanded ? null : TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
              ],

              // Spot details row
              Row(
                children: [
                  if (spot.rating > 0) ...[
                    Icon(
                      Icons.star,
                      size: 16,
                      color: AppColors.grey600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      spot.rating.toStringAsFixed(1),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  if (spot.address != null) ...[
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        spot.address!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),

              // Expanded section: Individual member compatibility
              if (isExpanded) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                Text(
                  'Member Compatibility',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                ...matchedSpot.memberCompatibilityScores.entries.map(
                  (entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Member ${entry.key.substring(0, 8)}...', // Truncated for privacy
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildCompatibilityBar(entry.value),
                          const SizedBox(width: 8),
                          Text(
                            '${(entry.value * 100).toStringAsFixed(0)}%',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.primary,
                                    ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),

                // Quantum compatibility breakdown
                Text(
                  'Quantum Compatibility Breakdown',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                _buildCompatibilityBreakdown(matchedSpot),
              ],

              const SizedBox(height: 12),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SpotDetailsPage(spot: spot),
                        ),
                      );
                    },
                    icon: const Icon(Icons.info_outline),
                    label: const Text('View Details'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Implement "Select Spot" action
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Selected ${spot.name} for group'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Select'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build compatibility bar
  Widget _buildCompatibilityBar(double compatibility) {
    return Container(
      width: 60,
      height: 6,
      decoration: BoxDecoration(
        color: AppColors.grey200,
        borderRadius: BorderRadius.circular(3),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: compatibility,
        child: Container(
          decoration: BoxDecoration(
            color: _getCompatibilityColor(compatibility),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }

  /// Get compatibility color based on score
  Color _getCompatibilityColor(double score) {
    if (score >= 0.8) {
      return AppColors.primary; // High compatibility
    } else if (score >= 0.6) {
      return AppColors.primary.withValues(alpha: 0.7); // Medium-high
    } else if (score >= 0.4) {
      return AppColors.warning; // Medium
    } else {
      return AppColors.error; // Low
    }
  }

  /// Build compatibility breakdown
  Widget _buildCompatibilityBreakdown(GroupMatchedSpot matchedSpot) {
    return Column(
      children: [
        _buildBreakdownRow(
          'Quantum',
          matchedSpot.quantumCompatibility,
        ),
        if (matchedSpot.knotCompatibility != null)
          _buildBreakdownRow(
            'Knot',
            matchedSpot.knotCompatibility!,
          ),
        if (matchedSpot.stringEvolutionCompatibility != null)
          _buildBreakdownRow(
            'String Evolution',
            matchedSpot.stringEvolutionCompatibility!,
          ),
        if (matchedSpot.fabricStability != null)
          _buildBreakdownRow(
            'Fabric Stability',
            matchedSpot.fabricStability!,
          ),
        if (matchedSpot.worldsheetCompatibility != null)
          _buildBreakdownRow(
            'Worldsheet',
            matchedSpot.worldsheetCompatibility!,
          ),
        _buildBreakdownRow(
          'Location',
          matchedSpot.locationCompatibility,
        ),
        _buildBreakdownRow(
          'Timing',
          matchedSpot.timingCompatibility,
        ),
      ],
    );
  }

  /// Build breakdown row
  Widget _buildBreakdownRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(width: 8),
          _buildCompatibilityBar(value),
          const SizedBox(width: 8),
          Text(
            '${(value * 100).toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

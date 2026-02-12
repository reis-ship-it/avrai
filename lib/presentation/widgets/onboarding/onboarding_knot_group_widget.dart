// Onboarding Knot Group Widget
// 
// Widget for displaying onboarding groups with knots
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Phase 3: Onboarding Integration

import 'package:flutter/material.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai_core/models/personality_knot.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/presentation/widgets/knot/personality_knot_widget.dart';
import 'package:avrai_knot/services/knot/knot_storage_service.dart';
import 'package:get_it/get_it.dart';

/// Widget for displaying onboarding groups with knots
/// 
/// Shows knots of group members and a combined group visualization
class OnboardingKnotGroupWidget extends StatefulWidget {
  final List<PersonalityProfile> groupMembers;
  final String? currentUserId;

  const OnboardingKnotGroupWidget({
    super.key,
    required this.groupMembers,
    this.currentUserId,
  });

  @override
  State<OnboardingKnotGroupWidget> createState() =>
      _OnboardingKnotGroupWidgetState();
}

class _OnboardingKnotGroupWidgetState
    extends State<OnboardingKnotGroupWidget> {
  final KnotStorageService _knotStorageService =
      GetIt.instance<KnotStorageService>();
  Map<String, PersonalityKnot?> _memberKnots = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMemberKnots();
  }

  Future<void> _loadMemberKnots() async {
    setState(() => _isLoading = true);

    final Map<String, PersonalityKnot?> knots = {};
    for (final member in widget.groupMembers) {
      try {
        final knot = await _knotStorageService.loadKnot(member.agentId);
        knots[member.agentId] = knot;
      } catch (e) {
        knots[member.agentId] = null;
      }
    }

    if (mounted) {
      setState(() {
        _memberKnots = knots;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Onboarding Group',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'People with compatible personality knots',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),

        // Loading state
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          )
        else ...[
          // Group members' knots
          _buildMembersKnots(context),

          const Divider(),

          // Group summary
          _buildGroupSummary(context),
        ],
      ],
    );
  }

  Widget _buildMembersKnots(BuildContext context) {
    if (widget.groupMembers.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: Text(
            'No group members yet',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Group Members (${widget.groupMembers.length})',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.groupMembers.length,
              itemBuilder: (context, index) {
                final member = widget.groupMembers[index];
                final knot = _memberKnots[member.agentId];
                return _buildMemberKnotCard(context, member, knot, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberKnotCard(
    BuildContext context,
    PersonalityProfile member,
    PersonalityKnot? knot,
    int index,
  ) {
    final isCurrentUser = member.agentId == widget.currentUserId;

    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12.0),
      child: Card(
        color: isCurrentUser
            ? AppColors.primary.withValues(alpha: 0.1)
            : AppColors.surface,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Knot visualization
              if (knot != null)
                PersonalityKnotWidget(
                  knot: knot,
                  size: 100.0,
                  showLabels: false,
                  showMetrics: false,
                  color: isCurrentUser ? AppColors.primary : AppColors.grey500,
                )
              else
                Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.grey300,
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 50,
                    color: AppColors.grey500,
                  ),
                ),
              const SizedBox(height: 8),
              
              // Member label
              Text(
                isCurrentUser ? 'You' : 'Member ${index + 1}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isCurrentUser
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                    ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupSummary(BuildContext context) {
    final membersWithKnots = _memberKnots.values
        .where((knot) => knot != null)
        .length;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Group Summary',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildSummaryChip(
                context,
                Icons.people,
                '${widget.groupMembers.length} members',
                AppColors.primary,
              ),
              const SizedBox(width: 8),
              _buildSummaryChip(
                context,
                Icons.category,
                '$membersWithKnots with knots',
                AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'This group was formed based on compatible personality knot structures. '
            'You\'ll be able to connect and learn from each other!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryChip(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

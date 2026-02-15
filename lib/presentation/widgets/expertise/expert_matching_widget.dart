import 'package:flutter/material.dart';
import 'package:avrai/core/models/user/unified_user.dart';
import 'package:avrai/core/services/expertise/expertise_matching_service.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/presentation/widgets/expertise/expertise_pin_widget.dart';
import 'package:avrai/presentation/presentation_spacing.dart';

/// Expert Matching Widget
/// Displays expert matches and connection suggestions
class ExpertMatchingWidget extends StatelessWidget {
  final UnifiedUser user;
  final String? category;
  final MatchingType matchingType;
  final Function(UnifiedUser)? onMatchSelected;

  const ExpertMatchingWidget({
    super.key,
    required this.user,
    this.category,
    this.matchingType = MatchingType.similar,
    this.onMatchSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ExpertMatch>>(
      future: _getMatches(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final matches = snapshot.data ?? [];

        if (matches.isEmpty) {
          return _buildEmptyState(context);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, matches.length),
            const SizedBox(height: 8),
            _buildMatchesList(context, matches),
          ],
        );
      },
    );
  }

  Future<List<ExpertMatch>> _getMatches() async {
    // Ensure the Future completes asynchronously so the loading state renders
    // for at least one frame (keeps UI/tests deterministic).
    await Future<void>.delayed(Duration.zero);
    final service = ExpertiseMatchingService();

    switch (matchingType) {
      case MatchingType.similar:
        if (category != null) {
          return await service.findSimilarExperts(user, category!);
        }
        return [];
      case MatchingType.complementary:
        return await service.findComplementaryExperts(user);
      case MatchingType.mentors:
        if (category != null) {
          return await service.findMentors(user, category!);
        }
        return [];
      case MatchingType.mentees:
        if (category != null) {
          return await service.findMentees(user, category!);
        }
        return [];
    }
  }

  Widget _buildHeader(BuildContext context, int count) {
    String title;
    switch (matchingType) {
      case MatchingType.similar:
        title = 'Similar Experts';
        break;
      case MatchingType.complementary:
        title = 'Complementary Experts';
        break;
      case MatchingType.mentors:
        title = 'Mentors';
        break;
      case MatchingType.mentees:
        title = 'Mentees';
        break;
    }

    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: kSpaceXs, vertical: kSpaceNano),
          decoration: BoxDecoration(
            color: AppColors.grey200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    String message;
    switch (matchingType) {
      case MatchingType.similar:
        message = 'No similar experts found';
        break;
      case MatchingType.complementary:
        message = 'No complementary experts found';
        break;
      case MatchingType.mentors:
        message = 'No mentors available';
        break;
      case MatchingType.mentees:
        message = 'No mentees found';
        break;
    }

    return Center(
      child: Column(
        children: [
          const Icon(Icons.people_outline,
              size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchesList(BuildContext context, List<ExpertMatch> matches) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: matches.length,
      itemBuilder: (context, index) {
        return _buildMatchCard(context, matches[index]);
      },
    );
  }

  Widget _buildMatchCard(BuildContext context, ExpertMatch match) {
    final matchedUser = match.user;
    final pins = matchedUser
        .getExpertisePins()
        .where((pin) => match.commonExpertise.contains(pin.category))
        .toList();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: kSpaceXxs),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.grey200,
          child: matchedUser.photoUrl != null
              ? Image.network(matchedUser.photoUrl!)
              : Text(
                  (matchedUser.displayName ?? matchedUser.email)[0]
                      .toUpperCase(),
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.textPrimary),
                ),
        ),
        title: Text(matchedUser.displayName ?? matchedUser.email),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              match.matchReason,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            if (pins.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: pins
                    .map((pin) => ExpertisePinWidget(
                          pin: pin,
                          showDetails: false,
                        ))
                    .toList(),
              ),
            ],
            if (match.complementaryExpertise.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Also: ${match.complementaryExpertise.join(', ')}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.electricGreen,
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ],
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: kSpaceXs, vertical: kSpaceXxs),
              decoration: BoxDecoration(
                color: AppColors.electricGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${(match.matchScore * 100).toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.electricGreen,
                    ),
              ),
            ),
          ],
        ),
        onTap: () => onMatchSelected?.call(matchedUser),
      ),
    );
  }
}

/// Matching Type
enum MatchingType {
  similar,
  complementary,
  mentors,
  mentees,
}

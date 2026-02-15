import 'package:flutter/material.dart';
import 'package:avrai/core/models/business/business_account.dart';
import 'package:avrai/core/models/user/unified_user.dart';
import 'package:avrai/core/models/business/business_patron_preferences.dart';
import 'package:avrai/core/services/business/user_business_matching_service.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/presentation/presentation_spacing.dart';

/// Business Compatibility Widget
/// Shows users how well they match a specific business's patron preferences
/// Helps users understand what vibes and qualities the business is looking for
class BusinessCompatibilityWidget extends StatelessWidget {
  final BusinessAccount business;
  final UnifiedUser user;

  const BusinessCompatibilityWidget({
    super.key,
    required this.business,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<BusinessCompatibilityScore>(
      future: _getCompatibilityScore(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.error),
            ),
          );
        }

        final score = snapshot.data;
        if (score == null) {
          return const SizedBox.shrink();
        }

        return _buildCompatibilityCard(context, score);
      },
    );
  }

  Future<BusinessCompatibilityScore> _getCompatibilityScore() async {
    // Ensure the Future completes asynchronously so the loading state renders
    // for at least one frame (keeps UI/tests deterministic).
    await Future<void>.delayed(Duration.zero);
    final service = UserBusinessMatchingService();
    return await service.getUserCompatibilityScore(user, business);
  }

  Widget _buildCompatibilityCard(
      BuildContext context, BusinessCompatibilityScore score) {
    final isGoodMatch = score.isGoodMatch;
    final preferences = business.patronPreferences;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(kSpaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.people,
                  color: AppColors.electricGreen,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Your Compatibility',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: kSpaceSm, vertical: kSpaceXsTight),
                  decoration: BoxDecoration(
                    color: isGoodMatch
                        ? AppColors.electricGreen.withValues(alpha: 0.1)
                        : AppColors.grey200,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${score.percentageScore}%',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isGoodMatch
                              ? AppColors.electricGreen
                              : AppColors.textSecondary,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (preferences != null) ...[
              // What the business is looking for
              _buildSectionTitle(
                  context, 'What ${business.name} is Looking For'),
              const SizedBox(height: 8),

              if (preferences.preferredVibePreferences?.isNotEmpty == true) ...[
                _buildInfoRow(
                  context: context,
                  icon: Icons.mood,
                  label: 'Vibe',
                  value: preferences.preferredVibePreferences!.join(', '),
                ),
                const SizedBox(height: 8),
              ],

              if (preferences.preferredInterests?.isNotEmpty == true) ...[
                _buildInfoRow(
                  context: context,
                  icon: Icons.favorite,
                  label: 'Interests',
                  value: preferences.preferredInterests!.take(3).join(', '),
                ),
                const SizedBox(height: 8),
              ],

              if (preferences.preferredPersonalityTraits?.isNotEmpty ==
                  true) ...[
                _buildInfoRow(
                  context: context,
                  icon: Icons.person,
                  label: 'Personality',
                  value: preferences.preferredPersonalityTraits!
                      .take(3)
                      .join(', '),
                ),
                const SizedBox(height: 8),
              ],

              if (preferences.preferredSpendingLevel != null) ...[
                _buildInfoRow(
                  context: context,
                  icon: Icons.attach_money,
                  label: 'Spending Level',
                  value: preferences.preferredSpendingLevel?.displayName ??
                      'Not specified',
                ),
                const SizedBox(height: 8),
              ],

              if (preferences.preferLocalPatrons ||
                  preferences.preferTourists) ...[
                _buildInfoRow(
                  context: context,
                  icon: Icons.location_on,
                  label: 'Location Preference',
                  value: preferences.preferLocalPatrons
                      ? 'Local Patrons'
                      : 'Tourists Welcome',
                ),
                const SizedBox(height: 8),
              ],

              if (preferences.preferCommunityMembers) ...[
                _buildInfoRow(
                  context: context,
                  icon: Icons.group,
                  label: 'Community',
                  value: 'Prefers Community Members',
                ),
                const SizedBox(height: 8),
              ],

              const SizedBox(height: 16),
            ],

            // How you match
            _buildSectionTitle(context, 'How You Match'),
            const SizedBox(height: 8),

            if (score.matchedCriteria.isNotEmpty) ...[
              ...score.matchedCriteria.map((criterion) => Padding(
                    padding: const EdgeInsets.only(bottom: kSpaceXs),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          size: 20,
                          color: AppColors.electricGreen,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            criterion,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textPrimary,
                                    ),
                          ),
                        ),
                      ],
                    ),
                  )),
            ] else ...[
              Text(
                'Complete your profile to see how you match',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],

            if (score.missingCriteria.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildSectionTitle(context, 'What You\'re Missing'),
              const SizedBox(height: 8),
              ...score.missingCriteria.take(3).map((criterion) => Padding(
                    padding: const EdgeInsets.only(bottom: kSpaceXs),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            criterion,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],

            if (preferences?.aiMatchingPrompt != null) ...[
              const SizedBox(height: 16),
              _buildSectionTitle(context, 'What They Say'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(kSpaceSm),
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  preferences!.aiMatchingPrompt!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: AppColors.textSecondary,
                      ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildInfoRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

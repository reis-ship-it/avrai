import 'package:flutter/material.dart';
import 'package:avrai/core/models/expertise/expertise_pin.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/presentation/presentation_spacing.dart';

/// Expertise Badge Widget
/// Shows expert validation badge on spot cards
/// Indicates spot has been reviewed/validated by experts
class ExpertiseBadgeWidget extends StatelessWidget {
  final List<ExpertisePin> expertPins; // Experts who validated this spot
  final String category;
  final bool compact;

  const ExpertiseBadgeWidget({
    super.key,
    required this.expertPins,
    required this.category,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    // Filter pins relevant to this spot's category
    final relevantPins = expertPins
        .where((pin) => pin.category.toLowerCase() == category.toLowerCase())
        .toList();

    if (relevantPins.isEmpty) {
      return const SizedBox.shrink();
    }

    if (compact) {
      return _buildCompactBadge(context, relevantPins);
    }

    return _buildFullBadge(context, relevantPins);
  }

  Widget _buildCompactBadge(BuildContext context, List<ExpertisePin> pins) {
    final pin = pins.first;
    final pinColor = pin.getPinColor();
    final pinIcon = pin.getPinIcon();

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: kSpaceXs, vertical: kSpaceXxs),
      decoration: BoxDecoration(
        color: pinColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: pinColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            pinIcon,
            size: 12,
            color: pinColor,
          ),
          const SizedBox(width: 4),
          Text(
            'Expert',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: pinColor,
                ),
          ),
          if (pins.length > 1) ...[
            const SizedBox(width: 4),
            Text(
              '+${pins.length - 1}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFullBadge(BuildContext context, List<ExpertisePin> pins) {
    final pin = pins.first;
    final pinColor = pin.getPinColor();
    final pinIcon = pin.getPinIcon();

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: kSpaceSm, vertical: kSpaceXsTight),
      decoration: BoxDecoration(
        color: pinColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: pinColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            pinIcon,
            size: 16,
            color: pinColor,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Verified by Experts',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: pinColor,
                    ),
              ),
              if (pins.length > 1)
                Text(
                  '${pins.length} $category Experts',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Simple Expert Indicator
/// Minimal indicator for expert-reviewed spots
class ExpertIndicator extends StatelessWidget {
  final bool isExpertReviewed;
  final String? category;

  const ExpertIndicator({
    super.key,
    required this.isExpertReviewed,
    this.category,
  });

  @override
  Widget build(BuildContext context) {
    if (!isExpertReviewed) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(kSpaceXxs),
      decoration: BoxDecoration(
        color: AppColors.electricGreen.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.verified,
        size: 12,
        color: AppColors.electricGreen,
      ),
    );
  }
}

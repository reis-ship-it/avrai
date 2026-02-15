import 'package:flutter/material.dart';
import 'package:avrai/core/models/expertise/expertise_pin.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/tokens/theme_tokens.dart';

/// Expertise Pin Widget
/// Displays a visual pin representing user expertise
/// OUR_GUTS.md: "Pins, Not Badges" - Visual recognition without gamification
class ExpertisePinWidget extends StatelessWidget {
  final ExpertisePin pin;
  final bool showDetails;
  final VoidCallback? onTap;

  const ExpertisePinWidget({
    super.key,
    required this.pin,
    this.showDetails = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final pinColor = pin.getPinColor();
    final pinIcon = pin.getPinIcon();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: spacing.sm,
          vertical: spacing.xs,
        ),
        decoration: BoxDecoration(
          color: pinColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: pinColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pin Icon
            Container(
              padding: EdgeInsets.all(spacing.xxs),
              decoration: BoxDecoration(
                color: pinColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                pinIcon,
                size: 16,
                color: pinColor,
              ),
            ),
            const SizedBox(width: 8),
            // Category and Level
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  pin.category,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                ),
                if (showDetails) ...[
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        pin.level.emoji,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${pin.level.displayName} Level',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      if (pin.location != null) ...[
                        const SizedBox(width: 4),
                        Text(
                          '• ${pin.location}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Expertise Pin Gallery Widget
/// Displays multiple pins in a gallery format
class ExpertisePinGallery extends StatelessWidget {
  final List<ExpertisePin> pins;
  final int maxDisplay;
  final bool expandable;

  const ExpertisePinGallery({
    super.key,
    required this.pins,
    this.maxDisplay = 3,
    this.expandable = true,
  });

  @override
  Widget build(BuildContext context) {
    if (pins.isEmpty) {
      return const SizedBox.shrink();
    }

    final displayPins = expandable && pins.length > maxDisplay
        ? pins.take(maxDisplay).toList()
        : pins;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...displayPins.map((pin) => ExpertisePinWidget(pin: pin)),
        if (expandable && pins.length > maxDisplay)
          _buildMorePinsChip(context, pins.length - maxDisplay),
      ],
    );
  }

  Widget _buildMorePinsChip(BuildContext context, int count) {
    final spacing = context.spacing;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.sm,
        vertical: spacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.grey300),
      ),
      child: Text(
        '+$count more',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
      ),
    );
  }
}

/// Expertise Pin Detail Card
/// Shows full details of a pin
class ExpertisePinDetailCard extends StatelessWidget {
  final ExpertisePin pin;

  const ExpertisePinDetailCard({
    super.key,
    required this.pin,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final pinColor = pin.getPinColor();
    final pinIcon = pin.getPinIcon();

    return Card(
      margin: EdgeInsets.all(spacing.md),
      child: Padding(
        padding: EdgeInsets.all(spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(spacing.sm),
                  decoration: BoxDecoration(
                    color: pinColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    pinIcon,
                    size: 24,
                    color: pinColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pin.category,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pin.getFullDescription(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            // Details
            _buildDetailRow(
                context, 'Earned', pin.earnedAt.toString().split(' ')[0]),
            _buildDetailRow(context, 'Reason', pin.earnedReason),
            if (pin.contributionCount > 0)
              _buildDetailRow(
                  context, 'Contributions', '${pin.contributionCount}'),
            if (pin.unlockedFeatures.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Unlocked Features:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: pin.unlockedFeatures.map((feature) {
                  return Chip(
                    label: Text(
                      feature.replaceAll('_', ' ').toUpperCase(),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    backgroundColor: AppColors.grey100,
                    side: const BorderSide(color: AppColors.grey300),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.spacing.xxs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

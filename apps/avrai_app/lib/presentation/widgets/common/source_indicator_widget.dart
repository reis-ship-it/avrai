import 'package:flutter/material.dart';
import 'package:avrai_core/models/spots/source_indicator.dart';
import 'package:avrai/theme/colors.dart';

/// Widget to display source indicator badge for data transparency
/// OUR_GUTS.md: "Privacy and Control Are Non-Negotiable" - Users must know data sources
class SourceIndicatorWidget extends StatelessWidget {
  final SourceIndicator indicator;
  final bool showWarning;
  final bool compact;

  const SourceIndicatorWidget({
    super.key,
    required this.indicator,
    this.showWarning = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompactBadge();
    } else {
      return _buildFullBadge(context);
    }
  }

  Widget _buildCompactBadge() {
    return Tooltip(
      message: indicator.warningMessage.isNotEmpty
          ? indicator.warningMessage
          : indicator.displayText,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Color(indicator.badgeColor).withValues(alpha: 0.1),
          border: Border.all(color: Color(indicator.badgeColor), width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              IconData(indicator.badgeIcon, fontFamily: 'MaterialIcons'),
              size: 12,
              color: Color(indicator.badgeColor),
            ),
            const SizedBox(width: 4),
            Text(
              indicator.sourceName,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Color(indicator.badgeColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullBadge(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Color(indicator.badgeColor).withValues(alpha: 0.1),
                border:
                    Border.all(color: Color(indicator.badgeColor), width: 1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    IconData(indicator.badgeIcon, fontFamily: 'MaterialIcons'),
                    size: 16,
                    color: Color(indicator.badgeColor),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    indicator.displayText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(indicator.badgeColor),
                    ),
                  ),
                ],
              ),
            ),
            if (indicator.qualityMetrics.qualityGrade != 'F') ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.grey200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  indicator.qualityMetrics.qualityGrade,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.grey800,
                  ),
                ),
              ),
            ],
          ],
        ),
        if (showWarning && indicator.warningMessage.isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 14,
                color: indicator.warningLevel == WarningLevel.high
                    ? AppColors.error
                    : AppColors.warning,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  indicator.warningMessage,
                  style: TextStyle(
                    fontSize: 11,
                    color: indicator.warningLevel == WarningLevel.high
                        ? AppColors.error
                        : AppColors.grey700,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

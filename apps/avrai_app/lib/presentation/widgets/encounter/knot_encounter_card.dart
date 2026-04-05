import 'dart:ui';

import 'package:avrai/presentation/widgets/encounter/progressive_confidence_widget.dart';
import 'package:avrai/theme/colors.dart';
import 'package:flutter/material.dart' hide Colors;

/// A subtle, non-intrusive card that logs a topological encounter.
///
/// Instead of pushing a loud push notification, these stack quietly in a
/// "Resonance Log" or can optionally surface as a silent local notification
/// for very high matches.
///
/// If the resonance is very high, it offers an optional "Sync" button to
/// trigger an immediate deep-dive or mesh connection.
class KnotEncounterCard extends StatelessWidget {
  final double confidenceScore;
  final DateTime timestamp;
  final VoidCallback? onSyncPressed;

  const KnotEncounterCard({
    super.key,
    required this.confidenceScore,
    required this.timestamp,
    this.onSyncPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isHighResonance = confidenceScore >= 0.8;

    // Determine messaging based on the math score
    String title;
    String subtitle;

    if (confidenceScore >= 0.9) {
      title = "Deep Resonance Detected";
      subtitle = "Near-identical topological match passed by.";
    } else if (confidenceScore >= 0.7) {
      title = "Strong Alignment";
      subtitle = "Significant mathematical overlap with a nearby node.";
    } else if (confidenceScore >= 0.4) {
      title = "Passing Connection";
      subtitle = "Brief topological intersection recorded.";
    } else {
      title = "Faint Signal";
      subtitle = "A distant mesh node was detected.";
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: AppColors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(
          color: isHighResonance
              ? AppColors.electricGreen.withValues(alpha: 0.5)
              : AppColors.grey800,
          width: 1.0,
        ),
        boxShadow: isHighResonance
            ? [
                BoxShadow(
                  color: AppColors.electricGreen.withValues(alpha: 0.1),
                  blurRadius: 20.0,
                  spreadRadius: 2.0,
                )
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Visualizer
                ProgressiveConfidenceWidget(
                  confidence: confidenceScore,
                  size: 60.0,
                  primaryColor: isHighResonance
                      ? AppColors.electricGreen
                      : AppColors.primary,
                ),

                const SizedBox(width: 16.0),

                // Text Context
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 16.0,
                          fontWeight: isHighResonance
                              ? FontWeight.bold
                              : FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: AppColors.grey300,
                          fontSize: 13.0,
                        ),
                      ),
                      const SizedBox(height: 6.0),
                      Text(
                        _formatTimeAgo(timestamp),
                        style: TextStyle(
                          color: AppColors.grey500,
                          fontSize: 11.0,
                        ),
                      ),
                    ],
                  ),
                ),

                // Optional Sync Action
                if (isHighResonance && onSyncPressed != null) ...[
                  const SizedBox(width: 12.0),
                  _buildSyncButton(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSyncButton() {
    return Material(
      color: const Color(0x00000000),
      child: InkWell(
        onTap: onSyncPressed,
        borderRadius: BorderRadius.circular(30.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: AppColors.electricGreen.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(30.0),
            border: Border.all(
              color: AppColors.electricGreen.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.sync_rounded,
                color: AppColors.electricGreen,
                size: 16.0,
              ),
              const SizedBox(width: 6.0),
              Text(
                "Sync",
                style: TextStyle(
                  color: AppColors.electricGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 13.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    return "${diff.inDays}d ago";
  }
}

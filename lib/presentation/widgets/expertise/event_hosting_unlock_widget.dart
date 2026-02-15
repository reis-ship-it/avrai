import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:avrai/core/models/expertise/expertise_level.dart';
import 'package:avrai/core/models/expertise/expertise_progress.dart';
import 'package:avrai/core/models/user/unified_user.dart';
import 'package:avrai/core/services/expertise/expertise_service.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/core/theme/tokens/theme_tokens.dart';

/// Event Hosting Unlock Widget
/// Shows when user unlocks event hosting (Local level+ required)
/// OUR_GUTS.md: "The key opens doors to events"
///
/// **Usage Example:**
/// ```dart
/// EventHostingUnlockWidget(
///   user: currentUser,
///   onUnlockTap: () {
///     AppNavigator.pushBuilder(context,
///       builder: (context) => CreateEventPage(),
///     ));
///   },
/// )
/// ```
class EventHostingUnlockWidget extends StatefulWidget {
  final UnifiedUser user;
  final VoidCallback? onUnlockTap;
  final VoidCallback? onProgressTap;

  const EventHostingUnlockWidget({
    super.key,
    required this.user,
    this.onUnlockTap,
    this.onProgressTap,
  });

  @override
  State<EventHostingUnlockWidget> createState() =>
      _EventHostingUnlockWidgetState();
}

class _EventHostingUnlockWidgetState extends State<EventHostingUnlockWidget>
    with SingleTickerProviderStateMixin {
  final ExpertiseService _expertiseService = ExpertiseService();
  bool _isUnlocked = false;
  bool _wasUnlockedBefore = false;
  ExpertiseLevel? _currentHighestLevel;
  ExpertiseProgress? _progressToCity;

  late AnimationController _unlockAnimationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    // #region agent log
    // Debug mode: log widget initialization (no PII values)
    try {
      final payload = <String, dynamic>{
        'id': 'log_${DateTime.now().millisecondsSinceEpoch}_H1',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'sessionId': 'debug-session',
        'runId': 'pre-fix-init',
        'hypothesisId': 'H1',
        'location':
            'lib/presentation/widgets/expertise/event_hosting_unlock_widget.dart:initState',
        'message': 'EventHostingUnlockWidget initialized',
        'data': {
          'userId': widget.user.id,
          'hasOnUnlockTap': widget.onUnlockTap != null,
          'hasOnProgressTap': widget.onProgressTap != null,
        },
      };
      File('/Users/reisgordon/SPOTS/.cursor/debug.log')
          .writeAsStringSync('${jsonEncode(payload)}\n', mode: FileMode.append);
    } catch (_) {}
    // #endregion

    _initAnimations();
    _checkUnlockStatus();
  }

  void _initAnimations() {
    _unlockAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _unlockAnimationController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _unlockAnimationController,
      curve: Curves.easeIn,
    ));

    _unlockAnimationController.forward();
  }

  @override
  void dispose() {
    _unlockAnimationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(EventHostingUnlockWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // #region agent log
    // Debug mode: log widget update (no PII values)
    try {
      final payload = <String, dynamic>{
        'id': 'log_${DateTime.now().millisecondsSinceEpoch}_H4',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'sessionId': 'debug-session',
        'runId': 'pre-fix-did-update',
        'hypothesisId': 'H4',
        'location':
            'lib/presentation/widgets/expertise/event_hosting_unlock_widget.dart:didUpdateWidget',
        'message': 'Widget updated',
        'data': {
          'userIdChanged': oldWidget.user.id != widget.user.id,
        },
      };
      File('/Users/reisgordon/SPOTS/.cursor/debug.log')
          .writeAsStringSync('${jsonEncode(payload)}\n', mode: FileMode.append);
    } catch (_) {}
    // #endregion

    if (oldWidget.user.id != widget.user.id) {
      _checkUnlockStatus();
    }
  }

  void _checkUnlockStatus() {
    // Check if user can host events (Local level+ required)
    final wasUnlocked = _isUnlocked;
    _isUnlocked = widget.user.canHostEvents();

    // #region agent log
    // Debug mode: log unlock status check (no PII values)
    try {
      final payload = <String, dynamic>{
        'id': 'log_${DateTime.now().millisecondsSinceEpoch}_H2',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'sessionId': 'debug-session',
        'runId': 'pre-fix-unlock-check',
        'hypothesisId': 'H2',
        'location':
            'lib/presentation/widgets/expertise/event_hosting_unlock_widget.dart:_checkUnlockStatus',
        'message': 'Unlock status checked',
        'data': {
          'wasUnlocked': wasUnlocked,
          'isUnlocked': _isUnlocked,
          'wasUnlockedBefore': _wasUnlockedBefore,
          'justUnlocked': !wasUnlocked && _isUnlocked,
        },
      };
      File('/Users/reisgordon/SPOTS/.cursor/debug.log')
          .writeAsStringSync('${jsonEncode(payload)}\n', mode: FileMode.append);
    } catch (_) {}
    // #endregion

    // Track if user was unlocked before widget initialization
    // This prevents showing animation on first load if already unlocked
    if (!_wasUnlockedBefore) {
      _wasUnlockedBefore = wasUnlocked || _isUnlocked;
    }

    // Trigger unlock animation if just unlocked (and wasn't already unlocked before init)
    if (!wasUnlocked && _isUnlocked && !_wasUnlockedBefore) {
      _unlockAnimationController.reset();
      _unlockAnimationController.forward();
    }

    // Get highest expertise level
    final pins = _expertiseService.getUserPins(widget.user);

    // #region agent log
    // Debug mode: log expertise level calculation (no PII values)
    try {
      final payload = <String, dynamic>{
        'id': 'log_${DateTime.now().millisecondsSinceEpoch}_H3',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'sessionId': 'debug-session',
        'runId': 'pre-fix-expertise-level',
        'hypothesisId': 'H3',
        'location':
            'lib/presentation/widgets/expertise/event_hosting_unlock_widget.dart:_checkUnlockStatus',
        'message': 'Expertise level calculated',
        'data': {
          'pinsCount': pins.length,
          'isUnlocked': _isUnlocked,
        },
      };
      File('/Users/reisgordon/SPOTS/.cursor/debug.log')
          .writeAsStringSync('${jsonEncode(payload)}\n', mode: FileMode.append);
    } catch (_) {}
    // #endregion

    if (pins.isNotEmpty) {
      pins.sort((a, b) => b.level.index.compareTo(a.level.index));
      _currentHighestLevel = pins.first.level;
    } else {
      _currentHighestLevel = ExpertiseLevel.local;
    }

    // Calculate progress to Local level if not unlocked
    if (!_isUnlocked) {
      // Find highest category to calculate progress
      if (pins.isNotEmpty) {
        final highestPin = pins.first;
        // Simplified progress calculation - in production, would get contribution counts
        _progressToCity = _expertiseService.calculateProgress(
          category: highestPin.category,
          location: highestPin.location,
          currentLevel: highestPin.level,
          respectedListsCount: highestPin.contributionCount,
          thoughtfulReviewsCount: highestPin.contributionCount,
          spotsReviewedCount: 0,
          communityTrustScore: highestPin.communityTrustScore,
        );
      } else {
        // No expertise yet - show progress to Local level
        _progressToCity = _expertiseService.calculateProgress(
          category: 'General',
          location: widget.user.location,
          currentLevel: ExpertiseLevel.local,
          respectedListsCount: 0,
          thoughtfulReviewsCount: 0,
          spotsReviewedCount: 0,
          communityTrustScore: 0.0,
        );
      }
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    return GestureDetector(
      onTap: _isUnlocked ? widget.onUnlockTap : widget.onProgressTap,
      child: Container(
        padding: EdgeInsets.all(spacing.md + spacing.xxs),
        decoration: BoxDecoration(
          color: _isUnlocked
              ? AppTheme.primaryColor.withValues(alpha: 0.1)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isUnlocked
                ? AppTheme.primaryColor.withValues(alpha: 0.3)
                : AppColors.grey300,
            width: 2,
          ),
        ),
        child: _isUnlocked ? _buildUnlockedState() : _buildLockedState(),
      ),
    );
  }

  Widget _buildUnlockedState() {
    final spacing = context.spacing;
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Unlocked Header
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(spacing.sm),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: AppTheme.primaryColor,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Event Hosting Unlocked!',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'You can now create and host events',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Current Level Display
            Container(
              padding: EdgeInsets.all(spacing.sm),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.grey200),
              ),
              child: Row(
                children: [
                  if (_currentHighestLevel != null) ...[
                    Text(
                      _currentHighestLevel!.emoji,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_currentHighestLevel!.displayName} Level',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Action Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: widget.onUnlockTap,
                icon: const Icon(Icons.event, size: 20),
                label: Text('Create Event'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: AppColors.white,
                  padding:
                      EdgeInsets.symmetric(vertical: spacing.sm + spacing.xxs),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLockedState() {
    final spacing = context.spacing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Locked Header
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(spacing.sm),
              decoration: const BoxDecoration(
                color: AppColors.grey200,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock,
                color: AppColors.textSecondary,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Unlock Event Hosting',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Reach Local level expertise to host events',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Requirement Display
        Container(
          padding: EdgeInsets.all(spacing.sm),
          decoration: BoxDecoration(
            color: AppColors.grey50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Requirement: ${ExpertiseLevel.local.emoji} ${ExpertiseLevel.local.displayName} Level or higher',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Current Level
        if (_currentHighestLevel != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Current Level',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              Row(
                children: [
                  Text(
                    _currentHighestLevel!.emoji,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _currentHighestLevel!.displayName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],

        // Progress to Local Level
        if (_progressToCity != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress to ${ExpertiseLevel.local.displayName}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              Text(
                '${_progressToCity!.progressPercentage.toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(
              begin: 0.0,
              end: _progressToCity!.progressPercentage / 100.0,
            ),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 8,
                  backgroundColor: AppColors.grey200,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryColor),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            _progressToCity!.getFormattedProgress(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],

        const SizedBox(height: 16),

        // Next Steps
        if (_progressToCity != null &&
            _progressToCity!.nextSteps.isNotEmpty) ...[
          Container(
            padding: EdgeInsets.all(spacing.sm),
            decoration: BoxDecoration(
              color: AppColors.grey50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Next Steps:',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 8),
                ..._progressToCity!.nextSteps.take(2).map((step) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: spacing.xxs),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: EdgeInsets.only(
                            top: spacing.xxs,
                            right: spacing.xs,
                          ),
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            step,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Event Hosting Unlock Notification Widget
/// Shows celebration when user unlocks event hosting
class EventHostingUnlockNotification extends StatelessWidget {
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const EventHostingUnlockNotification({
    super.key,
    this.onTap,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    return Container(
      margin: EdgeInsets.all(spacing.md),
      padding: EdgeInsets.all(spacing.md + spacing.xxs),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Celebration Icon
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '🎉',
                style: Theme.of(context).textTheme.displaySmall,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Event Hosting Unlocked!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'You\'ve reached Local level expertise. You can now create and host events!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: onDismiss,
                  child: Text(
                    'Dismiss',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: AppColors.white,
                  ),
                  child: Text('Create Event'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

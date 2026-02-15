import 'package:flutter/material.dart';
import 'package:avrai/core/design/feedback_presenter.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/models/expertise/expertise_event.dart';
import 'package:avrai/core/services/expertise/expertise_event_service.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/presentation/presentation_spacing.dart';

/// OUR_GUTS.md: "Make hosting incredibly easy"
/// Easy Event Hosting - Phase 3: Copy & Repeat
/// One-click button to duplicate past events
class EventHostAgainButton extends StatelessWidget {
  final ExpertiseEvent originalEvent;
  final VoidCallback? onSuccess;

  const EventHostAgainButton({
    super.key,
    required this.originalEvent,
    this.onSuccess,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _hostAgain(context),
      icon: const Icon(Icons.replay),
      label: Text('Host Again'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        padding: const EdgeInsets.symmetric(
            horizontal: kSpaceMdWide, vertical: kSpaceSm),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<void> _hostAgain(BuildContext context) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );

      // Duplicate the event
      final eventService = GetIt.I<ExpertiseEventService>();
      final newEvent = await eventService.duplicateEvent(
        originalEvent: originalEvent,
      );
      if (!context.mounted) return;

      // Close loading
      Navigator.pop(context);
      if (!context.mounted) return;

      // Show success
      context.showCustomSnackBar(
        SnackBar(
          content:
              Text('Event "${newEvent.title}" created for next weekend! 🎉'),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'View',
            textColor: AppColors.white,
            onPressed: () {
              if (!context.mounted) return;
              // Navigate to event detail page
              // Navigator.push(...);
            },
          ),
        ),
      );

      onSuccess?.call();
    } catch (e) {
      if (!context.mounted) return;
      // Close loading if still showing
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      if (!context.mounted) return;

      // Show error
      context.showError('Failed to duplicate event: $e');
    }
  }
}

/// Compact version for list items
class EventHostAgainIconButton extends StatelessWidget {
  final ExpertiseEvent originalEvent;
  final VoidCallback? onSuccess;

  const EventHostAgainIconButton({
    super.key,
    required this.originalEvent,
    this.onSuccess,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.replay, color: AppColors.primary),
      tooltip: 'Host Again',
      onPressed: () => _hostAgain(context),
    );
  }

  Future<void> _hostAgain(BuildContext context) async {
    // Same logic as button version
    final button = EventHostAgainButton(
      originalEvent: originalEvent,
      onSuccess: onSuccess,
    );
    await button._hostAgain(context);
  }
}

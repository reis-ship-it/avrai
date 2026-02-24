import 'package:avrai/core/services/predictive_outreach/outreach_preferences_service.dart';

class ExplicitFeedbackRateLimitDecision {
  const ExplicitFeedbackRateLimitDecision({
    required this.allowed,
    required this.reason,
    this.nextAllowedAt,
  });

  final bool allowed;
  final String reason;
  final DateTime? nextAllowedAt;
}

/// Phase 1.4.4 explicit feedback request limiter.
class ExplicitFeedbackRateLimiter {
  ExplicitFeedbackRateLimiter({
    Future<OutreachPreferences> Function(String userId)? preferenceResolver,
    DateTime Function()? nowProvider,
  })  : _preferenceResolver = preferenceResolver,
        _nowProvider = nowProvider ?? DateTime.now;

  final Future<OutreachPreferences> Function(String userId)?
      _preferenceResolver;
  final DateTime Function() _nowProvider;
  final Map<String, int> _sessionRequestCountByUser = {};
  final Map<String, DateTime> _lastRequestAtByUser = {};

  Future<ExplicitFeedbackRateLimitDecision> canRequest({
    required String userId,
    required String outreachType,
    DateTime? now,
  }) async {
    final currentTime = (now ?? _nowProvider()).toUtc();
    final preferences = await _resolvePreferences(userId);
    if (!preferences.isOutreachTypeAllowed(outreachType)) {
      return const ExplicitFeedbackRateLimitDecision(
        allowed: false,
        reason: 'outreach_preferences_blocked',
      );
    }

    final sessionCount = _sessionRequestCountByUser[userId] ?? 0;
    if (sessionCount >= 1) {
      return const ExplicitFeedbackRateLimitDecision(
        allowed: false,
        reason: 'session_limit_reached',
      );
    }

    final minimumGap = _minimumGapForFrequency(preferences.frequency);
    final previous = _lastRequestAtByUser[userId];
    if (previous != null) {
      final nextAllowed = previous.toUtc().add(minimumGap);
      if (currentTime.isBefore(nextAllowed)) {
        return ExplicitFeedbackRateLimitDecision(
          allowed: false,
          reason: 'back_to_back_blocked',
          nextAllowedAt: nextAllowed,
        );
      }
    }

    return const ExplicitFeedbackRateLimitDecision(
      allowed: true,
      reason: 'allowed',
    );
  }

  void markRequested({
    required String userId,
    DateTime? at,
  }) {
    _sessionRequestCountByUser[userId] =
        (_sessionRequestCountByUser[userId] ?? 0) + 1;
    _lastRequestAtByUser[userId] = (at ?? _nowProvider()).toUtc();
  }

  void resetSession({required String userId}) {
    _sessionRequestCountByUser[userId] = 0;
  }

  Future<OutreachPreferences> _resolvePreferences(String userId) async {
    final preferenceResolver = _preferenceResolver;
    if (preferenceResolver != null) {
      return preferenceResolver(userId);
    }
    return OutreachPreferences(
      userId: userId,
      enabled: true,
      frequency: 'medium',
      allowCommunityInvitations: true,
      allowGroupFormation: true,
      allowEventCalls: true,
      allowBusinessOutreach: true,
      allowClubOutreach: true,
      allowExpertOutreach: true,
      allowListSuggestions: true,
      updatedAt: _nowProvider(),
    );
  }

  Duration _minimumGapForFrequency(String frequency) {
    switch (frequency) {
      case 'high':
        return const Duration(minutes: 15);
      case 'medium':
        return const Duration(hours: 1);
      case 'low':
        return const Duration(hours: 6);
      case 'off':
        return const Duration(days: 3650);
      default:
        return const Duration(hours: 1);
    }
  }
}

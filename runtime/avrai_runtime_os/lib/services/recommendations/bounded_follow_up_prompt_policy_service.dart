import 'dart:math' as math;

import 'package:avrai_runtime_os/config/bham_beta_defaults.dart';

class BoundedFollowUpPromptPolicy {
  const BoundedFollowUpPromptPolicy({
    required this.maxPromptPlansPerDay,
    required this.quietHoursStartHour,
    required this.quietHoursEndHour,
    required this.suggestionFamilyCooldown,
    required this.eventFamilyCooldown,
  });

  final int maxPromptPlansPerDay;
  final int quietHoursStartHour;
  final int quietHoursEndHour;
  final Duration suggestionFamilyCooldown;
  final Duration eventFamilyCooldown;
}

class BoundedFollowUpPromptPolicyService {
  static final BoundedFollowUpPromptPolicy repoDefaultPolicy =
      BoundedFollowUpPromptPolicy(
    maxPromptPlansPerDay:
        BhamBetaDefaults.notificationDefaults.cappedSuggestionsPerDay,
    quietHoursStartHour:
        BhamBetaDefaults.notificationDefaults.quietHoursStartHour,
    quietHoursEndHour: BhamBetaDefaults.notificationDefaults.quietHoursEndHour,
    suggestionFamilyCooldown: Duration(days: 14),
    eventFamilyCooldown: Duration(days: 7),
  );

  static const Duration _communityFamilySuppression = Duration(days: 30);
  static const Duration _businessFamilySuppression = Duration(days: 30);
  static const Duration _groupFamilySuppression = Duration(days: 14);

  BoundedFollowUpPromptPolicyService({
    BoundedFollowUpPromptPolicy? policy,
  }) : policy = policy ?? repoDefaultPolicy;

  final BoundedFollowUpPromptPolicy policy;

  int clampPendingLimit(int limit) {
    if (limit <= 0) {
      return policy.maxPromptPlansPerDay;
    }
    return math.min(limit, policy.maxPromptPlansPerDay);
  }

  DateTime scheduleInitialEligibility({
    required DateTime plannedAtUtc,
    required int alreadyPlannedToday,
  }) {
    var next = plannedAtUtc.toUtc();
    if (_isQuietHours(next)) {
      next = _nextQuietHoursEnd(next);
    }
    if (alreadyPlannedToday >= policy.maxPromptPlansPerDay) {
      next = _startOfNextPromptWindow(next);
    }
    return next;
  }

  DateTime scheduleDeferredEligibility({
    required DateTime deferredAtUtc,
    required String channelHint,
  }) {
    var next = deferredAtUtc.toUtc().add(cooldownForChannelHint(channelHint));
    if (_isQuietHours(next)) {
      next = _nextQuietHoursEnd(next);
    }
    return next;
  }

  Duration cooldownForChannelHint(String channelHint) {
    switch (channelHint) {
      case 'event_reflection_follow_up':
      case 'future_event_preference_follow_up':
        return policy.eventFamilyCooldown;
      default:
        return policy.suggestionFamilyCooldown;
    }
  }

  Duration suppressionDurationForChannelHint(String channelHint) {
    switch (channelHint) {
      case 'event_reflection_follow_up':
      case 'future_event_preference_follow_up':
        return policy.eventFamilyCooldown;
      case 'community_reflection_follow_up':
        return _communityFamilySuppression;
      case 'business_operator_reflection_follow_up':
        return _businessFamilySuppression;
      case 'group_reflection_follow_up':
        return _groupFamilySuppression;
      default:
        return policy.suggestionFamilyCooldown;
    }
  }

  bool isEligible({
    required DateTime? nextEligibleAtUtc,
    DateTime? nowUtc,
  }) {
    if (nextEligibleAtUtc == null) {
      return true;
    }
    return !nextEligibleAtUtc
        .toUtc()
        .isAfter((nowUtc ?? DateTime.now()).toUtc());
  }

  bool _isQuietHours(DateTime nowUtc) {
    final hour = nowUtc.toUtc().hour;
    final start = policy.quietHoursStartHour;
    final end = policy.quietHoursEndHour;
    if (start > end) {
      return hour >= start || hour < end;
    }
    return hour >= start && hour < end;
  }

  DateTime _nextQuietHoursEnd(DateTime nowUtc) {
    final now = nowUtc.toUtc();
    final endHour = policy.quietHoursEndHour;
    var next = DateTime.utc(now.year, now.month, now.day, endHour);
    if (!next.isAfter(now)) {
      next = next.add(const Duration(days: 1));
    }
    return next;
  }

  DateTime _startOfNextPromptWindow(DateTime nowUtc) {
    final now = nowUtc.toUtc();
    return DateTime.utc(
      now.year,
      now.month,
      now.day,
      policy.quietHoursEndHour,
    ).add(const Duration(days: 1));
  }
}

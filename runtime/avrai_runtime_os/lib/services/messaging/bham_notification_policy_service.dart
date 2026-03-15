import 'package:avrai_runtime_os/config/bham_beta_defaults.dart';
import 'package:avrai_runtime_os/services/messaging/bham_messaging_models.dart';
import 'package:get_storage/get_storage.dart';

class BhamNotificationPolicyService {
  static const String _storeName = 'bham_notification_policy';

  NotificationBudgetPolicy get policy => NotificationBudgetPolicy(
        quietHoursStartHour:
            BhamBetaDefaults.notificationDefaults.quietHoursStartHour,
        quietHoursEndHour:
            BhamBetaDefaults.notificationDefaults.quietHoursEndHour,
        cappedClasses: const <NotificationClass>[
          NotificationClass.dailyDrop,
          NotificationClass.contextNudge,
          NotificationClass.ai2aiCompatibility,
        ],
        maxPerDay:
            BhamBetaDefaults.notificationDefaults.cappedSuggestionsPerDay,
      );

  Future<bool> canSend({
    required NotificationClass notificationClass,
    DateTime? nowUtc,
  }) async {
    if (notificationClass == NotificationClass.humanMessage) {
      return true;
    }
    final now = nowUtc ?? DateTime.now().toUtc();
    if (_isQuietHours(now)) {
      return false;
    }
    final count = await _currentCount(now);
    return count < policy.maxPerDay;
  }

  Future<void> recordSent({
    required NotificationClass notificationClass,
    DateTime? nowUtc,
  }) async {
    if (notificationClass == NotificationClass.humanMessage) {
      return;
    }
    final now = nowUtc ?? DateTime.now().toUtc();
    final box = GetStorage(_storeName);
    await box.write(_dayKey(now), (await _currentCount(now)) + 1);
  }

  bool _isQuietHours(DateTime nowUtc) {
    final hour = nowUtc.hour;
    final start = policy.quietHoursStartHour;
    final end = policy.quietHoursEndHour;
    if (start > end) {
      return hour >= start || hour < end;
    }
    return hour >= start && hour < end;
  }

  Future<int> _currentCount(DateTime nowUtc) async {
    final box = GetStorage(_storeName);
    return box.read<int>(_dayKey(nowUtc)) ?? 0;
  }

  String _dayKey(DateTime nowUtc) =>
      'count:${nowUtc.year}-${nowUtc.month}-${nowUtc.day}';
}

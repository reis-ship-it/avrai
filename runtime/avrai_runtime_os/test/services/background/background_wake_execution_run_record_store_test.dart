import 'package:avrai_runtime_os/services/background/background_execution_models.dart';
import 'package:avrai_runtime_os/services/background/background_wake_execution_run_record_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BackgroundWakeExecutionRunRecordStore', () {
    test('records and exports recent headless wake runs', () async {
      final store = BackgroundWakeExecutionRunRecordStore(
        nowUtc: () => DateTime.utc(2026, 3, 13, 20),
      );

      await store.record(
        BackgroundWakeExecutionRunRecord(
          reason: BackgroundWakeReason.bootCompleted,
          platformSource: 'android_boot_receiver',
          wakeTimestampUtc: DateTime.utc(2026, 3, 13, 19, 59),
          startedAtUtc: DateTime.utc(2026, 3, 13, 20),
          completedAtUtc: DateTime.utc(2026, 3, 13, 20, 0, 1),
          bootstrapSuccess: true,
          meshDueReplayCount: 1,
          meshRecoveredReplayCount: 2,
          meshDiscoveredPeerCount: 3,
          ai2aiReleasedCount: 1,
          ai2aiBlockedCount: 0,
          ai2aiTrustedRouteUnavailableBlockCount: 0,
          passiveIngestedDwellEventCount: 2,
          ambientCandidateObservationDeltaCount: 1,
          ambientConfirmedPromotionDeltaCount: 1,
          segmentRefreshCount: 1,
        ),
      );

      await store.record(
        BackgroundWakeExecutionRunRecord(
          reason: BackgroundWakeReason.backgroundTaskWindow,
          platformSource: 'ios_bg_task',
          wakeTimestampUtc: DateTime.utc(2026, 3, 13, 20, 5),
          startedAtUtc: DateTime.utc(2026, 3, 13, 20, 5),
          completedAtUtc: DateTime.utc(2026, 3, 13, 20, 5, 2),
          bootstrapSuccess: false,
          meshDueReplayCount: 0,
          meshRecoveredReplayCount: 0,
          meshDiscoveredPeerCount: 0,
          ai2aiReleasedCount: 0,
          ai2aiBlockedCount: 1,
          ai2aiTrustedRouteUnavailableBlockCount: 1,
          passiveIngestedDwellEventCount: 0,
          ambientCandidateObservationDeltaCount: 0,
          ambientConfirmedPromotionDeltaCount: 0,
          segmentRefreshCount: 0,
          failureSummary: 'timeout',
        ),
      );

      final recent = store.recentRecords(limit: 2);
      expect(recent, hasLength(2));
      expect(recent.first.platformSource, 'ios_bg_task');
      expect(recent.first.failureSummary, 'timeout');
      expect(recent.last.meshRecoveredReplayCount, 2);

      final export = store.exportRecentRuns(limit: 2);
      expect(export, contains('"platform_source": "ios_bg_task"'));
      expect(export, contains('"platform_source": "android_boot_receiver"'));
    });
  });
}

import 'package:flutter_test/flutter_test.dart';

import 'package:avrai/core/ai/memory/consolidation/consolidation_metrics_service.dart';
import 'package:avrai/core/services/ai_infrastructure/ai_improvement_tracking_service.dart';
import '../../../../helpers/platform_channel_helper.dart';

void main() {
  setUpAll(() async {
    await setupTestStorage();
  });

  tearDownAll(() async {
    await cleanupTestStorage();
  });

  test('logs consolidation metrics to AIImprovementTrackingService', () async {
    final tracking = AIImprovementTrackingService(storage: getTestStorage());
    final service = ConsolidationMetricsService(trackingService: tracking);

    await service.logSnapshot(
      ConsolidationMetricsSnapshot(
        agentId: 'agent-consolidation',
        episodesScanned: 120,
        episodesCompressed: 80,
        episodesPruned: 25,
        rulesExtracted: 6,
        memorySizeBefore: 500,
        memorySizeAfter: 430,
        duration: const Duration(seconds: 7),
        recordedAt: DateTime.utc(2026, 2, 20, 5, 0, 0),
      ),
    );

    final scanned = tracking.getOperationalMetrics(
      userId: 'agent-consolidation',
      metricName: 'memory_consolidation_episodes_scanned',
    );
    final duration = tracking.getOperationalMetrics(
      userId: 'agent-consolidation',
      metricName: 'memory_consolidation_duration_ms',
    );

    expect(scanned, hasLength(1));
    expect(scanned.first.value, 120);
    expect(duration, hasLength(1));
    expect(duration.first.value, 7000);
  });
}

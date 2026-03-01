import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_runtime_os/monitoring/connection_monitor.dart';
import 'package:avrai_runtime_os/monitoring/federated_learning_monitoring.dart';
import 'package:avrai_runtime_os/monitoring/hierarchical_ai_monitoring.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;

import '../../helpers/platform_channel_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FederatedLearningMonitoring', () {
    late FederatedLearningMonitoring monitoring;
    late ConnectionMonitor connectionMonitor;
    late HierarchicalAIMonitoring hierarchicalMonitoring;

    setUpAll(() async {
      await setupTestStorage();
    });

    setUp(() async {
      final prefs =
          await SharedPreferencesCompat.getInstance(storage: getTestStorage());
      connectionMonitor = ConnectionMonitor(prefs: prefs);
      hierarchicalMonitoring = HierarchicalAIMonitoring(
        connectionMonitor: connectionMonitor,
        areaResolver: null,
        regionResolver: null,
      );
      monitoring = FederatedLearningMonitoring(
        connectionMonitor: connectionMonitor,
        hierarchicalMonitoring: hierarchicalMonitoring,
      );
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });

    group('getActiveRounds', () {
      test('returns list (stub returns empty)', () async {
        final rounds = await monitoring.getActiveRounds();
        expect(rounds, isEmpty);
      });
    });

    group('getCompletedRounds', () {
      test('returns list (stub returns empty)', () async {
        final rounds = await monitoring.getCompletedRounds();
        expect(rounds, isEmpty);
      });
    });

    group('visualizeModelUpdates', () {
      test('returns ModelUpdateVisualization', () async {
        final viz = await monitoring.visualizeModelUpdates();
        expect(viz.localUpdateCount, 0);
        expect(viz.globalAggregationCount, 0);
        expect(viz.convergenceScore, inInclusiveRange(0.0, 1.0));
        expect(viz.computedAt, isA<DateTime>());
      });
    });

    group('calculateLearningEffectiveness', () {
      test('returns metrics (zero when no sessions)', () async {
        final metrics = await monitoring.calculateLearningEffectiveness();
        expect(metrics.sampleCount, 0);
        expect(metrics.convergenceSpeed, 0.0);
        expect(metrics.participantContributionQuality, 0.0);
      });
    });

    group('calculatePrivacyMetrics', () {
      test('returns FL privacy metrics', () async {
        final metrics = await monitoring.calculatePrivacyMetrics();
        expect(metrics.differentialPrivacyCompliant, isTrue);
        expect(metrics.anonymizationQuality, 1.0);
        expect(metrics.reidentificationRisk, 0.0);
      });
    });

    group('analyzeNetworkWidePatterns', () {
      test('returns list (possibly empty)', () async {
        final patterns = await monitoring.analyzeNetworkWidePatterns();
        expect(patterns, isA<List<NetworkWideLearningPattern>>());
      });
    });

    group('visualizeLearningPropagation', () {
      test('returns LearningPropagationVisualization', () async {
        final viz = await monitoring.visualizeLearningPropagation();
        expect(viz.userToAreaRate, inInclusiveRange(0.0, 1.0));
        expect(viz.areaToRegionRate, inInclusiveRange(0.0, 1.0));
        expect(viz.propagationSpeed, inInclusiveRange(0.0, 1.0));
        expect(viz.bottlenecks, isA<List<String>>());
        expect(viz.computedAt, isA<DateTime>());
      });
    });

    group('getFederatedLearningDashboard', () {
      test('returns full dashboard', () async {
        final dashboard = await monitoring.getFederatedLearningDashboard();
        expect(dashboard.activeRounds, isEmpty);
        expect(dashboard.completedRounds, isEmpty);
        expect(dashboard.modelUpdateVisualization, isNotNull);
        expect(dashboard.learningEffectiveness, isNotNull);
        expect(dashboard.privacyMetrics, isNotNull);
        expect(dashboard.networkWidePatterns,
            isA<List<NetworkWideLearningPattern>>());
        expect(dashboard.learningPropagation, isNotNull);
        expect(dashboard.generatedAt, isA<DateTime>());
      });
    });
  });

  group('FederatedLearningDashboard', () {
    test('empty() returns valid empty dashboard', () {
      final dashboard = FederatedLearningDashboard.empty();
      expect(dashboard.activeRounds, isEmpty);
      expect(dashboard.completedRounds, isEmpty);
      expect(dashboard.learningEffectiveness.sampleCount, 0);
      expect(dashboard.privacyMetrics.reidentificationRisk, 0.0);
    });
  });
}

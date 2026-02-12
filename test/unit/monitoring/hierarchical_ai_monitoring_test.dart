import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/monitoring/connection_monitor.dart';
import 'package:avrai/core/monitoring/hierarchical_ai_monitoring.dart';
import 'package:avrai/core/monitoring/hierarchical_ai_monitoring_models.dart';
import 'package:avrai/core/monitoring/network_flow.dart';
import 'package:avrai/core/models/quantum/connection_metrics.dart';

import 'package:avrai/core/services/infrastructure/storage_service.dart' show SharedPreferencesCompat;

import '../../helpers/platform_channel_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HierarchicalAIMonitoring', () {
    late HierarchicalAIMonitoring monitoring;
    late ConnectionMonitor connectionMonitor;

    setUpAll(() async {
      await setupTestStorage();
    });

    setUp(() async {
      final prefs =
          await SharedPreferencesCompat.getInstance(storage: getTestStorage());
      connectionMonitor = ConnectionMonitor(prefs: prefs);
      monitoring = HierarchicalAIMonitoring(
        connectionMonitor: connectionMonitor,
        areaResolver: null,
        regionResolver: null,
      );
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });

    group('getUserAIMetrics', () {
      test('returns empty list when no sessions', () async {
        final metrics = await monitoring.getUserAIMetrics();
        expect(metrics, isEmpty);
      });

      test('aggregates per agent when sessions exist', () async {
        final metrics = ConnectionMetrics.initial(
          localAISignature: 'agent-a',
          remoteAISignature: 'agent-b',
          compatibility: 0.8,
        );
        await connectionMonitor.startMonitoring('conn-1', metrics);
        final userMetrics = await monitoring.getUserAIMetrics();
        expect(userMetrics.length, 1);
        expect(userMetrics.first.agentId, 'agent-a');
        expect(userMetrics.first.connectionCount, 1);
        expect(userMetrics.first.averageCompatibility, closeTo(0.8, 0.01));
        expect(userMetrics.first.averagePleasureScore, inInclusiveRange(0.0, 1.0));
      });
    });

    group('getAreaAIMetrics', () {
      test('returns empty list when no user metrics', () async {
        final metrics = await monitoring.getAreaAIMetrics();
        expect(metrics, isEmpty);
      });

      test('groups user AIs into default area when no resolver', () async {
        final m = ConnectionMetrics.initial(
          localAISignature: 'agent-x',
          remoteAISignature: 'agent-y',
          compatibility: 0.7,
        );
        await connectionMonitor.startMonitoring('c1', m);
        final areaMetrics = await monitoring.getAreaAIMetrics();
        expect(areaMetrics.length, 1);
        expect(areaMetrics.first.areaId, 'default');
        expect(areaMetrics.first.userAICount, 1);
      });
    });

    group('getRegionalAIMetrics', () {
      test('returns empty list when no area metrics', () async {
        final metrics = await monitoring.getRegionalAIMetrics();
        expect(metrics, isEmpty);
      });
    });

    group('getUniversalAIMetrics', () {
      test('returns null when no regional metrics', () async {
        final metrics = await monitoring.getUniversalAIMetrics();
        expect(metrics, isNull);
      });
    });

    group('analyzeCrossLevelPatterns', () {
      test('returns list (possibly empty)', () async {
        final patterns = await monitoring.analyzeCrossLevelPatterns();
        expect(patterns, isA<List<CrossLevelPattern>>());
      });
    });

    group('getHierarchicalNetworkView', () {
      test('returns view with all levels', () async {
        final view = await monitoring.getHierarchicalNetworkView();
        expect(view.userMetrics, isA<List<UserAIMetrics>>());
        expect(view.areaMetrics, isA<List<AreaAIMetrics>>());
        expect(view.regionalMetrics, isA<List<RegionalAIMetrics>>());
        expect(view.crossLevelPatterns, isA<List<CrossLevelPattern>>());
        expect(view.generatedAt, isA<DateTime>());
      });
    });

    group('visualizeNetworkFlow', () {
      test('returns NetworkFlow (empty when no sessions)', () async {
        final flow = await monitoring.visualizeNetworkFlow();
        expect(flow, isA<NetworkFlow>());
        expect(flow.userAICount, 0);
        expect(flow.areaCount, 0);
        expect(flow.regionCount, 0);
        expect(flow.hasUniversal, false);
        expect(flow.learningPropagationRate, inInclusiveRange(0.0, 1.0));
        expect(flow.computedAt, isA<DateTime>());
      });
    });
  });

  group('NetworkFlow', () {
    test('empty() returns zero counts', () {
      final flow = NetworkFlow.empty();
      expect(flow.userAICount, 0);
      expect(flow.areaCount, 0);
      expect(flow.regionCount, 0);
      expect(flow.hasUniversal, false);
      expect(flow.bottlenecks, isEmpty);
      expect(flow.computedAt, isA<DateTime>());
    });

    test('fromHierarchicalView derives flow from view', () {
      final view = HierarchicalNetworkView(
        userMetrics: [
          UserAIMetrics(
            agentId: 'a1',
            connectionCount: 1,
            averageCompatibility: 0.8,
            averageLearningEffectiveness: 0.6,
            averagePleasureScore: 0.7,
            evolutionRate: 0.0,
            aggregatedAt: DateTime.now(),
          ),
        ],
        areaMetrics: [
          AreaAIMetrics(
            areaId: 'default',
            userAICount: 1,
            averageCompatibility: 0.8,
            averageLearningEffectiveness: 0.6,
            averagePleasureScore: 0.7,
            pleasureDistribution: {'a1': 0.7},
            aggregatedAt: DateTime.now(),
          ),
        ],
        regionalMetrics: [],
        universalMetrics: null,
        crossLevelPatterns: [],
        generatedAt: DateTime.now(),
      );
      final flow = NetworkFlow.fromHierarchicalView(view);
      expect(flow.userAICount, 1);
      expect(flow.areaCount, 1);
      expect(flow.regionCount, 0);
      expect(flow.hasUniversal, false);
      expect(flow.learningPropagationRate, inInclusiveRange(0.0, 1.0));
      expect(flow.patternEmergenceRate, inInclusiveRange(0.0, 1.0));
    });
  });
}

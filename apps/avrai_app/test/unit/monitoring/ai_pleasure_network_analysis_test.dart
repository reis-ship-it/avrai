import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_runtime_os/monitoring/ai_pleasure_network_analysis.dart';
import 'package:avrai_runtime_os/monitoring/connection_monitor.dart';
import 'package:avrai_core/models/quantum/connection_metrics.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;

import '../../helpers/platform_channel_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AIPleasureNetworkAnalysis', () {
    late AIPleasureNetworkAnalysis analysis;
    late ConnectionMonitor connectionMonitor;

    setUpAll(() async {
      await setupTestStorage();
    });

    setUp(() async {
      final prefs =
          await SharedPreferencesCompat.getInstance(storage: getTestStorage());
      connectionMonitor = ConnectionMonitor(prefs: prefs);
      analysis =
          AIPleasureNetworkAnalysis(connectionMonitor: connectionMonitor);
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });

    group('analyzePleasureMetrics', () {
      test('returns empty metrics when no sessions', () async {
        final metrics = await analysis.analyzePleasureMetrics();
        expect(metrics.sampleCount, 0);
        expect(metrics.mean, 0.5);
        expect(metrics.highPleasureCount, 0);
        expect(metrics.lowPleasureCount, 0);
      });

      test('computes distribution when sessions exist', () async {
        final m = ConnectionMetrics.initial(
          localAISignature: 'a',
          remoteAISignature: 'b',
          compatibility: 0.8,
        );
        await connectionMonitor.startMonitoring('c1', m);
        final metrics = await analysis.analyzePleasureMetrics();
        expect(metrics.sampleCount, 1);
        expect(metrics.mean, inInclusiveRange(0.0, 1.0));
        expect(metrics.median, inInclusiveRange(0.0, 1.0));
        expect(metrics.stdDev, greaterThanOrEqualTo(0.0));
        expect(metrics.percentile25, inInclusiveRange(0.0, 1.0));
        expect(metrics.percentile75, inInclusiveRange(0.0, 1.0));
      });
    });

    group('analyzePleasureTrends', () {
      test('returns list (possibly empty)', () async {
        final trends = await analysis.analyzePleasureTrends();
        expect(trends, isA<List<PleasureTrend>>());
      });
    });

    group('analyzePleasureCorrelation', () {
      test('returns empty when fewer than 2 sessions', () async {
        final m = ConnectionMetrics.initial(
          localAISignature: 'a',
          remoteAISignature: 'b',
          compatibility: 0.7,
        );
        await connectionMonitor.startMonitoring('c1', m);
        final corr = await analysis.analyzePleasureCorrelation();
        expect(corr, isEmpty);
      });

      test('returns correlations when 2+ sessions', () async {
        await connectionMonitor.startMonitoring(
          'c1',
          ConnectionMetrics.initial(
            localAISignature: 'a1',
            remoteAISignature: 'b1',
            compatibility: 0.8,
          ),
        );
        await connectionMonitor.startMonitoring(
          'c2',
          ConnectionMetrics.initial(
            localAISignature: 'a2',
            remoteAISignature: 'b2',
            compatibility: 0.6,
          ),
        );
        final corr = await analysis.analyzePleasureCorrelation();
        expect(corr.length, 2);
        expect(corr.any((c) => c.metric == 'connection_quality'), isTrue);
        expect(corr.any((c) => c.metric == 'learning_effectiveness'), isTrue);
        for (final c in corr) {
          expect(c.correlation, inInclusiveRange(-1.0, 1.0));
          expect(c.sampleCount, 2);
        }
      });
    });

    group('generatePleasureOptimizations', () {
      test('returns list (possibly empty)', () async {
        final recs = await analysis.generatePleasureOptimizations();
        expect(recs, isA<List<PleasureOptimizationRecommendation>>());
      });
    });
  });
}

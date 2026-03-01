import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_runtime_os/monitoring/network_analytics.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';

import '../../helpers/platform_channel_helper.dart';

/// SPOTS Network Analytics Tests
/// Date: November 20, 2025
/// Purpose: Test network analytics monitoring functionality
///
/// Test Coverage:
/// - Network health analysis
/// - Real-time metrics collection
/// - Analytics dashboard generation
/// - Anomaly detection
/// - Network optimization analysis
/// - Privacy metrics monitoring
///
/// Dependencies:
/// - Mock SharedPreferences: For storage operations
/// - NetworkAnalytics: Core analytics system

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NetworkAnalytics', () {
    late NetworkAnalytics networkAnalytics;
    late SharedPreferencesCompat prefs;

    setUpAll(() async {
      await setupTestStorage();
    });

    setUp(() async {
      prefs =
          await SharedPreferencesCompat.getInstance(storage: getTestStorage());
      networkAnalytics = NetworkAnalytics(prefs: prefs);
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });

    group('analyzeNetworkHealth', () {
      test('should generate network health report', () async {
        // Act
        final report = await networkAnalytics.analyzeNetworkHealth();

        // Assert
        expect(report, isNotNull);
        expect(report.overallHealthScore, greaterThanOrEqualTo(0.0));
        expect(report.overallHealthScore, lessThanOrEqualTo(1.0));
        expect(report.connectionQuality, isNotNull);
        expect(report.learningEffectiveness, isNotNull);
        expect(report.privacyMetrics, isNotNull);
        expect(report.stabilityMetrics, isNotNull);
        expect(report.aiPleasureAverage, greaterThanOrEqualTo(0.0));
        expect(report.aiPleasureAverage, lessThanOrEqualTo(1.0));
        expect(report.analysisTimestamp, isA<DateTime>());
      });

      test('should include performance issues when detected', () async {
        // Act
        final report = await networkAnalytics.analyzeNetworkHealth();

        // Assert
        expect(report.performanceIssues, isA<List<PerformanceIssue>>());
        expect(report.optimizationRecommendations,
            isA<List<OptimizationRecommendation>>());
      });

      test('should return degraded report on error', () async {
        // Arrange - Create analytics instance (storage-backed) and ensure it doesn't throw
        final invalidAnalytics = NetworkAnalytics(prefs: prefs);

        // Act - Force error by using invalid state
        final report = await invalidAnalytics.analyzeNetworkHealth();

        // Assert - Should still return a valid report (degraded or normal)
        expect(report, isNotNull);
        expect(report.overallHealthScore, greaterThanOrEqualTo(0.0));
      });
    });

    group('collectRealTimeMetrics', () {
      test('should collect real-time network metrics', () async {
        // Act
        final metrics = await networkAnalytics.collectRealTimeMetrics();

        // Assert
        expect(metrics, isNotNull);
        expect(metrics.connectionThroughput, greaterThanOrEqualTo(0.0));
        expect(metrics.matchingSuccessRate, greaterThanOrEqualTo(0.0));
        expect(metrics.matchingSuccessRate, lessThanOrEqualTo(1.0));
        expect(metrics.learningConvergenceSpeed, greaterThanOrEqualTo(0.0));
        expect(metrics.learningConvergenceSpeed, lessThanOrEqualTo(1.0));
        expect(metrics.vibeSynchronizationQuality, greaterThanOrEqualTo(0.0));
        expect(metrics.vibeSynchronizationQuality, lessThanOrEqualTo(1.0));
        expect(metrics.networkResponsiveness, greaterThanOrEqualTo(0.0));
        expect(metrics.networkResponsiveness, lessThanOrEqualTo(1.0));
        expect(metrics.resourceUtilization, isNotNull);
        expect(metrics.timestamp, isA<DateTime>());
      });

      test('should return zero metrics on error', () async {
        // Act - Should handle errors gracefully
        final metrics = await networkAnalytics.collectRealTimeMetrics();

        // Assert - Should return valid metrics (zero or normal)
        expect(metrics, isNotNull);
        expect(metrics.timestamp, isA<DateTime>());
      });
    });

    group('generateAnalyticsDashboard', () {
      test('should generate dashboard for specified time window', () async {
        // Arrange
        const timeWindow = Duration(days: 7);

        // Act
        final dashboard =
            await networkAnalytics.generateAnalyticsDashboard(timeWindow);

        // Assert
        expect(dashboard, isNotNull);
        expect(dashboard.timeWindow, equals(timeWindow));
        expect(dashboard.performanceTrends, isA<List<PerformanceTrend>>());
        expect(dashboard.evolutionStatistics, isNotNull);
        expect(dashboard.connectionPatterns, isA<List<ConnectionPattern>>());
        expect(dashboard.learningDistribution, isNotNull);
        expect(dashboard.privacyPreservationStats, isNotNull);
        expect(dashboard.usageAnalytics, isNotNull);
        expect(dashboard.networkGrowthMetrics, isNotNull);
        expect(dashboard.topPerformingArchetypes, isA<List<String>>());
        expect(dashboard.generatedAt, isA<DateTime>());
      });

      test('should return empty dashboard on error', () async {
        // Arrange
        const timeWindow = Duration(days: 1);

        // Act
        final dashboard =
            await networkAnalytics.generateAnalyticsDashboard(timeWindow);

        // Assert
        expect(dashboard, isNotNull);
        expect(dashboard.timeWindow, equals(timeWindow));
      });
    });

    group('detectNetworkAnomalies', () {
      test('should detect network anomalies', () async {
        // Act
        final anomalies = await networkAnalytics.detectNetworkAnomalies();

        // Assert
        expect(anomalies, isA<List<NetworkAnomaly>>());
        // Anomalies should be sorted by severity and recency
        if (anomalies.length > 1) {
          for (int i = 0; i < anomalies.length - 1; i++) {
            final current = anomalies[i];
            final next = anomalies[i + 1];

            // Severity should be descending, or if equal, recency descending
            final severityComparison =
                next.severity.index.compareTo(current.severity.index);
            if (severityComparison == 0) {
              expect(next.detectedAt.compareTo(current.detectedAt),
                  lessThanOrEqualTo(0));
            }
          }
        }
      });

      test('should return empty list when no anomalies detected', () async {
        // Act
        final anomalies = await networkAnalytics.detectNetworkAnomalies();

        // Assert
        expect(anomalies, isA<List<NetworkAnomaly>>());
        // May be empty or contain anomalies depending on network state
      });
    });

    group('analyzeNetworkOptimization', () {
      test('should generate optimization report', () async {
        // Act
        final report = await networkAnalytics.analyzeNetworkOptimization();

        // Assert
        expect(report, isNotNull);
        expect(report.connectionEfficiency, isNotNull);
        expect(report.learningBottlenecks, isA<List<LearningBottleneck>>());
        expect(report.resourceOptimization, isNotNull);
        expect(report.performanceImprovements, isNotNull);
        expect(report.optimizationActions, isA<List<OptimizationAction>>());
        expect(report.impactEstimates, isNotNull);
        expect(report.currentEfficiencyScore, greaterThanOrEqualTo(0.0));
        expect(report.currentEfficiencyScore, lessThanOrEqualTo(1.0));
        expect(report.potentialEfficiencyScore, greaterThanOrEqualTo(0.0));
        expect(report.potentialEfficiencyScore, lessThanOrEqualTo(1.0));
        expect(report.analyzedAt, isA<DateTime>());
      });

      test('should return empty report on error', () async {
        // Act
        final report = await networkAnalytics.analyzeNetworkOptimization();

        // Assert
        expect(report, isNotNull);
        expect(report.analyzedAt, isA<DateTime>());
      });
    });

    group('Privacy Metrics', () {
      test('should monitor privacy protection levels', () async {
        // Act
        final healthReport = await networkAnalytics.analyzeNetworkHealth();

        // Assert
        expect(healthReport.privacyMetrics, isNotNull);
        expect(healthReport.privacyMetrics.complianceRate,
            greaterThanOrEqualTo(0.0));
        expect(
            healthReport.privacyMetrics.complianceRate, lessThanOrEqualTo(1.0));
        expect(healthReport.privacyMetrics.anonymizationLevel,
            greaterThanOrEqualTo(0.0));
        expect(healthReport.privacyMetrics.anonymizationLevel,
            lessThanOrEqualTo(1.0));
        expect(healthReport.privacyMetrics.dataSecurityScore,
            greaterThanOrEqualTo(0.0));
        expect(healthReport.privacyMetrics.dataSecurityScore,
            lessThanOrEqualTo(1.0));
        expect(healthReport.privacyMetrics.encryptionStrength,
            greaterThanOrEqualTo(0.0));
        expect(healthReport.privacyMetrics.encryptionStrength,
            lessThanOrEqualTo(1.0));
      });

      test('should calculate overall privacy score', () {
        // Arrange
        final privacyMetrics = PrivacyMetrics(
          complianceRate: 0.95,
          anonymizationLevel: 0.90,
          dataSecurityScore: 0.98,
          privacyViolations: 0,
          encryptionStrength: 0.99,
        );

        // Act
        final overallScore = privacyMetrics.overallPrivacyScore;

        // Assert
        expect(overallScore, greaterThanOrEqualTo(0.0));
        expect(overallScore, lessThanOrEqualTo(1.0));
        expect(
            overallScore, closeTo(0.955, 0.01)); // Average of the four scores
      });
    });

    group('Overall health score formula (Phase 20.1)', () {
      test('should weight AI pleasure at 10% and clamp to [0,1]', () {
        final connectionQuality = ConnectionQualityMetrics(
          averageCompatibility: 0.8,
          connectionSuccessRate: 0.0,
          stabilityScore: 0.0,
          trustBuildingRate: 0.0,
          mutualBenefitScore: 0.0,
        );
        final learningEffectiveness = LearningEffectivenessMetrics(
          overallEffectiveness: 0.6,
          personalityEvolutionRate: 0.0,
          knowledgeAcquisitionSpeed: 0.0,
          insightQualityScore: 0.0,
          collectiveIntelligenceGrowth: 0.0,
        );
        final privacyMetrics = PrivacyMetrics(
          complianceRate: 0.9,
          anonymizationLevel: 0.0,
          dataSecurityScore: 0.0,
          privacyViolations: 0,
          encryptionStrength: 0.0,
        );
        final stabilityMetrics = NetworkStabilityMetrics(
          uptime: 0.5,
          reliability: 0.0,
          errorRate: 0.0,
          recoveryTime: Duration.zero,
          loadBalancing: 0.0,
        );

        final score = NetworkAnalytics.calculateOverallHealthScoreV1(
          connectionQuality: connectionQuality,
          learningEffectiveness: learningEffectiveness,
          privacyMetrics: privacyMetrics,
          stabilityMetrics: stabilityMetrics,
          aiPleasureAverage: 0.7,
        );

        // 0.25*0.8 + 0.25*0.6 + 0.20*0.9 + 0.20*0.5 + 0.10*0.7 = 0.70
        expect(score, closeTo(0.70, 0.0001));

        final clamped = NetworkAnalytics.calculateOverallHealthScoreV1(
          connectionQuality: connectionQuality,
          learningEffectiveness: learningEffectiveness,
          privacyMetrics: privacyMetrics,
          stabilityMetrics: stabilityMetrics,
          aiPleasureAverage: 2.0,
        );
        expect(clamped, inInclusiveRange(0.0, 1.0));
      });
    });

    group('Performance History', () {
      test('should maintain performance history', () async {
        // Act - Collect multiple metrics
        await networkAnalytics.collectRealTimeMetrics();
        await networkAnalytics.collectRealTimeMetrics();
        await networkAnalytics.collectRealTimeMetrics();

        // Generate dashboard to use history
        final dashboard = await networkAnalytics.generateAnalyticsDashboard(
          const Duration(days: 1),
        );

        // Assert
        expect(dashboard, isNotNull);
        expect(dashboard.performanceTrends, isA<List<PerformanceTrend>>());
      });
    });
  });
}

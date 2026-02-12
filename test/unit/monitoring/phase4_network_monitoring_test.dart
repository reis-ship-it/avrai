import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/monitoring/connection_monitor.dart';
import 'package:avrai/core/models/quantum/connection_metrics.dart';
import 'package:avrai/core/services/infrastructure/storage_service.dart' show SharedPreferencesCompat;
import '../../../test/mocks/mock_storage_service.dart';

/// Phase 4: Connection Monitor Test
/// OUR_GUTS.md: "Validation of AI2AI personality network monitoring systems"
/// 
/// This test focuses on ConnectionMonitor behavior testing.
/// NetworkAnalytics is tested separately in network_analytics_test.dart
void main() {
  group('Phase 4: Connection Monitor Tests', () {
    late SharedPreferencesCompat compatPrefs;
    
    setUpAll(() async {
      // Initialize mock storage for SharedPreferencesCompat
      final mockStorage = MockGetStorage.getInstance();
      MockGetStorage.reset();
      compatPrefs = await SharedPreferencesCompat.getInstance(storage: mockStorage);
    });
    
    setUp(() async {
      // Reset mock storage for test isolation
      MockGetStorage.reset();
      final mockStorage = MockGetStorage.getInstance();
      compatPrefs = await SharedPreferencesCompat.getInstance(storage: mockStorage);
    });
    
    tearDown(() {
      // Reset mock storage for test isolation
      MockGetStorage.reset();
    });
    
    group('Connection Monitor System', () {
      test('should start monitoring a connection', () async {
        final connectionMonitor = ConnectionMonitor(prefs: compatPrefs);
        
        final testMetrics = ConnectionMetrics(
          connectionId: 'test_connection_001',
          localAISignature: 'local_ai_signature',
          remoteAISignature: 'remote_ai_signature',
          initialCompatibility: 0.75,
          currentCompatibility: 0.80,
          learningEffectiveness: 0.70,
          aiPleasureScore: 0.85,
          connectionDuration: const Duration(minutes: 10),
          startTime: DateTime.now().subtract(const Duration(minutes: 10)),
          status: ConnectionStatus.active,
          learningOutcomes: {'insights_shared': 5},
          interactionHistory: [],
          dimensionEvolution: {'exploration_eagerness': 0.05, 'community_orientation': 0.03},
        );
        
        final session = await connectionMonitor.startMonitoring('test_connection_001', testMetrics);
        
        expect(session.connectionId, equals('test_connection_001'));
        expect(session.localAISignature, equals('local_ai_signature'));
        expect(session.remoteAISignature, equals('remote_ai_signature'));
        expect(session.initialMetrics, equals(testMetrics));
        expect(session.currentMetrics, equals(testMetrics));
        expect(session.qualityHistory, hasLength(1));
        expect(session.learningProgressHistory, hasLength(1));
        expect(session.alertsGenerated, isEmpty);
        expect(session.monitoringStatus, equals(MonitoringStatus.active));
        expect(session.startTime, isNotNull);
      });
      
      test('should update connection metrics during monitoring', () async {
        final monitor = ConnectionMonitor(prefs: compatPrefs);
        
        final initialMetrics = ConnectionMetrics(
          connectionId: 'test_connection_002',
          localAISignature: 'local_ai_signature_2',
          remoteAISignature: 'remote_ai_signature_2',
          initialCompatibility: 0.70,
          currentCompatibility: 0.70,
          learningEffectiveness: 0.65,
          aiPleasureScore: 0.80,
          connectionDuration: const Duration(minutes: 5),
          startTime: DateTime.now().subtract(const Duration(minutes: 5)),
          status: ConnectionStatus.active,
          learningOutcomes: {'insights_shared': 2},
          interactionHistory: [],
          dimensionEvolution: {'exploration_eagerness': 0.02},
        );
        
        // Start monitoring
        await monitor.startMonitoring('test_connection_002', initialMetrics);
        
        // Update metrics
        final updatedMetrics = ConnectionMetrics(
          connectionId: 'test_connection_002',
          localAISignature: 'local_ai_signature_2',
          remoteAISignature: 'remote_ai_signature_2',
          initialCompatibility: 0.70,
          currentCompatibility: 0.85,
          learningEffectiveness: 0.75,
          aiPleasureScore: 0.90,
          connectionDuration: const Duration(minutes: 10),
          startTime: DateTime.now().subtract(const Duration(minutes: 10)),
          status: ConnectionStatus.active,
          learningOutcomes: {'insights_shared': 8},
          interactionHistory: [],
          dimensionEvolution: {'exploration_eagerness': 0.08, 'community_orientation': 0.04},
        );
        
        final updatedSession = await monitor.updateConnectionMetrics('test_connection_002', updatedMetrics);
        
        expect(updatedSession.currentMetrics, equals(updatedMetrics));
        expect(updatedSession.qualityHistory, hasLength(2));
        expect(updatedSession.learningProgressHistory, hasLength(2));
        expect(updatedSession.lastUpdated, isNotNull);
      });
      
      test('should get real-time connection status', () async {
        final monitor = ConnectionMonitor(prefs: compatPrefs);
        
        final testMetrics = ConnectionMetrics(
          connectionId: 'test_connection_003',
          localAISignature: 'local_ai_signature_3',
          remoteAISignature: 'remote_ai_signature_3',
          initialCompatibility: 0.80,
          currentCompatibility: 0.82,
          learningEffectiveness: 0.78,
          aiPleasureScore: 0.88,
          connectionDuration: const Duration(minutes: 15),
          startTime: DateTime.now().subtract(const Duration(minutes: 15)),
          status: ConnectionStatus.active,
          learningOutcomes: {'insights_shared': 10},
          interactionHistory: [],
          dimensionEvolution: {'exploration_eagerness': 0.06},
        );
        
        // Start monitoring
        await monitor.startMonitoring('test_connection_003', testMetrics);
        
        final connectionStatus = await monitor.getConnectionStatus('test_connection_003');
        
        expect(connectionStatus.connectionId, equals('test_connection_003'));
        expect(connectionStatus.currentPerformance, isNotNull);
        expect(connectionStatus.healthScore, greaterThanOrEqualTo(0.0));
        expect(connectionStatus.healthScore, lessThanOrEqualTo(1.0));
        expect(connectionStatus.recentAlerts, isA<List<ConnectionAlert>>());
        expect(connectionStatus.trajectory, isNotNull);
        expect(connectionStatus.monitoringDuration, greaterThan(Duration.zero));
        expect(connectionStatus.lastUpdated, isNotNull);
      });
      
      test('should handle connection not found gracefully', () async {
        final monitor = ConnectionMonitor(prefs: compatPrefs);
        
        final connectionStatus = await monitor.getConnectionStatus('non_existent_connection');
        
        expect(connectionStatus.connectionId, equals('non_existent_connection'));
        expect(connectionStatus.healthScore, equals(0.0));
        expect(connectionStatus.monitoringDuration, equals(Duration.zero));
      });
      
      test('should analyze connection performance trends', () async {
        final monitor = ConnectionMonitor(prefs: compatPrefs);
        
        final testMetrics = ConnectionMetrics(
          connectionId: 'test_connection_004',
          localAISignature: 'local_ai_signature_4',
          remoteAISignature: 'remote_ai_signature_4',
          initialCompatibility: 0.75,
          currentCompatibility: 0.78,
          learningEffectiveness: 0.72,
          aiPleasureScore: 0.85,
          connectionDuration: const Duration(minutes: 20),
          startTime: DateTime.now().subtract(const Duration(minutes: 20)),
          status: ConnectionStatus.active,
          learningOutcomes: {'insights_shared': 12},
          interactionHistory: [],
          dimensionEvolution: {'exploration_eagerness': 0.07, 'authenticity_preference': 0.03},
        );
        
        // Start monitoring
        await monitor.startMonitoring('test_connection_004', testMetrics);
        
        final performanceAnalysis = await monitor.analyzeConnectionPerformance(
          'test_connection_004',
          const Duration(minutes: 30),
        );
        
        expect(performanceAnalysis.connectionId, equals('test_connection_004'));
        expect(performanceAnalysis.analysisWindow, equals(const Duration(minutes: 30)));
        expect(performanceAnalysis.qualityTrends, isNotNull);
        expect(performanceAnalysis.learningTrends, isNotNull);
        expect(performanceAnalysis.stabilityMetrics, isNotNull);
        expect(performanceAnalysis.performancePatterns, isA<List>());
        expect(performanceAnalysis.recommendations, isA<List>());
        expect(performanceAnalysis.overallPerformanceScore, greaterThanOrEqualTo(0.0));
        expect(performanceAnalysis.overallPerformanceScore, lessThanOrEqualTo(1.0));
        expect(performanceAnalysis.analyzedAt, isNotNull);
      });
      
      test('should generate active connections overview when no connections exist', () async {
        final monitor = ConnectionMonitor(prefs: compatPrefs);
        
        final overview = await monitor.getActiveConnectionsOverview();
        
        expect(overview.totalActiveConnections, equals(0));
        expect(overview.aggregateMetrics, isNotNull);
        expect(overview.topPerformingConnections, isEmpty);
        expect(overview.connectionsNeedingAttention, isEmpty);
        expect(overview.learningVelocityDistribution, isNotNull);
        expect(overview.optimizationOpportunities, isA<List>());
        expect(overview.averageConnectionDuration, equals(Duration.zero));
        expect(overview.totalAlertsGenerated, equals(0));
        expect(overview.generatedAt, isNotNull);
      });
      
      test('should detect connection anomalies', () async {
        final monitor = ConnectionMonitor(prefs: compatPrefs);
        
        final anomalies = await monitor.detectConnectionAnomalies();
        
        expect(anomalies, isA<List<ConnectionAnomaly>>());
        // Anomalies list can be empty if no connections are being monitored
        for (final anomaly in anomalies) {
          expect(anomaly.connectionId, isNotEmpty);
          expect(anomaly.type, isA<AnomalyType>());
          expect(anomaly.severity, isA<AlertSeverity>());
          expect(anomaly.description, isNotEmpty);
          expect(anomaly.detectedAt, isNotNull);
          expect(anomaly.metadata, isA<Map<String, dynamic>>());
        }
      });
      
      test('should stop monitoring and generate report', () async {
        final monitor = ConnectionMonitor(prefs: compatPrefs);
        
        final testMetrics = ConnectionMetrics(
          connectionId: 'test_connection_005',
          localAISignature: 'local_ai_signature_5',
          remoteAISignature: 'remote_ai_signature_5',
          initialCompatibility: 0.72,
          currentCompatibility: 0.85,
          learningEffectiveness: 0.80,
          aiPleasureScore: 0.90,
          connectionDuration: const Duration(minutes: 25),
          startTime: DateTime.now().subtract(const Duration(minutes: 25)),
          status: ConnectionStatus.completing,
          learningOutcomes: {'insights_shared': 15, 'dimensions_evolved': 3},
          interactionHistory: [],
          dimensionEvolution: {'exploration_eagerness': 0.10, 'community_orientation': 0.05},
        );
        
        // Start monitoring
        await monitor.startMonitoring('test_connection_005', testMetrics);
        
        // Stop monitoring
        final report = await monitor.stopMonitoring('test_connection_005');
        
        expect(report.connectionId, equals('test_connection_005'));
        expect(report.localAISignature, equals('local_ai_signature_5'));
        expect(report.remoteAISignature, equals('remote_ai_signature_5'));
        expect(report.connectionDuration, greaterThan(Duration.zero));
        expect(report.initialMetrics, isNotNull);
        expect(report.finalMetrics, equals(testMetrics));
        expect(report.performanceSummary, isNotNull);
        expect(report.learningOutcomes, isNotNull);
        expect(report.qualityAnalysis, isNotNull);
        expect(report.alertsGenerated, isA<List<ConnectionAlert>>());
        expect(report.overallRating, greaterThanOrEqualTo(0.0));
        expect(report.overallRating, lessThanOrEqualTo(1.0));
        expect(report.generatedAt, isNotNull);
        
        // Verify connection is no longer being monitored
        final statusAfterStop = await monitor.getConnectionStatus('test_connection_005');
        expect(statusAfterStop.healthScore, equals(0.0)); // Should return not found status
      });
    });
    
    group('Integration Validation', () {
      test('should validate monitoring data structures compatibility', () async {
        // Test that monitoring data structures are compatible with connection metrics
        final testMetrics = ConnectionMetrics(
          connectionId: 'integration_test_connection',
          localAISignature: 'local_signature',
          remoteAISignature: 'remote_signature',
          initialCompatibility: 0.75,
          currentCompatibility: 0.80,
          learningEffectiveness: 0.70,
          aiPleasureScore: 0.85,
          connectionDuration: const Duration(minutes: 10),
          startTime: DateTime.now().subtract(const Duration(minutes: 10)),
          status: ConnectionStatus.active,
          learningOutcomes: {'test': 1},
          interactionHistory: [],
          dimensionEvolution: {'test_dimension': 0.05},
        );
        
        // Validate that connection metrics work with monitoring components
        expect(testMetrics.connectionId, isNotEmpty);
        expect(testMetrics.currentCompatibility, greaterThanOrEqualTo(0.0));
        expect(testMetrics.currentCompatibility, lessThanOrEqualTo(1.0));
        expect(testMetrics.learningEffectiveness, greaterThanOrEqualTo(0.0));
        expect(testMetrics.learningEffectiveness, lessThanOrEqualTo(1.0));
        expect(testMetrics.status, isA<ConnectionStatus>());
        expect(testMetrics.dimensionEvolution, isA<Map<String, double>>());
      });
      
      test('should validate complete monitoring lifecycle', () async {
        final monitor = ConnectionMonitor(prefs: compatPrefs);
        
        // Test monitoring lifecycle
        final testMetrics = ConnectionMetrics(
          connectionId: 'lifecycle_test',
          localAISignature: 'local_test',
          remoteAISignature: 'remote_test',
          initialCompatibility: 0.70,
          currentCompatibility: 0.75,
          learningEffectiveness: 0.65,
          aiPleasureScore: 0.80,
          connectionDuration: const Duration(minutes: 5),
          startTime: DateTime.now().subtract(const Duration(minutes: 5)),
          status: ConnectionStatus.active,
          learningOutcomes: {},
          interactionHistory: [],
          dimensionEvolution: {},
        );
        
        // Start monitoring
        final session = await monitor.startMonitoring('lifecycle_test', testMetrics);
        expect(session.monitoringStatus, equals(MonitoringStatus.active));
        
        // Get connection status while monitoring
        final status = await monitor.getConnectionStatus('lifecycle_test');
        expect(status.connectionId, equals('lifecycle_test'));
        expect(status.healthScore, greaterThan(0.0));
        
        // Stop monitoring
        final report = await monitor.stopMonitoring('lifecycle_test');
        expect(report.connectionId, equals('lifecycle_test'));
        expect(report.connectionDuration, greaterThan(Duration.zero));
        
        // Verify connection is no longer being monitored
        final statusAfterStop = await monitor.getConnectionStatus('lifecycle_test');
        expect(statusAfterStop.healthScore, equals(0.0));
      });
    });
  });
}

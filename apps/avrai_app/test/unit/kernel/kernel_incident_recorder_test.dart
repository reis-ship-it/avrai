import 'package:avrai_runtime_os/cloud/production_readiness_manager.dart';
import 'package:avrai_runtime_os/cloud/microservices_manager.dart';
import 'package:avrai_runtime_os/cloud/realtime_sync_manager.dart' as sync;
import 'package:avrai_runtime_os/cloud/edge_computing_manager.dart' as edge;
import 'package:avrai_runtime_os/deployment/production_manager.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_os.dart';
import 'package:avrai_runtime_os/kernel/os/kernel_incident_recorder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('records production recovery through functional kernel OS', () async {
    final os = _FakeFunctionalKernelOs();
    final recorder = DefaultKernelIncidentRecorder(
      functionalKernelOs: os,
    );

    final record = await recorder.recordProductionRecovery(
      healthReport: ProductionHealthReport(
        overallHealth: 0.61,
        microservicesHealth: ClusterHealthReport(
          clusterId: 'cluster-a',
          overallHealth: 0.6,
          serviceHealth: <String, ServiceHealthStatus>{
            'api': ServiceHealthStatus(
              serviceName: 'api',
              isHealthy: true,
              responseTime: const Duration(milliseconds: 80),
              errorRate: 0.01,
              lastChecked: DateTime.utc(2026, 3, 7, 20),
            ),
            'sync': ServiceHealthStatus(
              serviceName: 'sync',
              isHealthy: false,
              responseTime: const Duration(milliseconds: 220),
              errorRate: 0.12,
              lastChecked: DateTime.utc(2026, 3, 7, 20),
            ),
          },
          infrastructureHealth: InfrastructureHealth(
            cpuUsage: 0.72,
            memoryUsage: 0.68,
            diskUsage: 0.41,
            networkLatency: const Duration(milliseconds: 120),
            score: 0.64,
          ),
          networkHealth: NetworkHealth(
            latency: const Duration(milliseconds: 140),
            throughput: 0.71,
            packetLoss: 0.04,
            connectivity: 0.83,
            score: 0.66,
          ),
          securityStatus: SecurityStatus(
            encryptionEnabled: true,
            authenticationEnabled: true,
            vulnerabilities: 2,
            lastSecurityScan: DateTime.utc(2026, 3, 7, 19),
            score: 0.74,
          ),
          timestamp: DateTime.utc(2026, 3, 7, 20),
          recommendations: const <String>['restart unhealthy services'],
        ),
        syncHealth: sync.SyncStatusReport(
          overallHealth: 0.52,
          channelStatuses: <String, sync.ChannelSyncStatus>{
            'primary': sync.ChannelSyncStatus(
              channelId: 'primary',
              status: sync.SyncChannelStatus.error,
              lastSyncTime: DateTime.utc(2026, 3, 7, 19, 58),
              pendingChanges: 11,
              syncLatency: const Duration(milliseconds: 240),
              errorRate: 0.18,
              throughput: 0.52,
            ),
          },
          bottlenecks: <sync.SyncBottleneck>[
            sync.SyncBottleneck(
              type: sync.BottleneckType.queueBacklog,
              channelId: 'primary',
              severity: sync.BottleneckSeverity.high,
              description: 'Queue backlog detected',
            ),
          ],
          recommendations: const <String>['drain sync queue'],
          totalPendingChanges: 11,
          avgSyncLatency: const Duration(milliseconds: 240),
          timestamp: DateTime.utc(2026, 3, 7, 20),
        ),
        edgeHealth: edge.EdgePerformanceReport(
          overallPerformance: 0.58,
          nodePerformances: <String, edge.EdgeNodePerformance>{
            'edge-1': edge.EdgeNodePerformance(
              nodeId: 'edge-1',
              cpuUsage: 0.77,
              memoryUsage: 0.63,
              networkLatency: const Duration(milliseconds: 180),
              cacheHitRate: 0.54,
              throughput: 0.6,
              availability: 0.96,
              errorRate: 0.07,
            ),
          },
          bottlenecks: <edge.PerformanceBottleneck>[
            edge.PerformanceBottleneck(
              type: edge.BottleneckType.highLatency,
              nodeId: 'edge-1',
              severity: edge.BottleneckSeverity.high,
              description: 'Latency above target',
            ),
          ],
          recommendations: const <String>['rebalance edge traffic'],
          slaCompliance: edge.SLACompliance(compliant: false, score: 0.62),
          averageLatency: const Duration(milliseconds: 180),
          cacheEfficiency: 0.54,
          bandwidthUtilization: 0.73,
          timestamp: DateTime.utc(2026, 3, 7, 20),
        ),
        deploymentHealth: ProductionHealthStatus(
          overallHealth: 0.63,
          systemHealth: SystemHealthMetrics(
            uptime: const Duration(hours: 12),
            availability: 0.97,
            diskUsage: 0.41,
            networkLatency: const Duration(milliseconds: 120),
            score: 0.66,
          ),
          performanceMetrics: PerformanceMetrics(
            responseTime: const Duration(milliseconds: 190),
            throughput: 420,
            errorRate: 0.06,
            memoryUsage: 0.68,
            cpuUsage: 0.72,
            score: 0.64,
          ),
          privacyCompliance: PrivacyComplianceMetrics(
            dataEncrypted: true,
            userConsentTracked: true,
            privacyViolations: 0,
            complianceScore: 0.98,
            score: 0.98,
          ),
          userExperience: UserExperienceMetrics(
            userSatisfaction: 0.74,
            averageSessionDuration: const Duration(minutes: 19),
            discoverySuccess: 0.7,
            recommendationAccuracy: 0.72,
            score: 0.73,
          ),
          aiSystemHealth: AISystemHealthMetrics(
            recommendationEngine: 0.72,
            ai2aiCommunication: 0.65,
            federatedLearning: 0.69,
            privacyPreservation: 0.94,
            score: 0.75,
          ),
          p2pNetworkHealth: P2PNetworkHealthMetrics(
            activeNodes: 14,
            networkConnectivity: 0.78,
            dataSync: 0.66,
            trustNetworkHealth: 0.81,
            score: 0.75,
          ),
          lastChecked: DateTime.utc(2026, 3, 7, 20),
        ),
        criticalIssues: <ProductionIssue>[
          ProductionIssue(
            issueId: 'sync-lag',
            description: 'sync lag',
            severity: 'high',
          ),
        ],
        recommendations: const <String>['restart services'],
        slaCompliance: SLAComplianceResult(compliant: false),
        uptime: const Duration(hours: 12),
        timestamp: DateTime.utc(2026, 3, 7, 20),
      ),
      recoveryResult: RecoveryActionResult(
        recoveryActions: const <String, bool>{
          'service_restart': true,
          'cache_reset': false,
        },
        overallSuccess: false,
        healthImprovement: 0.12,
        postRecoveryHealth: 0.73,
        timestamp: DateTime.utc(2026, 3, 7, 20, 5),
      ),
    );

    expect(record.bundle.why?.rootCauseType, WhyRootCauseType.mixed);
    expect(os.lastEnvelope?.eventType, equals('incident_recovery'));
    expect(os.lastWhyRequest?.actualOutcome, equals('recovery_degraded'));
  });
}

class _FakeFunctionalKernelOs implements FunctionalKernelOs {
  KernelEventEnvelope? lastEnvelope;
  KernelWhyRequest? lastWhyRequest;

  @override
  WhyKernelSnapshot explainWhy(KernelWhyRequest request) {
    return WhyKernelSnapshot(
      goal: request.goal ?? 'incident',
      summary: 'incident recorded',
      rootCauseType: WhyRootCauseType.mixed,
      confidence: 0.77,
      drivers: request.coreSignals,
      inhibitors: request.pheromoneSignals,
      counterfactuals: const <WhyCounterfactual>[],
      createdAtUtc: DateTime.utc(2026, 3, 7, 20, 5),
    );
  }

  @override
  Future<KernelBundleRecord> resolveAndExplain({
    required KernelEventEnvelope envelope,
    required KernelWhyRequest whyRequest,
  }) async {
    lastEnvelope = envelope;
    lastWhyRequest = whyRequest;
    return KernelBundleRecord(
      recordId: envelope.eventId,
      eventId: envelope.eventId,
      createdAtUtc: DateTime.utc(2026, 3, 7, 20, 5),
      bundle: KernelContextBundle(
        who: const WhoKernelSnapshot(
          primaryActor: 'system',
          affectedActor: 'runtime_cluster',
          companionActors: <String>[],
          actorRoles: <String>['system'],
          trustScope: 'system',
          cohortRefs: <String>[],
          identityConfidence: 1.0,
        ),
        what: const WhatKernelSnapshot(
          actionType: 'perform_automated_recovery',
          targetEntityType: 'runtime_cluster',
          targetEntityId: 'production_runtime',
          stateTransitionType: 'recovery',
          outcomeType: 'recovery_degraded',
          semanticTags: <String>['incident'],
          taxonomyConfidence: 1.0,
        ),
        when: WhenKernelSnapshot(
          observedAt: envelope.occurredAtUtc,
          freshness: 1.0,
          recencyBucket: 'immediate',
          timingConflictFlags: const <String>[],
          temporalConfidence: 1.0,
        ),
        where: const WhereKernelSnapshot(
          localityToken: 'where:bootstrap',
          cityCode: 'unknown_city',
          localityCode: 'unknown_locality',
          projection: <String, dynamic>{},
          boundaryTension: 0.0,
          spatialConfidence: 0.0,
          travelFriction: 0.0,
          placeFitFlags: <String>[],
        ),
        how: const HowKernelSnapshot(
          executionPath: 'automated_recovery',
          workflowStage: 'incident_recovery',
          transportMode: 'in_process',
          plannerMode: 'ops',
          modelFamily: 'production_readiness',
          interventionChain: <String>['restart', 'reset'],
          failureMechanism: 'cluster_degradation',
          mechanismConfidence: 0.85,
        ),
        why: explainWhy(whyRequest),
      ),
    );
  }

  @override
  Future<KernelContextBundle> resolveKernelContext(
          KernelEventEnvelope envelope) async =>
      throw UnimplementedError();
  @override
  Future<RealityKernelFusionInput> buildRealityKernelFusionInput({
    required KernelEventEnvelope envelope,
    required KernelWhyRequest whyRequest,
  }) async {
    final record = await resolveAndExplain(
      envelope: envelope,
      whyRequest: whyRequest,
    );
    return RealityKernelFusionInput(
      envelope: envelope,
      bundle: record.bundle,
      who: WhoRealityProjection(
        summary: 'system identity',
        confidence: record.bundle.who?.identityConfidence ?? 0.0,
      ),
      what: WhatRealityProjection(
        summary: 'incident recovery',
        confidence: record.bundle.what?.taxonomyConfidence ?? 0.0,
      ),
      when: WhenRealityProjection(
        summary: 'incident ordering',
        confidence: record.bundle.when?.temporalConfidence ?? 0.0,
      ),
      where: WhereRealityProjection(
        summary: 'bootstrap locality',
        confidence: record.bundle.where?.spatialConfidence ?? 0.0,
      ),
      why: WhyRealityProjection(
        summary: record.bundle.why?.summary ?? 'incident recorded',
        confidence: record.bundle.why?.confidence ?? 0.0,
      ),
      how: HowRealityProjection(
        summary: record.bundle.how?.executionPath ?? 'automated_recovery',
        confidence: record.bundle.how?.mechanismConfidence ?? 0.0,
      ),
      generatedAtUtc: record.createdAtUtc,
    );
  }

  @override
  Future<HowKernelSnapshot> resolveHow(KernelEventEnvelope envelope) async =>
      throw UnimplementedError();
  @override
  Future<WhatKernelSnapshot> resolveWhat(KernelEventEnvelope envelope) async =>
      throw UnimplementedError();
  @override
  Future<WhenKernelSnapshot> resolveWhen(KernelEventEnvelope envelope) async =>
      throw UnimplementedError();
  @override
  Future<WhereKernelSnapshot> resolveWhere(
          KernelEventEnvelope envelope) async =>
      throw UnimplementedError();
  @override
  Future<WhoKernelSnapshot> resolveWho(KernelEventEnvelope envelope) async =>
      throw UnimplementedError();
}

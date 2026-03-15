import 'package:avrai_runtime_os/kernel/mesh/mesh_kernel_contract.dart';
import 'package:avrai_runtime_os/kernel/mesh/mesh_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/mesh/mesh_native_bridge_bindings.dart';
import 'package:avrai_runtime_os/kernel/mesh/mesh_native_priority.dart';
import 'package:avrai_runtime_os/kernel/mesh/native_backed_mesh_kernel.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NativeBackedMeshKernel', () {
    test('falls back when native bridge is unavailable', () async {
      final kernel = NativeBackedMeshKernel(
        nativeBridge: _UnavailableMeshBridge(),
        fallback: _FakeMeshFallback(),
        policy: const MeshNativeExecutionPolicy(requireNative: false),
      );

      final plan = await kernel.planMesh(_planningRequest());

      expect(plan.reason, 'fallback_plan');
    });

    test('throws when native is required and unavailable', () async {
      final kernel = NativeBackedMeshKernel(
        nativeBridge: _UnavailableMeshBridge(),
        fallback: _FakeMeshFallback(),
        policy: const MeshNativeExecutionPolicy(requireNative: true),
      );

      expect(
        () => kernel.planMesh(_planningRequest()),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('Native mesh kernel is required'),
          ),
        ),
      );
    });

    test('consumes handled native plan payload', () async {
      final audit = MeshNativeFallbackAudit();
      final kernel = NativeBackedMeshKernel(
        nativeBridge: _DispatchingMeshBridge(
          <String, Map<String, dynamic>>{
            'plan_mesh': <String, dynamic>{
              'handled': true,
              'payload': <String, dynamic>{
                'planning_id': 'mesh-plan-native',
                'destination_id': 'peer-b',
                'planned_at_utc': '2026-03-12T18:00:00.000Z',
                'lifecycle_state': 'planned',
                'allowed': true,
                'queued': false,
                'reason': 'native_plan',
                'context': const <String, dynamic>{'source': 'native'},
              },
            },
          },
        ),
        fallback: _FakeMeshFallback(),
        audit: audit,
      );

      final plan = await kernel.planMesh(_planningRequest());

      expect(plan.reason, 'native_plan');
      expect(plan.context['source'], 'native');
      expect(audit.nativeHandledCount, 1);
    });

    test('diagnose reports native-backed health when native handles syscall',
        () async {
      final audit = MeshNativeFallbackAudit();
      final kernel = NativeBackedMeshKernel(
        nativeBridge: _DispatchingMeshBridge(
          <String, Map<String, dynamic>>{
            'diagnose_mesh_kernel': <String, dynamic>{
              'handled': true,
              'payload': const <String, dynamic>{
                'route_receipt_truth_present': true,
                'snapshot_supported': true,
                'replay_supported': true,
              },
            },
          },
        ),
        fallback: _FakeMeshFallback(),
        audit: audit,
      );

      final health = await kernel.diagnoseMesh();

      expect(health.nativeBacked, isTrue);
      expect(health.status, MeshHealthStatus.healthy);
      expect(health.diagnostics['route_receipt_truth_present'], isTrue);
      expect(audit.nativeHandledCount, 1);
    });
  });
}

class _UnavailableMeshBridge implements MeshNativeInvocationBridge {
  @override
  bool get isAvailable => false;

  @override
  void initialize() {}

  @override
  Map<String, dynamic> invoke({
    required String syscall,
    required Map<String, dynamic> payload,
  }) {
    throw UnimplementedError();
  }
}

class _DispatchingMeshBridge implements MeshNativeInvocationBridge {
  _DispatchingMeshBridge(this._responses);

  final Map<String, Map<String, dynamic>> _responses;

  @override
  bool get isAvailable => true;

  @override
  void initialize() {}

  @override
  Map<String, dynamic> invoke({
    required String syscall,
    required Map<String, dynamic> payload,
  }) {
    return _responses[syscall] ?? const <String, dynamic>{'handled': false};
  }
}

class _FakeMeshFallback extends MeshKernelFallbackSurface {
  @override
  Future<MeshTransportReceipt> commitTransport(MeshTransportCommit request) async {
    return MeshTransportReceipt(
      recordId: request.attemptId,
      subjectId: request.plan.destinationId,
      lifecycleState: MeshTransportLifecycleState.forwarded,
      recordedAtUtc: DateTime.utc(2026, 3, 12, 18),
    );
  }

  @override
  Future<MeshTransportReceipt> observeTransport(
      MeshObservation observation) async {
    return MeshTransportReceipt(
      recordId: observation.observationId,
      subjectId: observation.subjectId,
      accepted: true,
      lifecycleState: observation.lifecycleState.toTransportLifecycleState(),
      recordedAtUtc: DateTime.utc(2026, 3, 12, 18),
    );
  }

  @override
  Future<MeshTransportPlan> planTransport(MeshRoutePlanningRequest request) async {
    return MeshTransportPlan(
      planningId: request.planningId,
      destinationId: request.destinationId,
      plannedAtUtc: DateTime.utc(2026, 3, 12, 18),
      lifecycleState: MeshTransportLifecycleState.planned,
      allowed: true,
      reason: 'fallback_plan',
    );
  }

  @override
  MeshTransportSnapshot? snapshotTransport(String subjectId) {
    return MeshTransportSnapshot(
      subjectId: subjectId,
      destinationId: 'peer-b',
      lifecycleState: MeshTransportLifecycleState.planned,
      savedAtUtc: DateTime.utc(2026, 3, 12, 18),
    );
  }
}

MeshRoutePlanningRequest _planningRequest() {
  return MeshRoutePlanningRequest(
    planningId: 'mesh-plan-native',
    destinationId: 'peer-b',
    envelope: KernelEventEnvelope(
      eventId: 'mesh-plan-native',
      occurredAtUtc: DateTime.utc(2026, 3, 12, 18),
      agentId: 'agent-a',
      eventType: 'mesh_plan',
    ),
    governanceBundle: KernelContextBundle(
      who: const WhoKernelSnapshot(
        primaryActor: 'agent-a',
        affectedActor: 'peer-b',
        companionActors: <String>[],
        actorRoles: <String>['peer'],
        trustScope: 'private',
        cohortRefs: <String>[],
        identityConfidence: 0.9,
      ),
      what: const WhatKernelSnapshot(
        actionType: 'deliver',
        targetEntityType: 'message',
        targetEntityId: 'message-1',
        stateTransitionType: 'planned',
        outcomeType: 'pending',
        semanticTags: <String>['mesh'],
        taxonomyConfidence: 0.9,
      ),
      when: WhenKernelSnapshot(
        observedAt: DateTime.utc(2026, 3, 12, 18),
        freshness: 0.9,
        recencyBucket: 'hot',
        timingConflictFlags: const <String>[],
        temporalConfidence: 0.9,
      ),
      where: const WhereKernelSnapshot(
        localityToken: 'where:test',
        cityCode: 'bham',
        localityCode: 'test',
        projection: <String, dynamic>{},
        boundaryTension: 0.0,
        spatialConfidence: 0.9,
        travelFriction: 0.0,
        placeFitFlags: <String>[],
      ),
      how: const HowKernelSnapshot(
        executionPath: 'test',
        workflowStage: 'validation',
        transportMode: 'mesh',
        plannerMode: 'governed',
        modelFamily: 'signal_reticulum',
        interventionChain: <String>[],
        failureMechanism: 'none',
        mechanismConfidence: 0.9,
      ),
      why: WhyKernelSnapshot(
        goal: 'test',
        summary: 'test',
        rootCauseType: WhyRootCauseType.mechanism,
        confidence: 0.9,
        drivers: const <WhySignal>[],
        inhibitors: const <WhySignal>[],
        counterfactuals: const <WhyCounterfactual>[],
        createdAtUtc: DateTime.utc(2026, 3, 12, 18),
      ),
    ),
  );
}

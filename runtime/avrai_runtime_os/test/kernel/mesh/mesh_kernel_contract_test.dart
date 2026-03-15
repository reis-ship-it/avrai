import 'package:avrai_core/models/temporal/monte_carlo_run_context.dart';
import 'package:avrai_runtime_os/kernel/mesh/mesh_kernel_contract.dart';
import 'package:avrai_runtime_os/kernel/mesh/mesh_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MeshKernelContract', () {
    test('default replay and projection use snapshot truth', () async {
      final kernel = _FakeMeshKernel();

      final replay = await kernel.replayMesh(
        const KernelReplayRequest(subjectId: 'route:peer-b'),
      );
      final projection = await kernel.projectMeshForRealityModel(
        MeshProjectionRequest(
          subjectId: 'route:peer-b',
          whenSnapshot: WhenKernelSnapshot(
            observedAt: DateTime.utc(2026, 3, 11, 15, 30),
            freshness: 0.82,
            recencyBucket: 'hot',
            timingConflictFlags: const <String>['none'],
            temporalConfidence: 0.91,
          ),
        ),
      );
      final health = await kernel.diagnoseMesh();

      expect(replay.single.summary, contains('peer-b'));
      expect(projection.what.payload['destination_id'], 'peer-b');
      expect(projection.when.payload['projection_surface'], 'when');
      expect(projection.when.features['freshness'], 0.82);
      expect(projection.why.payload['projection_surface'], 'why');
      expect(health.kernelId, 'mesh_runtime_governance');
    });

    test('simulation request round-trips through json', () {
      final request = MeshSimulationRequest(
        simulationId: 'mesh-sim-1',
        runContext: const MonteCarloRunContext(
          canonicalReplayYear: 2026,
          replayYear: 2026,
          branchId: 'branch-bham',
          runId: 'run-mesh-1',
          seed: 7,
          divergencePolicy: 'bounded',
        ),
        seedEnvelopes: <KernelEventEnvelope>[
          KernelEventEnvelope(
            eventId: 'mesh-event-1',
            occurredAtUtc: DateTime.utc(2026, 3, 11),
            agentId: 'agent-a',
            eventType: 'mesh_path_update',
          ),
        ],
        topology: const <String, dynamic>{
          'mesh_runtime_state_frame': <String, dynamic>{
            'route_destination_count': 2,
            'pending_custody_count': 1,
          },
        },
      );

      final decoded = MeshSimulationRequest.fromJson(request.toJson());
      expect(decoded.simulationId, request.simulationId);
      expect(decoded.seedEnvelopes.single.eventId, 'mesh-event-1');
      expect(
        (decoded.topology['mesh_runtime_state_frame']
            as Map)['pending_custody_count'],
        1,
      );
    });

    test('default simulation telemetry carries mesh runtime state frame',
        () async {
      final kernel = _FakeMeshKernel();
      final result = await kernel.simulateMesh(
        const MeshSimulationRequest(
          simulationId: 'mesh-sim-telemetry-1',
          runContext: MonteCarloRunContext(
            canonicalReplayYear: 2026,
            replayYear: 2026,
            branchId: 'branch-bham',
            runId: 'run-mesh-telemetry-1',
            seed: 11,
            divergencePolicy: 'bounded',
          ),
          topology: <String, dynamic>{
            'mesh_runtime_state_frame': <String, dynamic>{
              'route_destination_count': 3,
              'pending_custody_count': 2,
              'encrypted_at_rest': true,
            },
          },
        ),
      );

      expect(result.simulationId, 'mesh-sim-telemetry-1');
      expect(
        (result.telemetry['mesh_runtime_state_frame']
            as Map)['pending_custody_count'],
        2,
      );
    });

    test('planning request carries governance bundle for runtime logic', () {
      final request = MeshRoutePlanningRequest(
        planningId: 'mesh-plan-1',
        destinationId: 'peer-b',
        envelope: KernelEventEnvelope(
          eventId: 'mesh-plan-event-1',
          occurredAtUtc: DateTime.utc(2026, 3, 11, 17),
          agentId: 'agent-a',
          eventType: 'mesh_plan_candidate',
        ),
        governanceBundle: _governanceBundle(),
      );

      final json = request.toJson();
      expect((json['governance_bundle'] as Map)['who'], isNotNull);
      expect((json['governance_bundle'] as Map)['why'], isNotNull);
    });
  });
}

class _FakeMeshKernel extends MeshKernelContract {
  @override
  Future<MeshTransportReceipt> commitTransport(MeshTransportCommit request) async {
    throw UnimplementedError();
  }

  @override
  Future<MeshTransportReceipt> observeTransport(
      MeshObservation observation) async {
    throw UnimplementedError();
  }

  @override
  Future<MeshTransportPlan> planTransport(
      MeshRoutePlanningRequest request) async {
    throw UnimplementedError();
  }

  @override
  MeshTransportSnapshot? snapshotTransport(String subjectId) {
    return MeshTransportSnapshot(
      subjectId: subjectId,
      destinationId: 'peer-b',
      lifecycleState: MeshTransportLifecycleState.custodyAccepted,
      savedAtUtc: DateTime.utc(2026, 3, 11, 12),
      queueDepth: 2,
    );
  }
}

KernelContextBundle _governanceBundle() {
  return KernelContextBundle(
    who: const WhoKernelSnapshot(
      primaryActor: 'agent-a',
      affectedActor: 'peer-b',
      companionActors: <String>[],
      actorRoles: <String>['peer'],
      trustScope: 'private',
      cohortRefs: <String>[],
      identityConfidence: 0.92,
    ),
    what: const WhatKernelSnapshot(
      actionType: 'deliver',
      targetEntityType: 'message',
      targetEntityId: 'message-1',
      stateTransitionType: 'queued_to_sent',
      outcomeType: 'pending',
      semanticTags: <String>['mesh', 'delivery'],
      taxonomyConfidence: 0.88,
    ),
    when: WhenKernelSnapshot(
      observedAt: DateTime.utc(2026, 3, 11, 12),
      freshness: 0.82,
      recencyBucket: 'hot',
      timingConflictFlags: const <String>['none'],
      temporalConfidence: 0.91,
    ),
    where: const WhereKernelSnapshot(
      localityToken: 'where:bham:1',
      cityCode: 'bham',
      localityCode: 'southside',
      projection: <String, dynamic>{'mode': 'local'},
      boundaryTension: 0.12,
      spatialConfidence: 0.86,
      travelFriction: 0.24,
      placeFitFlags: <String>['onsite'],
    ),
    how: const HowKernelSnapshot(
      executionPath: 'native_mesh',
      workflowStage: 'routing',
      transportMode: 'ble',
      plannerMode: 'governed',
      modelFamily: 'signal_reticulum',
      interventionChain: <String>['observe', 'route'],
      failureMechanism: 'none',
      mechanismConfidence: 0.89,
    ),
    why: WhyKernelSnapshot(
      goal: 'deliver_message',
      summary: 'Route chosen for resilient delivery.',
      rootCauseType: WhyRootCauseType.mechanism,
      confidence: 0.84,
      drivers: const <WhySignal>[
        WhySignal(label: 'delivery_probability', weight: 0.9),
      ],
      inhibitors: const <WhySignal>[],
      counterfactuals: const <WhyCounterfactual>[],
      createdAtUtc: DateTime.utc(2026, 3, 11, 12),
    ),
  );
}

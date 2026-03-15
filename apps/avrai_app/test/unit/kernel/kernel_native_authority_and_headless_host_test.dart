import 'package:avrai_core/models/why/why_models.dart' as core_why;
import 'package:avrai_runtime_os/kernel/how/how_native_bridge_bindings.dart';
import 'package:avrai_runtime_os/kernel/how/how_native_kernel_stub.dart';
import 'package:avrai_runtime_os/kernel/how/legacy/dart_how_fallback_kernel.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/os/headless_avrai_os_host.dart';
import 'package:avrai_runtime_os/kernel/os/kernel_prong_ports.dart';
import 'package:avrai_runtime_os/kernel/what/what_kernel_contract.dart';
import 'package:avrai_runtime_os/kernel/what/what_models.dart' as semantic_what;
import 'package:avrai_runtime_os/kernel/when/when_native_bridge_bindings.dart';
import 'package:avrai_runtime_os/kernel/when/when_native_kernel_stub.dart';
import 'package:avrai_runtime_os/kernel/when/legacy/dart_when_fallback_kernel.dart';
import 'package:avrai_runtime_os/kernel/who/legacy/dart_who_fallback_kernel.dart';
import 'package:avrai_runtime_os/kernel/who/who_native_bridge_bindings.dart';
import 'package:avrai_runtime_os/kernel/who/who_native_kernel_stub.dart';
import 'package:avrai_runtime_os/kernel/where/where_kernel_contract.dart';
import 'package:avrai_runtime_os/kernel/where/where_kernel_inputs.dart';
import 'package:avrai_runtime_os/kernel/where/where_kernel_outputs.dart';
import 'package:avrai_runtime_os/kernel/where/where_kernel_projection.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_state.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_token.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_training_contract.dart';
import 'package:avrai_runtime_os/kernel/why/legacy/dart_why_fallback_kernel.dart';
import 'package:avrai_runtime_os/kernel/why/why_native_bridge_bindings.dart';
import 'package:avrai_runtime_os/kernel/why/why_native_kernel_stub.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Native authority stubs', () {
    test('who stub uses native governance classification and diagnostics',
        () async {
      final stub = WhoNativeKernelStub(
        nativeBridge: _FakeWhoNativeBridge(),
        fallback: const DartWhoFallbackKernel(),
      );

      final binding = await stub.bindRuntime(
        const WhoRuntimeBindingRequest(
          runtimeId: 'runtime-1',
          actorId: 'agent-1',
        ),
      );
      final signature = await stub.sign(
        const WhoSigningRequest(
          actorId: 'agent-1',
          payload: <String, dynamic>{'scope': 'private'},
        ),
      );
      final verification = await stub.verify(
        WhoVerificationRequest(
          actorId: 'agent-1',
          payload: const <String, dynamic>{'scope': 'private'},
          signature: signature.signature,
        ),
      );
      final governance = await stub.projectForGovernance(
        const KernelProjectionRequest(subjectId: 'agent-1'),
      );
      final reality = await stub.projectForRealityModel(
        const KernelProjectionRequest(subjectId: 'agent-1'),
      );
      final health = await stub.diagnoseWho();

      expect(binding.continuityRef, contains('agent-1'));
      expect(verification.valid, isTrue);
      expect(governance.summary, contains('Governance identity'));
      expect(reality.summary, contains('agent-1'));
      expect(health.nativeBacked, isTrue);
      expect(health.status, KernelHealthStatus.healthy);
      expect(health.authorityLevel, KernelAuthorityLevel.authoritative);
    });

    test('when stub uses native timestamp, comparison, and event query',
        () async {
      final stub = WhenNativeKernelStub(
        nativeBridge: _FakeWhenNativeBridge(),
        fallback: const DartWhenFallbackKernel(),
      );

      final timestamp = await stub.issueTimestamp(
        WhenTimestampRequest(
          referenceId: 'event-1',
          occurredAtUtc: DateTime.utc(2026, 3, 7, 18),
        ),
      );
      final validation = await stub.validateWhen(
        WhenValidityWindow(
          timestamp: timestamp,
          effectiveAtUtc: DateTime.utc(2026, 3, 7, 18),
          expiresAtUtc: DateTime.utc(2026, 3, 7, 22),
          allowedDriftMs: 1000,
        ),
      );
      final comparison = await stub.compareWhen(
        timestamp,
        WhenTimestamp(
          referenceId: 'event-2',
          observedAtUtc: DateTime.utc(2026, 3, 7, 18, 5),
          quantumAtomicTick:
              DateTime.utc(2026, 3, 7, 18, 5).microsecondsSinceEpoch,
          confidence: 0.95,
        ),
      );
      final snapshot = await stub.snapshotWhen('runtime-1');
      final reconciliation = await stub.reconcileWhen(
        <WhenTimestamp>[
          timestamp,
          WhenTimestamp(
            referenceId: 'event-2',
            observedAtUtc: DateTime.utc(2026, 3, 7, 18, 5),
            quantumAtomicTick:
                DateTime.utc(2026, 3, 7, 18, 5).microsecondsSinceEpoch,
            confidence: 0.95,
          ),
        ],
      );
      final events = await stub.queryRuntimeEvents(
        const KernelReplayRequest(subjectId: 'runtime-1'),
      );
      final reality = await stub.projectForRealityModel(
        const KernelProjectionRequest(subjectId: 'runtime-1'),
      );
      final health = await stub.diagnoseWhen();

      expect(timestamp.quantumAtomicTick, greaterThan(0));
      expect(validation.valid, isTrue);
      expect(comparison.orderedAscending, isTrue);
      expect(snapshot, isNotNull);
      expect(reconciliation.conflictCount, 1);
      expect(events.single.runtimeId, 'runtime-1');
      expect(reality.summary, contains('Temporal ordering'));
      expect(health.authorityLevel, KernelAuthorityLevel.authoritative);
    });

    test('how stub uses native planning and diagnostics', () async {
      final stub = HowNativeKernelStub(
        nativeBridge: _FakeHowNativeBridge(),
        fallback: const DartHowFallbackKernel(),
      );

      final plan = await stub.planHow(
        const HowPlanningRequest(
          executionId: 'exec-1',
          goal: 'recommend_event',
        ),
      );
      final trace = await stub.executeHow(plan);
      final rollback = await stub.rollbackHow(
        const HowRollbackRequest(executionId: 'exec-1'),
      );
      final intervention = await stub.interveneHow(
        const HowInterventionDirective(
          executionId: 'exec-1',
          directive: 'pause',
        ),
      );
      final health = await stub.diagnoseHow();

      expect(plan.path, 'mesh_governed');
      expect(trace.status, 'executed');
      expect(rollback.rolledBack, isTrue);
      expect(intervention.accepted, isTrue);
      expect(health.nativeBacked, isTrue);
      expect(health.authorityLevel, KernelAuthorityLevel.authoritative);
    });

    test('why stub uses native conviction and anomaly paths', () async {
      final stub = WhyNativeKernelStub(
        nativeBridge: _FakeWhyNativeBridge(),
        fallback: const DartWhyFallbackKernel(),
      );
      const request = KernelWhyRequest(
        bundle: KernelContextBundleWithoutWhy(),
        goal: 'recommend_event',
        actualOutcome: 'generated',
        actualOutcomeScore: 1.0,
      );

      final conviction = stub.convictionWhy(request);
      final counterfactual = stub.counterfactualWhy(
        const WhyCounterfactualRequest(
          request: request,
          condition: 'Reduce temporal_mismatch',
        ),
      );
      final anomaly = stub.anomalyWhy(request);
      final reality = await stub.projectForRealityModel(
        const KernelProjectionRequest(subjectId: 'recommend_event'),
      );
      final health = await stub.diagnoseWhy();

      expect(conviction.summary, contains('temporal'));
      expect(counterfactual.expectedEffect, isNotEmpty);
      expect(anomaly.anomalous, isFalse);
      expect(reality.summary, contains('temporal'));
      expect(health.authorityLevel, KernelAuthorityLevel.authoritative);
    });
  });

  group('Headless AVRAI OS host', () {
    test('starts, reports health, and serves the three prongs', () async {
      final host = DefaultHeadlessAvraiOsHost(
        modelTruthPort: _FakeModelTruthPort(),
        runtimeExecutionPort: _FakeRuntimeExecutionPort(),
        trustGovernancePort: _FakeTrustGovernancePort(),
        whoKernel: const DartWhoFallbackKernel(),
        whatKernel: _FakeWhatKernel(),
        whenKernel: const DartWhenFallbackKernel(),
        whereKernel: _FakeWhereKernel(),
        howKernel: const DartHowFallbackKernel(),
        whyKernel: const DartWhyFallbackKernel(),
      );

      final state = await host.start();
      final runtime = await host.resolveRuntimeExecution(
        envelope: _envelope(),
      );
      final fusion = await host.buildModelTruth(
        envelope: _envelope(),
        whyRequest: _whyRequest(),
      );
      final governance = await host.inspectGovernance(
        envelope: _envelope(),
        whyRequest: _whyRequest(),
      );
      final health = await host.healthCheck();

      expect(state.started, isTrue);
      expect(state.localityContainedInWhere, isTrue);
      expect(runtime.who, isNotNull);
      expect(fusion.localityContainedInWhere, isTrue);
      expect(governance.projections.length, 6);
      expect(health.length, 6);
    });
  });
}

KernelEventEnvelope _envelope() => KernelEventEnvelope(
      eventId: 'event-headless-1',
      agentId: 'agent-1',
      userId: 'user-1',
      occurredAtUtc: DateTime.utc(2026, 3, 7, 19),
      sourceSystem: 'headless_test',
      eventType: 'recommendation_generated',
      actionType: 'recommend_event',
      entityId: 'event-1',
      entityType: 'event',
      context: const <String, dynamic>{
        'latitude': 41.8781,
        'longitude': -87.6298,
        'location_label': 'Loop',
      },
    );

KernelWhyRequest _whyRequest() => const KernelWhyRequest(
      bundle: KernelContextBundleWithoutWhy(),
      goal: 'recommend_event',
      actualOutcome: 'generated',
      actualOutcomeScore: 1.0,
      coreSignals: <WhySignal>[
        WhySignal(label: 'preference_match', weight: 0.7, source: 'core'),
      ],
    );

class _FakeWhoNativeBridge implements WhoNativeInvocationBridge {
  @override
  bool get isAvailable => true;

  @override
  void initialize() {}

  @override
  Map<String, dynamic> invoke({
    required String syscall,
    required Map<String, dynamic> payload,
  }) {
    switch (syscall) {
      case 'classify_relationship_scope':
        return <String, dynamic>{
          'handled': true,
          'payload': <String, dynamic>{
            'trust_scope': 'trusted_mesh',
            'companion_count': 2,
          },
        };
      case 'bind_runtime':
        return <String, dynamic>{
          'handled': true,
          'payload': <String, dynamic>{
            'runtime_id': payload['runtime_id'],
            'actor_id': payload['actor_id'],
            'bound_at_utc': DateTime.utc(2026, 3, 7, 18).toIso8601String(),
            'continuity_ref':
                'who:${payload['actor_id']}:${payload['runtime_id']}',
          },
        };
      case 'sign_who':
        return <String, dynamic>{
          'handled': true,
          'payload': <String, dynamic>{
            'actor_id': payload['actor_id'],
            'algorithm': payload['algorithm'],
            'signature': 'sig:${payload['actor_id']}',
            'issued_at_utc': DateTime.utc(2026, 3, 7, 18).toIso8601String(),
          },
        };
      case 'verify_who':
        return <String, dynamic>{
          'handled': true,
          'payload': <String, dynamic>{
            'valid': true,
            'reason': 'signature_match',
          },
        };
      case 'project_who_reality':
        return <String, dynamic>{
          'handled': true,
          'payload': <String, dynamic>{
            'summary': 'Actor agent-1 in trusted_mesh scope',
            'confidence': 0.91,
            'features': <String, dynamic>{'primary_actor': 'agent-1'},
            'payload': <String, dynamic>{'primary_actor': 'agent-1'},
          },
        };
      case 'project_who_governance':
        return <String, dynamic>{
          'handled': true,
          'payload': <String, dynamic>{
            'domain': 'who',
            'summary': 'Governance identity view for agent-1',
            'confidence': 0.91,
            'highlights': const <String>['trusted_mesh', 'requester'],
            'payload': <String, dynamic>{'primary_actor': 'agent-1'},
          },
        };
      case 'diagnose_who_kernel':
        return <String, dynamic>{
          'handled': true,
          'payload': <String, dynamic>{'status': 'ok', 'kernel': 'who'},
        };
      default:
        return <String, dynamic>{'handled': false};
    }
  }
}

class _FakeWhenNativeBridge implements WhenNativeInvocationBridge {
  @override
  bool get isAvailable => true;

  @override
  void initialize() {}

  @override
  Map<String, dynamic> invoke({
    required String syscall,
    required Map<String, dynamic> payload,
  }) {
    switch (syscall) {
      case 'now':
        return <String, dynamic>{
          'handled': true,
          'payload': <String, dynamic>{
            'instant': <String, dynamic>{
              'referenceTime': DateTime.utc(2026, 3, 7, 18).toIso8601String(),
            },
          },
        };
      case 'compare_when':
        return <String, dynamic>{
          'handled': true,
          'payload': <String, dynamic>{
            'ordered_ascending': true,
            'delta_ms': 300000,
          },
        };
      case 'validate_window':
        return <String, dynamic>{
          'handled': true,
          'payload': <String, dynamic>{
            'valid': true,
            'reason': 'within_validity_window',
            'observed_drift_ms': 0,
          },
        };
      case 'snapshot_when':
        return <String, dynamic>{
          'handled': true,
          'payload': <String, dynamic>{
            'observed_at': DateTime.utc(2026, 3, 7, 18).toIso8601String(),
            'effective_at': DateTime.utc(2026, 3, 7, 18).toIso8601String(),
            'expires_at': DateTime.utc(2026, 3, 7, 22).toIso8601String(),
            'freshness': 1.0,
            'recency_bucket': 'immediate',
            'timing_conflict_flags': const <String>[],
            'temporal_confidence': 0.95,
          },
        };
      case 'reconcile_timestamps':
        return <String, dynamic>{
          'handled': true,
          'payload': <String, dynamic>{
            'canonical_timestamp': <String, dynamic>{
              'reference_id': 'event-2',
              'observed_at_utc':
                  DateTime.utc(2026, 3, 7, 18, 5).toIso8601String(),
              'quantum_atomic_tick':
                  DateTime.utc(2026, 3, 7, 18, 5).microsecondsSinceEpoch,
              'confidence': 0.95,
            },
            'conflict_count': 1,
            'summary': 'selected latest timestamp as canonical reference',
          },
        };
      case 'query_when_events':
        return <String, dynamic>{
          'handled': true,
          'payload': <String, dynamic>{
            'events': <Map<String, dynamic>>[
              <String, dynamic>{
                'event_id': 'event-1',
                'runtime_id': 'runtime-1',
                'occurred_at_utc':
                    DateTime.utc(2026, 3, 7, 18).toIso8601String(),
                'stratum': 'personal',
                'payload': <String, dynamic>{'kind': 'runtime_event'},
              },
            ],
          },
        };
      case 'project_when_reality':
        return <String, dynamic>{
          'handled': true,
          'payload': <String, dynamic>{
            'summary': 'Temporal ordering at 2026-03-07T18:00:00.000Z',
            'confidence': 0.95,
            'features': <String, dynamic>{'recency_bucket': 'immediate'},
            'payload': <String, dynamic>{'observed_at': '2026-03-07T18:00:00.000Z'},
          },
        };
      case 'snapshot':
        return <String, dynamic>{
          'handled': true,
          'payload': <String, dynamic>{
            'instant': <String, dynamic>{
              'referenceTime': DateTime.utc(2026, 3, 7, 18).toIso8601String(),
            },
            'status': 'ok',
            'kernel': 'when',
          },
        };
      default:
        return <String, dynamic>{'handled': false};
    }
  }
}

class _FakeHowNativeBridge implements HowNativeInvocationBridge {
  @override
  bool get isAvailable => true;

  @override
  void initialize() {}

  @override
  Map<String, dynamic> invoke({
    required String syscall,
    required Map<String, dynamic> payload,
  }) {
    switch (syscall) {
      case 'classify_execution_path':
        return <String, dynamic>{
          'handled': true,
          'payload': <String, dynamic>{
            'execution_path': 'mesh_governed',
            'workflow_stage': 'planned_execution',
          },
        };
      case 'execute_how':
        return <String, dynamic>{
          'handled': true,
          'payload': <String, dynamic>{
            'execution_id': payload['execution_id'],
            'path': payload['path'] ?? 'mesh_governed',
            'completed_at_utc': DateTime.utc(2026, 3, 7, 19).toIso8601String(),
            'status': 'executed',
            'capability_chain':
                payload['capability_chain'] ?? const <String>['rank', 'respond'],
          },
        };
      case 'rollback_how':
        return <String, dynamic>{
          'handled': true,
          'payload': <String, dynamic>{
            'execution_id': payload['execution_id'],
            'rolled_back': true,
            'recorded_at_utc': DateTime.utc(2026, 3, 7, 19).toIso8601String(),
          },
        };
      case 'intervene_how':
        return <String, dynamic>{
          'handled': true,
          'payload': <String, dynamic>{
            'execution_id': payload['execution_id'],
            'directive': payload['directive'],
            'accepted': true,
            'recorded_at_utc': DateTime.utc(2026, 3, 7, 19).toIso8601String(),
          },
        };
      case 'diagnose_how_kernel':
        return <String, dynamic>{
          'handled': true,
          'payload': <String, dynamic>{'status': 'ok', 'kernel': 'how'},
        };
      default:
        return <String, dynamic>{'handled': false};
    }
  }
}

class _FakeWhyNativeBridge implements WhyNativeInvocationBridge {
  @override
  bool get isAvailable => true;

  @override
  void initialize() {}

  @override
  Map<String, dynamic> invoke({
    required String syscall,
    required Map<String, dynamic> payload,
  }) {
    switch (syscall) {
      case 'explain_why':
        return <String, dynamic>{
          'handled': true,
          'payload': <String, dynamic>{
            'goal': 'recommend_event',
            'summary': 'temporal alignment drove the recommendation',
            'root_cause_type': 'temporal',
            'confidence': 0.86,
            'drivers': const <dynamic>[],
            'inhibitors': const <dynamic>[],
            'counterfactuals': const <dynamic>[],
            'created_at_utc': DateTime.utc(2026, 3, 7, 19).toIso8601String(),
          },
        };
      case 'classify_root_cause':
        return <String, dynamic>{
          'handled': true,
          'payload': <String, dynamic>{'root_cause_type': 'temporal'},
        };
      case 'conviction_why':
        return <String, dynamic>{
          'handled': true,
          'payload': <String, dynamic>{
            'goal': 'recommend_event',
            'conviction_tier': 'high',
            'confidence': 0.86,
            'summary': 'temporal alignment drove the recommendation',
          },
        };
      case 'counterfactual_why':
        return <String, dynamic>{
          'handled': true,
          'payload': <String, dynamic>{
            'condition': payload['condition'],
            'expected_effect': 'Outcome is more likely to improve',
            'confidence_delta': 0.2,
          },
        };
      case 'anomaly_why':
        return <String, dynamic>{
          'handled': true,
          'payload': <String, dynamic>{
            'anomalous': false,
            'summary': 'why kernel did not detect abnormal reasoning',
            'severity': 'none',
          },
        };
      case 'project_why_reality':
        return <String, dynamic>{
          'handled': true,
          'payload': <String, dynamic>{
            'summary': 'temporal alignment drove the recommendation',
            'confidence': 0.86,
            'features': <String, dynamic>{'goal': 'recommend_event'},
            'payload': <String, dynamic>{'root_cause_type': 'temporal'},
          },
        };
      case 'diagnose_why_kernel':
        return <String, dynamic>{
          'handled': true,
          'payload': <String, dynamic>{'status': 'ok', 'kernel': 'why'},
        };
      default:
        return <String, dynamic>{'handled': false};
    }
  }
}

class _FakeModelTruthPort implements ModelTruthPort {
  @override
  Future<RealityKernelFusionInput> buildRealityKernelFusionInput({
    required KernelEventEnvelope envelope,
    required KernelWhyRequest whyRequest,
  }) async {
    return RealityKernelFusionInput(
      envelope: envelope,
      bundle: const KernelContextBundle(
        who: null,
        what: null,
        when: null,
        where: null,
        how: null,
        why: null,
      ),
      who: const WhoRealityProjection(summary: 'who', confidence: 0.9),
      what: const WhatRealityProjection(summary: 'what', confidence: 0.9),
      when: const WhenRealityProjection(summary: 'when', confidence: 0.9),
      where: const WhereRealityProjection(
        summary: 'where',
        confidence: 0.9,
        features: <String, dynamic>{'locality_contained_in_where': true},
      ),
      why: const WhyRealityProjection(summary: 'why', confidence: 0.9),
      how: const HowRealityProjection(summary: 'how', confidence: 0.9),
      generatedAtUtc: DateTime.utc(2026, 3, 7, 19),
    );
  }
}

class _FakeRuntimeExecutionPort implements RuntimeExecutionPort {
  @override
  Future<KernelContextBundle> resolveRuntimeExecution({
    required KernelEventEnvelope envelope,
  }) async {
    return const KernelContextBundle(
      who: WhoKernelSnapshot(
        primaryActor: 'agent-1',
        affectedActor: 'user-1',
        companionActors: <String>[],
        actorRoles: <String>['requester'],
        trustScope: 'private',
        cohortRefs: <String>[],
        identityConfidence: 0.9,
      ),
      what: null,
      when: null,
      where: null,
      how: null,
      why: null,
    );
  }
}

class _FakeTrustGovernancePort implements TrustGovernancePort {
  @override
  Future<KernelGovernanceReport> inspectTrustGovernance({
    required KernelEventEnvelope envelope,
    required KernelWhyRequest whyRequest,
  }) async {
    return KernelGovernanceReport(
      envelope: envelope,
      bundle: const KernelContextBundle(
        who: null,
        what: null,
        when: null,
        where: null,
        how: null,
        why: null,
      ),
      projections: const <KernelGovernanceProjection>[
        KernelGovernanceProjection(
          domain: KernelDomain.who,
          summary: 'who',
          confidence: 0.9,
        ),
        KernelGovernanceProjection(
          domain: KernelDomain.what,
          summary: 'what',
          confidence: 0.9,
        ),
        KernelGovernanceProjection(
          domain: KernelDomain.when,
          summary: 'when',
          confidence: 0.9,
        ),
        KernelGovernanceProjection(
          domain: KernelDomain.where,
          summary: 'where',
          confidence: 0.9,
        ),
        KernelGovernanceProjection(
          domain: KernelDomain.how,
          summary: 'how',
          confidence: 0.9,
        ),
        KernelGovernanceProjection(
          domain: KernelDomain.why,
          summary: 'why',
          confidence: 0.9,
        ),
      ],
      generatedAtUtc: DateTime.utc(2026, 3, 7, 19),
    );
  }
}

class _FakeWhatKernel extends WhatKernelContract {
  const _FakeWhatKernel();

  @override
  Future<semantic_what.WhatState> resolveWhat(
    semantic_what.WhatPerceptionInput input,
  ) async {
    return semantic_what.WhatState(
      entityRef: input.entityRef,
      canonicalType: 'event',
      placeType: 'event',
      activityTypes: const <String>['recommend_event'],
      socialContexts: const <String>['generated'],
      userRelation: semantic_what.WhatUserRelation.neutral,
      lifecycleState: semantic_what.WhatLifecycleState.established,
      confidence: 0.88,
      firstObservedAtUtc: input.observedAtUtc,
      lastObservedAtUtc: input.observedAtUtc,
    );
  }

  @override
  Future<semantic_what.WhatUpdateReceipt> observeWhat(
    semantic_what.WhatObservation observation,
  ) async {
    final state = await resolveWhat(
      semantic_what.WhatPerceptionInput(
        agentId: observation.agentId,
        observedAtUtc: observation.observedAtUtc,
        source: observation.source,
        entityRef: observation.entityRef,
      ),
    );
    return semantic_what.WhatUpdateReceipt(state: state);
  }

  @override
  semantic_what.WhatProjection projectWhat(
    semantic_what.WhatProjectionRequest request,
  ) {
    return semantic_what.WhatProjection(
      baseEntityRef: request.entityRef,
      projectedTypes: const <String>['event'],
      confidence: 0.8,
      basis: 'headless_host_test',
    );
  }

  @override
  semantic_what.WhatKernelSnapshot? snapshotWhat(String agentId) {
    return semantic_what.WhatKernelSnapshot(
      agentId: agentId,
      savedAtUtc: DateTime.utc(2026, 3, 7, 19),
    );
  }

  @override
  Future<semantic_what.WhatSyncResult> syncWhat(
    semantic_what.WhatSyncRequest request,
  ) async {
    return semantic_what.WhatSyncResult(
      acceptedCount: request.deltas.length,
      rejectedCount: 0,
      mergedEntityRefs: request.deltas.map((entry) => entry.entityRef).toList(),
      savedAtUtc: request.observedAtUtc,
    );
  }

  @override
  Future<semantic_what.WhatRecoveryResult> recoverWhat(
    semantic_what.WhatRecoveryRequest request,
  ) async {
    return semantic_what.WhatRecoveryResult(
      restoredCount: 1,
      droppedCount: 0,
      schemaVersion: 1,
      savedAtUtc: DateTime.utc(2026, 3, 7, 19),
    );
  }
}

class _FakeWhereKernel extends WhereKernelContract {
  final WhereState _state = WhereState(
    activeTokenId: 'gh7:dp3wjzt',
    activeTokenAlias: 'Loop',
    activeTokenKind: LocalityTokenKind.geohashCell.name,
    embedding: const <double>[
      0.1,
      0.2,
      0.3,
      0.4,
      0.5,
      0.6,
      0.7,
      0.2,
      0.3,
      0.4,
      0.5,
      0.6,
    ],
    confidence: 0.84,
    boundaryTension: 0.18,
    reliabilityTier: LocalityReliabilityTier.established.name,
    freshness: DateTime.utc(2026, 3, 7, 19),
    evidenceCount: 9,
    evolutionRate: 0.03,
    advisoryStatus: LocalityAdvisoryStatus.inactive.name,
    sourceMix: const <String, double>{
      'local': 0.6,
      'mesh': 0.1,
      'federated': 0.2,
      'geometry': 0.1,
      'synthetic_prior': 0.0,
    },
    topAlias: 'Loop',
    parentTokenId: 'chicago_il',
  );

  @override
  Future<WhereState> resolveWhere(WhereKernelInput input) async => _state;

  @override
  Future<WhereState> seedHomebase({
    required String userId,
    required String agentId,
    required double latitude,
    required double longitude,
    String? cityCode,
    String source = 'headless_host_test',
  }) async =>
      _state;

  @override
  Future<WhereObservationReceipt?> observeVisit({
    required String userId,
    required WhereVisit visit,
    required String source,
  }) async {
    return WhereObservationReceipt(
      state: _state,
      cloudUpdated: false,
      meshForwarded: false,
    );
  }

  @override
  Future<WhereObservationReceipt> observe(WhereObservation observation) async {
    return WhereObservationReceipt(
      state: _state,
      cloudUpdated: false,
      meshForwarded: false,
    );
  }

  @override
  Future<WhereSyncResult> sync(WhereSyncRequest request) async {
    return const WhereSyncResult(synced: true, message: 'ok');
  }

  @override
  WhereProjection project(WhereProjectionRequest request) {
    return WhereProjection(
      primaryLabel: request.state.topAlias ?? 'Loop',
      confidenceBucket: 'high',
      nearBoundary: false,
      activeTokenId: request.state.activeTokenId,
      activeTokenKind: request.state.activeTokenKind,
      activeTokenAlias: request.state.activeTokenAlias,
      metadata: const <String, dynamic>{'locality_contained_in_where': true},
    );
  }

  @override
  Future<WherePointResolution> resolvePoint(WherePointQuery request) async {
    return WherePointResolution(
      state: _state,
      projection: project(
        WhereProjectionRequest(audience: request.audience, state: _state),
      ),
      localityCode: 'loop_chicago',
      cityCode: 'chicago_il',
      displayName: 'Loop',
    );
  }

  @override
  Future<bool> observeMeshUpdate({
    required WhereMeshKey key,
    required List<double> delta12,
    required int ttlMs,
    required int hop,
  }) async {
    return true;
  }

  @override
  Future<WhereZeroReliabilityReport> evaluateZeroWhereReadiness({
    required String cityProfile,
    String modelFamily = 'reality_kernel',
    int localityCount = 12,
  }) async {
    return const LocalityZeroReliabilityReport(
      evaluationId: 'eval-1',
      metrics: <LocalityEvaluationMetric>[],
      calibration: <String, dynamic>{},
    );
  }

  @override
  WhereSnapshot? snapshot(String agentId) {
    return WhereSnapshot(
      agentId: agentId,
      state: _state,
      savedAtUtc: DateTime.utc(2026, 3, 7, 19),
    );
  }

  @override
  Future<WhereRecoveryResult> recover(WhereRecoveryRequest request) async {
    return WhereRecoveryResult(
      state: _state,
      recoveredFromSnapshot: true,
    );
  }

  @override
  WhereWhySnapshot explainWhy(WhereWhyRequest request) {
    return const core_why.WhySnapshot(
      goal: 'explain_where',
      drivers: <core_why.WhySignal>[],
      inhibitors: <core_why.WhySignal>[],
      confidence: 0.84,
      rootCauseType: core_why.WhyRootCauseType.locality,
      summary: 'stable locality',
      counterfactuals: <core_why.WhyCounterfactual>[],
    );
  }
}

import 'package:avrai_core/models/spots/spot.dart';
import 'package:avrai_core/models/discovery/discovery_models.dart';
import 'package:avrai_runtime_os/ai/perpetual_list/models/suggested_list.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_native_kernel_stub.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_state.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_token.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_os.dart';
import 'package:avrai_runtime_os/kernel/os/kernel_outcome_attribution_lane.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DefaultKernelOutcomeAttributionLane', () {
    test('records list interaction through functional kernel OS', () async {
      final os = _FakeFunctionalKernelOs();
      final lane = DefaultKernelOutcomeAttributionLane(
        functionalKernelOs: os,
      );

      final record = await lane.recordListInteraction(
        userId: 'user-1',
        userAge: 27,
        interaction: ListInteraction(
          type: ListInteractionType.dismissed,
          listId: 'list-1',
          timestamp: DateTime.utc(2026, 3, 7, 18),
          metadata: const <String, dynamic>{
            ListInteraction.negativePreferenceIntentMetadataKey:
                ListInteraction.hardNotInterestedIntentValue,
            'theme': 'late_night_food',
          },
        ),
        suggestedList: SuggestedList(
          id: 'list-1',
          title: 'Late Night Food',
          description: 'Comfort options after dark',
          places: <Spot>[_spot(id: 'spot-1', name: 'Noodle House')],
          theme: 'late_night_food',
          generatedAt: DateTime.utc(2026, 3, 7, 17),
          avgCompatibilityScore: 0.74,
        ),
      );

      expect(record.eventId, equals('list:list-1:dismissed:1772906400000000'));
      expect(os.lastEnvelope?.eventType, equals('list_interaction'));
      expect(os.lastEnvelope?.actionType, equals('dismiss_list'));
      expect(
        os.lastWhyRequest?.pheromoneSignals.first.label,
        equals(ListInteraction.hardNotInterestedIntentValue),
      );
      expect(record.bundle.why?.rootCauseType, WhyRootCauseType.mixed);
    });
  });

  group('LocalityNativeKernelStub', () {
    test('records locality recovery incidents through attribution lane',
        () async {
      final lane = _CapturingLane();
      final stub = LocalityNativeKernelStub(
        transport: _FakeLocalityTransport(),
        kernelOutcomeAttributionLane: lane,
      );

      final result = await stub.recover(
        const LocalityRecoveryRequest(agentId: 'agent-9'),
      );

      expect(result.recoveredFromSnapshot, isTrue);
      expect(lane.recordedAgentId, equals('agent-9'));
      expect(lane.recordedResult?.state.activeToken.id, equals('gh7:dr5ru7k'));
    });
  });
}

class _FakeFunctionalKernelOs implements FunctionalKernelOs {
  KernelEventEnvelope? lastEnvelope;
  KernelWhyRequest? lastWhyRequest;

  @override
  WhyKernelSnapshot explainWhy(KernelWhyRequest request) {
    return WhyKernelSnapshot(
      goal: request.goal ?? 'explain',
      summary: 'synthetic why snapshot',
      rootCauseType: WhyRootCauseType.mixed,
      confidence: 0.81,
      drivers: request.coreSignals,
      inhibitors: request.pheromoneSignals
          .map(
            (signal) => WhySignal(
              label: signal.label,
              weight: signal.weight.abs(),
              source: signal.source,
              durable: signal.durable,
            ),
          )
          .toList(),
      counterfactuals: const <WhyCounterfactual>[],
      createdAtUtc: DateTime.utc(2026, 3, 7, 18),
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
      recordId: 'record:${envelope.eventId}',
      eventId: envelope.eventId,
      createdAtUtc: DateTime.utc(2026, 3, 7, 18),
      bundle: KernelContextBundle(
        who: const WhoKernelSnapshot(
          primaryActor: 'user-1',
          affectedActor: 'user-1',
          companionActors: <String>[],
          actorRoles: <String>['user'],
          trustScope: 'private',
          cohortRefs: <String>[],
          identityConfidence: 0.9,
        ),
        what: const WhatKernelSnapshot(
          actionType: 'dismiss_list',
          targetEntityType: 'suggested_list',
          targetEntityId: 'list-1',
          stateTransitionType: 'interaction',
          outcomeType: 'dismissed',
          semanticTags: <String>['list'],
          taxonomyConfidence: 0.86,
        ),
        when: WhenKernelSnapshot(
          observedAt: envelope.occurredAtUtc,
          freshness: 1.0,
          recencyBucket: 'immediate',
          timingConflictFlags: const <String>[],
          temporalConfidence: 0.92,
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
          executionPath: 'test_lane',
          workflowStage: 'attribution',
          transportMode: 'in_process',
          plannerMode: 'test',
          modelFamily: 'test',
          interventionChain: <String>['resolveAndExplain'],
          failureMechanism: 'none',
          mechanismConfidence: 0.88,
        ),
        why: explainWhy(whyRequest),
      ),
    );
  }

  @override
  Future<KernelContextBundle> resolveKernelContext(
    KernelEventEnvelope envelope,
  ) async {
    throw UnimplementedError();
  }

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
        summary: 'user identity',
        confidence: record.bundle.who?.identityConfidence ?? 0.0,
      ),
      what: WhatRealityProjection(
        summary: 'list interaction',
        confidence: record.bundle.what?.taxonomyConfidence ?? 0.0,
      ),
      when: WhenRealityProjection(
        summary: 'interaction ordering',
        confidence: record.bundle.when?.temporalConfidence ?? 0.0,
      ),
      where: WhereRealityProjection(
        summary: 'bootstrap locality',
        confidence: record.bundle.where?.spatialConfidence ?? 0.0,
      ),
      why: WhyRealityProjection(
        summary: record.bundle.why?.summary ?? 'synthetic why snapshot',
        confidence: record.bundle.why?.confidence ?? 0.0,
      ),
      how: HowRealityProjection(
        summary: record.bundle.how?.executionPath ?? 'test_lane',
        confidence: record.bundle.how?.mechanismConfidence ?? 0.0,
      ),
      generatedAtUtc: record.createdAtUtc,
    );
  }

  @override
  Future<HowKernelSnapshot> resolveHow(KernelEventEnvelope envelope) async {
    throw UnimplementedError();
  }

  @override
  Future<WhatKernelSnapshot> resolveWhat(KernelEventEnvelope envelope) async {
    throw UnimplementedError();
  }

  @override
  Future<WhenKernelSnapshot> resolveWhen(KernelEventEnvelope envelope) async {
    throw UnimplementedError();
  }

  @override
  Future<WhereKernelSnapshot> resolveWhere(KernelEventEnvelope envelope) async {
    throw UnimplementedError();
  }

  @override
  Future<WhoKernelSnapshot> resolveWho(KernelEventEnvelope envelope) async {
    throw UnimplementedError();
  }
}

class _CapturingLane implements KernelOutcomeAttributionLane {
  String? recordedAgentId;
  LocalityRecoveryResult? recordedResult;

  @override
  Future<KernelBundleRecord> recordDiscoveryInteraction({
    required String userId,
    required DiscoveryEntityReference entity,
    required RecommendationFeedbackAction action,
    RecommendationAttribution? attribution,
    required String sourceSurface,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) {
    throw UnimplementedError();
  }

  @override
  Future<KernelBundleRecord> recordListInteraction({
    required String userId,
    int? userAge,
    required ListInteraction interaction,
    SuggestedList? suggestedList,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<KernelBundleRecord> recordLocalityRecovery({
    required String agentId,
    required LocalityRecoveryRequest request,
    required LocalityRecoveryResult result,
  }) async {
    recordedAgentId = agentId;
    recordedResult = result;
    return KernelBundleRecord(
      recordId: 'incident:$agentId',
      eventId: 'incident:$agentId',
      createdAtUtc: DateTime.utc(2026, 3, 7, 18),
      bundle: KernelContextBundle(
        who: const WhoKernelSnapshot(
          primaryActor: 'agent-9',
          affectedActor: 'agent-9',
          companionActors: <String>[],
          actorRoles: <String>['system'],
          trustScope: 'system',
          cohortRefs: <String>[],
          identityConfidence: 1.0,
        ),
        what: const WhatKernelSnapshot(
          actionType: 'recover_locality',
          targetEntityType: 'locality_runtime',
          targetEntityId: 'agent-9',
          stateTransitionType: 'recovery',
          outcomeType: 'recovered',
          semanticTags: <String>['incident'],
          taxonomyConfidence: 1.0,
        ),
        when: WhenKernelSnapshot(
          observedAt: DateTime.utc(2026, 3, 7, 18),
          freshness: 1.0,
          recencyBucket: 'immediate',
          timingConflictFlags: const <String>[],
          temporalConfidence: 1.0,
        ),
        where: const WhereKernelSnapshot(
          localityToken: 'gh7:dr5ru7k',
          cityCode: 'unknown_city',
          localityCode: 'avondale',
          projection: <String, dynamic>{},
          boundaryTension: 0.28,
          spatialConfidence: 0.82,
          travelFriction: 0.0,
          placeFitFlags: <String>[],
        ),
        how: const HowKernelSnapshot(
          executionPath: 'locality_recover',
          workflowStage: 'incident_recovery',
          transportMode: 'in_process',
          plannerMode: 'fallback',
          modelFamily: 'locality_kernel',
          interventionChain: <String>['recover'],
          failureMechanism: 'none',
          mechanismConfidence: 1.0,
        ),
      ),
    );
  }
}

class _FakeLocalityTransport implements LocalitySyscallTransport {
  @override
  Future<Map<String, dynamic>> invokeAsync({
    required String syscall,
    required Map<String, dynamic> payload,
  }) async {
    expect(syscall, equals('recover_locality'));
    return <String, dynamic>{
      'state': _localityState().toJson(),
      'recoveredFromSnapshot': true,
    };
  }

  @override
  Map<String, dynamic> invokeSync({
    required String syscall,
    required Map<String, dynamic> payload,
  }) {
    throw UnimplementedError();
  }
}

LocalityState _localityState() {
  return LocalityState(
    activeToken: const LocalityToken(
      kind: LocalityTokenKind.geohashCell,
      id: 'gh7:dr5ru7k',
      alias: 'Avondale',
    ),
    embedding: const <double>[
      0.2,
      0.3,
      0.4,
      0.5,
      0.6,
      0.7,
      0.4,
      0.3,
      0.5,
      0.6,
      0.4,
      0.5,
    ],
    confidence: 0.82,
    boundaryTension: 0.28,
    reliabilityTier: LocalityReliabilityTier.established,
    freshness: DateTime.utc(2026, 3, 7),
    evidenceCount: 10,
    evolutionRate: 0.04,
    advisoryStatus: LocalityAdvisoryStatus.inactive,
    sourceMix: const LocalitySourceMix(
      local: 0.5,
      mesh: 0.1,
      federated: 0.3,
      geometry: 0.1,
      syntheticPrior: 0.0,
    ),
    topAlias: 'Avondale',
  );
}

Spot _spot({
  required String id,
  required String name,
}) {
  return Spot(
    id: id,
    name: name,
    description: 'test',
    category: 'restaurant',
    latitude: 33.52,
    longitude: -86.77,
    rating: 4.5,
    createdBy: 'tester',
    address: '123 Test St',
    createdAt: DateTime.utc(2026, 3, 7),
    updatedAt: DateTime.utc(2026, 3, 7),
  );
}

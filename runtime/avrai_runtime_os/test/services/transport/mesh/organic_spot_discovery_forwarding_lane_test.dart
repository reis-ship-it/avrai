// ignore_for_file: deprecated_member_use

import 'dart:typed_data';

import 'package:avrai_network/avra_network.dart';
import 'package:avrai_runtime_os/kernel/os/ai2ai_mesh_governance_binding_service.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_os.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_custody_outbox.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_forwarding_context.dart';
import 'package:avrai_runtime_os/services/transport/mesh/governed_mesh_packet_codec.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_route_ledger.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_runtime_state_store.dart';
import 'package:avrai_runtime_os/services/transport/mesh/organic_spot_discovery_forwarding_lane.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OrganicSpotDiscoveryForwardingLane', () {
    test('defers delivery to custody outbox when no candidates exist',
        () async {
      final fakeKernelOs = _FakeFunctionalKernelOs();
      final context = MeshForwardingContext(
        packetCodec: GovernedMeshPacketCodec(
          encryptionService: _PassthroughEncryptionService(),
        ),
        discovery: _FakeDiscoveryService(const <String, DiscoveredDevice>{}),
        governanceBindingService:
            Ai2AiMeshGovernanceBindingService(kernelOs: fakeKernelOs),
        routeLedger: MeshRouteLedger(store: InMemoryMeshRuntimeStateStore()),
        custodyOutbox: MeshCustodyOutbox(
          store: InMemoryMeshRuntimeStateStore(),
          nowUtc: () => DateTime.utc(2026, 3, 12, 21),
        ),
        localUserId: 'user-a',
        localAgentId: 'agent-a',
      );

      await OrganicSpotDiscoveryForwardingLane.forward(
        signal: const <String, dynamic>{
          'geohash': '9q4xy',
          'geographic_scope': 'locality',
        },
        discoveredNodeIds: const <String>[],
        context: context,
        localNodeId: 'node-local',
        peerNodeIdByDeviceId: const <String, String>{},
        logger: const AppLogger(defaultTag: 'test'),
        logName: 'OrganicSpotDiscoveryForwardingLaneTest',
      );

      expect(
        context.custodyOutbox?.pendingCount(
          destinationId: '9q4xy',
          payloadKind: 'organic_spot_discovery',
        ),
        1,
      );
      expect(fakeKernelOs.lastEnvelope?.routeReceipt?.status, 'queued');
      expect(
        fakeKernelOs.lastWhyRequest?.actualOutcome,
        'mesh_deferred_to_custody',
      );
    });
  });
}

class _FakeDiscoveryService extends DeviceDiscoveryService {
  _FakeDiscoveryService(this._devices);

  final Map<String, DiscoveredDevice> _devices;

  @override
  DiscoveredDevice? getDevice(String deviceId) => _devices[deviceId];
}

class _PassthroughEncryptionService implements MessageEncryptionService {
  @override
  EncryptionType get encryptionType => EncryptionType.aes256gcm;

  @override
  Future<String> decrypt(EncryptedMessage encrypted, String senderId) async {
    return String.fromCharCodes(encrypted.encryptedContent);
  }

  @override
  Future<EncryptedMessage> encrypt(String plaintext, String recipientId) async {
    return EncryptedMessage(
      encryptedContent: Uint8List.fromList(plaintext.codeUnits),
      encryptionType: EncryptionType.aes256gcm,
    );
  }
}

class _FakeFunctionalKernelOs implements FunctionalKernelOs {
  int _recordCounter = 0;
  KernelEventEnvelope? lastEnvelope;
  KernelWhyRequest? lastWhyRequest;

  @override
  Future<RealityKernelFusionInput> buildRealityKernelFusionInput({
    required KernelEventEnvelope envelope,
    required KernelWhyRequest whyRequest,
  }) {
    throw UnimplementedError();
  }

  @override
  WhyKernelSnapshot explainWhy(KernelWhyRequest request) {
    throw UnimplementedError();
  }

  @override
  Future<KernelBundleRecord> resolveAndExplain({
    required KernelEventEnvelope envelope,
    required KernelWhyRequest whyRequest,
  }) async {
    lastEnvelope = envelope;
    lastWhyRequest = whyRequest;
    _recordCounter += 1;
    return KernelBundleRecord(
      recordId: 'record-$_recordCounter',
      eventId: envelope.eventId,
      bundle: KernelContextBundle(
        who: WhoKernelSnapshot(
          primaryActor: envelope.agentId ?? 'unknown_agent',
          affectedActor: envelope.entityId ?? 'unknown_entity',
          companionActors: const <String>[],
          actorRoles: const <String>['mesh_peer'],
          trustScope: 'private',
          cohortRefs: const <String>[],
          identityConfidence: 0.9,
        ),
        what: WhatKernelSnapshot(
          actionType: envelope.actionType ?? 'forward',
          targetEntityType: envelope.entityType ?? 'mesh_payload',
          targetEntityId: envelope.entityId ?? 'unknown_entity',
          stateTransitionType: 'mesh_forward',
          outcomeType: whyRequest.actualOutcome ??
              whyRequest.predictedOutcome ??
              'pending',
          semanticTags: const <String>['mesh', 'governance'],
          taxonomyConfidence: 0.87,
        ),
        when: WhenKernelSnapshot(
          observedAt: envelope.occurredAtUtc,
          freshness: 0.85,
          recencyBucket: 'hot',
          timingConflictFlags: const <String>[],
          temporalConfidence: 0.9,
        ),
        where: const WhereKernelSnapshot(
          localityToken: 'where:test',
          cityCode: 'test',
          localityCode: 'mesh',
          projection: <String, dynamic>{'mode': 'local'},
          boundaryTension: 0.08,
          spatialConfidence: 0.84,
          travelFriction: 0.18,
          placeFitFlags: <String>['proximate'],
        ),
        how: const HowKernelSnapshot(
          executionPath: 'governed_runtime',
          workflowStage: 'mesh_forward',
          transportMode: 'mesh',
          plannerMode: 'kernel_bound',
          modelFamily: 'reticulum_inspired',
          interventionChain: <String>['resolve', 'explain'],
          failureMechanism: 'none',
          mechanismConfidence: 0.88,
        ),
        why: WhyKernelSnapshot(
          goal: whyRequest.goal ?? 'govern_mesh_delivery',
          summary: 'Governed mesh route record resolved.',
          rootCauseType: WhyRootCauseType.mechanism,
          confidence: 0.82,
          drivers: whyRequest.coreSignals,
          inhibitors: const <WhySignal>[],
          counterfactuals: const <WhyCounterfactual>[],
          createdAtUtc: envelope.occurredAtUtc,
        ),
      ),
      createdAtUtc: envelope.occurredAtUtc,
    );
  }

  @override
  Future<KernelContextBundle> resolveKernelContext(
    KernelEventEnvelope envelope,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<HowKernelSnapshot> resolveHow(KernelEventEnvelope envelope) {
    throw UnimplementedError();
  }

  @override
  Future<WhatKernelSnapshot> resolveWhat(KernelEventEnvelope envelope) {
    throw UnimplementedError();
  }

  @override
  Future<WhenKernelSnapshot> resolveWhen(KernelEventEnvelope envelope) {
    throw UnimplementedError();
  }

  @override
  Future<WhereKernelSnapshot> resolveWhere(KernelEventEnvelope envelope) {
    throw UnimplementedError();
  }

  @override
  Future<WhoKernelSnapshot> resolveWho(KernelEventEnvelope envelope) {
    throw UnimplementedError();
  }
}

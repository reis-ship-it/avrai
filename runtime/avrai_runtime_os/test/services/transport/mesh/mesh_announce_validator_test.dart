import 'package:avrai_core/models/signatures/entity_signature.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_announce_ledger.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_announce_validator.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_interface_registry.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_runtime_state_store.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_segment_models.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_segment_revocation_policy.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_segment_revocation_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MeshAnnounceValidator', () {
    final privateMeshProfile = const MeshInterfaceProfile(
      interfaceId: 'ble',
      kind: MeshInterfaceKind.ble,
      enabled: true,
      supportsDiscovery: true,
      supportsCustody: true,
      reachabilityScope: MeshInterfaceReachabilityScope.local,
      costClass: MeshInterfaceCostClass.low,
      energyCostClass: MeshInterfaceEnergyCostClass.medium,
      trustClass: MeshInterfaceTrustClass.localTrusted,
      allowedPrivacyModes: <String>{
        MeshTransportPrivacyMode.privateMesh,
      },
      defaultAnnounceTtl: Duration(minutes: 5),
      maxHopCount: 4,
    );

    MeshSegmentCredential validCredential({
      required String credentialId,
      required String segmentProfileId,
      required String principalId,
    }) {
      final nowUtc = DateTime.now().toUtc();
      return MeshSegmentCredential(
        credentialId: credentialId,
        segmentProfileId: segmentProfileId,
        principalId: principalId,
        principalKind: SignatureEntityKind.user,
        issuedAtUtc: nowUtc.subtract(const Duration(hours: 2)),
        expiresAtUtc: nowUtc.add(const Duration(hours: 2)),
      );
    }

    MeshAnnounceAttestation validAttestation({
      required String attestationId,
      required String segmentProfileId,
      required String credentialId,
      required String signerEntityId,
    }) {
      final nowUtc = DateTime.now().toUtc();
      return MeshAnnounceAttestation(
        attestationId: attestationId,
        segmentProfileId: segmentProfileId,
        credentialId: credentialId,
        signerEntityId: signerEntityId,
        signerEntityKind: SignatureEntityKind.user,
        signedAtUtc: nowUtc.subtract(const Duration(hours: 1)),
        expiresAtUtc: nowUtc.add(const Duration(hours: 2)),
      );
    }

    test('rejects unauthenticated private mesh announce', () {
      final validator = const MeshAnnounceValidator();
      final result = validator.validate(
        observation: const MeshAnnounceObservation(
          destinationId: 'peer-2',
          nextHopPeerId: 'peer-2',
          interfaceId: 'ble',
          hopCount: 1,
          geographicScope: 'local',
          confidence: 0.9,
          supportsCustody: true,
          sourceType: MeshAnnounceSourceType.directDiscovery,
        ),
        interfaceProfile: privateMeshProfile,
        privacyMode: MeshTransportPrivacyMode.privateMesh,
      );

      expect(result.accepted, isFalse);
      expect(result.reason, 'authenticated_segment_required');
    });

    test('accepts authenticated private mesh announce', () {
      final validator = const MeshAnnounceValidator();
      final segmentProfile = const MeshSegmentProfile(
        segmentProfileId: 'segment-1',
        privacyMode: MeshTransportPrivacyMode.privateMesh,
        allowedInterfaceIds: <String>{'ble'},
        requiresAuthenticatedAnnounces: true,
      );
      final credential = validCredential(
        credentialId: 'cred-1',
        segmentProfileId: 'segment-1',
        principalId: 'peer-2',
      );
      final attestation = validAttestation(
        attestationId: 'attest-1',
        segmentProfileId: 'segment-1',
        credentialId: 'cred-1',
        signerEntityId: 'peer-2',
      );

      final result = validator.validate(
        observation: MeshAnnounceObservation(
          destinationId: 'peer-2',
          nextHopPeerId: 'peer-2',
          interfaceId: 'ble',
          hopCount: 1,
          geographicScope: 'local',
          confidence: 0.9,
          supportsCustody: true,
          sourceType: MeshAnnounceSourceType.directDiscovery,
          segmentProfile: segmentProfile,
          segmentCredential: credential,
          attestation: attestation,
        ),
        interfaceProfile: privateMeshProfile,
        privacyMode: MeshTransportPrivacyMode.privateMesh,
      );

      expect(result.accepted, isTrue);
      expect(result.reason, 'accepted');
    });

    test('ledger does not insert rejected private mesh announce', () async {
      final ledger = MeshAnnounceLedger(
        store: InMemoryMeshRuntimeStateStore(),
        announceValidator: const MeshAnnounceValidator(),
      );

      final update = await ledger.observe(
        observation: const MeshAnnounceObservation(
          destinationId: 'peer-2',
          nextHopPeerId: 'peer-2',
          interfaceId: 'ble',
          hopCount: 1,
          geographicScope: 'local',
          confidence: 0.9,
          supportsCustody: true,
          sourceType: MeshAnnounceSourceType.directDiscovery,
        ),
        interfaceProfile: privateMeshProfile,
        privacyMode: MeshTransportPrivacyMode.privateMesh,
      );

      expect(update.accepted, isFalse);
      expect(ledger.activeRecords(destinationId: 'peer-2'), isEmpty);
      expect(ledger.rejectedRecords(destinationId: 'peer-2'), hasLength(1));
      expect(
        ledger.rejectionReasonCounts()['authenticated_segment_required'],
        1,
      );
    });

    test('rejects revoked segment credential', () {
      final store = MeshSegmentRevocationStore();
      store.revokeCredential('cred-2', reason: 'compromised');
      final validator = MeshAnnounceValidator(
        revocationPolicy: MeshSegmentRevocationPolicy(revocationStore: store),
      );
      final segmentProfile = const MeshSegmentProfile(
        segmentProfileId: 'segment-2',
        privacyMode: MeshTransportPrivacyMode.privateMesh,
        allowedInterfaceIds: <String>{'ble'},
        requiresAuthenticatedAnnounces: true,
      );
      final credential = validCredential(
        credentialId: 'cred-2',
        segmentProfileId: 'segment-2',
        principalId: 'peer-3',
      );
      final attestation = validAttestation(
        attestationId: 'attest-2',
        segmentProfileId: 'segment-2',
        credentialId: 'cred-2',
        signerEntityId: 'peer-3',
      );

      final result = validator.validate(
        observation: MeshAnnounceObservation(
          destinationId: 'peer-3',
          nextHopPeerId: 'peer-3',
          interfaceId: 'ble',
          hopCount: 1,
          geographicScope: 'local',
          confidence: 0.9,
          supportsCustody: true,
          sourceType: MeshAnnounceSourceType.directDiscovery,
          segmentProfile: segmentProfile,
          segmentCredential: credential,
          attestation: attestation,
        ),
        interfaceProfile: privateMeshProfile,
        privacyMode: MeshTransportPrivacyMode.privateMesh,
      );

      expect(result.accepted, isFalse);
      expect(result.reason, 'segment_credential_revoked');
    });

    test('rejects revoked announce attestation', () {
      final store = MeshSegmentRevocationStore();
      store.revokeAttestation('attest-3', reason: 'revoked');
      final validator = MeshAnnounceValidator(
        revocationPolicy: MeshSegmentRevocationPolicy(revocationStore: store),
      );
      final segmentProfile = const MeshSegmentProfile(
        segmentProfileId: 'segment-3',
        privacyMode: MeshTransportPrivacyMode.privateMesh,
        allowedInterfaceIds: <String>{'ble'},
        requiresAuthenticatedAnnounces: true,
      );
      final credential = validCredential(
        credentialId: 'cred-3',
        segmentProfileId: 'segment-3',
        principalId: 'peer-4',
      );
      final attestation = validAttestation(
        attestationId: 'attest-3',
        segmentProfileId: 'segment-3',
        credentialId: 'cred-3',
        signerEntityId: 'peer-4',
      );

      final result = validator.validate(
        observation: MeshAnnounceObservation(
          destinationId: 'peer-4',
          nextHopPeerId: 'peer-4',
          interfaceId: 'ble',
          hopCount: 1,
          geographicScope: 'local',
          confidence: 0.9,
          supportsCustody: true,
          sourceType: MeshAnnounceSourceType.directDiscovery,
          segmentProfile: segmentProfile,
          segmentCredential: credential,
          attestation: attestation,
        ),
        interfaceProfile: privateMeshProfile,
        privacyMode: MeshTransportPrivacyMode.privateMesh,
      );

      expect(result.accepted, isFalse);
      expect(result.reason, 'announce_attestation_revoked');
    });
  });
}

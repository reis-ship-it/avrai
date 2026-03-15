import 'package:avrai_core/models/signatures/entity_signature.dart';
import 'package:avrai_network/avra_network.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_announce_attestation_factory.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_announce_ledger.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_interface_registry.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_route_ledger.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_segment_credential_refresh_service.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_segment_credential_factory.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_segment_models.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_segment_profile_resolver.dart';

class MeshAnnounceProducerLane {
  const MeshAnnounceProducerLane._();

  static Future<List<MeshAnnounceUpdateResult>> syncReachablePeers({
    required MeshAnnounceLedger announceLedger,
    required Iterable<String> reachablePeerIds,
    required DeviceDiscoveryService discovery,
    required MeshInterfaceRegistry interfaceRegistry,
    required String privacyMode,
    MeshSegmentProfileResolver? segmentProfileResolver,
    MeshSegmentCredentialFactory? segmentCredentialFactory,
    MeshAnnounceAttestationFactory? announceAttestationFactory,
    MeshSegmentCredentialRefreshService? credentialRefreshService,
    MeshRouteLedger? routeLedger,
    Map<String, String> peerNodeIdByDeviceId = const <String, String>{},
    DateTime? observedAtUtc,
  }) async {
    final updates = <MeshAnnounceUpdateResult>[];
    final now = observedAtUtc?.toUtc() ?? DateTime.now().toUtc();
    for (final peerId in reachablePeerIds.toSet()) {
      final device = discovery.getDevice(peerId);
      if (device == null) {
        continue;
      }
      final profile = interfaceRegistry.resolveForDevice(
        device,
        privacyMode: privacyMode,
      );
      if (!profile.enabled) {
        continue;
      }
      final nextHopNodeId = peerNodeIdByDeviceId[device.deviceId] ??
          device.metadata['node_id']?.toString();
      final ttl = _ttlFor(
        MeshAnnounceSourceType.directDiscovery,
        interfaceProfile: profile,
      );
      final trust = _buildTrustMaterial(
        segmentProfileResolver: segmentProfileResolver,
        segmentCredentialFactory: segmentCredentialFactory,
        announceAttestationFactory: announceAttestationFactory,
        interfaceProfile: profile,
        privacyMode: privacyMode,
        principalId: nextHopNodeId ?? peerId,
        signerEntityId: nextHopNodeId ?? peerId,
        issuedAtUtc: now,
        ttl: ttl,
      );
      updates.add(await announceLedger.observe(
        observation: MeshAnnounceObservation(
          destinationId: peerId,
          nextHopPeerId: peerId,
          nextHopNodeId: nextHopNodeId,
          interfaceId: profile.interfaceId,
          hopCount: 1,
          geographicScope: 'local',
          confidence: MeshInterfaceRegistry.confidenceForDevice(device),
          supportsCustody: profile.supportsCustody,
          sourceType: MeshAnnounceSourceType.directDiscovery,
          segmentProfile: trust.segmentProfile,
          segmentCredential: trust.segmentCredential,
          attestation: trust.attestation,
        ),
        interfaceProfile: profile,
        privacyMode: privacyMode,
        nowUtc: now,
      ));
      credentialRefreshService?.recordIssued(
        credential: trust.segmentCredential,
        attestation: trust.attestation,
      );

      final historicalRoutes =
          routeLedger?.entriesForPeer(peerId) ?? const <MeshRouteLedgerEntry>[];
      for (final entry in historicalRoutes) {
        final update = await observeHeardForward(
          announceLedger: announceLedger,
          interfaceProfile: profile,
          privacyMode: privacyMode,
          destinationId: entry.destinationId,
          nextHopPeerId: peerId,
          nextHopNodeId: entry.peerNodeId ?? nextHopNodeId,
          geographicScope: entry.geographicScope ?? 'mesh',
          confidence: entry.scoreAt(
            nowUtc: now,
            liveProximityScore: device.proximityScore,
            liveSignalStrengthDbm: device.signalStrength,
            requestedGeographicScope: entry.geographicScope,
          ),
          supportsCustody: profile.supportsCustody,
          hopCount: 1,
          observedAtUtc: now,
          segmentProfileResolver: segmentProfileResolver,
          segmentCredentialFactory: segmentCredentialFactory,
          announceAttestationFactory: announceAttestationFactory,
          credentialRefreshService: credentialRefreshService,
          principalId: entry.peerNodeId ?? nextHopNodeId ?? peerId,
          signerEntityId: entry.peerNodeId ?? nextHopNodeId ?? peerId,
        );
        updates.add(update);
      }
    }
    return updates;
  }

  static Future<List<MeshAnnounceUpdateResult>> seedCloudAvailability({
    required MeshAnnounceLedger announceLedger,
    required Iterable<String> destinationIds,
    required MeshInterfaceRegistry interfaceRegistry,
    required String privacyMode,
    MeshSegmentProfileResolver? segmentProfileResolver,
    MeshSegmentCredentialFactory? segmentCredentialFactory,
    MeshAnnounceAttestationFactory? announceAttestationFactory,
    MeshSegmentCredentialRefreshService? credentialRefreshService,
    DateTime? observedAtUtc,
  }) async {
    final profile = interfaceRegistry.cloudProfile(privacyMode: privacyMode);
    if (!profile.enabled) {
      return const <MeshAnnounceUpdateResult>[];
    }
    final updates = <MeshAnnounceUpdateResult>[];
    final now = observedAtUtc?.toUtc() ?? DateTime.now().toUtc();
    final ttl = _ttlFor(
      MeshAnnounceSourceType.cloudAvailable,
      interfaceProfile: profile,
    );
    final trust = _buildTrustMaterial(
      segmentProfileResolver: segmentProfileResolver,
      segmentCredentialFactory: segmentCredentialFactory,
      announceAttestationFactory: announceAttestationFactory,
      interfaceProfile: profile,
      privacyMode: privacyMode,
      principalId: 'federated_cloud',
      signerEntityId: 'federated_cloud',
      issuedAtUtc: now,
      ttl: ttl,
    );
    for (final destinationId in destinationIds.toSet()) {
      updates.add(await announceLedger.observe(
        observation: MeshAnnounceObservation(
          destinationId: destinationId,
          nextHopPeerId: 'federated_cloud',
          nextHopNodeId: 'federated_cloud',
          interfaceId: profile.interfaceId,
          hopCount: 1,
          geographicScope: 'global',
          confidence: 0.78,
          supportsCustody: profile.supportsCustody,
          sourceType: MeshAnnounceSourceType.cloudAvailable,
          segmentProfile: trust.segmentProfile,
          segmentCredential: trust.segmentCredential,
          attestation: trust.attestation,
        ),
        interfaceProfile: profile,
        privacyMode: privacyMode,
        nowUtc: now,
      ));
      credentialRefreshService?.recordIssued(
        credential: trust.segmentCredential,
        attestation: trust.attestation,
      );
    }
    return updates;
  }

  static Future<MeshAnnounceUpdateResult> observeHeardForward({
    required MeshAnnounceLedger announceLedger,
    required MeshInterfaceProfile interfaceProfile,
    required String privacyMode,
    required String destinationId,
    required String nextHopPeerId,
    required String? nextHopNodeId,
    required String geographicScope,
    required double confidence,
    required bool supportsCustody,
    required int hopCount,
    MeshSegmentProfileResolver? segmentProfileResolver,
    MeshSegmentCredentialFactory? segmentCredentialFactory,
    MeshAnnounceAttestationFactory? announceAttestationFactory,
    MeshSegmentCredentialRefreshService? credentialRefreshService,
    String? principalId,
    String? signerEntityId,
    DateTime? observedAtUtc,
  }) async {
    final now = observedAtUtc?.toUtc() ?? DateTime.now().toUtc();
    final ttl = _ttlFor(
      MeshAnnounceSourceType.heardForward,
      interfaceProfile: interfaceProfile,
    );
    final trust = _buildTrustMaterial(
      segmentProfileResolver: segmentProfileResolver,
      segmentCredentialFactory: segmentCredentialFactory,
      announceAttestationFactory: announceAttestationFactory,
      interfaceProfile: interfaceProfile,
      privacyMode: privacyMode,
      principalId: principalId ?? nextHopNodeId ?? nextHopPeerId,
      signerEntityId: signerEntityId ?? nextHopNodeId ?? nextHopPeerId,
      issuedAtUtc: now,
      ttl: ttl,
    );
    credentialRefreshService?.recordIssued(
      credential: trust.segmentCredential,
      attestation: trust.attestation,
    );
    return announceLedger.observe(
      observation: MeshAnnounceObservation(
        destinationId: destinationId,
        nextHopPeerId: nextHopPeerId,
        nextHopNodeId: nextHopNodeId,
        interfaceId: interfaceProfile.interfaceId,
        hopCount: hopCount,
        geographicScope: geographicScope,
        confidence: confidence,
        supportsCustody: supportsCustody,
        sourceType: MeshAnnounceSourceType.heardForward,
        segmentProfile: trust.segmentProfile,
        segmentCredential: trust.segmentCredential,
        attestation: trust.attestation,
      ),
      interfaceProfile: interfaceProfile,
      privacyMode: privacyMode,
      nowUtc: now,
    );
  }

  static Future<MeshAnnounceUpdateResult> observeRelayRefresh({
    required MeshAnnounceLedger announceLedger,
    required MeshInterfaceProfile interfaceProfile,
    required String privacyMode,
    required String destinationId,
    required String nextHopPeerId,
    required String? nextHopNodeId,
    required String geographicScope,
    required double confidence,
    required bool supportsCustody,
    required int hopCount,
    MeshSegmentProfileResolver? segmentProfileResolver,
    MeshSegmentCredentialFactory? segmentCredentialFactory,
    MeshAnnounceAttestationFactory? announceAttestationFactory,
    MeshSegmentCredentialRefreshService? credentialRefreshService,
    String? principalId,
    String? signerEntityId,
    DateTime? observedAtUtc,
  }) async {
    final now = observedAtUtc?.toUtc() ?? DateTime.now().toUtc();
    final ttl = _ttlFor(
      MeshAnnounceSourceType.forwardSuccess,
      interfaceProfile: interfaceProfile,
    );
    final trust = _buildTrustMaterial(
      segmentProfileResolver: segmentProfileResolver,
      segmentCredentialFactory: segmentCredentialFactory,
      announceAttestationFactory: announceAttestationFactory,
      interfaceProfile: interfaceProfile,
      privacyMode: privacyMode,
      principalId: principalId ?? nextHopNodeId ?? nextHopPeerId,
      signerEntityId: signerEntityId ?? nextHopNodeId ?? nextHopPeerId,
      issuedAtUtc: now,
      ttl: ttl,
    );
    credentialRefreshService?.recordIssued(
      credential: trust.segmentCredential,
      attestation: trust.attestation,
    );
    return announceLedger.observe(
      observation: MeshAnnounceObservation(
        destinationId: destinationId,
        nextHopPeerId: nextHopPeerId,
        nextHopNodeId: nextHopNodeId,
        interfaceId: interfaceProfile.interfaceId,
        hopCount: hopCount,
        geographicScope: geographicScope,
        confidence: confidence,
        supportsCustody: supportsCustody,
        sourceType: MeshAnnounceSourceType.forwardSuccess,
        segmentProfile: trust.segmentProfile,
        segmentCredential: trust.segmentCredential,
        attestation: trust.attestation,
      ),
      interfaceProfile: interfaceProfile,
      privacyMode: privacyMode,
      nowUtc: now,
    );
  }

  static Duration _ttlFor(
    MeshAnnounceSourceType sourceType, {
    required MeshInterfaceProfile interfaceProfile,
  }) {
    return switch (sourceType) {
      MeshAnnounceSourceType.directDiscovery =>
        interfaceProfile.defaultAnnounceTtl,
      MeshAnnounceSourceType.cloudAvailable => const Duration(minutes: 15),
      MeshAnnounceSourceType.forwardSuccess => const Duration(minutes: 3),
      MeshAnnounceSourceType.heardForward => const Duration(minutes: 3),
    };
  }

  static _MeshAnnounceTrustMaterial _buildTrustMaterial({
    required MeshSegmentProfileResolver? segmentProfileResolver,
    required MeshSegmentCredentialFactory? segmentCredentialFactory,
    required MeshAnnounceAttestationFactory? announceAttestationFactory,
    required MeshInterfaceProfile interfaceProfile,
    required String privacyMode,
    required String principalId,
    required String signerEntityId,
    required DateTime issuedAtUtc,
    required Duration ttl,
  }) {
    final segmentProfile = segmentProfileResolver?.resolve(
      interfaceProfile: interfaceProfile,
      privacyMode: privacyMode,
    );
    final segmentCredential = segmentProfile == null
        ? null
        : segmentCredentialFactory?.issue(
            segmentProfile: segmentProfile,
            principalId: principalId,
            principalKind: SignatureEntityKind.user,
            issuedAtUtc: issuedAtUtc,
            ttl: ttl,
          );
    final attestation = segmentProfile == null || segmentCredential == null
        ? null
        : announceAttestationFactory?.attest(
            segmentProfile: segmentProfile,
            credential: segmentCredential,
            signerEntityId: signerEntityId,
            signerEntityKind: SignatureEntityKind.user,
            signedAtUtc: issuedAtUtc,
            ttl: ttl,
          );
    return _MeshAnnounceTrustMaterial(
      segmentProfile: segmentProfile,
      segmentCredential: segmentCredential,
      attestation: attestation,
    );
  }
}

class _MeshAnnounceTrustMaterial {
  const _MeshAnnounceTrustMaterial({
    required this.segmentProfile,
    required this.segmentCredential,
    required this.attestation,
  });

  final MeshSegmentProfile? segmentProfile;
  final MeshSegmentCredential? segmentCredential;
  final MeshAnnounceAttestation? attestation;
}

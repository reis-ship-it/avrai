import 'package:avrai_core/models/signatures/entity_signature.dart';
import 'package:avrai_runtime_os/services/signatures/signature_confidence_service.dart';
import 'package:avrai_runtime_os/services/signatures/signature_freshness_tracker.dart';
import 'package:avrai_runtime_os/services/signatures/signature_repository.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_segment_models.dart';

class MeshAnnounceAttestationFactory {
  const MeshAnnounceAttestationFactory({
    SignatureRepository? signatureRepository,
    SignatureConfidenceService confidenceService =
        const SignatureConfidenceService(),
    SignatureFreshnessTracker freshnessTracker =
        const SignatureFreshnessTracker(),
  })  : _signatureRepository = signatureRepository,
        _confidenceService = confidenceService,
        _freshnessTracker = freshnessTracker;

  final SignatureRepository? _signatureRepository;
  final SignatureConfidenceService _confidenceService;
  final SignatureFreshnessTracker _freshnessTracker;

  MeshAnnounceAttestation? attest({
    required MeshSegmentProfile segmentProfile,
    required MeshSegmentCredential credential,
    required String signerEntityId,
    required SignatureEntityKind signerEntityKind,
    required DateTime signedAtUtc,
    required Duration ttl,
  }) {
    final signature = _signatureRepository?.get(
      entityKind: signerEntityKind,
      entityId: signerEntityId,
    );
    if (signature == null) {
      return null;
    }

    final freshness = _freshnessTracker.blend(
      <double>[
        signature.freshness,
        _freshnessTracker.fromTimestamp(signature.updatedAt, now: signedAtUtc),
      ],
    );
    final confidence = _confidenceService.blend(<double>[signature.confidence]);
    return MeshAnnounceAttestation(
      attestationId:
          'mesh-attestation-${credential.credentialId}-$signerEntityId',
      segmentProfileId: segmentProfile.segmentProfileId,
      credentialId: credential.credentialId,
      signerEntityId: signerEntityId,
      signerEntityKind: signerEntityKind,
      signedAtUtc: signedAtUtc,
      expiresAtUtc: signedAtUtc.add(ttl),
      confidence: confidence,
      freshness: freshness,
    );
  }
}

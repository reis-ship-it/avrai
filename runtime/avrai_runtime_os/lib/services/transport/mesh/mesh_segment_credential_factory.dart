import 'package:avrai_core/models/signatures/entity_signature.dart';
import 'package:avrai_runtime_os/services/signatures/signature_confidence_service.dart';
import 'package:avrai_runtime_os/services/signatures/signature_freshness_tracker.dart';
import 'package:avrai_runtime_os/services/signatures/signature_repository.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_segment_models.dart';

class MeshSegmentCredentialFactory {
  const MeshSegmentCredentialFactory({
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

  MeshSegmentCredential? issue({
    required MeshSegmentProfile segmentProfile,
    required String principalId,
    required SignatureEntityKind principalKind,
    required DateTime issuedAtUtc,
    required Duration ttl,
  }) {
    final signature = _signatureRepository?.get(
      entityKind: principalKind,
      entityId: principalId,
    );
    if (signature == null) {
      return null;
    }

    final freshness = _freshnessTracker.blend(
      <double>[
        signature.freshness,
        _freshnessTracker.fromTimestamp(signature.updatedAt, now: issuedAtUtc),
      ],
    );
    final confidence = _confidenceService.blend(<double>[signature.confidence]);
    return MeshSegmentCredential(
      credentialId:
          'mesh-credential-${segmentProfile.segmentProfileId}-$principalId',
      segmentProfileId: segmentProfile.segmentProfileId,
      principalId: principalId,
      principalKind: principalKind,
      issuedAtUtc: issuedAtUtc,
      expiresAtUtc: issuedAtUtc.add(ttl),
      confidence: confidence,
      freshness: freshness,
    );
  }
}

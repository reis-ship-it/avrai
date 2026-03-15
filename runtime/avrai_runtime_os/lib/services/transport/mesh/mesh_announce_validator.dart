import 'package:avrai_runtime_os/services/signatures/signature_repository.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_announce_ledger.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_interface_registry.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_segment_models.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_segment_revocation_policy.dart';

class MeshAnnounceValidator {
  const MeshAnnounceValidator({
    this.signatureRepository,
    this.revocationPolicy,
    this.minimumSignatureConfidence = 0.5,
    this.minimumSignatureFreshness = 0.5,
  });

  final SignatureRepository? signatureRepository;
  final MeshSegmentRevocationPolicy? revocationPolicy;
  final double minimumSignatureConfidence;
  final double minimumSignatureFreshness;

  MeshAnnounceValidationResult validate({
    required MeshAnnounceObservation observation,
    required MeshInterfaceProfile interfaceProfile,
    required String privacyMode,
  }) {
    final normalizedPrivacyMode =
        MeshTransportPrivacyMode.normalize(privacyMode);
    final nowUtc = DateTime.now().toUtc();
    final segmentProfile = observation.segmentProfile;
    final credential = observation.segmentCredential;
    final attestation = observation.attestation;

    if (normalizedPrivacyMode == MeshTransportPrivacyMode.localSovereign) {
      return const MeshAnnounceValidationResult(
        accepted: false,
        reason: 'local_sovereign_blocks_egress_announces',
      );
    }

    if (normalizedPrivacyMode == MeshTransportPrivacyMode.privateMesh ||
        (normalizedPrivacyMode == MeshTransportPrivacyMode.federatedCloud &&
            interfaceProfile.kind == MeshInterfaceKind.federatedCloud)) {
      if (segmentProfile == null ||
          credential == null ||
          attestation == null ||
          !segmentProfile.requiresAuthenticatedAnnounces) {
        return const MeshAnnounceValidationResult(
          accepted: false,
          reason: 'authenticated_segment_required',
        );
      }
    }

    if (segmentProfile != null &&
        !segmentProfile.allowedInterfaceIds
            .contains(interfaceProfile.interfaceId)) {
      return MeshAnnounceValidationResult(
        accepted: false,
        reason: 'segment_interface_mismatch',
        segmentProfileId: segmentProfile.segmentProfileId,
      );
    }

    if (credential != null) {
      if (revocationPolicy?.isCredentialRevoked(credential) ?? false) {
        return MeshAnnounceValidationResult(
          accepted: false,
          reason: 'segment_credential_revoked',
          segmentProfileId: credential.segmentProfileId,
          credentialId: credential.credentialId,
        );
      }
      if (!credential.isValidAt(nowUtc)) {
        return MeshAnnounceValidationResult(
          accepted: false,
          reason: 'segment_credential_invalid',
          segmentProfileId: credential.segmentProfileId,
          credentialId: credential.credentialId,
        );
      }
      if (segmentProfile != null &&
          credential.segmentProfileId != segmentProfile.segmentProfileId) {
        return MeshAnnounceValidationResult(
          accepted: false,
          reason: 'segment_credential_profile_mismatch',
          segmentProfileId: segmentProfile.segmentProfileId,
          credentialId: credential.credentialId,
        );
      }
    }

    if (attestation != null) {
      if (revocationPolicy?.isAttestationRevoked(attestation) ?? false) {
        return MeshAnnounceValidationResult(
          accepted: false,
          reason: 'announce_attestation_revoked',
          segmentProfileId: attestation.segmentProfileId,
          credentialId: attestation.credentialId,
          attestationId: attestation.attestationId,
        );
      }
      if (!attestation.isValidAt(nowUtc)) {
        return MeshAnnounceValidationResult(
          accepted: false,
          reason: 'announce_attestation_invalid',
          segmentProfileId: attestation.segmentProfileId,
          credentialId: attestation.credentialId,
          attestationId: attestation.attestationId,
        );
      }
      if (credential != null &&
          attestation.credentialId != credential.credentialId) {
        return MeshAnnounceValidationResult(
          accepted: false,
          reason: 'announce_attestation_credential_mismatch',
          segmentProfileId: attestation.segmentProfileId,
          credentialId: credential.credentialId,
          attestationId: attestation.attestationId,
        );
      }
      if (segmentProfile != null &&
          attestation.segmentProfileId != segmentProfile.segmentProfileId) {
        return MeshAnnounceValidationResult(
          accepted: false,
          reason: 'announce_attestation_profile_mismatch',
          segmentProfileId: segmentProfile.segmentProfileId,
          credentialId: attestation.credentialId,
          attestationId: attestation.attestationId,
        );
      }

      final repository = signatureRepository;
      if (repository != null) {
        final signature = repository.get(
          entityKind: attestation.signerEntityKind,
          entityId: attestation.signerEntityId,
        );
        if (signature == null ||
            signature.confidence < minimumSignatureConfidence ||
            signature.freshness < minimumSignatureFreshness) {
          return MeshAnnounceValidationResult(
            accepted: false,
            reason: 'signer_signature_untrusted',
            segmentProfileId: attestation.segmentProfileId,
            credentialId: attestation.credentialId,
            attestationId: attestation.attestationId,
          );
        }
      }
    }

    return MeshAnnounceValidationResult(
      accepted: true,
      reason: 'accepted',
      segmentProfileId: segmentProfile?.segmentProfileId,
      credentialId: credential?.credentialId,
      attestationId: attestation?.attestationId,
    );
  }
}

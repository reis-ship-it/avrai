import 'package:avrai_core/models/signatures/entity_signature.dart';

class MeshSegmentProfile {
  const MeshSegmentProfile({
    required this.segmentProfileId,
    required this.privacyMode,
    required this.allowedInterfaceIds,
    this.requiresAuthenticatedAnnounces = false,
  });

  final String segmentProfileId;
  final String privacyMode;
  final Set<String> allowedInterfaceIds;
  final bool requiresAuthenticatedAnnounces;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'segment_profile_id': segmentProfileId,
        'privacy_mode': privacyMode,
        'allowed_interface_ids': allowedInterfaceIds.toList(growable: false),
        'requires_authenticated_announces': requiresAuthenticatedAnnounces,
      };

  factory MeshSegmentProfile.fromJson(Map<String, dynamic> json) {
    return MeshSegmentProfile(
      segmentProfileId:
          json['segment_profile_id'] as String? ?? 'unknown_segment_profile',
      privacyMode: json['privacy_mode'] as String? ?? 'private_mesh',
      allowedInterfaceIds:
          (json['allowed_interface_ids'] as List? ?? const <dynamic>[])
              .map((entry) => entry.toString())
              .toSet(),
      requiresAuthenticatedAnnounces:
          json['requires_authenticated_announces'] as bool? ?? false,
    );
  }
}

class MeshSegmentCredential {
  const MeshSegmentCredential({
    required this.credentialId,
    required this.segmentProfileId,
    required this.principalId,
    required this.principalKind,
    required this.issuedAtUtc,
    required this.expiresAtUtc,
    this.confidence = 1.0,
    this.freshness = 1.0,
  });

  final String credentialId;
  final String segmentProfileId;
  final String principalId;
  final SignatureEntityKind principalKind;
  final DateTime issuedAtUtc;
  final DateTime expiresAtUtc;
  final double confidence;
  final double freshness;

  bool isValidAt(DateTime nowUtc) =>
      !expiresAtUtc.isBefore(nowUtc) && confidence >= 0.5 && freshness >= 0.5;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'credential_id': credentialId,
        'segment_profile_id': segmentProfileId,
        'principal_id': principalId,
        'principal_kind': principalKind.name,
        'issued_at_utc': issuedAtUtc.toUtc().toIso8601String(),
        'expires_at_utc': expiresAtUtc.toUtc().toIso8601String(),
        'confidence': confidence,
        'freshness': freshness,
      };

  factory MeshSegmentCredential.fromJson(Map<String, dynamic> json) {
    return MeshSegmentCredential(
      credentialId: json['credential_id'] as String? ?? 'unknown_credential',
      segmentProfileId:
          json['segment_profile_id'] as String? ?? 'unknown_segment',
      principalId: json['principal_id'] as String? ?? 'unknown_principal',
      principalKind: SignatureEntityKind.values.byName(
        json['principal_kind'] as String? ?? SignatureEntityKind.user.name,
      ),
      issuedAtUtc:
          DateTime.tryParse(json['issued_at_utc'] as String? ?? '')?.toUtc() ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      expiresAtUtc:
          DateTime.tryParse(json['expires_at_utc'] as String? ?? '')
                  ?.toUtc() ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
      freshness: (json['freshness'] as num?)?.toDouble() ?? 1.0,
    );
  }
}

class MeshAnnounceAttestation {
  const MeshAnnounceAttestation({
    required this.attestationId,
    required this.segmentProfileId,
    required this.credentialId,
    required this.signerEntityId,
    required this.signerEntityKind,
    required this.signedAtUtc,
    required this.expiresAtUtc,
    this.confidence = 1.0,
    this.freshness = 1.0,
  });

  final String attestationId;
  final String segmentProfileId;
  final String credentialId;
  final String signerEntityId;
  final SignatureEntityKind signerEntityKind;
  final DateTime signedAtUtc;
  final DateTime expiresAtUtc;
  final double confidence;
  final double freshness;

  bool isValidAt(DateTime nowUtc) =>
      !expiresAtUtc.isBefore(nowUtc) && confidence >= 0.5 && freshness >= 0.5;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'attestation_id': attestationId,
        'segment_profile_id': segmentProfileId,
        'credential_id': credentialId,
        'signer_entity_id': signerEntityId,
        'signer_entity_kind': signerEntityKind.name,
        'signed_at_utc': signedAtUtc.toUtc().toIso8601String(),
        'expires_at_utc': expiresAtUtc.toUtc().toIso8601String(),
        'confidence': confidence,
        'freshness': freshness,
      };

  factory MeshAnnounceAttestation.fromJson(Map<String, dynamic> json) {
    return MeshAnnounceAttestation(
      attestationId:
          json['attestation_id'] as String? ?? 'unknown_attestation',
      segmentProfileId:
          json['segment_profile_id'] as String? ?? 'unknown_segment',
      credentialId: json['credential_id'] as String? ?? 'unknown_credential',
      signerEntityId:
          json['signer_entity_id'] as String? ?? 'unknown_signer',
      signerEntityKind: SignatureEntityKind.values.byName(
        json['signer_entity_kind'] as String? ??
            SignatureEntityKind.user.name,
      ),
      signedAtUtc:
          DateTime.tryParse(json['signed_at_utc'] as String? ?? '')?.toUtc() ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      expiresAtUtc:
          DateTime.tryParse(json['expires_at_utc'] as String? ?? '')
                  ?.toUtc() ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
      freshness: (json['freshness'] as num?)?.toDouble() ?? 1.0,
    );
  }
}

class MeshAnnounceValidationResult {
  const MeshAnnounceValidationResult({
    required this.accepted,
    required this.reason,
    this.segmentProfileId,
    this.credentialId,
    this.attestationId,
  });

  final bool accepted;
  final String reason;
  final String? segmentProfileId;
  final String? credentialId;
  final String? attestationId;
}

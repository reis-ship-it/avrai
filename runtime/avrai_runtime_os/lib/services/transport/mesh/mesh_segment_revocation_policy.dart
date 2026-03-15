import 'package:avrai_runtime_os/services/transport/mesh/mesh_segment_models.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_segment_revocation_store.dart';

class MeshSegmentRevocationPolicy {
  const MeshSegmentRevocationPolicy({
    MeshSegmentRevocationStore? revocationStore,
  }) : _revocationStore = revocationStore;

  final MeshSegmentRevocationStore? _revocationStore;

  bool isCredentialRevoked(MeshSegmentCredential credential) =>
      _revocationStore?.isCredentialRevoked(credential.credentialId) ?? false;

  bool isAttestationRevoked(MeshAnnounceAttestation attestation) =>
      _revocationStore?.isAttestationRevoked(attestation.attestationId) ??
      false;
}

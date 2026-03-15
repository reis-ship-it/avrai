import 'package:avrai_runtime_os/services/transport/mesh/mesh_interface_registry.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_segment_models.dart';

class MeshSegmentProfileResolver {
  const MeshSegmentProfileResolver();

  MeshSegmentProfile resolve({
    required MeshInterfaceProfile interfaceProfile,
    required String privacyMode,
  }) {
    final normalizedPrivacyMode =
        MeshTransportPrivacyMode.normalize(privacyMode);
    final requiresAuthenticatedAnnounces =
        normalizedPrivacyMode == MeshTransportPrivacyMode.privateMesh ||
            (normalizedPrivacyMode == MeshTransportPrivacyMode.federatedCloud &&
                interfaceProfile.kind == MeshInterfaceKind.federatedCloud);

    return MeshSegmentProfile(
      segmentProfileId:
          'mesh-segment-$normalizedPrivacyMode-${interfaceProfile.interfaceId}',
      privacyMode: normalizedPrivacyMode,
      allowedInterfaceIds: <String>{interfaceProfile.interfaceId},
      requiresAuthenticatedAnnounces: requiresAuthenticatedAnnounces,
    );
  }
}

// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'package:avrai_runtime_os/kernel/mesh/mesh_kernel_contract.dart';
import 'package:avrai_runtime_os/kernel/os/ai2ai_mesh_governance_binding_service.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_announce_ledger.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_announce_attestation_factory.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_announce_validator.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_custody_outbox.dart';
import 'package:avrai_runtime_os/services/transport/mesh/governed_mesh_packet_codec.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_interface_registry.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_route_ledger.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_segment_credential_refresh_service.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_segment_credential_factory.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_segment_profile_resolver.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_segment_revocation_policy.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_segment_revocation_store.dart';
import 'package:avrai_runtime_os/services/signatures/signature_confidence_service.dart';
import 'package:avrai_runtime_os/services/signatures/signature_freshness_tracker.dart';
import 'package:avrai_runtime_os/services/signatures/signature_repository.dart';
import 'package:avrai_network/avra_network.dart';
import 'package:get_it/get_it.dart';

class MeshForwardingContext {
  const MeshForwardingContext({
    required this.discovery,
    this.governanceBindingService,
    this.meshKernel,
    this.packetCodec,
    this.routeLedger,
    this.custodyOutbox,
    this.interfaceRegistry,
    this.announceLedger,
    this.segmentProfileResolver,
    this.segmentCredentialFactory,
    this.segmentCredentialRefreshService,
    this.segmentRevocationStore,
    this.announceAttestationFactory,
    this.localUserId,
    this.localAgentId,
    this.privacyMode = MeshTransportPrivacyMode.privateMesh,
    this.reticulumTransportControlPlaneEnabled = false,
    this.trustedAnnounceEnforcementEnabled = false,
  });

  final DeviceDiscoveryService discovery;
  final Ai2AiMeshGovernanceBindingService? governanceBindingService;
  final MeshKernelContract? meshKernel;
  final GovernedMeshPacketCodec? packetCodec;
  final MeshRouteLedger? routeLedger;
  final MeshCustodyOutbox? custodyOutbox;
  final MeshInterfaceRegistry? interfaceRegistry;
  final MeshAnnounceLedger? announceLedger;
  final MeshSegmentProfileResolver? segmentProfileResolver;
  final MeshSegmentCredentialFactory? segmentCredentialFactory;
  final MeshSegmentCredentialRefreshService? segmentCredentialRefreshService;
  final MeshSegmentRevocationStore? segmentRevocationStore;
  final MeshAnnounceAttestationFactory? announceAttestationFactory;
  final String? localUserId;
  final String? localAgentId;
  final String privacyMode;
  final bool reticulumTransportControlPlaneEnabled;
  final bool trustedAnnounceEnforcementEnabled;

  static MeshForwardingContext? tryCreate({
    required DeviceDiscoveryService? discovery,
    Ai2AiMeshGovernanceBindingService? governanceBindingService,
    MeshKernelContract? meshKernel,
    GovernedMeshPacketCodec? packetCodec,
    MeshRouteLedger? routeLedger,
    MeshCustodyOutbox? custodyOutbox,
    MeshInterfaceRegistry? interfaceRegistry,
    MeshAnnounceLedger? announceLedger,
    MeshSegmentProfileResolver? segmentProfileResolver,
    MeshSegmentCredentialFactory? segmentCredentialFactory,
    MeshSegmentCredentialRefreshService? segmentCredentialRefreshService,
    MeshSegmentRevocationStore? segmentRevocationStore,
    MeshAnnounceAttestationFactory? announceAttestationFactory,
    String? localUserId,
    String? localAgentId,
    String privacyMode = MeshTransportPrivacyMode.privateMesh,
    bool reticulumTransportControlPlaneEnabled = false,
    bool trustedAnnounceEnforcementEnabled = false,
  }) {
    if (discovery == null) {
      return null;
    }
    final normalizedPrivacyMode =
        MeshTransportPrivacyMode.normalize(privacyMode);
    final resolvedMeshKernel = meshKernel ??
        (GetIt.instance.isRegistered<MeshKernelContract>()
            ? GetIt.instance<MeshKernelContract>()
            : null);
    final resolvedPacketCodec = packetCodec ??
        (GetIt.instance.isRegistered<GovernedMeshPacketCodec>()
            ? GetIt.instance<GovernedMeshPacketCodec>()
            : null);
    if (resolvedPacketCodec == null) {
      return null;
    }
    final signatureRepository =
        GetIt.instance.isRegistered<SignatureRepository>()
            ? GetIt.instance<SignatureRepository>()
            : null;
    final confidenceService =
        GetIt.instance.isRegistered<SignatureConfidenceService>()
            ? GetIt.instance<SignatureConfidenceService>()
            : const SignatureConfidenceService();
    final freshnessTracker =
        GetIt.instance.isRegistered<SignatureFreshnessTracker>()
            ? GetIt.instance<SignatureFreshnessTracker>()
            : const SignatureFreshnessTracker();
    final resolvedSegmentProfileResolver = segmentProfileResolver ??
        (trustedAnnounceEnforcementEnabled
            ? const MeshSegmentProfileResolver()
            : null);
    final resolvedSegmentCredentialFactory = segmentCredentialFactory ??
        (trustedAnnounceEnforcementEnabled
            ? MeshSegmentCredentialFactory(
                signatureRepository: signatureRepository,
                confidenceService: confidenceService,
                freshnessTracker: freshnessTracker,
              )
            : null);
    final resolvedSegmentRevocationStore = segmentRevocationStore ??
        (GetIt.instance.isRegistered<MeshSegmentRevocationStore>()
            ? GetIt.instance<MeshSegmentRevocationStore>()
            : null);
    final resolvedSegmentCredentialRefreshService =
        segmentCredentialRefreshService ??
            (GetIt.instance.isRegistered<MeshSegmentCredentialRefreshService>()
                ? GetIt.instance<MeshSegmentCredentialRefreshService>()
                : null);
    final resolvedAnnounceAttestationFactory = announceAttestationFactory ??
        (trustedAnnounceEnforcementEnabled
            ? MeshAnnounceAttestationFactory(
                signatureRepository: signatureRepository,
                confidenceService: confidenceService,
                freshnessTracker: freshnessTracker,
              )
            : null);
    final resolvedAnnounceLedger = announceLedger ??
        MeshAnnounceLedger(
          announceValidator: trustedAnnounceEnforcementEnabled
              ? MeshAnnounceValidator(
                  signatureRepository: signatureRepository,
                  revocationPolicy: MeshSegmentRevocationPolicy(
                    revocationStore: resolvedSegmentRevocationStore,
                  ),
                )
              : null,
        );
    return MeshForwardingContext(
      discovery: discovery,
      governanceBindingService: governanceBindingService,
      meshKernel: resolvedMeshKernel,
      packetCodec: resolvedPacketCodec,
      routeLedger: routeLedger ?? MeshRouteLedger(),
      custodyOutbox: custodyOutbox ?? MeshCustodyOutbox(),
      interfaceRegistry: interfaceRegistry ??
          MeshInterfaceRegistry(
            cloudInterfaceAvailable: normalizedPrivacyMode ==
                    MeshTransportPrivacyMode.federatedCloud ||
                normalizedPrivacyMode == MeshTransportPrivacyMode.multiMode,
          ),
      announceLedger: resolvedAnnounceLedger,
      segmentProfileResolver: resolvedSegmentProfileResolver,
      segmentCredentialFactory: resolvedSegmentCredentialFactory,
      segmentCredentialRefreshService: resolvedSegmentCredentialRefreshService,
      segmentRevocationStore: resolvedSegmentRevocationStore,
      announceAttestationFactory: resolvedAnnounceAttestationFactory,
      localUserId: localUserId,
      localAgentId: localAgentId,
      privacyMode: normalizedPrivacyMode,
      reticulumTransportControlPlaneEnabled:
          reticulumTransportControlPlaneEnabled,
      trustedAnnounceEnforcementEnabled: trustedAnnounceEnforcementEnabled,
    );
  }
}

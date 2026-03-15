import 'package:avrai_runtime_os/ai2ai/aipersonality_node.dart';
import 'package:avrai_runtime_os/kernel/mesh/mesh_kernel_contract.dart';
import 'package:avrai_runtime_os/kernel/os/ai2ai_mesh_governance_binding_service.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_announce_ledger.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_announce_attestation_factory.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_custody_outbox.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_forwarding_context.dart';
import 'package:avrai_runtime_os/services/transport/mesh/governed_mesh_packet_codec.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_interface_registry.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_route_ledger.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_segment_credential_factory.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_segment_profile_resolver.dart';
import 'package:avrai_network/avra_network.dart';
import 'package:avrai_network/network/bloom_filter.dart';

class MeshForwardingContextOrchestrationLane {
  const MeshForwardingContextOrchestrationLane._();

  static OptimizedBloomFilter getOrCreateBloomFilter({
    required Map<String, OptimizedBloomFilter> bloomFilters,
    required String scope,
  }) {
    return bloomFilters.putIfAbsent(
      scope,
      () => OptimizedBloomFilter(geographicScope: scope),
    );
  }

  static Iterable<String> discoveredNodeIds({
    required Map<String, AIPersonalityNode> discoveredNodes,
  }) {
    return discoveredNodes.values.map((node) => node.nodeId);
  }

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
    MeshAnnounceAttestationFactory? announceAttestationFactory,
    String? localUserId,
    String? localAgentId,
    String privacyMode = MeshTransportPrivacyMode.privateMesh,
    bool reticulumTransportControlPlaneEnabled = false,
    bool trustedAnnounceEnforcementEnabled = false,
  }) {
    return MeshForwardingContext.tryCreate(
      discovery: discovery,
      governanceBindingService: governanceBindingService,
      meshKernel: meshKernel,
      packetCodec: packetCodec,
      routeLedger: routeLedger,
      custodyOutbox: custodyOutbox,
      interfaceRegistry: interfaceRegistry,
      announceLedger: announceLedger,
      segmentProfileResolver: segmentProfileResolver,
      segmentCredentialFactory: segmentCredentialFactory,
      announceAttestationFactory: announceAttestationFactory,
      localUserId: localUserId,
      localAgentId: localAgentId,
      privacyMode: privacyMode,
      reticulumTransportControlPlaneEnabled:
          reticulumTransportControlPlaneEnabled,
      trustedAnnounceEnforcementEnabled: trustedAnnounceEnforcementEnabled,
    );
  }
}

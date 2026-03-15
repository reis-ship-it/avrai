// ignore_for_file: deprecated_member_use

import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai_core/models/vibe/vibe_models.dart';
import 'package:avrai_runtime_os/ai2ai/canonical_peer_resolution_service.dart';
import 'package:avrai_network/network/ai2ai_protocol.dart';
import 'package:avrai_network/network/message_encryption_service.dart';

abstract class LegacyProtocolCodecAdapter {
  MessageEncryptionService get encryptionService;

  Future<PersonalityProfile?> exchangePersonalityProfile({
    required String remoteDeviceId,
    required PersonalityProfile localPersonality,
  });

  Future<Ai2AiCanonicalPeerPayload?> exchangeCanonicalPeerPayload({
    required String remoteDeviceId,
    required Ai2AiCanonicalPeerPayload localPeerPayload,
  });

  Future<ResolvedPeerVibeContext?> exchangeResolvedPeerContext({
    required String remoteDeviceId,
    required String localAgentId,
    required PersonalityProfile localPersonality,
    required Ai2AiCanonicalPeerPayload localPeerPayload,
  });
}

class Ai2AiProtocolCodecAdapter implements LegacyProtocolCodecAdapter {
  const Ai2AiProtocolCodecAdapter({
    required AI2AIProtocol protocol,
  }) : _protocol = protocol;

  final AI2AIProtocol _protocol;

  @override
  MessageEncryptionService get encryptionService => _protocol.encryptionService;

  @override
  Future<PersonalityProfile?> exchangePersonalityProfile({
    required String remoteDeviceId,
    required PersonalityProfile localPersonality,
  }) {
    return _protocol.exchangePersonalityProfile(
      remoteDeviceId,
      localPersonality,
    );
  }

  @override
  Future<Ai2AiCanonicalPeerPayload?> exchangeCanonicalPeerPayload({
    required String remoteDeviceId,
    required Ai2AiCanonicalPeerPayload localPeerPayload,
  }) {
    return _protocol.exchangeCanonicalPeerPayload(
      remoteDeviceId,
      localPeerPayload,
    );
  }

  @override
  Future<ResolvedPeerVibeContext?> exchangeResolvedPeerContext({
    required String remoteDeviceId,
    required String localAgentId,
    required PersonalityProfile localPersonality,
    required Ai2AiCanonicalPeerPayload localPeerPayload,
  }) async {
    final peerResolutionService = CanonicalPeerResolutionService();
    final canonicalPayload = await exchangeCanonicalPeerPayload(
      remoteDeviceId: remoteDeviceId,
      localPeerPayload: localPeerPayload,
    );
    if (canonicalPayload != null) {
      return peerResolutionService.resolveInboundPayload(
        localAgentId: localAgentId,
        remotePayload: canonicalPayload,
      );
    }

    final legacyProfile = await exchangePersonalityProfile(
      remoteDeviceId: remoteDeviceId,
      localPersonality: localPersonality,
    );
    if (legacyProfile == null) {
      return null;
    }

    return peerResolutionService.resolveLegacyPersonalityProfile(
      localAgentId: localAgentId,
      remoteProfile: legacyProfile,
    );
  }
}

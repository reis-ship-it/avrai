// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'dart:async';
import 'dart:typed_data';

import 'package:avrai_runtime_os/ai/vibe_analysis_engine.dart';
import 'package:avrai_runtime_os/ai2ai/aipersonality_node.dart';
import 'package:avrai_runtime_os/ai2ai/discovery/anonymized_vibe_mapper.dart';
import 'package:avrai_runtime_os/ai2ai/trust/trusted_node_factory.dart';
import 'package:avrai_core/models/user/user_vibe.dart';
import 'package:avrai_core/models/personality_knot.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai_network/avra_network.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai_knot/services/knot/dna_encoder_service.dart';
import 'package:avrai_knot/services/knot/deterministic_matcher_service.dart';
import 'package:avrai_knot/services/knot/personality_knot_service.dart';

class HotDeviceProcessingLane {
  const HotDeviceProcessingLane._();

  static Future<void> process({
    required DiscoveredDevice device,
    required String? currentUserId,
    required PersonalityProfile? currentPersonality,
    required UserVibeAnalyzer vibeAnalyzer,
    required bool allowBleSideEffects,
    required DeviceDiscoveryService? deviceDiscovery,
    required Future<void> Function({
      required DiscoveredDevice device,
      required BleGattSession session,
    }) primeOfflineSignalPreKeyBundleInSession,
    required bool Function(VibeCompatibilityResult compatibility)
        isConnectionWorthy,
    required void Function(List<AIPersonalityNode> nodes) updateDiscoveredNodes,
    required Future<void> Function({
      required String userId,
      required PersonalityProfile localPersonality,
      required List<AIPersonalityNode> nodes,
      required Map<String, VibeCompatibilityResult> compatibilityByNodeId,
    }) maybeApplyPassiveAi2AiLearning,
    Future<void> Function({
      required DiscoveredDevice device,
      required BleGattSession? session,
      required VibeCompatibilityResult compatibility,
    })? maybeSwapPheromones,
    required AppLogger logger,
    required String logName,
    required void Function(int valueMs) onSessionOpenMs,
    required void Function(int valueMs) onVibeReadMs,
    required void Function(int valueMs) onCompatMs,
    required void Function(int valueMs) onTotalMs,
    required void Function() maybeLogHotMetrics,
  }) async {
    final String? userId = currentUserId;
    final PersonalityProfile? personality = currentPersonality;
    if (userId == null || personality == null) return;

    final Stopwatch totalSw = Stopwatch()..start();
    try {
      final UserVibe localVibe =
          await vibeAnalyzer.compileUserVibe(userId, personality);

      AnonymizedVibeData? personalityData = device.personalityData;
      Uint8List? dnaPayload;

      BleGattSession? session;
      if (allowBleSideEffects && device.type == DeviceType.bluetooth) {
        try {
          final Stopwatch openSw = Stopwatch()..start();
          session =
              await BleConnectionPool.instance.openSession(device: device);
          openSw.stop();
          onSessionOpenMs(openSw.elapsedMilliseconds);

          // Phase 0.1 Pivot: Try reading the binary DNA string payload
          final Stopwatch vibeReadSw = Stopwatch()..start();
          final List<int>? vibeBytes =
              await session.readStreamPayload(streamId: 0);
          vibeReadSw.stop();
          onVibeReadMs(vibeReadSw.elapsedMilliseconds);
          
          if (vibeBytes != null && vibeBytes.isNotEmpty) {
            dnaPayload = Uint8List.fromList(vibeBytes);
          }

          await primeOfflineSignalPreKeyBundleInSession(
            device: device,
            session: session,
          );
        } catch (e) {
          logger.debug(
            'Hot-path BLE session failed for ${device.deviceId}: $e',
            tag: logName,
          );
        } finally {
          try {
            await session?.close();
          } catch (_) {
            // Ignore.
          }
        }
      }

      personalityData ??= await deviceDiscovery?.extractPersonalityData(device);
      dnaPayload ??= await deviceDiscovery?.extractDnaPayload(device);

      if (personalityData == null && dnaPayload == null) return;

      PersonalityKnot? decodedKnot;
      if (dnaPayload != null) {
        try {
          final dnaEncoder = DnaEncoderService();
          decodedKnot = dnaEncoder.decode(dnaPayload);
        } catch (e) {
          logger.warn('Failed to decode DNA math string: $e', tag: logName);
        }
      }

      final UserVibe vibe = personalityData != null 
          ? AnonymizedVibeMapper.toUserVibe(personalityData)
          : UserVibe(
              hashedSignature: device.deviceId,
              anonymizedDimensions: {},
              overallEnergy: 0.5,
              socialPreference: 0.5,
              explorationTendency: 0.5,
              createdAt: DateTime.now(),
              expiresAt: DateTime.now().add(const Duration(hours: 1)),
              privacyLevel: 1.0,
              temporalContext: 'unknown',
            );

      final double proximityScore =
          deviceDiscovery?.calculateProximity(device) ?? 0.5;
      final AIPersonalityNode node = TrustedNodeFactory.fromProximity(
        nodeId: device.deviceId,
        vibe: vibe,
        lastSeen: device.discoveredAt,
        proximityScore: proximityScore,
      );

      // We need to pass the knot down so DeterministicMatcherService can score it
      final nodeWithKnot = AIPersonalityNode(
        nodeId: node.nodeId,
        vibe: node.vibe,
        knot: decodedKnot,
        lastSeen: node.lastSeen,
        trustScore: node.trustScore,
        learningHistory: node.learningHistory,
      );

      final Stopwatch compatSw = Stopwatch()..start();
      
      // Phase 0.1 Pivot: If we have a knot, use DeterministicMatcherService
      VibeCompatibilityResult compatibility;
      if (decodedKnot != null) {
        final knotService = GetIt.instance.isRegistered<PersonalityKnotService>()
            ? GetIt.instance<PersonalityKnotService>()
            : PersonalityKnotService();
        final localKnot = await knotService.generateKnot(personality);
        
        final matcher = DeterministicMatcherService();
        final matchScore = matcher.calculateVibeMatch(localKnot, decodedKnot);
        
        // Wrap the raw score in a VibeCompatibilityResult
        compatibility = VibeCompatibilityResult(
          basicCompatibility: matchScore,
          aiPleasurePotential: matchScore, // Approximation
          learningOpportunities: [],
          connectionStrength: matchScore,
          interactionStyle: AI2AIInteractionStyle.focusedExchange,
          trustBuildingPotential: matchScore,
          recommendedConnectionDuration: const Duration(seconds: 300),
          connectionPriority: matchScore > 0.7 ? ConnectionPriority.high : ConnectionPriority.low,
        );
        
        logger.debug('Vibe compatibility via DeterministicMatcher: $matchScore', tag: logName);
      } else {
        compatibility = await vibeAnalyzer.analyzeVibeCompatibility(localVibe, nodeWithKnot.vibe);
      }
      
      compatSw.stop();
      onCompatMs(compatSw.elapsedMilliseconds);
      if (!isConnectionWorthy(compatibility)) return;

      updateDiscoveredNodes(<AIPersonalityNode>[nodeWithKnot]);

      unawaited(maybeApplyPassiveAi2AiLearning(
        userId: userId,
        localPersonality: personality,
        nodes: <AIPersonalityNode>[nodeWithKnot],
        compatibilityByNodeId: <String, VibeCompatibilityResult>{
          nodeWithKnot.nodeId: compatibility,
        },
      ));

      if (maybeSwapPheromones != null) {
        unawaited(maybeSwapPheromones(
          device: device,
          session: session,
          compatibility: compatibility,
        ));
      }
    } catch (e) {
      logger.debug(
        'Hot-path processing failed for ${device.deviceId}: $e',
        tag: logName,
      );
    } finally {
      totalSw.stop();
      onTotalMs(totalSw.elapsedMilliseconds);
      maybeLogHotMetrics();
    }
  }
}

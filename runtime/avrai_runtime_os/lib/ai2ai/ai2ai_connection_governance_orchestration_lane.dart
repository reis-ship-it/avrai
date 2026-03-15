import 'package:avrai_core/models/quantum/connection_metrics.dart';
import 'package:avrai_runtime_os/ai2ai/aipersonality_node.dart';
import 'package:avrai_runtime_os/kernel/os/ai2ai_mesh_governance_binding_service.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';

class Ai2AiConnectionGovernanceOrchestrationLane {
  const Ai2AiConnectionGovernanceOrchestrationLane._();

  static Future<String?> recordPlan({
    required Ai2AiMeshGovernanceBindingService? governanceBindingService,
    required String localUserId,
    required String localAgentId,
    required AIPersonalityNode remoteNode,
    Map<String, dynamic>? canonicalPeerMetadata,
    required AppLogger logger,
    required String logName,
    void Function(String subjectId, String recordId)? onRecorded,
  }) async {
    if (governanceBindingService == null) {
      return null;
    }

    try {
      final now = DateTime.now().toUtc();
      final envelope = KernelEventEnvelope(
        eventId: _eventId('ai2ai-connection-plan'),
        occurredAtUtc: now,
        userId: localUserId,
        agentId: localAgentId,
        sourceSystem: 'vibe_connection_orchestrator',
        eventType: 'ai2ai_connection_plan',
        actionType: 'establish',
        entityId: remoteNode.nodeId,
        entityType: 'ai2ai_connection',
        privacyMode: 'private',
        context: <String, dynamic>{
          'remote_node_id': remoteNode.nodeId,
          'remote_vibe_archetype': remoteNode.vibeArchetype,
          'remote_is_recently_seen': remoteNode.isRecentlySeen,
          'remote_trust_score': _normalized(remoteNode.trustScore),
          'learning_history_size': remoteNode.learningHistory.length,
          if (canonicalPeerMetadata != null)
            'canonical_peer_metadata': canonicalPeerMetadata,
        },
        policyContext: const <String, dynamic>{
          'requires_signal_session': true,
          'governed_runtime_path': true,
        },
      );

      final record = await governanceBindingService.buildAi2AiGovernanceRecord(
        envelope: envelope,
        goal: 'govern_ai2ai_connection',
        predictedOutcome: 'connection_established',
        predictedConfidence: _normalized(remoteNode.trustScore),
        coreSignals: <WhySignal>[
          WhySignal(
            label: 'peer_trust',
            weight: _normalized(remoteNode.trustScore),
            source: 'remote_node',
            durable: true,
          ),
          WhySignal(
            label: 'peer_recently_seen',
            weight: remoteNode.isRecentlySeen ? 0.8 : 0.3,
            source: 'remote_node',
          ),
          ..._canonicalSignals(canonicalPeerMetadata),
        ],
        memoryContext: <String, dynamic>{
          'learning_history_keys': remoteNode.learningHistory.keys.toList(),
          if (canonicalPeerMetadata != null)
            'canonical_reason_codes':
                canonicalPeerMetadata['canonical_reason_codes'],
          if (canonicalPeerMetadata != null)
            'peer_why_summary': canonicalPeerMetadata['peer_why_summary'],
        },
        severity: 'info',
      );

      onRecorded?.call(remoteNode.nodeId, record.recordId);
      logger.debug(
        'Recorded governed AI2AI connection plan for ${remoteNode.nodeId}: ${record.recordId}',
        tag: logName,
      );
      return record.recordId;
    } catch (error, stackTrace) {
      logger.warning(
        'Failed to record governed AI2AI connection plan',
        tag: logName,
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  static Future<String?> recordOutcome({
    required Ai2AiMeshGovernanceBindingService? governanceBindingService,
    required String localUserId,
    required String localAgentId,
    required AIPersonalityNode remoteNode,
    required ConnectionMetrics? connection,
    Map<String, dynamic>? canonicalPeerMetadata,
    String? reason,
    required AppLogger logger,
    required String logName,
    void Function(String subjectId, String recordId)? onRecorded,
  }) async {
    if (governanceBindingService == null) {
      return null;
    }

    try {
      final now = DateTime.now().toUtc();
      final subjectId = connection?.connectionId ?? remoteNode.nodeId;
      final qualityScore =
          connection == null ? 0.0 : _normalized(connection.qualityScore);
      final outcomeLabel = _outcomeLabel(connection, reason: reason);
      final effectiveCanonicalPeerMetadata = canonicalPeerMetadata ??
          _connectionCanonicalPeerMetadata(connection);
      final envelope = KernelEventEnvelope(
        eventId: _eventId('ai2ai-connection-observation'),
        occurredAtUtc: now,
        userId: localUserId,
        agentId: localAgentId,
        sourceSystem: 'vibe_connection_orchestrator',
        eventType: 'ai2ai_connection_observation',
        actionType: connection == null ? 'reject' : 'complete',
        entityId: subjectId,
        entityType: 'ai2ai_connection',
        privacyMode: 'private',
        context: <String, dynamic>{
          'remote_node_id': remoteNode.nodeId,
          'remote_vibe_archetype': remoteNode.vibeArchetype,
          if (reason != null) 'reason': reason,
          if (connection != null) 'connection_summary': connection.getSummary(),
          if (effectiveCanonicalPeerMetadata != null)
            'canonical_peer_metadata': effectiveCanonicalPeerMetadata,
        },
        policyContext: const <String, dynamic>{
          'requires_signal_session': true,
          'governed_runtime_path': true,
        },
      );

      final record = await governanceBindingService.buildAi2AiGovernanceRecord(
        envelope: envelope,
        goal: 'observe_ai2ai_connection',
        actualOutcome: outcomeLabel,
        actualOutcomeScore: qualityScore,
        coreSignals: <WhySignal>[
          WhySignal(
            label: 'peer_trust',
            weight: _normalized(remoteNode.trustScore),
            source: 'remote_node',
            durable: true,
          ),
          WhySignal(
            label: 'connection_quality',
            weight: qualityScore,
            source: 'connection_metrics',
          ),
          ..._canonicalSignals(effectiveCanonicalPeerMetadata),
        ],
        memoryContext: <String, dynamic>{
          'remote_learning_history_size': remoteNode.learningHistory.length,
          if (connection != null) 'connection_status': connection.status.name,
          if (reason != null) 'completion_reason': reason,
          if (effectiveCanonicalPeerMetadata != null)
            'canonical_reason_codes':
                effectiveCanonicalPeerMetadata['canonical_reason_codes'],
          if (effectiveCanonicalPeerMetadata != null)
            'peer_why_summary':
                effectiveCanonicalPeerMetadata['peer_why_summary'],
        },
        severity: connection == null ? 'warning' : 'info',
      );

      onRecorded?.call(subjectId, record.recordId);
      logger.debug(
        'Recorded governed AI2AI connection outcome for $subjectId: ${record.recordId}',
        tag: logName,
      );
      return record.recordId;
    } catch (error, stackTrace) {
      logger.warning(
        'Failed to record governed AI2AI connection outcome',
        tag: logName,
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  static String _eventId(String prefix) =>
      '$prefix-${DateTime.now().toUtc().microsecondsSinceEpoch}';

  static double _normalized(double value) => value.clamp(0.0, 1.0).toDouble();

  static String _outcomeLabel(
    ConnectionMetrics? connection, {
    String? reason,
  }) {
    if (connection == null) {
      return reason ?? 'connection_failed';
    }
    if (reason != null && reason.isNotEmpty) {
      return '${connection.status.name}:$reason';
    }
    return connection.status.name;
  }

  static Map<String, dynamic>? _connectionCanonicalPeerMetadata(
    ConnectionMetrics? connection,
  ) {
    if (connection == null) {
      return null;
    }
    final metadata = <String, dynamic>{};
    for (final key in <String>[
      'canonical_reason_codes',
      'peer_confidence',
      'peer_freshness_hours',
      'shared_geographic_levels',
      'shared_scoped_context_ids',
      'peer_why_summary',
      'legacy_profile_compatibility_only',
    ]) {
      if (connection.learningOutcomes.containsKey(key)) {
        metadata[key] = connection.learningOutcomes[key];
      }
    }
    return metadata.isEmpty ? null : metadata;
  }

  static List<WhySignal> _canonicalSignals(
    Map<String, dynamic>? canonicalPeerMetadata,
  ) {
    if (canonicalPeerMetadata == null) {
      return const <WhySignal>[];
    }

    final signals = <WhySignal>[];
    final reasonCodes =
        (canonicalPeerMetadata['canonical_reason_codes'] as List?)
                ?.map((entry) => entry.toString())
                .toList(growable: false) ??
            const <String>[];
    for (final reasonCode in reasonCodes) {
      signals.add(
        WhySignal(
          label: 'canonical:$reasonCode',
          weight: 0.72,
          source: 'canonical_peer_context',
        ),
      );
    }

    final peerConfidence =
        (canonicalPeerMetadata['peer_confidence'] as num?)?.toDouble();
    if (peerConfidence != null) {
      signals.add(
        WhySignal(
          label: 'peer_confidence',
          weight: _normalized(peerConfidence),
          source: 'canonical_peer_context',
        ),
      );
    }

    final peerFreshnessHours =
        (canonicalPeerMetadata['peer_freshness_hours'] as num?)?.toDouble();
    if (peerFreshnessHours != null) {
      final freshnessWeight =
          (1.0 - (peerFreshnessHours.clamp(0.0, 168.0) / 168.0))
              .clamp(0.0, 1.0);
      signals.add(
        WhySignal(
          label: 'peer_freshness',
          weight: freshnessWeight,
          source: 'canonical_peer_context',
        ),
      );
    }

    return signals;
  }
}

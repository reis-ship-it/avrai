import 'dart:collection';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:avrai_core/schemas/semantic_tuple.dart';
import 'package:avrai_runtime_os/kernel/what/what_kernel_contract.dart';
import 'package:avrai_runtime_os/kernel/what/what_models.dart';
import 'package:avrai_runtime_os/kernel/what/what_observation_intake_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/supabase_service.dart';
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';

abstract class WhatRuntimeIngestionService {
  Future<String?> currentAgentId();

  Future<WhatUpdateReceipt?> ingestSemanticTuples({
    required String source,
    required String entityRef,
    required List<SemanticTuple> tuples,
    String? agentId,
    Map<String, dynamic>? locationContext,
    Map<String, dynamic>? temporalContext,
    String? lineageRef,
  });

  Future<WhatUpdateReceipt?> ingestVisitObservation({
    required String entityRef,
    required DateTime observedAtUtc,
    String? agentId,
    Map<String, dynamic>? structuredSignals,
    Map<String, dynamic>? locationContext,
    Map<String, dynamic>? temporalContext,
    String? socialContext,
    String? activityContext,
    double confidence,
    String? lineageRef,
  });

  Future<WhatUpdateReceipt?> ingestPassiveDwellObservation({
    required String entityRef,
    required DateTime observedAtUtc,
    String? agentId,
    List<SemanticTuple> semanticTuples,
    Map<String, dynamic>? structuredSignals,
    Map<String, dynamic>? locationContext,
    Map<String, dynamic>? temporalContext,
    String? socialContext,
    String? activityContext,
    double confidence,
    String? lineageRef,
  });

  Future<WhatUpdateReceipt?> ingestAmbientSocialObservation({
    required String entityRef,
    required DateTime observedAtUtc,
    String? agentId,
    List<SemanticTuple> semanticTuples,
    Map<String, dynamic>? structuredSignals,
    Map<String, dynamic>? locationContext,
    Map<String, dynamic>? temporalContext,
    String? socialContext,
    String? activityContext,
    double confidence,
    String? lineageRef,
  });

  Future<WhatUpdateReceipt?> ingestEventAttendanceObservation({
    required String entityRef,
    required DateTime observedAtUtc,
    String? agentId,
    List<SemanticTuple> semanticTuples,
    Map<String, dynamic>? structuredSignals,
    Map<String, dynamic>? locationContext,
    Map<String, dynamic>? temporalContext,
    String? socialContext,
    String? activityContext,
    double confidence,
    String? lineageRef,
  });

  Future<WhatUpdateReceipt?> ingestListInteractionObservation({
    required String entityRef,
    required DateTime observedAtUtc,
    String? agentId,
    List<SemanticTuple> semanticTuples,
    Map<String, dynamic>? structuredSignals,
    Map<String, dynamic>? locationContext,
    Map<String, dynamic>? temporalContext,
    String? socialContext,
    String? activityContext,
    double confidence,
    String? lineageRef,
  });

  Future<WhatUpdateReceipt?> ingestPluginSemanticObservation({
    required String source,
    required String entityRef,
    required DateTime observedAtUtc,
    String? agentId,
    List<SemanticTuple> semanticTuples,
    Map<String, dynamic>? structuredSignals,
    Map<String, dynamic>? locationContext,
    Map<String, dynamic>? temporalContext,
    String? socialContext,
    String? activityContext,
    double confidence,
    String? lineageRef,
  });
}

class DefaultWhatRuntimeIngestionService
    implements WhatRuntimeIngestionService {
  static const String _logName = 'WhatRuntimeIngestionService';

  final WhatKernelContract _kernel;
  final WhatObservationIntakeService _intake;
  final AgentIdService? _agentIdService;
  final SupabaseService? _supabaseService;

  const DefaultWhatRuntimeIngestionService({
    required WhatKernelContract kernel,
    required WhatObservationIntakeService intake,
    AgentIdService? agentIdService,
    SupabaseService? supabaseService,
  })  : _kernel = kernel,
        _intake = intake,
        _agentIdService = agentIdService,
        _supabaseService = supabaseService;

  @override
  Future<String?> currentAgentId() async {
    final userId = _supabaseService?.currentUser?.id;
    if (userId == null || userId.isEmpty || _agentIdService == null) {
      return null;
    }
    try {
      return await _agentIdService.getUserAgentId(userId);
    } catch (error, stackTrace) {
      developer.log(
        'Failed resolving current agent id: $error',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  @override
  Future<WhatUpdateReceipt?> ingestSemanticTuples({
    required String source,
    required String entityRef,
    required List<SemanticTuple> tuples,
    String? agentId,
    Map<String, dynamic>? locationContext,
    Map<String, dynamic>? temporalContext,
    String? lineageRef,
  }) async {
    final resolvedAgentId = await _resolveAgentId(agentId);
    if (resolvedAgentId == null || tuples.isEmpty) {
      _logSkipped(
        source: source,
        entityRef: entityRef,
        reason: tuples.isEmpty ? 'no_semantic_tuples' : 'agent_id_unavailable',
      );
      return null;
    }

    final observation = _intake.fromSemanticTuples(
      agentId: resolvedAgentId,
      source: source,
      entityRef: entityRef,
      tuples: tuples,
      locationContext: locationContext,
      temporalContext: temporalContext,
      lineageRef: lineageRef,
    );
    return _kernel.observeWhat(observation);
  }

  @override
  Future<WhatUpdateReceipt?> ingestVisitObservation({
    required String entityRef,
    required DateTime observedAtUtc,
    String? agentId,
    Map<String, dynamic>? structuredSignals,
    Map<String, dynamic>? locationContext,
    Map<String, dynamic>? temporalContext,
    String? socialContext,
    String? activityContext,
    double confidence = 0.62,
    String? lineageRef,
  }) {
    return _ingestStructuredObservation(
      source: 'visit_runtime',
      entityRef: entityRef,
      observedAtUtc: observedAtUtc,
      agentId: agentId,
      kind: WhatObservationKind.visit,
      semanticTuples: const <SemanticTuple>[],
      structuredSignals: structuredSignals,
      locationContext: locationContext,
      temporalContext: temporalContext,
      socialContext: socialContext,
      activityContext: activityContext,
      confidence: confidence,
      lineageRef: lineageRef,
    );
  }

  @override
  Future<WhatUpdateReceipt?> ingestPassiveDwellObservation({
    required String entityRef,
    required DateTime observedAtUtc,
    String? agentId,
    List<SemanticTuple> semanticTuples = const <SemanticTuple>[],
    Map<String, dynamic>? structuredSignals,
    Map<String, dynamic>? locationContext,
    Map<String, dynamic>? temporalContext,
    String? socialContext,
    String? activityContext,
    double confidence = 0.58,
    String? lineageRef,
  }) {
    return _ingestStructuredObservation(
      source: 'passive_dwell_runtime',
      entityRef: entityRef,
      observedAtUtc: observedAtUtc,
      agentId: agentId,
      kind: WhatObservationKind.passiveDwell,
      semanticTuples: semanticTuples,
      structuredSignals: structuredSignals,
      locationContext: locationContext,
      temporalContext: temporalContext,
      socialContext: socialContext,
      activityContext: activityContext,
      confidence: confidence,
      lineageRef: lineageRef,
    );
  }

  @override
  Future<WhatUpdateReceipt?> ingestAmbientSocialObservation({
    required String entityRef,
    required DateTime observedAtUtc,
    String? agentId,
    List<SemanticTuple> semanticTuples = const <SemanticTuple>[],
    Map<String, dynamic>? structuredSignals,
    Map<String, dynamic>? locationContext,
    Map<String, dynamic>? temporalContext,
    String? socialContext,
    String? activityContext,
    double confidence = 0.64,
    String? lineageRef,
  }) {
    return _ingestStructuredObservation(
      source: 'ambient_social_runtime',
      entityRef: entityRef,
      observedAtUtc: observedAtUtc,
      agentId: agentId,
      kind: WhatObservationKind.ambientSocialEvent,
      semanticTuples: semanticTuples,
      structuredSignals: structuredSignals,
      locationContext: locationContext,
      temporalContext: temporalContext,
      socialContext: socialContext,
      activityContext: activityContext,
      confidence: confidence,
      lineageRef: lineageRef,
    );
  }

  @override
  Future<WhatUpdateReceipt?> ingestEventAttendanceObservation({
    required String entityRef,
    required DateTime observedAtUtc,
    String? agentId,
    List<SemanticTuple> semanticTuples = const <SemanticTuple>[],
    Map<String, dynamic>? structuredSignals,
    Map<String, dynamic>? locationContext,
    Map<String, dynamic>? temporalContext,
    String? socialContext,
    String? activityContext,
    double confidence = 0.64,
    String? lineageRef,
  }) {
    return _ingestStructuredObservation(
      source: 'event_attendance_runtime',
      entityRef: entityRef,
      observedAtUtc: observedAtUtc,
      agentId: agentId,
      kind: WhatObservationKind.eventAttendance,
      semanticTuples: semanticTuples,
      structuredSignals: structuredSignals,
      locationContext: locationContext,
      temporalContext: temporalContext,
      socialContext: socialContext,
      activityContext: activityContext,
      confidence: confidence,
      lineageRef: lineageRef,
    );
  }

  @override
  Future<WhatUpdateReceipt?> ingestListInteractionObservation({
    required String entityRef,
    required DateTime observedAtUtc,
    String? agentId,
    List<SemanticTuple> semanticTuples = const <SemanticTuple>[],
    Map<String, dynamic>? structuredSignals,
    Map<String, dynamic>? locationContext,
    Map<String, dynamic>? temporalContext,
    String? socialContext,
    String? activityContext,
    double confidence = 0.57,
    String? lineageRef,
  }) {
    return _ingestStructuredObservation(
      source: 'list_interaction_runtime',
      entityRef: entityRef,
      observedAtUtc: observedAtUtc,
      agentId: agentId,
      kind: WhatObservationKind.listInteraction,
      semanticTuples: semanticTuples,
      structuredSignals: structuredSignals,
      locationContext: locationContext,
      temporalContext: temporalContext,
      socialContext: socialContext,
      activityContext: activityContext,
      confidence: confidence,
      lineageRef: lineageRef,
    );
  }

  @override
  Future<WhatUpdateReceipt?> ingestPluginSemanticObservation({
    required String source,
    required String entityRef,
    required DateTime observedAtUtc,
    String? agentId,
    List<SemanticTuple> semanticTuples = const <SemanticTuple>[],
    Map<String, dynamic>? structuredSignals,
    Map<String, dynamic>? locationContext,
    Map<String, dynamic>? temporalContext,
    String? socialContext,
    String? activityContext,
    double confidence = 0.6,
    String? lineageRef,
  }) {
    return _ingestStructuredObservation(
      source: source,
      entityRef: entityRef,
      observedAtUtc: observedAtUtc,
      agentId: agentId,
      kind: WhatObservationKind.pluginSemanticEvent,
      semanticTuples: semanticTuples,
      structuredSignals: structuredSignals,
      locationContext: locationContext,
      temporalContext: temporalContext,
      socialContext: socialContext,
      activityContext: activityContext,
      confidence: confidence,
      lineageRef: lineageRef,
    );
  }

  Future<WhatUpdateReceipt?> _ingestStructuredObservation({
    required String source,
    required String entityRef,
    required DateTime observedAtUtc,
    required WhatObservationKind kind,
    required List<SemanticTuple> semanticTuples,
    String? agentId,
    Map<String, dynamic>? structuredSignals,
    Map<String, dynamic>? locationContext,
    Map<String, dynamic>? temporalContext,
    String? socialContext,
    String? activityContext,
    required double confidence,
    String? lineageRef,
  }) async {
    final resolvedAgentId = await _resolveAgentId(agentId);
    if (resolvedAgentId == null) {
      _logSkipped(
        source: source,
        entityRef: entityRef,
        reason: 'agent_id_unavailable',
      );
      return null;
    }

    final observation = _intake.fromStructuredEvent(
      agentId: resolvedAgentId,
      source: source,
      entityRef: entityRef,
      kind: kind,
      observedAtUtc: observedAtUtc,
      semanticTuples: semanticTuples,
      structuredSignals: structuredSignals,
      locationContext: locationContext,
      temporalContext: temporalContext,
      socialContext: socialContext,
      activityContext: activityContext,
      confidence: confidence,
      lineageRef: lineageRef,
    );
    return _kernel.observeWhat(observation);
  }

  Future<String?> _resolveAgentId(String? agentId) async {
    if (agentId != null && agentId.isNotEmpty) {
      return agentId;
    }
    return currentAgentId();
  }

  void _logSkipped({
    required String source,
    required String entityRef,
    required String reason,
  }) {
    developer.log(
      'Skipping what ingestion for $source/$entityRef because $reason',
      name: _logName,
    );
  }

  static String deterministicEntityRef(
    String namespace,
    Map<String, Object?> identityParts,
  ) {
    final canonicalIdentity = SplayTreeMap<String, Object?>.from(identityParts);
    final encoded = jsonEncode(canonicalIdentity);
    return '$namespace:${encoded.hashCode.toUnsigned(32)}';
  }
}

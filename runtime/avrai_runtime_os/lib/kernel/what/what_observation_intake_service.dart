import 'package:avrai_core/schemas/semantic_tuple.dart';
import 'package:avrai_runtime_os/kernel/what/what_models.dart';

class WhatObservationIntakeService {
  const WhatObservationIntakeService();

  WhatObservation fromSemanticTuples({
    required String agentId,
    required String source,
    required String entityRef,
    required List<SemanticTuple> tuples,
    Map<String, dynamic>? locationContext,
    Map<String, dynamic>? temporalContext,
    String? lineageRef,
  }) {
    return WhatObservation(
      agentId: agentId,
      observedAtUtc: _latestTupleTime(tuples),
      source: source,
      entityRef: entityRef,
      observationKind: WhatObservationKind.tupleIntake,
      semanticTuples: tuples
          .map(
            (tuple) => WhatSemanticTuple(
              category: tuple.category,
              subject: tuple.subject,
              predicate: tuple.predicate,
              object: tuple.object,
              confidence: tuple.confidence,
              extractedAt: tuple.extractedAt.toUtc(),
            ),
          )
          .toList(growable: false),
      locationContext: locationContext,
      temporalContext: temporalContext,
      confidence: _averageConfidence(tuples),
      lineageRef: lineageRef,
    );
  }

  WhatObservation fromStructuredEvent({
    required String agentId,
    required String source,
    required String entityRef,
    required WhatObservationKind kind,
    required DateTime observedAtUtc,
    List<SemanticTuple> semanticTuples = const [],
    Map<String, dynamic>? structuredSignals,
    Map<String, dynamic>? locationContext,
    Map<String, dynamic>? temporalContext,
    String? socialContext,
    String? activityContext,
    double confidence = 0.42,
    String? lineageRef,
  }) {
    return WhatObservation(
      agentId: agentId,
      observedAtUtc: observedAtUtc.toUtc(),
      source: source,
      entityRef: entityRef,
      observationKind: kind,
      semanticTuples: semanticTuples
          .map(
            (tuple) => WhatSemanticTuple(
              category: tuple.category,
              subject: tuple.subject,
              predicate: tuple.predicate,
              object: tuple.object,
              confidence: tuple.confidence,
              extractedAt: tuple.extractedAt.toUtc(),
            ),
          )
          .toList(growable: false),
      structuredSignals: structuredSignals,
      locationContext: locationContext,
      temporalContext: temporalContext,
      socialContext: socialContext,
      activityContext: activityContext,
      confidence: confidence,
      lineageRef: lineageRef,
    );
  }

  DateTime _latestTupleTime(List<SemanticTuple> tuples) {
    if (tuples.isEmpty) {
      return DateTime.now().toUtc();
    }
    return tuples
        .map((tuple) => tuple.extractedAt.toUtc())
        .reduce((left, right) => left.isAfter(right) ? left : right);
  }

  double _averageConfidence(List<SemanticTuple> tuples) {
    if (tuples.isEmpty) {
      return 0.42;
    }
    return tuples
            .map((tuple) => tuple.confidence)
            .reduce((left, right) => left + right) /
        tuples.length;
  }
}

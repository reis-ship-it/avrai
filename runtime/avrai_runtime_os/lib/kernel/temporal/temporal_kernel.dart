import 'package:avrai_core/avra_core.dart';

class TemporalSnapshotRequest {
  const TemporalSnapshotRequest({
    this.effectiveAt,
    this.expiresAt,
    this.lineageRef,
    this.cadence,
  });

  final TemporalInstant? effectiveAt;
  final TemporalInstant? expiresAt;
  final String? lineageRef;
  final TemporalCadence? cadence;
}

class TemporalFreshnessResult {
  const TemporalFreshnessResult({
    required this.age,
    required this.isFresh,
    required this.isFromFuture,
  });

  final Duration age;
  final bool isFresh;
  final bool isFromFuture;
}

enum TemporalOrderingRelation {
  before,
  after,
  equal,
  concurrent,
  incomparable,
}

class TemporalOrderingResult {
  const TemporalOrderingResult({
    required this.relation,
    required this.delta,
  });

  final TemporalOrderingRelation relation;
  final Duration delta;
}

class HistoricalTemporalEvidenceReceipt {
  const HistoricalTemporalEvidenceReceipt({
    required this.evidenceId,
    required this.recordedAt,
  });

  final String evidenceId;
  final TemporalInstant recordedAt;
}

class ForecastTemporalClaimReceipt {
  const ForecastTemporalClaimReceipt({
    required this.claimId,
    required this.recordedAt,
  });

  final String claimId;
  final TemporalInstant recordedAt;
}

class HistoricalTemporalEvidenceLookup {
  const HistoricalTemporalEvidenceLookup({
    required this.evidence,
    required this.recordedAt,
  });

  final HistoricalTemporalEvidence evidence;
  final TemporalInstant recordedAt;
}

class ForecastTemporalClaimLookup {
  const ForecastTemporalClaimLookup({
    required this.claim,
    required this.recordedAt,
  });

  final ForecastTemporalClaim claim;
  final TemporalInstant recordedAt;
}

class RuntimeTemporalEventReceipt {
  const RuntimeTemporalEventReceipt({
    required this.eventId,
    required this.recordedAt,
  });

  final String eventId;
  final TemporalInstant recordedAt;
}

class RuntimeTemporalEventLookup {
  const RuntimeTemporalEventLookup({
    required this.event,
    required this.recordedAt,
  });

  final RuntimeTemporalEvent event;
  final TemporalInstant recordedAt;
}

class RuntimeTemporalEventQuery {
  const RuntimeTemporalEventQuery({
    this.source,
    this.stage,
    this.peerId,
    this.occurredAfter,
    this.occurredBefore,
    this.limit = 50,
  });

  final String? source;
  final RuntimeTemporalEventStage? stage;
  final String? peerId;
  final DateTime? occurredAfter;
  final DateTime? occurredBefore;
  final int limit;

  Map<String, dynamic> toJson() {
    return {
      'source': source,
      'stage': stage?.name,
      'peerId': peerId,
      'occurredAfter': occurredAfter?.toUtc().toIso8601String(),
      'occurredBefore': occurredBefore?.toUtc().toIso8601String(),
      'limit': limit,
    };
  }
}

abstract class TemporalKernel {
  Future<TemporalInstant> nowMonotonic();
  Future<TemporalInstant> nowCivil();
  Future<TemporalSnapshot> snapshot(TemporalSnapshotRequest request);
  Future<TemporalOrderingResult> compare(
    TemporalSnapshot left,
    TemporalSnapshot right,
  );
  Future<TemporalFreshnessResult> freshnessOf(
    TemporalSnapshot snapshot,
    TemporalFreshnessPolicy policy,
  );
  Future<bool> isExpired(
    TemporalSnapshot snapshot,
    TemporalFreshnessPolicy policy,
  );
  Future<HistoricalTemporalEvidenceReceipt> recordHistoricalEvidence(
    HistoricalTemporalEvidence evidence,
  );
  Future<ForecastTemporalClaimReceipt> recordForecast(
    ForecastTemporalClaim claim,
  );
  Future<HistoricalTemporalEvidenceLookup?> getHistoricalEvidence(
    String evidenceId,
  );
  Future<ForecastTemporalClaimLookup?> getForecast(
    String claimId,
  );
  Future<RuntimeTemporalEventReceipt> recordRuntimeEvent(
    RuntimeTemporalEvent event,
  );
  Future<RuntimeTemporalEventLookup?> getRuntimeEvent(
    String eventId,
  );
  Future<List<RuntimeTemporalEventLookup>> queryRuntimeEvents(
    RuntimeTemporalEventQuery query,
  );
}

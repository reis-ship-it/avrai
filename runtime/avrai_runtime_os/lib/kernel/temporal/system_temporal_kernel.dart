import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/kernel/temporal/temporal_kernel.dart';

class SystemTemporalKernel implements TemporalKernel {
  SystemTemporalKernel({
    required ClockSource clockSource,
  }) : _clockSource = clockSource;

  final ClockSource _clockSource;
  final Map<String, HistoricalTemporalEvidenceLookup> _historicalEvidence =
      <String, HistoricalTemporalEvidenceLookup>{};
  final Map<String, ForecastTemporalClaimLookup> _forecasts =
      <String, ForecastTemporalClaimLookup>{};
  final Map<String, RuntimeTemporalEventLookup> _runtimeEvents =
      <String, RuntimeTemporalEventLookup>{};

  @override
  Future<TemporalInstant> nowCivil() {
    return _clockSource.now();
  }

  @override
  Future<TemporalInstant> nowMonotonic() {
    return _clockSource.now();
  }

  @override
  Future<TemporalSnapshot> snapshot(TemporalSnapshotRequest request) async {
    final now = await _clockSource.now();
    final effectiveAt = request.effectiveAt ?? now;
    return TemporalSnapshot(
      observedAt: now,
      recordedAt: now,
      effectiveAt: effectiveAt,
      expiresAt: request.expiresAt,
      semanticBand: _semanticBandFor(now.civilTime),
      cadence: request.cadence,
      lineageRef: request.lineageRef,
    );
  }

  @override
  Future<TemporalFreshnessResult> freshnessOf(
    TemporalSnapshot snapshot,
    TemporalFreshnessPolicy policy,
  ) async {
    final now = await _clockSource.now();
    final age = now.referenceTime.difference(snapshot.observedAt.referenceTime);
    final isFromFuture = age.isNegative;
    final normalizedAge = isFromFuture ? age.abs() : age;
    final isFresh = !isFromFuture
        ? normalizedAge <= policy.maxAge
        : normalizedAge <= policy.maxFutureSkew;
    return TemporalFreshnessResult(
      age: age,
      isFresh: isFresh,
      isFromFuture: isFromFuture,
    );
  }

  @override
  Future<TemporalOrderingResult> compare(
    TemporalSnapshot left,
    TemporalSnapshot right,
  ) async {
    final delta = left.observedAt.referenceTime
        .difference(right.observedAt.referenceTime);
    final absDelta = delta.abs();
    final leftWindow = left.observedAt.uncertainty.window;
    final rightWindow = right.observedAt.uncertainty.window;
    final overlapWindow = leftWindow + rightWindow;

    if (absDelta <= overlapWindow) {
      return TemporalOrderingResult(
        relation: TemporalOrderingRelation.concurrent,
        delta: delta,
      );
    }
    if (delta.isNegative) {
      return TemporalOrderingResult(
        relation: TemporalOrderingRelation.before,
        delta: delta,
      );
    }
    if (delta > Duration.zero) {
      return TemporalOrderingResult(
        relation: TemporalOrderingRelation.after,
        delta: delta,
      );
    }
    return TemporalOrderingResult(
      relation: TemporalOrderingRelation.equal,
      delta: delta,
    );
  }

  @override
  Future<bool> isExpired(
    TemporalSnapshot snapshot,
    TemporalFreshnessPolicy policy,
  ) async {
    final expiresAt = snapshot.expiresAt;
    if (expiresAt != null) {
      final now = await _clockSource.now();
      return !now.referenceTime.isBefore(expiresAt.referenceTime);
    }
    final freshness = await freshnessOf(snapshot, policy);
    return !freshness.isFresh;
  }

  @override
  Future<HistoricalTemporalEvidenceReceipt> recordHistoricalEvidence(
    HistoricalTemporalEvidence evidence,
  ) async {
    final now = await _clockSource.now();
    _historicalEvidence[evidence.evidenceId] = HistoricalTemporalEvidenceLookup(
      evidence: evidence,
      recordedAt: now,
    );
    return HistoricalTemporalEvidenceReceipt(
      evidenceId: evidence.evidenceId,
      recordedAt: now,
    );
  }

  @override
  Future<ForecastTemporalClaimReceipt> recordForecast(
    ForecastTemporalClaim claim,
  ) async {
    final now = await _clockSource.now();
    _forecasts[claim.claimId] = ForecastTemporalClaimLookup(
      claim: claim,
      recordedAt: now,
    );
    return ForecastTemporalClaimReceipt(
      claimId: claim.claimId,
      recordedAt: now,
    );
  }

  @override
  Future<HistoricalTemporalEvidenceLookup?> getHistoricalEvidence(
    String evidenceId,
  ) async {
    return _historicalEvidence[evidenceId];
  }

  @override
  Future<ForecastTemporalClaimLookup?> getForecast(String claimId) async {
    return _forecasts[claimId];
  }

  @override
  Future<RuntimeTemporalEventReceipt> recordRuntimeEvent(
    RuntimeTemporalEvent event,
  ) async {
    final now = await _clockSource.now();
    _runtimeEvents[event.eventId] = RuntimeTemporalEventLookup(
      event: event,
      recordedAt: now,
    );
    return RuntimeTemporalEventReceipt(
      eventId: event.eventId,
      recordedAt: now,
    );
  }

  @override
  Future<RuntimeTemporalEventLookup?> getRuntimeEvent(String eventId) async {
    return _runtimeEvents[eventId];
  }

  @override
  Future<List<RuntimeTemporalEventLookup>> queryRuntimeEvents(
    RuntimeTemporalEventQuery query,
  ) async {
    final filtered = _runtimeEvents.values.where((entry) {
      if (query.source != null && entry.event.source != query.source) {
        return false;
      }
      if (query.stage != null && entry.event.stage != query.stage) {
        return false;
      }
      if (query.peerId != null && entry.event.peerId != query.peerId) {
        return false;
      }
      if (query.occurredAfter != null &&
          !entry.event.occurredAt.isAfter(query.occurredAfter!)) {
        return false;
      }
      if (query.occurredBefore != null &&
          !entry.event.occurredAt.isBefore(query.occurredBefore!)) {
        return false;
      }
      return true;
    }).toList()
      ..sort((a, b) => b.event.occurredAt.compareTo(a.event.occurredAt));

    if (filtered.length <= query.limit) {
      return filtered;
    }
    return filtered.sublist(0, query.limit);
  }

  SemanticTimeBand _semanticBandFor(DateTime localTime) {
    final hour = localTime.hour;
    if (hour >= 5 && hour < 7) {
      return SemanticTimeBand.dawn;
    }
    if (hour >= 7 && hour < 12) {
      return SemanticTimeBand.morning;
    }
    if (hour >= 12 && hour < 13) {
      return SemanticTimeBand.noon;
    }
    if (hour >= 13 && hour < 17) {
      return SemanticTimeBand.afternoon;
    }
    if (hour >= 17 && hour < 19) {
      return SemanticTimeBand.dusk;
    }
    if (hour >= 19 && hour < 20) {
      return SemanticTimeBand.goldenHour;
    }
    return SemanticTimeBand.night;
  }
}

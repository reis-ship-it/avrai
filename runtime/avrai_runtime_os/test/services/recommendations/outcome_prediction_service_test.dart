import 'package:avrai_core/models/spots/spot_vibe.dart';
import 'package:avrai_core/models/user/user_vibe.dart';
import 'package:avrai_core/models/temporal/forecast_temporal_claim.dart';
import 'package:avrai_core/models/temporal/historical_temporal_evidence.dart';
import 'package:avrai_core/models/temporal/runtime_temporal_event.dart';
import 'package:avrai_core/models/temporal/temporal_freshness_policy.dart';
import 'package:avrai_core/models/temporal/temporal_instant.dart';
import 'package:avrai_core/models/temporal/temporal_snapshot.dart';
import 'package:avrai_runtime_os/ml/outcome_prediction_model.dart';
import 'package:avrai_runtime_os/kernel/temporal/temporal_kernel.dart';
import 'package:avrai_runtime_os/services/admin/temporal_kernel_admin_service.dart';
import 'package:avrai_runtime_os/services/calling_score/calling_score_calculator.dart';
import 'package:avrai_runtime_os/services/recommendations/outcome_prediction_service.dart';
import 'package:avrai_runtime_os/services/temporal/runtime_temporal_context_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('temporal ordering pressure increases predicted outcome', () async {
    final service = OutcomePredictionService(
      model: _FakeOutcomePredictionModel(baseProbability: 0.5),
      runtimeTemporalContextService: RuntimeTemporalContextService(
        temporalKernelAdminService: _StubTemporalKernelAdminService(
          totalEvents: 10,
          orderedCount: 8,
          bufferedCount: 1,
          uniquePeerCount: 4,
        ),
      ),
    );

    final probability = await service.predictOutcome(
      userVibe: _userVibe(),
      spotVibe: _spotVibe(),
      context: CallingContext.empty(),
      timingFactors: TimingFactors.empty(),
    );

    expect(probability, greaterThan(0.5));
  });

  test('buffered pressure decreases predicted outcome', () async {
    final service = OutcomePredictionService(
      model: _FakeOutcomePredictionModel(baseProbability: 0.5),
      runtimeTemporalContextService: RuntimeTemporalContextService(
        temporalKernelAdminService: _StubTemporalKernelAdminService(
          totalEvents: 10,
          orderedCount: 1,
          bufferedCount: 7,
          uniquePeerCount: 0,
        ),
      ),
    );

    final probability = await service.predictOutcome(
      userVibe: _userVibe(),
      spotVibe: _spotVibe(),
      context: CallingContext.empty(),
      timingFactors: TimingFactors.empty(),
    );

    expect(probability, lessThan(0.5));
  });
}

class _FakeOutcomePredictionModel extends OutcomePredictionModel {
  _FakeOutcomePredictionModel({
    required this.baseProbability,
  });

  final double baseProbability;

  @override
  Future<double> predict({
    required List<double> baseFeatures,
    required List<double> historyFeatures,
  }) async {
    return baseProbability;
  }
}

class _StubTemporalKernelAdminService extends TemporalKernelAdminService {
  _StubTemporalKernelAdminService({
    required this.totalEvents,
    required this.orderedCount,
    required this.bufferedCount,
    required this.uniquePeerCount,
  }) : super(temporalKernel: _UnsupportedTemporalKernel());

  final int totalEvents;
  final int orderedCount;
  final int bufferedCount;
  final int uniquePeerCount;

  @override
  Future<TemporalRuntimeEventSnapshot> getRuntimeEventSnapshot({
    String source = 'ai2ai_protocol',
    String? peerId,
    Duration lookbackWindow = const Duration(minutes: 15),
    int limit = 200,
  }) async {
    return TemporalRuntimeEventSnapshot(
      generatedAt: DateTime.utc(2026, 3, 6, 12),
      windowStart: DateTime.utc(2026, 3, 6, 11, 45),
      windowEnd: DateTime.utc(2026, 3, 6, 12),
      totalEvents: totalEvents,
      encodedCount: 0,
      decodedCount: 0,
      bufferedCount: bufferedCount,
      orderedCount: orderedCount,
      uniquePeerCount: uniquePeerCount,
      latestOccurredAt: DateTime.utc(2026, 3, 6, 11, 59),
      recentEvents: const [],
      topPeers: [
        TemporalRuntimeEventPeerSummary(
          peerId: 'peer-a',
          eventCount: totalEvents,
          orderedCount: orderedCount,
          bufferedCount: bufferedCount,
          latestOccurredAt: DateTime.utc(2026, 3, 6, 11, 59),
        ),
      ],
    );
  }
}

class _UnsupportedTemporalKernel implements TemporalKernel {
  @override
  Future<TemporalOrderingResult> compare(
    TemporalSnapshot left,
    TemporalSnapshot right,
  ) =>
      throw UnimplementedError();

  @override
  Future<TemporalFreshnessResult> freshnessOf(
    TemporalSnapshot snapshot,
    TemporalFreshnessPolicy policy,
  ) =>
      throw UnimplementedError();

  @override
  Future<ForecastTemporalClaimLookup?> getForecast(String claimId) =>
      throw UnimplementedError();

  @override
  Future<HistoricalTemporalEvidenceLookup?> getHistoricalEvidence(
    String evidenceId,
  ) =>
      throw UnimplementedError();

  @override
  Future<RuntimeTemporalEventLookup?> getRuntimeEvent(String eventId) =>
      throw UnimplementedError();

  @override
  Future<bool> isExpired(
    TemporalSnapshot snapshot,
    TemporalFreshnessPolicy policy,
  ) =>
      throw UnimplementedError();

  @override
  Future<TemporalInstant> nowCivil() => throw UnimplementedError();

  @override
  Future<TemporalInstant> nowMonotonic() => throw UnimplementedError();

  @override
  Future<List<RuntimeTemporalEventLookup>> queryRuntimeEvents(
    RuntimeTemporalEventQuery query,
  ) =>
      throw UnimplementedError();

  @override
  Future<ForecastTemporalClaimReceipt> recordForecast(
    ForecastTemporalClaim claim,
  ) =>
      throw UnimplementedError();

  @override
  Future<HistoricalTemporalEvidenceReceipt> recordHistoricalEvidence(
    HistoricalTemporalEvidence evidence,
  ) =>
      throw UnimplementedError();

  @override
  Future<RuntimeTemporalEventReceipt> recordRuntimeEvent(
    RuntimeTemporalEvent event,
  ) =>
      throw UnimplementedError();

  @override
  Future<TemporalSnapshot> snapshot(TemporalSnapshotRequest request) =>
      throw UnimplementedError();
}

UserVibe _userVibe() {
  return UserVibe(
    hashedSignature: 'user-1-signature',
    anonymizedDimensions: const {
      'exploration_eagerness': 0.5,
      'community_orientation': 0.5,
      'location_adventurousness': 0.5,
      'authenticity_preference': 0.5,
      'trust_network_reliance': 0.5,
      'temporal_flexibility': 0.5,
      'energy_preference': 0.5,
      'novelty_seeking': 0.5,
      'value_orientation': 0.5,
      'crowd_tolerance': 0.5,
      'social_preference': 0.5,
      'overall_energy': 0.5,
    },
    overallEnergy: 0.5,
    socialPreference: 0.5,
    explorationTendency: 0.5,
    createdAt: DateTime.utc(2026, 3, 6, 12),
    expiresAt: DateTime.utc(2026, 4, 6, 12),
    privacyLevel: 0.8,
    temporalContext: 'midday',
  );
}

SpotVibe _spotVibe() {
  return SpotVibe(
    spotId: 'spot-1',
    vibeDimensions: const {
      'exploration_eagerness': 0.5,
      'community_orientation': 0.5,
      'location_adventurousness': 0.5,
      'authenticity_preference': 0.5,
      'trust_network_reliance': 0.5,
      'temporal_flexibility': 0.5,
      'energy_preference': 0.5,
      'novelty_seeking': 0.5,
      'value_orientation': 0.5,
      'crowd_tolerance': 0.5,
      'social_preference': 0.5,
      'overall_energy': 0.5,
    },
    vibeDescription: 'Balanced neighborhood cafe',
    overallEnergy: 0.5,
    socialPreference: 0.5,
    explorationTendency: 0.5,
    createdAt: DateTime.utc(2026, 3, 6, 12),
    updatedAt: DateTime.utc(2026, 3, 6, 12),
  );
}

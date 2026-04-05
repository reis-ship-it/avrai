import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_projection_service.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_state.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_token.dart';

void main() {
  group('LocalityProjectionService', () {
    final service = LocalityProjectionService();
    final state = LocalityState(
      activeToken: const LocalityToken(
        kind: LocalityTokenKind.geohashCell,
        id: 'gh7:dr4e9x1',
        precision: 7,
        alias: 'Avondale',
      ),
      embedding: List<double>.filled(12, 0.6),
      confidence: 0.82,
      boundaryTension: 0.61,
      reliabilityTier: LocalityReliabilityTier.established,
      freshness: DateTime.utc(2026, 3, 6),
      evidenceCount: 14,
      evolutionRate: 0.13,
      advisoryStatus: LocalityAdvisoryStatus.eligible,
      sourceMix: const LocalitySourceMix(
        local: 0.4,
        mesh: 0.2,
        federated: 0.4,
      ),
      topAlias: 'Avondale',
    );

    test('projects user-facing label and confidence bucket', () {
      final projection = service.project(
        LocalityProjectionRequest(
          audience: LocalityProjectionAudience.user,
          state: state,
        ),
      );

      expect(projection.primaryLabel, 'Avondale');
      expect(projection.confidenceBucket, 'high');
      expect(projection.nearBoundary, isTrue);
      expect(projection.metadata, isEmpty);
    });

    test('projects admin metadata and predictive trend', () {
      final projection = service.project(
        LocalityProjectionRequest(
          audience: LocalityProjectionAudience.admin,
          state: state,
          includePrediction: true,
        ),
      );

      expect(projection.primaryLabel, 'Avondale');
      expect(projection.metadata['reliabilityTier'], 'established');
      expect(projection.metadata['advisoryStatus'], 'eligible');
      expect(projection.metadata['dominantSource'], 'local');
      expect(projection.metadata['sourceMixSummary'], 'localLed');
      expect(projection.metadata['stabilityClass'], 'accelerating');
      expect(projection.metadata['nextStateRisk'], 'medium');
      expect(projection.metadata['promotionReadiness'], 'established');
      expect(projection.metadata['predictiveTrend'], 'accelerating');
      expect(
        projection.metadata['explanatoryFactors'],
        containsAll(<String>['highConfidence', 'boundaryTension']),
      );
    });
  });
}

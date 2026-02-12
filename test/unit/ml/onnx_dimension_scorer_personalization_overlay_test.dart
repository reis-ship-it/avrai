/// SPOTS OnnxDimensionScorer Personalization Overlay Tests
/// Date: January 2, 2026
/// Purpose: Make federated delta application "real" via safe on-device overlay.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/ai2ai/embedding_delta_collector.dart';
import 'package:avrai/core/constants/vibe_constants.dart';
import 'package:avrai/core/ml/onnx_dimension_scorer.dart';
import 'package:avrai/core/services/infrastructure/storage_service.dart';

import '../../helpers/platform_channel_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OnnxDimensionScorer personalization overlay', () {
    const biasKey = 'onnx_dimension_scorer_bias_v1';

    setUpAll(() async {
      await setupTestStorage();
    });

    setUp(() async {
      // Ensure deterministic state across test runs.
      try {
        await StorageService.instance.aiStorage.remove(biasKey);
      } catch (_) {
        // Best-effort; scorer degrades gracefully if storage isn't ready.
      }
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });

    test('returns all 12 dimensions and applies persisted bias after deltas',
        () async {
      final scorer = OnnxDimensionScorer();

      final base = await scorer.scoreDimensions(const {
        'onboarding_data': <String, dynamic>{},
      });

      expect(base, hasLength(VibeConstants.coreDimensions.length));
      for (final d in VibeConstants.coreDimensions) {
        expect(base[d], inInclusiveRange(0.0, 1.0));
      }

      final idxEnergy =
          VibeConstants.coreDimensions.indexOf('energy_preference');
      expect(base['energy_preference'], equals(0.5));

      final vec = List<double>.filled(VibeConstants.coreDimensions.length, 0.0);
      vec[idxEnergy] = 1.0; // strong positive signal

      await scorer.updateWithDeltas([
        EmbeddingDelta(
          delta: vec,
          timestamp: DateTime.now(),
          category: 'general',
        ),
      ]);

      final adjusted = await scorer.scoreDimensions(const {
        'onboarding_data': <String, dynamic>{},
      });
      expect(adjusted['energy_preference'], equals(0.55)); // 0.5 + clamp(1.0*0.15,0.05)

      // New instance should load persisted overlay.
      final scorer2 = OnnxDimensionScorer();
      final persisted = await scorer2.scoreDimensions(const {
        'onboarding_data': <String, dynamic>{},
      });
      expect(persisted['energy_preference'], equals(0.55));
    });
  });
}


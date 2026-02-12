/// SPOTS PersonalityLearning AI2AI Bounds Tests
/// Date: January 2, 2026
/// Purpose: Regression coverage for safe application of AI2AI learning deltas.
/// - Even if upstream filters fail, applied deltas must remain safe and clamped.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/ai/personality_learning.dart';
import 'package:shared_preferences/shared_preferences.dart' as real_prefs;
import 'package:avrai/core/services/infrastructure/storage_service.dart' as storage;
import 'package:avrai_core/models/personality_profile.dart';

import '../../helpers/platform_channel_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PersonalityLearning.evolveFromAI2AILearning bounds safety', () {
    late PersonalityLearning personalityLearning;

    setUpAll(() async {
      await setupTestStorage();
      real_prefs.SharedPreferences.setMockInitialValues({});
    });

    setUp(() async {
      final mockStorage = getTestStorage();
      final compatPrefs =
          await storage.SharedPreferencesCompat.getInstance(storage: mockStorage);
      personalityLearning = PersonalityLearning.withPrefs(compatPrefs);
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });

    test('clamps extreme AI2AI deltas into [0,1] and records learning event',
        () async {
      const userId = 'bounds_user';

      final base = await personalityLearning.initializePersonality(userId);
      final baseValue = base.dimensions['exploration_eagerness']!;

      // Large positive delta should not overflow the [0,1] contract.
      final positive = AI2AILearningInsight(
        type: AI2AIInsightType.dimensionDiscovery,
        dimensionInsights: const {
          'exploration_eagerness': 100.0,
        },
        learningQuality: 1.0,
        timestamp: DateTime.now(),
      );

      final afterPositive =
          await personalityLearning.evolveFromAI2AILearning(userId, positive);

      final maxUp = (baseValue + PersonalityProfile.maxDriftFromCore)
          .clamp(0.0, 1.0);
      expect(
        afterPositive.dimensions['exploration_eagerness']!,
        equals(maxUp),
      );
      expect(afterPositive.learningHistory['successful_ai2ai_connections'],
          equals(1));

      // Large negative delta should not underflow the [0,1] contract.
      final negative = AI2AILearningInsight(
        type: AI2AIInsightType.dimensionDiscovery,
        dimensionInsights: const {
          'exploration_eagerness': -100.0,
        },
        learningQuality: 1.0,
        timestamp: DateTime.now(),
      );

      final afterNegative =
          await personalityLearning.evolveFromAI2AILearning(userId, negative);
      final maxDown = (baseValue - PersonalityProfile.maxDriftFromCore)
          .clamp(0.0, 1.0);
      expect(afterNegative.dimensions['exploration_eagerness']!, equals(maxDown));

      // Safety invariant: all dimension values remain within [0,1].
      for (final v in afterNegative.dimensions.values) {
        expect(v, inInclusiveRange(0.0, 1.0));
      }
    });
  });
}


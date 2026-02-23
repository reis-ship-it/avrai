import 'package:avrai/core/services/ai_infrastructure/model_retraining_service.dart';
import 'package:avrai/core/services/ai_infrastructure/model_version_manager.dart';
import 'package:avrai/core/services/ai_infrastructure/online_learning_service.dart';
import 'package:avrai/core/services/calling_score/calling_score_data_collector.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _MockCallingScoreDataCollector extends Mock
    implements CallingScoreDataCollector {}

class _MockModelVersionManager extends Mock implements ModelVersionManager {}

class _MockModelRetrainingService extends Mock
    implements ModelRetrainingService {}

void main() {
  group('OnlineLearningService', () {
    test('scheduled retraining enforces strict local-first export', () async {
      final service = OnlineLearningService(
        supabase: _MockSupabaseClient(),
        dataCollector: _MockCallingScoreDataCollector(),
        versionManager: _MockModelVersionManager(),
        retrainingService: _MockModelRetrainingService(),
      );

      final triggered = await service.triggerRetraining(
        reason: 'scheduled',
        newDataCount: OnlineLearningService.minSamplesForRetraining,
      );

      expect(triggered, isFalse);
    });
  });
}

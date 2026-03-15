import 'package:avrai_core/models/boundary/boundary_models.dart';
import 'package:avrai_core/models/interpretation/interpretation_models.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/language_pattern_learning_service.dart';
import 'package:avrai_runtime_os/services/language/language_profile_diagnostics_service.dart';
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_storage_helper.dart';

void main() {
  group('LanguageProfileDiagnosticsService', () {
    late LanguagePatternLearningService learningService;
    late LanguageProfileDiagnosticsService diagnosticsService;

    setUp(() async {
      await TestStorageHelper.initTestStorage();
      await TestStorageHelper.getBox('language_patterns').erase();
      learningService = LanguagePatternLearningService(
        agentIdService: _StubAgentIdService(),
      );
      diagnosticsService = LanguageProfileDiagnosticsService(
        languageLearningService: learningService,
        agentIdService: _StubAgentIdService(),
      );
    });

    tearDown(() async {
      await TestStorageHelper.clearTestStorage();
    });

    test('returns derived user diagnostics without storing raw message text',
        () async {
      await learningService.analyzeMessage(
        'user-1',
        'I absolutely love quiet coffee shops and clear plans.',
        'agent',
      );

      final snapshot = await diagnosticsService.getDiagnosticsForUser('user-1');

      expect(snapshot, isNotNull);
      expect(snapshot!.profile.messageCount, 1);
      expect(snapshot.recentEvents, hasLength(1));
      expect(
        snapshot.recentEvents.first.summary,
        'Learned from a direct agent-chat message.',
      );
      expect(snapshot.recentEvents.first.vocabularySample, contains('quiet'));
      expect(
        snapshot.recentEvents.first.summary,
        isNot(contains('quiet coffee shops')),
      );
    });

    test('returns governance rewrite diagnostics for operator profiles',
        () async {
      await learningService.analyzeSanitizedArtifact(
        profileRef: 'governance_operator_test_admin',
        displayRef: 'governance_operator_test_admin',
        learningScope: 'governance_feedback_rewrite',
        surface: 'admin_reality_system_check_in_feedback',
        artifact: const BoundarySanitizedArtifact(
          pseudonymousActorRef: 'anon_operator',
          summary: 'Shorter summary requested.',
          safeClaims: <String>['transport drift needs a shorter summary'],
          safeQuestions: <String>[],
          safePreferenceSignals: <InterpretationPreferenceSignal>[
            InterpretationPreferenceSignal(
              kind: 'brevity',
              value: 'shorter',
              confidence: 0.9,
            ),
          ],
          learningVocabulary: <String>['transport', 'shorter'],
          learningPhrases: <String>['keep it shorter'],
          redactedText: 'approved rewrite for transport drift',
        ),
      );

      final snapshot = await diagnosticsService.getDiagnosticsForProfileRef(
        'governance_operator_test_admin',
      );

      expect(snapshot, isNotNull);
      expect(snapshot!.recentEvents, hasLength(1));
      expect(snapshot.recentEvents.first.isGovernanceFeedback, isTrue);
      expect(
        snapshot.recentEvents.first.summary,
        'Learned from an approved admin rewrite.',
      );
      expect(
        snapshot.recentEvents.first.vocabularySample,
        contains('transport'),
      );
    });
  });
}

class _StubAgentIdService extends AgentIdService {
  @override
  Future<String> getUserAgentId(String userId) async => 'agent_for_$userId';
}
